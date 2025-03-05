import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class TeacherNotificationScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? preSelectedClassId;

  const TeacherNotificationScreen({
    Key? key,
    required this.teacherId,
    required this.teacherName,
    this.preSelectedClassId,
  }) : super(key: key);

  @override
  _TeacherNotificationScreenState createState() => _TeacherNotificationScreenState();
}

class _TeacherNotificationScreenState extends State<TeacherNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedStudentRollNo;
  String? _selectedStudentName;
  bool _isLoading = false;
  bool _isForWholeClass = true;
  List<Map<String, dynamic>> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.preSelectedClassId;
    if (_selectedClassId != null) {
      _loadClassName();
    }
  }

  Future<void> _loadClassName() async {
    if (_selectedClassId == null) return;

    try {
      final classDoc = await _firestore.collection('classes').doc(_selectedClassId).get();
      if (classDoc.exists) {
        setState(() {
          _selectedClassName = classDoc.data()?['name'] ?? 'Unknown Class';
        });
      }
    } catch (e) {
      print('Error loading class name: $e');
    }
  }

  void _searchStudents(String query) async {
    if (_selectedClassId == null) return;

    if (query.isEmpty) {
      setState(() {
        _filteredStudents = [];
      });
      return;
    }

    try {
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(_selectedClassId)
          .collection('students')
          .get();

      final students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'rollNumber': data['rollNumber'] ?? '',
        };
      }).toList();

      setState(() {
        _filteredStudents = students
            .where((student) =>
                student['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
                student['rollNumber'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } catch (e) {
      print('Error searching students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching students: $e')),
      );
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isForWholeClass) {
        // Send to whole class
        await _notificationService.sendClassNotification(
          classId: _selectedClassId!,
          title: _titleController.text,
          message: _messageController.text,
          teacherId: widget.teacherId,
          teacherName: widget.teacherName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to all students in the class'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Send to individual student
        await _notificationService.sendStudentNotification(
          classId: _selectedClassId!,
          rollNumber: _selectedStudentRollNo!,
          title: _titleController.text,
          message: _messageController.text,
          teacherId: widget.teacherId,
          teacherName: widget.teacherName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent to $_selectedStudentName'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear form
      _titleController.clear();
      _messageController.clear();
      if (!_isForWholeClass) {
        setState(() {
          _selectedStudentRollNo = null;
          _selectedStudentName = null;
          _searchController.clear();
          _filteredStudents = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notifications'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildClassSelector(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              if (_selectedClassId != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Whole Class'),
                                value: true,
                                groupValue: _isForWholeClass,
                                onChanged: (value) {
                                  setState(() {
                                    _isForWholeClass = value!;
                                    _selectedStudentRollNo = null;
                                    _selectedStudentName = null;
                                    _searchController.clear();
                                    _filteredStudents = [];
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Individual Student'),
                                value: false,
                                groupValue: _isForWholeClass,
                                onChanged: (value) {
                                  setState(() {
                                    _isForWholeClass = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                if (!_isForWholeClass) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Student',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search by name or roll number',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _searchStudents,
                          ),
                          SizedBox(height: 16),
                          if (_selectedStudentName != null) ...[
                            ListTile(
                              title: Text(_selectedStudentName!),
                              subtitle: Text('Roll No: $_selectedStudentRollNo'),
                              leading: CircleAvatar(
                                child: Text(_selectedStudentRollNo ?? ''),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedStudentRollNo = null;
                                    _selectedStudentName = null;
                                  });
                                },
                              ),
                            ),
                          ] else if (_filteredStudents.isNotEmpty) ...[
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.builder(
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  return ListTile(
                                    title: Text(student['name']),
                                    subtitle: Text('Roll No: ${student['rollNumber']}'),
                                    leading: CircleAvatar(
                                      child: Text(student['rollNumber'].toString()),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedStudentRollNo = student['rollNumber'];
                                        _selectedStudentName = student['name'];
                                        _searchController.clear();
                                        _filteredStudents = [];
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                          SizedBox(height: 8),
                          if (_searchController.text.isNotEmpty && _filteredStudents.isEmpty)
                            Text(
                              'No matching students found',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            labelText: 'Message',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a message';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (!_isForWholeClass && _selectedStudentRollNo == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Please select a student'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  _sendNotification();
                                },
                          icon: Icon(Icons.send),
                          label: Text(_isLoading
                              ? 'Sending...'
                              : _isForWholeClass
                                  ? 'Send to Whole Class'
                                  : 'Send to Student'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: widget.teacherId)
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading classes: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data?.docs ?? [];

        if (classes.isEmpty) {
          return Text('No classes found. Please add a class first.');
        }

        return DropdownButtonFormField<String>(
          value: _selectedClassId,
          decoration: InputDecoration(
            labelText: 'Select Class',
            border: OutlineInputBorder(),
          ),
          items: classes.map((classDoc) {
            final classData = classDoc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: classDoc.id,
              child: Text(classData['name'] ?? 'Unknown Class'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClassId = value;
              _selectedClassName = classes
                  .firstWhere((doc) => doc.id == value)['name'];
              _selectedStudentRollNo = null;
              _selectedStudentName = null;
              _isForWholeClass = true;
              _searchController.clear();
              _filteredStudents = [];
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a class';
            }
            return null;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}