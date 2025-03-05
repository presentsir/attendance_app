import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../models/school_model.dart';
import 'teacher_dashboard.dart';

class TeacherSignInScreen extends StatefulWidget {
  @override
  _TeacherSignInScreenState createState() => _TeacherSignInScreenState();
}

class _TeacherSignInScreenState extends State<TeacherSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<Map<String, dynamic>> _schools = [];
  String? _selectedSchool;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      print('Starting to load schools...');
      final String jsonString =
          await rootBundle.loadString('assets/data/SchoolCBSE.json');
      print('JSON string loaded successfully');

      final List<dynamic> jsonData = json.decode(jsonString);
      print('Loaded schools count: ${jsonData.length}');

      final Map<String, Map<String, dynamic>> uniqueSchools = {};

      for (var school in jsonData) {
        if (school is Map<String, dynamic>) {
          final affNo = school['aff_no']?.toString() ?? '';
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

      print('Unique schools count: ${uniqueSchools.length}');

      if (mounted) {
        setState(() {
          _schools = uniqueSchools.values.toList();
          _schools.insert(0, {'name': 'Select School', 'affNo': ''});
        });
      }
    } catch (e, stackTrace) {
      print('Error loading schools: $e');
      print('Stack trace: $stackTrace');
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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First, verify the school exists
      final schoolQuery = await FirebaseFirestore.instance
          .collection('schools')
          .where('aff_no', isEqualTo: _selectedSchool)
          .get();

      if (schoolQuery.docs.isEmpty) {
        // If school doesn't exist in Firestore, create it
        final selectedSchoolData = _schools.firstWhere(
          (school) => school['affNo'] == _selectedSchool,
          orElse: () => {'name': 'Unknown School', 'affNo': _selectedSchool},
        );

        // Create school document in Firestore
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(_selectedSchool)
            .set({
          'name': selectedSchoolData['name'],
          'aff_no': _selectedSchool,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Retry fetching the school
        final retrySchoolQuery = await FirebaseFirestore.instance
            .collection('schools')
            .where('aff_no', isEqualTo: _selectedSchool)
            .get();

        if (retrySchoolQuery.docs.isEmpty) {
          throw 'Failed to create school record';
        }
      }

      // Sign in with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get teacher data
      final teacherQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: _emailController.text.trim())
          .where('schoolId', isEqualTo: _selectedSchool)
          .get();

      if (teacherQuery.docs.isEmpty) {
        throw 'Teacher not found in this school';
      }

      final teacherData = teacherQuery.docs.first.data();
      final school = School.fromFirestore(schoolQuery.docs.first);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherDashboard(
            school: school,
            teacherId: teacherQuery.docs.first.id,
            teacherName: teacherData['name'],
            classId: teacherData['classId'],
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Verify the school exists or create it
      final schoolQuery = await FirebaseFirestore.instance
          .collection('schools')
          .where('aff_no', isEqualTo: _selectedSchool)
          .get();

      if (schoolQuery.docs.isEmpty) {
        // Find school data from the loaded schools
        final selectedSchoolData = _schools.firstWhere(
          (school) => school['affNo'] == _selectedSchool,
          orElse: () => {'name': 'Unknown School', 'affNo': _selectedSchool},
        );

        // Create school document in Firestore
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(_selectedSchool)
            .set({
          'name': selectedSchoolData['name'],
          'aff_no': _selectedSchool,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // Create user with email and password
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create teacher document
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': '+91${_phoneController.text.trim()}',
        'subject': _subjectController.text.trim(),
        'schoolId': _selectedSchool,
        'createdAt': FieldValue.serverTimestamp(),
        'educationBoard': 'CBSE', // Default value
      });

      // Create school in Firestore if needed
      final school = _schools.firstWhere(
        (s) => s['affNo'] == _selectedSchool,
        orElse: () => {'name': 'Unknown School', 'affNo': _selectedSchool},
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherDashboard(
            school: School(
              name: school['name'],
              address: 'Unknown',
              district: 'Unknown',
              state: 'Unknown',
              region: 'Unknown',
              pincode: 0.0,
              affNo: int.tryParse(_selectedSchool!) ?? 0,
              phoneNumber: '',
              email: '',
              principalName: '',
              principalPhone: '',
              principalEmail: '',
            ),
            teacherId: userCredential.user!.uid,
            teacherName: _nameController.text.trim(),
            classId: '',
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Teacher Registration' : 'Teacher Login'),
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
                    _isRegistering ? 'Teacher Registration' : 'Teacher Login',
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
                  if (_isRegistering) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Teacher Contact',
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
                          return 'Please enter your contact number';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'Please enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your subject';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      helperText: _isRegistering
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (_isRegistering && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (_isRegistering) ...[
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 32 : 48),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isRegistering ? _register : _signIn),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isRegistering ? 'Register' : 'Login',
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
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isRegistering = !_isRegistering;
                            });
                          },
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Login'
                          : 'New teacher? Register here',
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    super.dispose();
  }
}
