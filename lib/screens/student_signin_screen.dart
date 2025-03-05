import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../models/school_model.dart';
import 'student_dashboard.dart';

class StudentSignInScreen extends StatefulWidget {
  @override
  _StudentSignInScreenState createState() => _StudentSignInScreenState();
}

class _StudentSignInScreenState extends State<StudentSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rollNoController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchool;
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      print('Starting to load schools...'); // Debug print
      final String jsonString =
          await rootBundle.loadString('assets/data/SchoolCBSE.json');
      print('JSON string loaded successfully'); // Debug print

      final List<dynamic> jsonData = json.decode(jsonString);
      print('Loaded schools count: ${jsonData.length}'); // Debug print

      // Create a map to store unique schools by affNo
      final Map<String, Map<String, dynamic>> uniqueSchools = {};

      for (var school in jsonData) {
        if (school is Map<String, dynamic>) {
          final affNo = school['affNo']?.toString() ?? '';
          final name = school['name']?.toString() ?? '';

          if (affNo.isNotEmpty &&
              name.isNotEmpty &&
              !uniqueSchools.containsKey(affNo)) {
            uniqueSchools[affNo] = {
              'name': name,
              'affNo': affNo,
            };
          }
        }
      }

      print('Unique schools count: ${uniqueSchools.length}'); // Debug print

      if (mounted) {
        setState(() {
          _schools = uniqueSchools.values.toList();
          // Add a default "Select School" option
          _schools.insert(0, {'name': 'Select School', 'affNo': ''});
        });
      }
    } catch (e, stackTrace) {
      print('Error loading schools: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print stack trace
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schools: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedSchool == null) return;

    setState(() {
      _isLoading = true;
      _classes = [];
      _selectedClass = null;
    });

    try {
      final classesQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('schoolId', isEqualTo: _selectedSchool)
          .get();

      setState(() {
        _classes = classesQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Class',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading classes: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading classes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First, verify the school exists
      final schoolQuery = await FirebaseFirestore.instance
          .collection('schools')
          .where('affNo', isEqualTo: _selectedSchool)
          .get();

      if (schoolQuery.docs.isEmpty) {
        throw 'School not found';
      }

      final school = School.fromFirestore(schoolQuery.docs.first);

      // Then, find the student in the selected class
      final studentQuery = await FirebaseFirestore.instance
          .collection('classes')
          .doc(_selectedClass)
          .collection('students')
          .where('rollNumber', isEqualTo: _rollNoController.text.trim())
          .where('mobileNumber',
              isEqualTo: '+91${_phoneController.text.trim()}')
          .get();

      if (studentQuery.docs.isEmpty) {
        throw 'Student not found or invalid details';
      }

      final studentData = studentQuery.docs.first.data();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboard(
            school: school,
            classId: _selectedClass!,
            rollNo: _rollNoController.text.trim(),
            studentName: studentData['name'] ?? 'Student',
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
    // Get screen size
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Student Login',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  DropdownSearch<Map<String, dynamic>>(
                    items: _schools,
                    itemAsString: (school) =>
                        school['name'] ?? 'Unknown School',
                    selectedItem: _schools.firstWhere(
                      (school) => school['affNo'] == _selectedSchool,
                      orElse: () => _schools.first,
                    ),
                    onChanged: (school) {
                      if (school != null) {
                        setState(() {
                          _selectedSchool = school['affNo'];
                          _selectedClass = null;
                          _classes = [];
                        });
                        _loadClasses();
                      }
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Select School',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                    ),
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search school by name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  if (_selectedSchool != null)
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                      items: _classes.map((classData) {
                        return DropdownMenuItem<String>(
                          value: classData['id'],
                          child: Text(
                            classData['name'],
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClass = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a class';
                        }
                        return null;
                      },
                    ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextFormField(
                    controller: _rollNoController,
                    decoration: InputDecoration(
                      labelText: 'Roll Number',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter roll number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      border: OutlineInputBorder(),
                      prefixText: '+91 ',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
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
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyStudent,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
