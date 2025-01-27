import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart'; // Import your School model

class ProfileScreen extends StatefulWidget {
  final School school;
  final String userEmail;
  final int numberOfClasses; // Add this parameter
  final Map<String, int> studentsPerClass; // Add this parameter

  ProfileScreen({
    required this.school,
    required this.userEmail,
    required this.numberOfClasses,
    required this.studentsPerClass,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display School Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('School Name: ${widget.school.name}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('School Code: ${widget.school.affNo}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('Email: ${widget.userEmail}', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Add Class Section
            TextField(
              controller: _classNameController,
              decoration: InputDecoration(labelText: 'Class Name'),
            ),
            ElevatedButton(
              onPressed: _addClass,
              child: Text('Add Class'),
            ),
            SizedBox(height: 20),

            // Add Student Section
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('classes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var classes = snapshot.data!.docs;
                return DropdownButton<String>(
                  value: _selectedClass,
                  hint: Text('Select Class'),
                  items: classes.map((classDoc) {
                    return DropdownMenuItem<String>(
                      value: classDoc.id,
                      child: Text(classDoc['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                );
              },
            ),
            TextField(
              controller: _studentNameController,
              decoration: InputDecoration(labelText: 'Student Name'),
            ),
            TextField(
              controller: _rollNumberController,
              decoration: InputDecoration(labelText: 'Roll Number'),
            ),
            TextField(
              controller: _mobileNumberController,
              decoration: InputDecoration(labelText: 'Mobile Number'),
            ),
            ElevatedButton(
              onPressed: _addStudent,
              child: Text('Add Student'),
            ),
            SizedBox(height: 20),

            // Display Classes and Students
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('classes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var classData = snapshot.data!.docs[index];
                      return Card(
                        child: ExpansionTile(
                          title: Text(classData['name']),
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('classes')
                                  .doc(classData.id)
                                  .collection('students')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return CircularProgressIndicator();
                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    var student = snapshot.data!.docs[index];
                                    return ListTile(
                                      title: Text(student['name']),
                                      subtitle: Text(
                                          'Roll: ${student['rollNumber']}, Mobile: ${student['mobileNumber']}'),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addClass() async {
    if (_classNameController.text.isNotEmpty) {
      await _firestore.collection('classes').add({
        'name': _classNameController.text,
      });
      _classNameController.clear();
    }
  }

  void _addStudent() async {
    if (_selectedClass != null &&
        _studentNameController.text.isNotEmpty &&
        _rollNumberController.text.isNotEmpty &&
        _mobileNumberController.text.isNotEmpty) {
      await _firestore
          .collection('classes')
          .doc(_selectedClass)
          .collection('students')
          .add({
        'name': _studentNameController.text,
        'rollNumber': _rollNumberController.text,
        'mobileNumber': _mobileNumberController.text,
      });
      _studentNameController.clear();
      _rollNumberController.clear();
      _mobileNumberController.clear();
    }
  }
}