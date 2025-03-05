import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/school_model.dart';
import '../widgets/attendance_chart.dart';
import 'login_screen.dart';
import '../services/user_session.dart';

class StudentDashboard extends StatefulWidget {
  final School school;
  final String rollNo;
  final String studentName;
  final String classId;

  StudentDashboard({
    required this.school,
    required this.rollNo,
    required this.studentName,
    required this.classId,
  });

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  double _attendancePercentage = 0.0;
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  Map<String, dynamic>? _classData;
  Map<String, dynamic>? _teacherData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      // Get student data
      final studentDoc = await _firestore
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .where('rollNumber', isEqualTo: widget.rollNo)
          .get();

      if (studentDoc.docs.isNotEmpty) {
        _studentData = studentDoc.docs.first.data();
      }

      // Get class data
      final classDoc =
          await _firestore.collection('classes').doc(widget.classId).get();
      _classData = classDoc.data();

      // Get teacher data
      if (_classData != null && _classData!['teacherId'] != null) {
        final teacherDoc = await _firestore
            .collection('teachers')
            .doc(_classData!['teacherId'])
            .get();
        _teacherData = teacherDoc.data();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAttendance() async {
    try {
      final QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance_records')
          .where('classId', isEqualTo: widget.classId)
          .where('rollNumber', isEqualTo: widget.rollNo)
          .orderBy('date')
          .get();

      int totalDays = attendanceSnapshot.docs.length;
      int presentDays = attendanceSnapshot.docs
          .where((doc) => doc['status'] == 'present')
          .length;

      if (!mounted) return;

      setState(() {
        _attendancePercentage =
            totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
        _isLoading = false;
      });

      if (_attendancePercentage < 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Your attendance is below 60%'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error calculating attendance: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error calculating attendance. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmLogout != true) return;

    try {
      await UserSession.clearSession();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileCard() {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${_studentData?['name'] ?? 'Student'}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Divider(),
            _buildInfoRow(
                'Roll No.', _studentData?['rollNumber'] ?? 'Not available'),
            _buildInfoRow('Contact Number',
                _studentData?['mobileNumber'] ?? 'Not available'),
            _buildInfoRow('Class', _classData?['name'] ?? 'Not available'),
            _buildInfoRow(
                'Class Teacher', _teacherData?['name'] ?? 'Not available'),
            _buildInfoRow('Teacher Contact',
                _teacherData?['phoneNumber'] ?? 'Not available'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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

  Widget _buildAttendanceButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceRecordsScreen(
              classId: widget.classId,
              rollNo: widget.rollNo,
              studentName: _studentData?['name'] ?? 'Student',
            ),
          ),
        );
      },
      icon: Icon(Icons.calendar_today),
      label: Text('View Attendance Records'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(),
            SizedBox(height: 20),
            _buildAttendanceButton(),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceRecordsScreen extends StatelessWidget {
  final String classId;
  final String rollNo;
  final String studentName;

  AttendanceRecordsScreen({
    required this.classId,
    required this.rollNo,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Records'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance_records')
            .where('classId', isEqualTo: classId)
            .where('rollNumber', isEqualTo: rollNo)
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading records. Please try again later.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs;

          if (records.isEmpty) {
            return Center(
              child: Text('No attendance records found'),
            );
          }

          // Calculate attendance statistics
          int totalDays = records.length;
          int presentDays =
              records.where((doc) => doc['status'] == 'present').length;
          double attendancePercentage =
              totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Attendance Overview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${attendancePercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: attendancePercentage < 60
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                Text('Total Attendance'),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$totalDays',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Total Days'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Attendance History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final date = DateFormat('dd MMM yyyy')
                        .format((record['date'] as Timestamp).toDate());
                    final status = record['status'];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          status == 'present'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              status == 'present' ? Colors.green : Colors.red,
                        ),
                        title: Text(date),
                        subtitle: Text(
                          status.toString().toUpperCase(),
                          style: TextStyle(
                            color:
                                status == 'present' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
