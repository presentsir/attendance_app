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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
