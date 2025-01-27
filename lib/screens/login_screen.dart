import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/json_service.dart';
import '../models/school_model.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'teacher_signin_screen.dart'; // Import the teacher sign-in screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _schoolCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'student'; // Default role
  List<School> _schools = [];
  School? _selectedSchool;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    final schools = await JsonService().loadSchools();
    if (schools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No schools found in the JSON file')),
      );
    }
    setState(() {
      _schools = schools;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final schoolCode = int.tryParse(_schoolCodeController.text);
    if (schoolCode == null && _selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or enter a valid school code')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final school = _selectedSchool ?? _schools.firstWhere(
      (school) => school.affNo == schoolCode,
      orElse: () => School(
        name: '',
        affNo: 0,
        state: '',
        district: '',
        region: '',
        address: '',
        pincode: 0,
      ),
    );

    if (school.affNo == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School not found')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (_role == 'teacher') {
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherDashboard(school: school, teacherName: _nameController.text),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'user-disabled':
            errorMessage = 'The user has been disabled.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          default:
            errorMessage = 'An unknown error occurred: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again. Error: $e')),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboard(school: school, rollNo: _rollNoController.text),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownSearch<School>(
              items: _schools,
              itemAsString: (School school) => '${school.name} (${school.affNo})',
              onChanged: (School? school) {
                setState(() {
                  _selectedSchool = school;
                  if (school != null) {
                    _schoolCodeController.text = school.affNo.toString();
                  }
                });
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Select a school',
                  hintText: 'Search by school name or code',
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search by school name or code',
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _schoolCodeController,
              decoration: InputDecoration(labelText: 'Or enter school code (aff_no)'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _selectedSchool = null; // Clear selected school if user types manually
                });
              },
            ),
            SizedBox(height: 20),
            RadioListTile(
              title: Text('Student'),
              value: 'student',
              groupValue: _role,
              onChanged: (value) => setState(() => _role = value.toString()),
            ),
            RadioListTile(
              title: Text('Teacher'),
              value: 'teacher',
              groupValue: _role,
              onChanged: (value) => setState(() => _role = value.toString()),
            ),
            if (_role == 'teacher') ...[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
            if (_role == 'student')
              TextField(
                controller: _rollNoController,
                decoration: InputDecoration(labelText: 'Roll Number'),
              ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: Text('Login'),
                  ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherSignInScreen(),
                  ),
                );
              },
              child: Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}