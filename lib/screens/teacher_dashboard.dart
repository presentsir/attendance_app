import 'package:flutter/material.dart';
import '../models/school_model.dart'; // Import your School model
import 'profile_screen.dart'; // Import your profile screen
import 'attendance_screen.dart'; // Import your attendance screen
import 'records_screen.dart'; // Import your records screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user email

class TeacherDashboard extends StatefulWidget {
  final School school; // School data passed from the login screen
  final String teacherName; // Teacher name passed from the login screen

  TeacherDashboard({required this.school, required this.teacherName});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0; // Track the selected index for the bottom navigation bar

  // Define the screens corresponding to the bottom navigation bar items
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with the required data
    _screens = [
      AttendanceScreen(), // Your attendance screen
      RecordsScreen(), // Your records screen
      ProfileScreen(
        school: widget.school, // Pass the school object
        userEmail: FirebaseAuth.instance.currentUser!.email!, // Pass the user's email
        numberOfClasses: 5, // Example: Pass the number of classes
        studentsPerClass: {
          '1': 30,
          '2': 28,
          '3': 32,
          '4': 29,
          '5': 31,
        }, // Example: Pass students per class
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
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