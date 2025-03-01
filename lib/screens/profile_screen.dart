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
  Map<String, List<DocumentSnapshot>> _studentsCache = {};
  bool _isLoading = false;

  // Query for classes
  late final Query _classesQuery = _firestore
      .collection('classes')
      .where('teacherId', isEqualTo: widget.teacherId)
      .where('schoolId', isEqualTo: widget.school.affNo.toString())
      .orderBy('createdAt', descending: true);

  Future<List<DocumentSnapshot>> _getStudentsForClass(String classId) async {
    // Check cache first
    if (_studentsCache.containsKey(classId)) {
      return _studentsCache[classId]!;
    }

    // If not in cache, fetch from Firestore
    final studentsSnapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('students')
        .get();

    // Sort students by roll number
    List<DocumentSnapshot> sortedStudents = studentsSnapshot.docs;
    sortedStudents.sort((a, b) {
      int aRoll = int.tryParse(a['rollNumber'].toString()) ?? 0;
      int bRoll = int.tryParse(b['rollNumber'].toString()) ?? 0;
      return aRoll.compareTo(bRoll);
    });

    // Store in cache
    _studentsCache[classId] = sortedStudents;
    return sortedStudents;
  }

  Widget _buildStudentsList(DocumentSnapshot classData) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _getStudentsForClass(classData.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No students in this class yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        List<DocumentSnapshot> students = snapshot.data!;
        Set<String> rollNumbers = {};
        bool hasDuplicates = false;

        // Check for duplicate roll numbers
        for (var student in students) {
          String rollNumber = student['rollNumber'];
          if (rollNumbers.contains(rollNumber)) {
            hasDuplicates = true;
            break;
          }
          rollNumbers.add(rollNumber);
        }

        if (hasDuplicates) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: Duplicate roll numbers detected in ${classData['name']}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Total Students: ${students.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  trailing: rollNumbers.contains(student['rollNumber'])
                      ? Icon(Icons.warning, color: Colors.red)
                      : null,
                );
              },
            ),
          ],
        );
      },
    );
  }

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
                    Text(
                      'School Name: ${widget.school.name}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'School Code: ${widget.school.affNo}',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Email: ${widget.userEmail}',
                      style: TextStyle(fontSize: 18),
                    ),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addClass,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.add),
                  label: Text('Add Class'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Bulk Upload Button
            ElevatedButton.icon(
              onPressed: _selectedClass == null
                  ? null
                  : () => _navigateToBulkUpload(_selectedClass!),
              icon: Icon(Icons.upload_file),
              label: Text('Bulk Upload Students'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 20),

            // Classes List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _classesQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // Check specifically for the index error
                    if (snapshot.error
                            .toString()
                            .contains('failed-precondition') ||
                        snapshot.error
                            .toString()
                            .contains('requires an index')) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build, size: 64, color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'Setting up database...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Please wait while we complete the initial setup. This may take a few minutes.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ],
                        ),
                      );
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading classes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.class_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No classes added yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first class using the field above',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var classData = snapshot.data!.docs[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(
                            classData['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Created: ${(classData['createdAt'] as Timestamp).toDate().toString().split('.')[0]}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirmation(classData),
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
                          children: [_buildStudentsList(classData)],
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

  Future<void> _navigateToBulkUpload(String classId) async {
    final studentsSnapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('students')
        .get();

    if (!mounted) return;

    if (studentsSnapshot.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Existing Students'),
          content: Text(
            'This class already has students. You can edit existing students or add new ones with higher roll numbers.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BulkStudentUpload(classId: classId),
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BulkStudentUpload(classId: classId),
        ),
      );
    }
  }

  void _addClass() async {
    if (_classNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a class name')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
        setState(() => _isLoading = false);
        return;
      }

      // Add class with teacher and school information
      await _firestore.collection('classes').add({
        'name': _classNameController.text,
        'teacherId': widget.teacherId,
        'teacherEmail': widget.userEmail,
        'schoolId': widget.school.affNo.toString(),
        'schoolName': widget.school.name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'totalStudents': 0,
      });

      _classNameController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding class: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
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
        setState(() => _isLoading = true);

        // Delete all students in the class
        final studentsSnapshot =
            await classDoc.reference.collection('students').get();

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

        // Remove from cache
        _studentsCache.remove(classDoc.id);

        // Commit the batch
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Class deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting class: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
