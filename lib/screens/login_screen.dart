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

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _schoolCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'student'; // Default role
  List<School> _schools = [];
  School? _selectedSchool;
  bool _isLoading = false;
  String? _selectedClassId;
  String? _selectedClassName;
  List<QueryDocumentSnapshot> _availableClasses = [];

  @override
  void initState() {
    super.initState();
    _loadSchools();
    _checkExistingSession();
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

  Future<void> _checkExistingSession() async {
    final isLoggedIn = await UserSession.isLoggedIn();
    if (isLoggedIn) {
      final userType = await UserSession.getUserType();
      final userData = await UserSession.getUserData();

      if (userData != null && userType != null) {
        _navigateBasedOnUserType(userType, userData);
      }
    }
  }

  void _navigateBasedOnUserType(
      String userType, Map<String, dynamic> userData) {
    if (!mounted) return;

    final school = School.fromJson(userData['school'] as Map<String, dynamic>);

    if (userType == 'teacher') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherDashboard(
            teacherId: userData['teacherId'],
            school: school,
            teacherName: userData['teacherName'] ?? 'Teacher',
            classId: userData['classId'] ?? '', // Add classId
          ),
        ),
      );
    } else if (userType == 'student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboard(
            school: school,
            rollNo: userData['rollNo'],
            studentName: userData['studentName'],
            classId: userData['classId'],
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a school first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_role == 'student') {
      if (_selectedClassId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select your class'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (_rollNoController.text.trim().isEmpty ||
          _mobileController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter both roll number and mobile number'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      try {
        // Verify student credentials directly with the selected class
        final studentsQuery = await FirebaseFirestore.instance
            .collection('classes')
            .doc(_selectedClassId)
            .collection('students')
            .where('rollNumber', isEqualTo: _rollNoController.text.trim())
            .where('mobileNumber', isEqualTo: _mobileController.text.trim())
            .get();

        if (studentsQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Invalid roll number or mobile number for this class'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        final studentData = studentsQuery.docs.first.data();

        // Save student session data
        await UserSession.saveUserSession(
          userType: 'student',
          userData: {
            'school': _selectedSchool!.toJson(), // Convert school to JSON
            'rollNo': _rollNoController.text.trim(),
            'studentName': studentData['name'] ?? 'Student',
            'classId': _selectedClassId!,
          },
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful! Welcome, ${studentData['name']}'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to student dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              school: _selectedSchool!,
              rollNo: _rollNoController.text.trim(),
              studentName: studentData['name'] ?? 'Student',
              classId: _selectedClassId!,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during login: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } else {
      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Verify if the teacher belongs to the selected school
        final teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(userCredential.user!.uid)
            .get();

        if (!teacherDoc.exists) {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Teacher account not found')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final teacherData = teacherDoc.data() as Map<String, dynamic>;
        if (teacherData['schoolId'] != _selectedSchool!.affNo.toString()) {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('You can only login to your registered school')),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Save teacher session data
        await UserSession.saveUserSession(
          userType: 'teacher',
          userData: {
            'teacherId': userCredential.user!.uid,
            'school': _selectedSchool!.toJson(),
            'teacherName':
                teacherData['name'] ?? _emailController.text.split('@')[0],
          },
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherDashboard(
              school: _selectedSchool!,
              teacherName:
                  teacherData['name'] ?? _emailController.text.split('@')[0],
              teacherId: userCredential.user!.uid,
              classId: teacherData['classId'] ?? '', // Add classId
            ),
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
          SnackBar(
              content: Text('An error occurred. Please try again. Error: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildStudentLoginFields() {
    return Column(
      children: [
        if (_selectedSchool != null) ...[
          SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where('schoolId', isEqualTo: _selectedSchool!.affNo.toString())
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // Check specifically for the index error
                if (snapshot.error.toString().contains('failed-precondition') ||
                    snapshot.error.toString().contains('requires an index')) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.build, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'Setting up database...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Please wait while we complete the initial setup.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  );
                }
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(height: 8),
                        Text(
                          'Error loading classes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Please try again later',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(
                        'Loading classes...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              _availableClasses = snapshot.data?.docs ?? [];

              if (_availableClasses.isEmpty) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(height: 8),
                        Text(
                          'No classes found for this school',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Please contact your teacher to add your class',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Select Your Class',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                  hintText: 'Choose your class',
                ),
                items: _availableClasses.map((classDoc) {
                  return DropdownMenuItem<String>(
                    value: classDoc.id,
                    child: Text(classDoc['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                    _selectedClassName = _availableClasses
                        .firstWhere((doc) => doc.id == value)['name'];
                  });
                },
              );
            },
          ),
        ],
        if (_selectedClassId != null) ...[
          SizedBox(height: 20),
          TextField(
            controller: _rollNoController,
            decoration: InputDecoration(
              labelText: 'Roll Number',
              prefixIcon: Icon(Icons.numbers),
              border: OutlineInputBorder(),
              hintText: 'Enter your roll number',
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          TextField(
            controller: _mobileController,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone),
              hintText: 'Enter registered mobile number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ],
    );
  }

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
                      builder: (context) => TeacherSignInScreen()),
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
                      builder: (context) => StudentSignInScreen()),
                ),
              ),
              SizedBox(height: 16),
              _buildLoginCard(
                'Parent Login',
                Icons.family_restroom,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ParentLoginScreen()),
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
