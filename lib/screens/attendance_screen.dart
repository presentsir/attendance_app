import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedClass;
  int _currentStudentIndex = 0;
  List<Map<String, dynamic>> _students = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedClass,
              hint: Text('Select Class'),
              items: _getClassDropdownItems(),
              onChanged: (value) async {
                setState(() {
                  _selectedClass = value;
                  _currentStudentIndex = 0;
                });
                await _loadStudents(value!);
              },
            ),
            SizedBox(height: 20),
            if (_students.isNotEmpty)
              Column(
                children: [
                  Text('Roll Number: ${_students[_currentStudentIndex]['rollNumber']}'),
                  Text('Name: ${_students[_currentStudentIndex]['name']}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _markAttendance(true),
                        child: Text('Present'),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () => _markAttendance(false),
                        child: Text('Absent'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _currentStudentIndex > 0
                            ? () => setState(() => _currentStudentIndex--)
                            : null,
                        icon: Icon(Icons.arrow_back),
                      ),
                      IconButton(
                        onPressed: _currentStudentIndex < _students.length - 1
                            ? () => setState(() => _currentStudentIndex++)
                            : null,
                        icon: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getClassDropdownItems() {
    // Fetch classes from Firestore and return dropdown items
    // This is a placeholder. You can implement Firestore fetching here.
    return [];
  }

  Future<void> _loadStudents(String classId) async {
    var students = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('students')
        .get();
    setState(() {
      _students = students.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> _markAttendance(bool isPresent) async {
    await _firestore.collection('attendance').add({
      'classId': _selectedClass,
      'studentId': _students[_currentStudentIndex]['id'],
      'date': DateTime.now().toString(),
      'status': isPresent ? 'Present' : 'Absent',
    });
    if (_currentStudentIndex < _students.length - 1) {
      setState(() {
        _currentStudentIndex++;
      });
    }
  }
}