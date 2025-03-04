import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/school_model.dart';
import 'attendance_records_screen.dart';

class ParentDashboard extends StatefulWidget {
  final School school;
  final String classId;
  final Map<String, dynamic> studentData;

  ParentDashboard({
    required this.school,
    required this.classId,
    required this.studentData,
  });

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _classData;
  Map<String, dynamic>? _teacherData;
  List<Map<String, dynamic>> _testReports = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
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

      // Get test reports
      final testReportsQuery = await _firestore
          .collection('test_reports')
          .where('classId', isEqualTo: widget.classId)
          .where('rollNumber', isEqualTo: widget.studentData['rollNumber'])
          .orderBy('date', descending: true)
          .get();

      _testReports = testReportsQuery.docs.map((doc) => doc.data()).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
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
              'Student Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Divider(),
            _buildInfoRow(
                'Name', widget.studentData['name'] ?? 'Not available'),
            _buildInfoRow('Roll No.',
                widget.studentData['rollNumber'] ?? 'Not available'),
            _buildInfoRow('Contact Number',
                widget.studentData['mobileNumber'] ?? 'Not available'),
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
              rollNo: widget.studentData['rollNumber'],
              studentName: widget.studentData['name'],
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

  Widget _buildTestReports() {
    if (_testReports.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No test reports available yet'),
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
              'Test Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _testReports.length,
              itemBuilder: (context, index) {
                final report = _testReports[index];
                final date = DateFormat('dd MMM yyyy')
                    .format((report['date'] as Timestamp).toDate());

                return ListTile(
                  title: Text(report['subject']),
                  subtitle: Text('Date: $date'),
                  trailing: Text(
                    '${report['score']}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: report['score'] >= 60 ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard'),
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
            _buildTestReports(),
          ],
        ),
      ),
    );
  }
}
