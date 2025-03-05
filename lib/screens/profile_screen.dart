import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_model.dart';
import 'bulk_student_upload.dart';
<<<<<<< HEAD
import 'bluetooth_service.dart';
import 'dart:convert';
import 'dart:convert' show utf8;
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../services/user_session.dart';
>>>>>>> lakshya

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
<<<<<<< HEAD
  BluetoothService _bluetoothService = BluetoothService();
  String? _syncStatus;
  bool _isConnected = false;
  bool _isSyncing = false;
=======
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

  void _showClassOptionsMenu(BuildContext context, DocumentSnapshot classData) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('Bulk Upload Students'),
            onTap: () {
              Navigator.pop(context);
              _navigateToBulkUpload(classData.id);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Modify Class Details'),
            onTap: () {
              Navigator.pop(context);
              _showModifyClassDialog(classData);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Class', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(classData);
            },
          ),
        ],
      ),
    );
  }

  void _showModifyClassDialog(DocumentSnapshot classData) async {
    final studentsSnapshot = await _firestore
        .collection('classes')
        .doc(classData.id)
        .collection('students')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modify ${classData['name']}'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Students:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...studentsSnapshot.docs.map((student) => ListTile(
                    title: Text(student['name']),
                    subtitle: Text('Roll: ${student['rollNumber']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStudent(
                          classData.id, student.id, student['name']),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(
      String classId, String studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('classes')
            .doc(classId)
            .collection('students')
            .doc(studentId)
            .delete();

        // Remove from cache
        _studentsCache[classId]?.removeWhere((doc) => doc.id == studentId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student deleted successfully')),
        );

        // Refresh the modify dialog
        Navigator.pop(context);
        _showModifyClassDialog(
            await _firestore.collection('classes').doc(classId).get());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting student: $e')),
        );
      }
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Total Students: ${students.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: students.length,
              itemBuilder: (context, index) {
                var student = students[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(student['rollNumber'].toString()),
                      backgroundColor: Colors.blue[100],
                    ),
                    title: Text(
                      student['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile: ${student['mobileNumber']}'),
                        if (student['gender'] != null)
                          Text('Gender: ${student['gender']}'),
                        if (student['familyStructure'] != null)
                          Text('Family: ${student['familyStructure']}'),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: hasDuplicates &&
                            rollNumbers.contains(student['rollNumber'])
                        ? Icon(Icons.warning, color: Colors.red)
                        : null,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeacherInfoCard() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('teachers').doc(widget.teacherId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Teacher information not found'),
            ),
          );
        }

        final teacherData = snapshot.data!.data() as Map<String, dynamic>;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Divider(),
                _buildInfoRow('School Name', widget.school.name),
                _buildInfoRow('School Code', widget.school.affNo.toString()),
                _buildInfoRow('School Board',
                    teacherData['educationBoard'] ?? 'Not specified'),
                SizedBox(height: 20),
                Text(
                  'Teacher Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Divider(),
                _buildInfoRow('Name', teacherData['name'] ?? 'Not specified'),
                _buildInfoRow('Email', teacherData['email'] ?? 'Not specified'),
                _buildInfoRow('Contact No.',
                    teacherData['phoneNumber'] ?? 'Not specified'),
                _buildInfoRow(
                    'Subject', teacherData['subject'] ?? 'Not specified'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTeacherDialog(Map<String, dynamic> teacherData) {
    final TextEditingController nameController =
        TextEditingController(text: teacherData['name']);
    final TextEditingController phoneController =
        TextEditingController(text: teacherData['phoneNumber']);
    final TextEditingController subjectController =
        TextEditingController(text: teacherData['subject']);
    String selectedBoard = teacherData['educationBoard'] ?? 'CBSE';
    final List<String> boards = ['CBSE', 'ICSE', 'State Board'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '10-digit mobile number',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.book),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedBoard,
                  decoration: InputDecoration(
                    labelText: 'Education Board',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: boards.map((String board) {
                    return DropdownMenuItem<String>(
                      value: board,
                      child: Text(board),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedBoard = newValue);
                    }
                  },
                ),
                SizedBox(height: 24),
                Divider(),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Clear user session
                      await UserSession.clearSession();
                      // Sign out from Firebase
                      await FirebaseAuth.instance.signOut();
                      // Navigate to login screen and clear all previous routes
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error signing out: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Logout', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate phone number
                if (phoneController.text.trim().length != 10 ||
                    !RegExp(r'^[0-9]{10}$')
                        .hasMatch(phoneController.text.trim())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Please enter a valid 10-digit phone number')),
                  );
                  return;
                }

                try {
                  await _firestore
                      .collection('teachers')
                      .doc(widget.teacherId)
                      .update({
                    'name': nameController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'subject': subjectController.text.trim(),
                    'educationBoard': selectedBoard,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
>>>>>>> lakshya

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future:
                _firestore.collection('teachers').doc(widget.teacherId).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox();

              return IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  if (snapshot.data != null && snapshot.data!.exists) {
                    _showEditTeacherDialog(
                        snapshot.data!.data() as Map<String, dynamic>);
                  }
                },
                tooltip: 'Edit Profile',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTeacherInfoCard(),
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

            // Classes List
            StreamBuilder<QuerySnapshot>(
              stream: _classesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No classes added yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var classData = snapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          ListTile(
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
                                  icon: Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _showClassOptionsMenu(context, classData),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _selectedClass == classData.id
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedClass =
                                          _selectedClass == classData.id
                                              ? null
                                              : classData.id;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_selectedClass == classData.id)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: _buildStudentsList(classData),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            // Add after the school information card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bluetooth, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'ESP32 Device',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        _buildConnectionStatus(),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _connectESP32Device,
                      icon: Icon(Icons.bluetooth_searching),
                      label: Text('Connect ESP32 Device'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    if (_syncStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _syncStatus!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
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
<<<<<<< HEAD
        final studentsSnapshot = await classDoc.reference
            .collection('students')
            .get();
=======
        final studentsSnapshot =
            await classDoc.reference.collection('students').get();
>>>>>>> lakshya

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

<<<<<<< HEAD
=======
        // Remove from cache
        _studentsCache.remove(classDoc.id);

>>>>>>> lakshya
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
<<<<<<< HEAD

  Widget _buildConnectionStatus() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isConnected ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(width: 8),
        Text(
          _isConnected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color: _isConnected ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Future<void> _connectESP32Device() async {
    try {
      setState(() => _syncStatus = 'Scanning for devices...');

      final devices = await _bluetoothService.scanForDevices();

      if (devices.isEmpty) {
        setState(() => _syncStatus = 'No ESP32 devices found');
        return;
      }

      // Show device selection dialog if multiple devices found
      BluetoothDevice selectedDevice;
      if (devices.length > 1) {
        selectedDevice = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select ESP32 Device'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: devices.map((device) =>
                ListTile(
                  title: Text(device.name),
                  onTap: () => Navigator.pop(context, device),
                ),
              ).toList(),
            ),
          ),
        );
      } else {
        selectedDevice = devices.first;
      }

      if (selectedDevice == null) return;

      setState(() => _syncStatus = 'Connecting...');
      await _bluetoothService.connectToDevice(selectedDevice);

      setState(() {
        _isConnected = true;
        _syncStatus = 'Connected! Starting sync...';
        _isSyncing = true;
      });

      // Start the sync process
      await _syncData();

    } catch (e) {
      setState(() {
        _isConnected = false;
        _syncStatus = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _syncData() async {
    try {
      // 1. First sync: Send all class and student data
      setState(() => _syncStatus = 'Syncing class data...');

      // Get all classes for this teacher
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: widget.teacherId)
          .get();

      final classesData = await Future.wait(
        classesSnapshot.docs.map((classDoc) async {
          // Get students for each class
          final studentsSnapshot = await classDoc.reference
              .collection('students')
              .orderBy('rollNumber')
              .get();

          return {
            'classId': classDoc.id,
            'className': classDoc['name'],
            'students': studentsSnapshot.docs.map((doc) => doc.data()).toList(),
          };
        })
      );

      // Send class data to ESP32
      await _bluetoothService.sendClassData(json.encode({
        'type': 'sync_classes',
        'classes': classesData,
      }));

      // 2. Check for pending attendance data from ESP32
      setState(() => _syncStatus = 'Checking for pending attendance...');

      // Listen for attendance data from ESP32
      _bluetoothService.getAttendanceData().listen((data) async {
        try {
          final attendanceData = json.decode(utf8.decode(data));

          // Show sync progress
          setState(() => _syncStatus = 'Syncing attendance for ${attendanceData['className']}...');

          // Upload attendance to Firebase
          await _uploadAttendance(attendanceData);

          setState(() => _syncStatus = 'Attendance synced successfully!');
        } catch (e) {
          print('Error processing attendance data: $e');
        }
      });

    } catch (e) {
      setState(() => _syncStatus = 'Sync error: ${e.toString()}');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _uploadAttendance(Map<String, dynamic> attendanceData) async {
    final batch = _firestore.batch();

    for (var record in attendanceData['attendance']) {
      final docRef = _firestore.collection('attendance_records').doc();
      batch.set(docRef, {
        'classId': attendanceData['classId'],
        'date': DateTime.fromMillisecondsSinceEpoch(record['timestamp'] * 1000),
        'rollNumber': record['rollNumber'],
        'status': record['status'],
        'teacherId': widget.teacherId,
        'synced': true,
        'syncTimestamp': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
=======
}
>>>>>>> lakshya
