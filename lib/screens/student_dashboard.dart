import 'package:flutter/material.dart';
import '../models/school_model.dart';

class StudentDashboard extends StatelessWidget {
  final School school;
  final String rollNo;

  StudentDashboard({required this.school, required this.rollNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Dashboard - ${school.name}')),
      body: Center(child: Text('Welcome, Roll No: $rollNo!')),
    );
  }
}