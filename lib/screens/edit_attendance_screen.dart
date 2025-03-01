import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String teacherId;
  final String classId;
  final String className;
  final DateTime date;

  EditAttendanceScreen({
    required this.teacherId,
    required this.classId,
    required this.className,
    required this.date,
  });

  @override
  _EditAttendanceScreenState createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _students = [];
  final Map<String, bool> _tempAttendance = {};
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAttendance();
  }

  Future<void> _loadStudentsAndAttendance() async {
    setState(() => _isLoading = true);
    try {
      // Load attendance records first
      final attendanceSnapshot = await _firestore
          .collection('attendance_records')
          .where('classId', isEqualTo: widget.classId)
          .where('date', isEqualTo: Timestamp.fromDate(widget.date))
          .get();

      // Initialize temporary attendance map with existing records
      _tempAttendance.clear();
      for (var doc in attendanceSnapshot.docs) {
        _tempAttendance[doc['rollNumber'].toString()] = doc['status'] == 'present';
      }

      // Load students
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .orderBy('rollNumber')
          .get();

      _students = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        final rollNumber = data['rollNumber'].toString();

        // If there's an existing attendance record, use it
        // Otherwise, check if any attendance exists for the class
        if (!_tempAttendance.containsKey(rollNumber)) {
          _tempAttendance[rollNumber] = attendanceSnapshot.docs.isNotEmpty;
        }

        return {
          'name': data['name'],
          'rollNumber': rollNumber,
          'docId': doc.id,
        };
      }).toList();

      // Sort students by roll number numerically
      _students.sort((a, b) {
        int aRoll = int.tryParse(a['rollNumber']) ?? 0;
        int bRoll = int.tryParse(b['rollNumber']) ?? 0;
        return aRoll.compareTo(bRoll);
      });

      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleAttendance(String rollNumber) async {
    setState(() {
      _tempAttendance[rollNumber] = !(_tempAttendance[rollNumber] ?? false);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _markAllWithStatus(bool present) async {
    setState(() {
      for (var student in _students) {
        _tempAttendance[student['rollNumber']] = present;
      }
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveAttendance() async {
    if (!_hasUnsavedChanges) return;

    setState(() => _isSaving = true);
    try {
      final String dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      final batch = _firestore.batch();

      for (var student in _students) {
        final String docId = '${widget.classId}_${dateStr}_${student['rollNumber']}';
        final docRef = _firestore.collection('attendance_records').doc(docId);

        batch.set(docRef, {
          'classId': widget.classId,
          'date': Timestamp.fromDate(widget.date),
          'rollNumber': student['rollNumber'],
          'studentName': student['name'],
          'status': _tempAttendance[student['rollNumber']] == true ? 'present' : 'absent',
          'teacherId': widget.teacherId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      setState(() => _hasUnsavedChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes'),
        content: Text('You have unsaved changes. Do you want to save them before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              await _saveAttendance();
              if (mounted) Navigator.pop(context, true);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Attendance'),
              Text(
                '${widget.className} • ${DateFormat('dd MMM yyyy').format(widget.date)}',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.check_circle_outline),
              tooltip: 'Mark All Present',
              onPressed: _isSaving ? null : () => _markAllWithStatus(true),
            ),
            IconButton(
              icon: Icon(Icons.cancel_outlined),
              tooltip: 'Mark All Absent',
              onPressed: _isSaving ? null : () => _markAllWithStatus(false),
            ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Present',
                          _tempAttendance.values.where((v) => v).length,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Absent',
                          _tempAttendance.values.where((v) => !v).length,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Total',
                          _students.length,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final isPresent = _tempAttendance[student['rollNumber']] ?? false;

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPresent ? Colors.green : Colors.red,
                              child: Text(
                                student['rollNumber'],
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Switch(
                              value: isPresent,
                              onChanged: _isSaving
                                  ? null
                                  : (_) => _toggleAttendance(student['rollNumber']),
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _hasUnsavedChanges
            ? Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAttendance,
                      icon: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}
