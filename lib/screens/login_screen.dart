import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/json_service.dart';
import '../models/school_model.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'teacher_signin_screen.dart'; // Import the teacher sign-in screen
import '../services/user_session.dart';
import 'parent_dashboard.dart';
import 'forgot_password_screen.dart';

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
  final _parentMobileController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _parentMobileController.dispose();
    super.dispose();
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

    // Convert the stored school JSON back to a School object
    final school = School.fromJson(userData['school'] as Map<String, dynamic>);

    if (userType == 'teacher') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherDashboard(
            teacherId: userData['teacherId'],
            school: school,
            teacherName: userData['teacherName'] ?? 'Teacher',
            classId: userData['classId'],
          ),
        ),
      );
    } else if (userType == 'student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDashboard(
            userId: userData['rollNo'],
            studentId: userData['rollNo'],
            classId: userData['classId'],
            school: school,
            studentName: userData['studentName'] ?? 'Student',
          ),
        ),
      );
    } else if (userType == 'parent') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParentDashboard(
            mobileNumber: userData['mobileNumber'],
            school: school,
            children: List<Map<String, dynamic>>.from(userData['children']),
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
            builder: (context) => StudentDashboard(
              userId: _rollNoController.text.trim(),
              studentId: _rollNoController.text.trim(),
              classId: _selectedClassId!,
              school: _selectedSchool!,
              studentName: studentData['name'] ?? 'Student',
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

        // Get the teacher's class ID
        final classQuery = await FirebaseFirestore.instance
            .collection('classes')
            .where('schoolId', isEqualTo: _selectedSchool!.affNo.toString())
            .where('teacherId', isEqualTo: userCredential.user!.uid)
            .get();

        String? classId;
        if (classQuery.docs.isNotEmpty) {
          classId = classQuery.docs.first.id;
        }

        // Save teacher session data
        await UserSession.saveUserSession(
          userType: 'teacher',
          userData: {
            'teacherId': userCredential.user!.uid,
            'school': _selectedSchool!.toJson(),
            'teacherName':
                teacherData['name'] ?? _emailController.text.split('@')[0],
            'classId': classId,
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
              classId: classId ?? '', // Pass empty string if no class assigned
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

  Future<void> _handleParentLogin() async {
    if (_selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a school first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_parentMobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get all classes in the school
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('schoolId', isEqualTo: _selectedSchool!.affNo.toString())
          .get();

      List<Map<String, dynamic>> children = [];

      // Search for students with matching mobile number in each class
      for (var classDoc in classesSnapshot.docs) {
        final studentsQuery = await classDoc.reference
            .collection('students')
            .where('mobileNumber',
                isEqualTo: _parentMobileController.text.trim())
            .get();

        for (var studentDoc in studentsQuery.docs) {
          final studentData = studentDoc.data();
          children.add({
            'id': studentDoc.id,
            'name': studentData['name'] ?? 'Student',
            'classId': classDoc.id,
            'className': classDoc['name'],
          });
        }
      }

      if (children.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No students found with this mobile number'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Save parent session data
      await UserSession.saveUserSession(
        userType: 'parent',
        userData: {
          'school': _selectedSchool!.toJson(),
          'mobileNumber': _parentMobileController.text.trim(),
          'children': children,
        },
      );

      // Navigate to parent dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ParentDashboard(
            mobileNumber: _parentMobileController.text.trim(),
            school: _selectedSchool!,
            children: children,
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
  }

  Widget _buildStudentLoginFields() {
    return Column(
      children: [
        if (_selectedSchool != null) ...[
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where('schoolId', isEqualTo: _selectedSchool!.affNo.toString())
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final classes = snapshot.data?.docs ?? [];

              if (classes.isEmpty) {
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

              _availableClasses = classes;

              return DropdownButtonFormField<String>(
                value: _selectedClassId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Select Your Class',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_),
                  hintText: 'Choose your class',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: classes.map((classDoc) {
                  return DropdownMenuItem<String>(
                    value: classDoc.id,
                    child: Text(
                      classDoc['name'],
                      overflow: TextOverflow.ellipsis,
                    ),
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
          SizedBox(height: 16),
          TextField(
            controller: _rollNoController,
            decoration: InputDecoration(
              labelText: 'Roll Number',
              prefixIcon: Icon(Icons.numbers),
              border: OutlineInputBorder(),
              hintText: 'Enter your roll number',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _mobileController,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              prefixIcon: Icon(Icons.phone),
              hintText: 'Enter registered mobile number',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select School',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    DropdownSearch<School>(
                      items: _schools,
                      itemAsString: (School school) =>
                          '${school.name} (${school.affNo})',
                      onChanged: (School? school) {
                        setState(() {
                          _selectedSchool = school;
                          _selectedClassId = null;
                          _selectedClassName = null;
                          if (school != null) {
                            _schoolCodeController.text =
                                school.affNo.toString();
                          }
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select a school',
                          hintText: 'Search by school name or code',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search by school name or code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          RadioListTile(
                            title: Text('Student'),
                            value: 'student',
                            groupValue: _role,
                            onChanged: (value) => setState(() {
                              _role = value.toString();
                              _selectedClassId = null;
                              _selectedClassName = null;
                            }),
                          ),
                          Divider(height: 1),
                          RadioListTile(
                            title: Text('Teacher'),
                            value: 'teacher',
                            groupValue: _role,
                            onChanged: (value) => setState(() {
                              _role = value.toString();
                              _selectedClassId = null;
                              _selectedClassName = null;
                            }),
                          ),
                          Divider(height: 1),
                          RadioListTile(
                            title: Text('Parent'),
                            value: 'parent',
                            groupValue: _role,
                            onChanged: (value) => setState(() {
                              _role = value.toString();
                              _selectedClassId = null;
                              _selectedClassName = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_role == 'student')
                      _buildStudentLoginFields()
                    else if (_role == 'teacher') ...[
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (_emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Please enter your email first'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (_selectedSchool == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Please select your school first'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  email: _emailController.text,
                                  school: _selectedSchool!,
                                ),
                              ),
                            );
                          },
                          child: Text('Forgot Password?'),
                        ),
                      ),
                    ] else if (_role == 'parent') ...[
                      TextFormField(
                        controller: _parentMobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          hintText: 'Enter registered mobile number',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mobile number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed:
                        _role == 'parent' ? _handleParentLogin : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 56),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _role == 'parent' ? 'Login' : 'Login',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
            SizedBox(height: 16),
            if (_role == 'teacher')
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
            if (_role == 'student')
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Note: Students can login with roll number and mobile number provided by their teacher.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
            if (_role == 'parent')
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Note: Parents can login using the mobile number registered with their child\'s account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
