import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import 'bulk_student_upload.dart';

class ProfileScreen extends StatefulWidget {
  final School school;
  final String userEmail;
  final int numberOfClasses;
  final Map<String, int> studentsPerClass;
  final String teacherId;

  ProfileScreen({
    required this.school,
    required this.userEmail,
    required this.numberOfClasses,
    required this.studentsPerClass,
    required this.teacherId,
  });

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _classNameController = TextEditingController();
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
            // School Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('School Name: ${widget.school.name}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('School Code: ${widget.school.affNo}',
                        style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('Email: ${widget.userEmail}',
                        style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Add Class Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classNameController,
                    decoration: InputDecoration(
                      labelText: 'Class Name',
                      hintText: 'Enter class name (e.g., Class 1-A)',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addClass,
                  child: Text('Add Class'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Bulk Upload Button
            ElevatedButton(
              onPressed: () async {
                if (_selectedClass != null) {
                  try {
                    // Check for existing roll numbers first
                    final QuerySnapshot studentsSnapshot = await _firestore
                        .collection('classes')
                        .doc(_selectedClass)
                        .collection('students')
                        .orderBy('rollNumber') // Ensure students are fetched in order
                        .get();

                    if (studentsSnapshot.docs.isNotEmpty) {
                      // Show warning dialog if students exist
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Existing Students'),
                          content: Text(
                              'This class already has students. You can edit existing students or add new ones with higher roll numbers.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BulkStudentUpload(
                                      classId: _selectedClass!,
                                    ),
                                  ),
                                );
                              },
                              child: Text('Continue'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // No existing students, proceed directly
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BulkStudentUpload(
                            classId: _selectedClass!,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Log the error
                    print('Error during bulk upload: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error during bulk upload: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a class first')),
                  );
                }
              },
              child: Text('Bulk Upload Students'),
            ),
            SizedBox(height: 20),

            // Classes and Students List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('classes').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var classData = snapshot.data!.docs[index];
                      return Card(
                        child: ExpansionTile(
                          title: Text(classData['name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(classData),
                              ),
                              Icon(
                                _selectedClass == classData.id
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ],
                          ),
                          onExpansionChanged: (expanded) {
                            if (expanded) {
                              setState(() {
                                _selectedClass = classData.id;
                              });
                            }
                          },
                          children: [
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('classes')
                                  .doc(classData.id)
                                  .collection('students')
                                  .snapshots(),
                              builder: (context, studentsSnapshot) {
                                if (!studentsSnapshot.hasData) {
                                  return Center(child: CircularProgressIndicator());
                                }

                                // Sort students by roll number numerically
                                List<DocumentSnapshot> students = studentsSnapshot.data!.docs;
                                students.sort((a, b) {
                                  int aRoll = int.tryParse(a['rollNumber'].toString()) ?? 0;
                                  int bRoll = int.tryParse(b['rollNumber'].toString()) ?? 0;
                                  return aRoll.compareTo(bRoll);
                                });

                                // Validate roll numbers
                                Set<String> rollNumbers = {};
                                bool hasDuplicates = false;

                                for (var student in students) {
                                  String rollNumber = student['rollNumber'];
                                  if (rollNumbers.contains(rollNumber)) {
                                    hasDuplicates = true;
                                    break;
                                  }
                                  rollNumbers.add(rollNumber);
                                }

                                // Show warning if duplicates found
                                if (hasDuplicates) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Warning: Duplicate roll numbers detected in ${classData['name']}'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 5),
                                      ),
                                    );
                                  });
                                }

                                return Column(
                                  children: [
                                    if (students.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Total Students: ${students.length}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: students.length,
                                      itemBuilder: (context, index) {
                                        var student = students[index];
                                        return ListTile(
                                          title: Text(student['name']),
                                          subtitle: Text(
                                            'Roll: ${student['rollNumber']}, Mobile: ${student['mobileNumber']}',
                                          ),
                                          // Add warning icon for duplicate roll numbers
                                          trailing: rollNumbers.contains(student['rollNumber'])
                                              ? Icon(Icons.warning, color: Colors.red)
                                              : null,
                                        );
                                      },
                                    ),
                                  ],
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
    if (_classNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a class name')),
      );
      return;
    }

    try {
      // Check if class name already exists for this teacher
      QuerySnapshot existingClasses = await _firestore
          .collection('classes')
          .where('name', isEqualTo: _classNameController.text)
          .where('teacherId', isEqualTo: widget.teacherId)
          .where('schoolId', isEqualTo: widget.school.affNo.toString())
          .get();

      if (existingClasses.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A class with this name already exists')),
        );
        return;
      }

      await _firestore.collection('classes').add({
        'name': _classNameController.text,
        'teacherId': widget.teacherId,
        'schoolId': widget.school.affNo.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _classNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Class added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(DocumentSnapshot classDoc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${classDoc['name']}?'),
            SizedBox(height: 10),
            Text(
              'This will permanently delete all student records and attendance data for this class.',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete all students in the class
        final studentsSnapshot = await classDoc.reference
            .collection('students')
            .get();

        final batch = FirebaseFirestore.instance.batch();

        // Delete students
        for (var student in studentsSnapshot.docs) {
          batch.delete(student.reference);
        }

        // Delete attendance records
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('attendance_records')
            .where('classId', isEqualTo: classDoc.id)
            .get();

        for (var record in attendanceSnapshot.docs) {
          batch.delete(record.reference);
        }

        // Delete the class document
        batch.delete(classDoc.reference);

        // Commit the batch
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}