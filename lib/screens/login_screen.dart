import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/json_service.dart';
import '../models/school_model.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'teacher_signin_screen.dart'; // Import the teacher sign-in screen
import 'student_signin_screen.dart';
import '../services/user_session.dart';
import 'parent_login_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              Text(
                'Welcome to Attendance App',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              _buildLoginCard(
                'Teacher Login',
                Icons.school,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherSignInScreen(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildLoginCard(
                'Student Login',
                Icons.person,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentSignInScreen(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildLoginCard(
                'Parent Login',
                Icons.family_restroom,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ParentLoginScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      elevation: 5,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
