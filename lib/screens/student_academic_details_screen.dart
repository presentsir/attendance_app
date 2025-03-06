import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentAcademicDetailsScreen extends StatefulWidget {
  final String studentId;
  final String classId;
  final String studentName;

  StudentAcademicDetailsScreen({
    required this.studentId,
    required this.classId,
    required this.studentName,
  });

  @override
  _StudentAcademicDetailsScreenState createState() =>
      _StudentAcademicDetailsScreenState();
}

class _StudentAcademicDetailsScreenState
    extends State<StudentAcademicDetailsScreen> {
  final _testNameController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _testResult;

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

  Future<void> _searchTestResult() async {
    if (_testNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter test name')),
      );
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Searching for test results with:');
      print('Class ID: ${widget.classId}');
      print('Student Name: ${widget.studentName}');
      print('Test Name: ${_testNameController.text.trim()}');
      print('Subject: ${_subjectController.text.trim()}');
      print('Date: ${_selectedDate.toString()}');

      // First, get all test results for the class
      final querySnapshot = await FirebaseFirestore.instance
          .collection('academic_marks')
          .where('classId', isEqualTo: widget.classId)
          .get();

      print('Found ${querySnapshot.docs.length} test results for the class');

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _testResult = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No test results found for this class')),
        );
        return;
      }

      // Find matching test result
      QueryDocumentSnapshot? matchingTest;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final testDate = (data['testDate'] as Timestamp).toDate();
        final isSameDate = testDate.year == _selectedDate.year &&
            testDate.month == _selectedDate.month &&
            testDate.day == _selectedDate.day;

        print('\nChecking test result:');
        print('Test Name in DB: ${data['testName']}');
        print('Subject in DB: ${data['subject']}');
        print('Date in DB: ${testDate.toString()}');
        print('Is same date: $isSameDate');
        print(
            'Is same test name: ${data['testName'] == _testNameController.text.trim()}');
        print(
            'Is same subject: ${data['subject'] == _subjectController.text.trim()}');

        if (data['testName'] == _testNameController.text.trim() &&
            data['subject'] == _subjectController.text.trim() &&
            isSameDate) {
          matchingTest = doc;
          print('Found matching test!');
          break;
        }
      }

      if (matchingTest == null) {
        setState(() {
          _testResult = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No test result found for the given details')),
        );
        return;
      }

      final testData = matchingTest.data() as Map<String, dynamic>;
      print('\nFound test data:');
      print('Test Name: ${testData['testName']}');
      print('Subject: ${testData['subject']}');
      print('Student Marks: ${testData['studentMarks']}');

      // Find the student's marks by name
      final studentMarks = testData['studentMarks'] as List;
      print('\nLooking for student with name: ${widget.studentName}');
      print(
          'Available students: ${studentMarks.map((m) => '${m['name']} (Roll: ${m['rollNumber']})').toList()}');

      final studentMark = studentMarks.firstWhere(
        (mark) => mark['name'] == widget.studentName,
        orElse: () {
          print('Student not found in test results');
          return null;
        },
      );

      if (studentMark == null) {
        setState(() {
          _testResult = null;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No marks found for this student in this test')),
        );
        return;
      }

      print('\nFound student mark:');
      print('Student Name: ${widget.studentName}');
      print('Roll Number: ${studentMark['rollNumber']}');
      print('Marks: ${studentMark['marks']}');

      setState(() {
        _testResult = {
          'testName': testData['testName'],
          'subject': testData['subject'],
          'testDate': testData['testDate'],
          'marks': studentMark['marks'],
          'rollNumber': studentMark['rollNumber'],
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching test result: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching test result: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Academic Details'),
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
                      'Search Test Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Student: ${widget.studentName}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
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
                    DropdownButtonFormField<String>(
                      value: _subjectController.text.isEmpty
                          ? null
                          : _subjectController.text,
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
                          _subjectController.text = value ?? '';
                        });
                      },
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
                    ElevatedButton(
                      onPressed: _searchTestResult,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text('Search Result'),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_testResult != null) ...[
              SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Test Result',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Roll Number: ${_testResult!['rollNumber']}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You got ${_testResult!['marks']} marks in ${_testResult!['subject']}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Test: ${_testResult!['testName']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy').format((_testResult!['testDate'] as Timestamp).toDate())}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
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
    _subjectController.dispose();
    super.dispose();
  }
}
