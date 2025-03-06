import 'package:flutter/material.dart';
import '../models/school_model.dart'; // Import your School model
import 'profile_screen.dart'; // Import your profile screen
import 'attendance_screen.dart'; // Import your attendance screen
import 'records_screen.dart'; // Import your records screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user email
import 'login_screen.dart';
import '../services/user_session.dart';
import 'notification_screen.dart';
import '../services/notification_service.dart';
import 'test_results_screen.dart';
import 'student_details_screen.dart';
import 'bulk_student_upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDashboard extends StatefulWidget {
  final School school; // School data passed from the login screen
  final String teacherName; // Teacher name passed from the login screen
  final String teacherId; // Add teacherId
  final String classId; // Add classId

  TeacherDashboard({
    required this.school,
    required this.teacherName,
    required this.teacherId, // Add teacherId parameter
    required this.classId, // Add classId parameter
  });

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex =
      0; // Track the selected index for the bottom navigation bar
  final NotificationService _notificationService = NotificationService();
  int _unreadNotifications = 0;

  // Define the screens corresponding to the bottom navigation bar items
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with the required data
    _screens = [
      AttendanceScreen(teacherId: widget.teacherId), // Pass teacherId
      RecordsScreen(teacherId: widget.teacherId), // Pass teacherId
      TestResultsScreen(
        teacherId: widget.teacherId,
        classId: widget.classId,
        className:
            widget.classId, // You might want to pass the actual class name
      ),
      ProfileScreen(
        school: widget.school,
        userEmail: widget.teacherName,
        numberOfClasses: 0,
        studentsPerClass: {},
        teacherId: widget.teacherId, // Add teacherId here
      ),
    ];
    _loadUnreadNotifications();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadUnreadNotifications() {
    _notificationService
        .getUnreadCount(widget.teacherId, widget.classId)
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
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

  void _showClassOptions(
      BuildContext context, String classId, String className) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Class Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('View Students'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsScreen(
                      classId: classId,
                      className: className,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text('Bulk Upload'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BulkStudentUpload(
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Class', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteClass(context, classId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteClass(BuildContext context, String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting class: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(
                        userId: widget.teacherId,
                        isTeacher: true,
                        school: widget.school,
                        classId: widget.classId,
                      ),
                    ),
                  );
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    school: widget.school,
                    userEmail: widget.teacherName,
                    numberOfClasses: 0,
                    studentsPerClass: {},
                    teacherId: widget.teacherId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade),
            label: 'Test Results',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
