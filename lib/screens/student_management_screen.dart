import 'package:flutter/material.dart';
import 'add_student_stepper.dart';

class StudentManagementScreen extends StatefulWidget {
  final String classId;
  final String teacherId;

  const StudentManagementScreen({
    Key? key,
    required this.classId,
    required this.teacherId,
  }) : super(key: key);

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing scaffold content ...

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStudentStepper(
                classId: widget.classId,
                teacherId: widget.teacherId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}