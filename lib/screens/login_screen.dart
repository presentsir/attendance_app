import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/json_service.dart';
import '../models/school_model.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _schoolCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  String _role = 'student'; // Default role
  List<School> _schools = [];
  School? _selectedSchool;

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

  void _handleLogin() {
    final schoolCode = int.tryParse(_schoolCodeController.text);
    if (schoolCode == null && _selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select or enter a valid school code')),
      );
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
      return;
    }

    if (_role == 'teacher') {
      // Navigate to teacher dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherDashboard(school: school, teacherName: _nameController.text),
        ),
      );
    } else {
      // Navigate to student dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDashboard(school: school, rollNo: _rollNoController.text),
        ),
      );
    }
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
            if (_role == 'teacher')
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Teacher Name'),
              ),
            if (_role == 'student')
              TextField(
                controller: _rollNoController,
                decoration: InputDecoration(labelText: 'Roll Number'),
              ),

//             Row(
//   children: [
//     Expanded(
//       child: DropdownSearch<School>(
//         items: _schools,
//         itemAsString: (School school) => '${school.name} (${school.affNo})',
//         onChanged: (School? school) {
//           setState(() {
//             _selectedSchool = school;
//             if (school != null) {
//               _schoolCodeController.text = school.affNo.toString();
//             }
//           });
//         },
//         dropdownDecoratorProps: DropDownDecoratorProps(
//           dropdownSearchDecoration: InputDecoration(
//             labelText: 'Select a school',
//             hintText: 'Search by school name or code',
//           ),
//         ),
//         popupProps: PopupProps.menu(
//           showSearchBox: true,
//           searchFieldProps: TextFieldProps(
//             decoration: InputDecoration(
//               hintText: 'Search by school name or code',
//             ),
//           ),
//         ),
//       ),
//     ),
//     IconButton(
//       icon: Icon(Icons.clear),
//       onPressed: () {
//         setState(() {
//           _selectedSchool = null;
//           _schoolCodeController.clear();
//         });
//       },
//     ),
//   ],
// ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}