import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/academic_marks_service.dart';

class EnterMarksScreen extends StatefulWidget {
  final String teacherId;
  final String classId;
  final String className;
  final String testName;
  final DateTime testDate;
  final String? testId;
  final List<Map<String, dynamic>>? studentMarks;

  EnterMarksScreen({
    required this.teacherId,
    required this.classId,
    required this.className,
    required this.testName,
    required this.testDate,
    this.testId,
    this.studentMarks,
  });

  @override
  _EnterMarksScreenState createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  final AcademicMarksService _marksService = AcademicMarksService();
  String? _selectedSubject;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _markControllers = {};

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Geography',
    'Computer Science',
    'Physics',
    'Chemistry',
    'Biology',
    'Economics',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _markControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
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

        // Initialize controllers with existing marks if editing
        if (widget.studentMarks != null) {
          for (var student in _students) {
            final existingMark = widget.studentMarks!.firstWhere(
              (mark) => mark['studentId'] == student['id'],
              orElse: () => {'marks': '0'},
            );
            _markControllers[student['id']] = TextEditingController(
              text: existingMark['marks'].toString(),
            );
          }
        } else {
          // Initialize controllers with empty values for new test
          for (var student in _students) {
            _markControllers[student['id']] = TextEditingController(text: '0');
          }
        }
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

  Future<void> _saveMarks() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentMarks = _students.map((student) {
        final controller = _markControllers[student['id']];
        return {
          'studentId': student['id'],
          'rollNumber': student['rollNumber'],
          'name': student['name'],
          'marks': int.tryParse(controller?.text ?? '0') ?? 0,
        };
      }).toList();

      print('\nSaving test result:');
      print('Class ID: ${widget.classId}');
      print('Test Name: ${widget.testName}');
      print('Subject: ${_selectedSubject}');
      print('Test Date: ${widget.testDate}');
      print('Student Marks: $studentMarks');

      if (widget.testId != null) {
        // Update existing test result
        await _marksService.updateTestResult(
          testId: widget.testId!,
          studentMarks: studentMarks,
        );
      } else {
        // Add new test result
        await _marksService.addTestResult(
          classId: widget.classId,
          subject: _selectedSubject!,
          testDate: widget.testDate,
          testName: widget.testName,
          studentMarks: studentMarks,
          teacherId: widget.teacherId,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks saved successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error saving marks: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving marks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Marks - ${widget.testName}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.testName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Date: ${widget.testDate.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSubject,
                            decoration: InputDecoration(
                              labelText: 'Select Subject',
                              border: OutlineInputBorder(),
                            ),
                            items: _subjects.map((subject) {
                              return DropdownMenuItem<String>(
                                value: subject,
                                child: Text(subject),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubject = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Roll No',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Marks',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                          ..._students.map((student) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(student['rollNumber']),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(student['name']),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller:
                                          _markControllers[student['id']],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveMarks,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text('Save Marks'),
                  ),
                ],
              ),
            ),
    );
  }
}
