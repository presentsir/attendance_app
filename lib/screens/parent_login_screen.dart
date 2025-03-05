import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
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
    // Get screen size
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Login'),
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
                    'Parent Login',
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
                        });
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
                  TextFormField(
                    controller: _rollNoController,
                    decoration: InputDecoration(
                      labelText: 'Student Roll Number',
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
                      labelText: 'Student Contact Number',
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
                            'View Student Profile',
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
