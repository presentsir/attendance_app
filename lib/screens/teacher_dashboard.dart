import 'package:flutter/material.dart';
import '../models/school_model.dart'; // Import your School model
import 'profile_screen.dart'; // Import your profile screen
import 'attendance_screen.dart'; // Import your attendance screen
import 'records_screen.dart'; // Import your records screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user email
import 'login_screen.dart';
import '../services/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'teacher_notification_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final School school; // School data passed from the login screen
  final String teacherName; // Teacher name passed from the login screen
  final String teacherId; // Add teacherId
  final String classId; // Add classId parameter

  TeacherDashboard({
    required this.school,
    required this.teacherName,
    required this.teacherId, // Add teacherId parameter
    required this.classId, // Add classId to constructor
  });

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex =
      0; // Track the selected index for the bottom navigation bar

  // Define the screens corresponding to the bottom navigation bar items
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with the required data
    _screens = [
      AttendanceScreen(teacherId: widget.teacherId), // Pass teacherId
      RecordsScreen(teacherId: widget.teacherId), // Pass teacherId
      ProfileScreen(
        school: widget.school,
        userEmail: widget.teacherName,
        numberOfClasses: 0,
        studentsPerClass: {},
        teacherId: widget.teacherId, // Add teacherId here
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await UserSession.clearSession();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showUploadTestReportDialog() async {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController scoreController = TextEditingController();
    String selectedStudent = '';

    // Get list of students
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .get();

    final students = studentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'rollNumber': data['rollNumber'],
      };
    }).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Test Report'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Student',
                  border: OutlineInputBorder(),
                ),
                items: students.map((student) {
                  return DropdownMenuItem<String>(
                    value: student['id'] as String,
                    child:
                        Text('${student['name']} (${student['rollNumber']})'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedStudent = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a student';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subject';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(date);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select date';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: scoreController,
                decoration: InputDecoration(
                  labelText: 'Score (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter score';
                  }
                  final score = double.tryParse(value);
                  if (score == null || score < 0 || score > 100) {
                    return 'Please enter a valid score between 0 and 100';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStudent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a student')),
                );
                return;
              }

              try {
                final student =
                    students.firstWhere((s) => s['id'] == selectedStudent);
                await FirebaseFirestore.instance
                    .collection('test_reports')
                    .add({
                  'classId': widget.classId,
                  'studentId': selectedStudent,
                  'rollNumber': student['rollNumber'],
                  'subject': subjectController.text,
                  'date': Timestamp.fromDate(
                      DateFormat('yyyy-MM-dd').parse(dateController.text)),
                  'score': double.parse(scoreController.text),
                  'uploadedBy': widget.teacherId,
                  'uploadedAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Test report uploaded successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error uploading test report: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        children: [
          _buildDashboardCard(
            'Take Attendance',
            Icons.calendar_today,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceScreen(
                  teacherId: widget.teacherId,
                ),
              ),
            ),
          ),
          _buildDashboardCard(
            'View Records',
            Icons.history,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordsScreen(
                  teacherId: widget.teacherId,
                ),
              ),
            ),
          ),
          _buildDashboardCard(
            'Send Notifications',
            Icons.notifications_active,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherNotificationScreen(
                  teacherId: widget.teacherId,
                  teacherName: widget.teacherName,
                  preSelectedClassId: widget.classId.isNotEmpty ? widget.classId : null,
                ),
              ),
            ),
          ),
          _buildDashboardCard(
            'Upload Test Report',
            Icons.upload_file,
            _showUploadTestReportDialog,
          ),
          _buildDashboardCard(
            'Profile',
            Icons.person,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  school: widget.school,
                  userEmail: widget.teacherName,
                  numberOfClasses: 1,
                  studentsPerClass: {'class': 0},
                  teacherId: widget.teacherId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      String title, IconData icon, VoidCallback onPressed) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
