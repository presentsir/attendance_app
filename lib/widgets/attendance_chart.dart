import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceChart extends StatelessWidget {
  final String classId;
  final String rollNumber;

  const AttendanceChart({
    Key? key,
    required this.classId,
    required this.rollNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance_records')
          .where('classId', isEqualTo: classId)
          .where('rollNumber', isEqualTo: rollNumber)
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('attendence chart'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!.docs;
        if (records.isEmpty) {
          return Center(child: Text('No attendance records found'));
        }

        // Process the last 30 days of attendance
        final attendanceData = List.generate(30, (index) {
          final date = DateTime.now().subtract(Duration(days: index));
          final record = records.firstWhere(
            (doc) {
              final recordDate = (doc['date'] as Timestamp).toDate();
              return recordDate.year == date.year &&
                  recordDate.month == date.month &&
                  recordDate.day == date.day;
            },
            orElse: () => records.first,
          );
          return record != null ? (record['status'] == 'present' ? 1 : 0) : -1;
        }).reversed.toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 1,
            barGroups: List.generate(
              30,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: attendanceData[index].toDouble(),
                    color: attendanceData[index] == -1
                        ? Colors.grey
                        : attendanceData[index] == 1
                            ? Colors.green
                            : Colors.red,
                  ),
                ],
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() % 5 != 0) return SizedBox.shrink();
                    final date = DateTime.now()
                        .subtract(Duration(days: 29 - value.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() != 0 && value.toInt() != 1) {
                      return SizedBox.shrink();
                    }
                    return Text(
                      value.toInt() == 1 ? 'Present' : 'Absent',
                      style: TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: true),
          ),
        );
      },
    );
  }
}
