import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/academic_marks_service.dart';
import 'enter_marks_screen.dart';

class TestResultsScreen extends StatefulWidget {
  final String teacherId;
  final String classId;
  final String className;

  TestResultsScreen({
    required this.teacherId,
    required this.classId,
    required this.className,
  });

  @override
  _TestResultsScreenState createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final _testNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedClassId;
  String? _selectedClassName;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: widget.teacherId)
          .get();

      setState(() {
        _classes = classesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        // Set initial class if provided
        if (widget.classId.isNotEmpty) {
          _selectedClassId = widget.classId;
          _selectedClassName = widget.className;
          _loadStudents(widget.classId);
        }
      });
    } catch (e) {
      print('Error loading classes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading classes: $e')),
      );
    }
  }

  Future<void> _loadStudents(String classId) async {
    setState(() => _isLoading = true);
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      setState(() {
        _students = studentsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList()
          ..sort((a, b) {
            int aRoll = int.tryParse(a['rollNumber'].toString()) ?? 0;
            int bRoll = int.tryParse(b['rollNumber'].toString()) ?? 0;
            return aRoll.compareTo(bRoll);
          });
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _proceedToEnterMarks() async {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    if (_testNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter test name')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnterMarksScreen(
          teacherId: widget.teacherId,
          classId: _selectedClassId!,
          className: _selectedClassName!,
          testName: _testNameController.text.trim(),
          testDate: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Results'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Test Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                      ),
                      items: _classes.map((classData) {
                        return DropdownMenuItem<String>(
                          value: classData['id'],
                          child: Text(classData['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                          _selectedClassName = _classes
                              .firstWhere((c) => c['id'] == value)['name'];
                          _loadStudents(value!);
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _testNameController,
                      decoration: InputDecoration(
                        labelText: 'Test Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                      ),
                      trailing: TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text('Change Date'),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_selectedClassId != null && _students.isNotEmpty)
                      Text(
                        '${_students.length} students in ${_selectedClassName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _proceedToEnterMarks,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text('Proceed to Enter Marks'),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedClassId != null) ...[
              SizedBox(height: 24),
              Text(
                'Recent Test Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('academic_marks')
                    .where('classId', isEqualTo: _selectedClassId)
                    .orderBy('testDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final testResults = snapshot.data!.docs;

                  if (testResults.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No test results found'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: testResults.length,
                    itemBuilder: (context, index) {
                      final result = testResults[index];
                      final data = result.data() as Map<String, dynamic>;
                      final date = (data['testDate'] as Timestamp).toDate();

                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(data['testName']),
                          subtitle: Text(
                            '${data['subject']} • ${DateFormat('dd MMM yyyy').format(date)}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EnterMarksScreen(
                                    teacherId: widget.teacherId,
                                    classId: _selectedClassId!,
                                    className: _selectedClassName!,
                                    testName: data['testName'],
                                    testDate: date,
                                    testId: result.id,
                                    studentMarks:
                                        List<Map<String, dynamic>>.from(
                                            data['studentMarks']),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _testNameController.dispose();
    super.dispose();
  }
}
