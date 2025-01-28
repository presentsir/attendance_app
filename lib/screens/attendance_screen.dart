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
  Map<String, String> _attendanceStatus = {}; // Track attendance status for each student

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
            // Dropdown to select class
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var classes = snapshot.data!.docs;
                return DropdownButton<String>(
                  value: _selectedClass,
                  hint: Text('Select Class'),
                  items: classes.map((classDoc) {
                    return DropdownMenuItem<String>(
                      value: classDoc.id,
                      child: Text(classDoc['name']),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      _selectedClass = value;
                      _currentStudentIndex = 0;
                      _attendanceStatus.clear(); // Clear previous attendance data
                    });
                    await _loadStudents(value!);
                  },
                );
              },
            ),
            SizedBox(height: 20),
            if (_students.isNotEmpty)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display student roll number and name
                    Text(
                      'Roll Number: ${_students[_currentStudentIndex]['rollNumber']}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Name: ${_students[_currentStudentIndex]['name']}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 40),
                    // Present and Absent buttons (bigger size)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => _markAttendance(true),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            textStyle: TextStyle(fontSize: 24),
                          ),
                          child: Text('Present'),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () => _markAttendance(false),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            textStyle: TextStyle(fontSize: 24),
                          ),
                          child: Text('Absent'),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    // Back and Forward buttons (icons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentStudentIndex > 0
                              ? () => setState(() => _currentStudentIndex--)
                              : null,
                          icon: Icon(Icons.arrow_back, size: 40),
                        ),
                        SizedBox(width: 20),
                        IconButton(
                          onPressed: _currentStudentIndex < _students.length - 1
                              ? () => setState(() => _currentStudentIndex++)
                              : null,
                          icon: Icon(Icons.arrow_forward, size: 40),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Save button (visible only when all students are marked)
                    if (_attendanceStatus.length == _students.length)
                      ElevatedButton(
                        onPressed: _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          textStyle: TextStyle(fontSize: 24),
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Save Attendance'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Load students for the selected class
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

  // Mark attendance for the current student
  Future<void> _markAttendance(bool isPresent) async {
    String studentId = _students[_currentStudentIndex]['id'];
    setState(() {
      _attendanceStatus[studentId] = isPresent ? 'Present' : 'Absent';
    });

    // Move to the next student automatically
    if (_currentStudentIndex < _students.length - 1) {
      setState(() {
        _currentStudentIndex++;
      });
    }
  }

  // Save attendance to Firestore
  Future<void> _saveAttendance() async {
    String date = DateTime.now().toString().split(' ')[0]; // Get today's date
    await _firestore.collection('attendance').doc(date).set({
      'classId': _selectedClass,
      'attendance': _attendanceStatus,
      'date': date,
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance saved successfully!')),
    );

    // Reset the screen
    setState(() {
      _selectedClass = null;
      _students.clear();
      _attendanceStatus.clear();
      _currentStudentIndex = 0;
    });
  }
}