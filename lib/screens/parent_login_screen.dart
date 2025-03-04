import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/school_model.dart';
import 'parent_dashboard.dart';

class ParentLoginScreen extends StatefulWidget {
  @override
  _ParentLoginScreenState createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rollNoController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchool;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/SchoolCBSE.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _schools = jsonData
            .map((school) => {
                  'name': school['name'],
                  'affNo': school['affNo'],
                })
            .toList();
      });
    } catch (e) {
      print('Error loading schools: $e');
    }
  }

  Future<void> _verifyStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First, find the school
      final schoolQuery = await FirebaseFirestore.instance
          .collection('schools')
          .where('affNo', isEqualTo: _selectedSchool)
          .get();

      if (schoolQuery.docs.isEmpty) {
        throw 'School not found';
      }

      final school = School.fromFirestore(schoolQuery.docs.first);

      // Then, find the student in any class of the school
      final classesQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('schoolId', isEqualTo: school.affNo.toString())
          .get();

      String? foundClassId;
      Map<String, dynamic>? studentData;

      for (var classDoc in classesQuery.docs) {
        final studentQuery = await classDoc.reference
            .collection('students')
            .where('rollNumber', isEqualTo: _rollNoController.text.trim())
            .where('mobileNumber',
                isEqualTo: '+91${_phoneController.text.trim()}')
            .get();

        if (studentQuery.docs.isNotEmpty) {
          foundClassId = classDoc.id;
          studentData = studentQuery.docs.first.data();
          break;
        }
      }

      if (foundClassId == null || studentData == null) {
        throw 'Student not found or invalid details';
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParentDashboard(
            school: school,
            classId: foundClassId!,
            studentData: studentData!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Student Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              DropdownButtonFormField<String>(
                value: _selectedSchool,
                decoration: InputDecoration(
                  labelText: 'Select School',
                  border: OutlineInputBorder(),
                ),
                items: _schools.map((school) {
                  return DropdownMenuItem<String>(
                    value: school['affNo'],
                    child: Text(school['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSchool = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a school';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _rollNoController,
                decoration: InputDecoration(
                  labelText: 'Student Roll Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter roll number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Student Contact Number',
                  border: OutlineInputBorder(),
                  prefixText: '+91 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyStudent,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('View Student Profile'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rollNoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
