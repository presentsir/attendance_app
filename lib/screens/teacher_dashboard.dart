import 'package:flutter/material.dart';
import '../models/school_model.dart';

class TeacherDashboard extends StatelessWidget {
  final School school;
  final String teacherName;

  TeacherDashboard({required this.school, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teacher Dashboard - ${school.name}')),
      body: Center(child: Text('Welcome, $teacherName!')),
    );
  }
}