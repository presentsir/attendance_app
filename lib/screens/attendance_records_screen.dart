import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
            .collection('classes')
            .doc(classId)
            .collection('attendance')
            .where('rollNumber', isEqualTo: rollNo)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final attendanceRecords = snapshot.data?.docs ?? [];
          if (attendanceRecords.isEmpty) {
            return Center(child: Text('No attendance records found'));
          }

          // Calculate attendance statistics
          int totalDays = attendanceRecords.length;
          int presentDays = attendanceRecords
              .where((doc) => doc['status'] == 'present')
              .length;
          double attendancePercentage = (presentDays / totalDays) * 100;

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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Total Days',
                              totalDays.toString(),
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Present',
                              presentDays.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Absent',
                              (totalDays - presentDays).toString(),
                              Icons.cancel,
                              Colors.red,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Attendance Percentage: ${attendancePercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: attendancePercentage >= 75
                                ? Colors.green
                                : attendancePercentage >= 60
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = attendanceRecords[index];
                    final date = (record['date'] as Timestamp).toDate();
                    final status = record['status'] as String;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          status == 'present'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color:
                              status == 'present' ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          DateFormat('dd MMM yyyy').format(date),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          status == 'present' ? 'Present' : 'Absent',
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
