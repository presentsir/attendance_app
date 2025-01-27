import 'package:flutter/material.dart';
import '../models/school_model.dart';
import 'attendance_screen.dart'; // Import your attendance screen
import 'records_screen.dart'; // Import your records screen
import 'profile_screen.dart'; // Import your profile screen

class TeacherDashboard extends StatefulWidget {
  final School school;
  final String teacherName;

  TeacherDashboard({required this.school, required this.teacherName});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0; // Track the selected index for the bottom navigation bar

  // Define the screens corresponding to the bottom navigation bar items
  final List<Widget> _screens = [
    AttendanceScreen(), // Your attendance screen
    RecordsScreen(), // Your records screen
    ProfileScreen(), // Your profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Teacher Dashboard - ${widget.school.name}'),
      // ),
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