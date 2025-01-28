import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BulkStudentUpload extends StatefulWidget {
  final String classId;

  BulkStudentUpload({required this.classId});

  @override
  _BulkStudentUploadState createState() => _BulkStudentUploadState();
}

class _BulkStudentUploadState extends State<BulkStudentUpload> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _startRollController = TextEditingController();
  final TextEditingController _endRollController = TextEditingController();
  final List<StudentData> _students = [];
  bool _isLoading = true;
  Set<String> _existingRollNumbers = {};

  @override
  void initState() {
    super.initState();
    _loadExistingStudents();
  }

  Future<void> _loadExistingStudents() async {
    setState(() => _isLoading = true);
    try {
      final QuerySnapshot studentsSnapshot = await _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .get();

      _students.clear();
      _existingRollNumbers.clear();

      for (var doc in studentsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        _students.add(StudentData(
          id: doc.id,
          rollNumber: data['rollNumber'],
          nameController: TextEditingController(text: data['name']),
          mobileController: TextEditingController(text: data['mobileNumber']),
        ));
        _existingRollNumbers.add(data['rollNumber']);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bulk Student Upload'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Only show roll number range inputs if no existing students
                  if (_students.isEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startRollController,
                            decoration: InputDecoration(labelText: 'Start Roll Number'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _endRollController,
                            decoration: InputDecoration(labelText: 'End Roll Number'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _generateStudentList,
                      child: Text('Generate Student List'),
                    ),
                  ],
                  SizedBox(height: 20),
                  // Column headers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text('Roll No.', style: TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(width: 10),
                        Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(width: 10),
                        Expanded(flex: 2, child: Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(_students[index].rollNumber),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _students[index].nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter name',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _students[index].mobileController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter mobile',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveStudents,
                    child: Text('Save Students'),
                  ),
                ],
              ),
            ),
    );
  }

  void _generateStudentList() {
    int startRoll = int.tryParse(_startRollController.text) ?? 0;
    int endRoll = int.tryParse(_endRollController.text) ?? 0;

    if (startRoll > endRoll) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start roll number must be less than end roll number')),
      );
      return;
    }

    // Check for duplicate roll numbers
    Set<String> newRollNumbers = {};
    for (int i = startRoll; i <= endRoll; i++) {
      if (_existingRollNumbers.contains(i.toString()) ||
          newRollNumbers.contains(i.toString())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Roll number ${i} already exists')),
        );
        return;
      }
      newRollNumbers.add(i.toString());
    }

    setState(() {
      for (int i = startRoll; i <= endRoll; i++) {
        _students.add(StudentData(
          rollNumber: i.toString(),
          nameController: TextEditingController(),
          mobileController: TextEditingController(),
        ));
      }
    });
  }

  Future<void> _saveStudents() async {
    try {
      // Validation for empty fields
      for (var student in _students) {
        if (student.nameController.text.isEmpty ||
            student.mobileController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please fill all fields for roll number ${student.rollNumber}')),
          );
          return;
        }
      }

      // Batch write to Firestore
      WriteBatch batch = _firestore.batch();

      for (var student in _students) {
        DocumentReference docRef;
        if (student.id != null) {
          // Update existing student
          docRef = _firestore
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc(student.id);
        } else {
          // Add new student
          docRef = _firestore
              .collection('classes')
              .doc(widget.classId)
              .collection('students')
              .doc();
        }

        batch.set(docRef, {
          'rollNumber': student.rollNumber,
          'name': student.nameController.text,
          'mobileNumber': student.mobileController.text,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Students data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (var student in _students) {
      student.nameController.dispose();
      student.mobileController.dispose();
    }
    _startRollController.dispose();
    _endRollController.dispose();
    super.dispose();
  }
}

class StudentData {
  final String? id;  // Firestore document ID
  final String rollNumber;
  final TextEditingController nameController;
  final TextEditingController mobileController;

  StudentData({
    this.id,
    required this.rollNumber,
    required this.nameController,
    required this.mobileController,
  });
}