import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RecordsScreen extends StatefulWidget {
  final String? teacherId;
  final String? studentRollNo;
  final String? classId;

  RecordsScreen({
    this.teacherId,
    this.studentRollNo,
    this.classId,
  });

  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedClass;
  String? _selectedStudent;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.classId;
    _selectedStudent = widget.studentRollNo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Records'),
        actions: [
          if (widget.teacherId != null)
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.teacherId != null) _buildClassSelector(),
          _buildDateRangeCard(),
          _buildAttendanceStats(),
          Expanded(
            child: _buildRecordsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('classes')
            .where('teacherId', isEqualTo: widget.teacherId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var classes = snapshot.data!.docs;
          return DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Select Class',
              border: OutlineInputBorder(),
              filled: true,
            ),
            items: classes.map((classDoc) {
              return DropdownMenuItem<String>(
                value: classDoc.id,
                child: Text(classDoc['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClass = value;
                _selectedStudent = null;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('dd MMM yyyy').format(_startDate)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('To', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('dd MMM yyyy').format(_endDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAttendanceQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var records = snapshot.data!.docs;
        int totalDays = records.length;
        int presentDays = records
            .where((doc) => doc['status'] == 'present')
            .length;
        double percentage = totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16),
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
                    _buildStatCard(
                      'Present Days',
                      presentDays.toString(),
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Total Days',
                      totalDays.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Percentage',
                      '${percentage.toStringAsFixed(1)}%',
                      percentage < 60 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
                if (percentage < 60)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Warning: Attendance below 60%',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildRecordsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAttendanceQuery().snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var records = snapshot.data!.docs;
        if (records.isEmpty) {
          return Center(
            child: Text('No attendance records found'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            var record = records[index];
            DateTime date = (record['date'] as Timestamp).toDate();
            String status = record['status'];
            String studentName = record['studentName'] ?? '';
            String rollNumber = record['rollNumber'] ?? '';

            return Card(
              child: ListTile(
                leading: Icon(
                  status == 'present' ? Icons.check_circle : Icons.cancel,
                  color: status == 'present' ? Colors.green : Colors.red,
                ),
                title: Text(DateFormat('dd MMM yyyy').format(date)),
                subtitle: widget.teacherId != null
                    ? Text('$studentName (Roll No: $rollNumber)')
                    : null,
                trailing: widget.teacherId != null
                    ? IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editAttendance(record),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Query<Map<String, dynamic>> _getAttendanceQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('attendance_records')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate));

    if (widget.teacherId != null) {
      query = query.where('teacherId', isEqualTo: widget.teacherId);
      if (_selectedClass != null) {
        query = query.where('classId', isEqualTo: _selectedClass);
      }
      if (_selectedStudent != null) {
        query = query.where('rollNumber', isEqualTo: _selectedStudent);
      }
    } else if (widget.studentRollNo != null) {
      query = query.where('rollNumber', isEqualTo: widget.studentRollNo);
    }

    return query.orderBy('date', descending: true);
  }

  Future<void> _showFilterDialog() async {
    DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (dateRange != null) {
      setState(() {
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });
    }
  }

  Future<void> _editAttendance(DocumentSnapshot record) async {
    bool isPresent = record['status'] == 'present';
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${record['studentName']}'),
            Text('Date: ${DateFormat('dd MMM yyyy').format((record['date'] as Timestamp).toDate())}'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Present'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Absent'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result != null && result != isPresent) {
      try {
        await record.reference.update({
          'status': result ? 'present' : 'absent',
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Update the main attendance document
        String dateStr = DateFormat('yyyy-MM-dd').format((record['date'] as Timestamp).toDate());
        String docId = '${record['classId']}_$dateStr';
        String rollNumber = record['rollNumber'];

        DocumentSnapshot mainDoc = await _firestore
            .collection('attendance')
            .doc(docId)
            .get();

        if (mainDoc.exists) {
          Map<String, dynamic> attendance = Map<String, dynamic>.from(mainDoc.get('attendance'));
          attendance[rollNumber] = result;
          await mainDoc.reference.update({
            'attendance': attendance,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating attendance: $e')),
        );
      }
    }
  }

  Widget _buildAttendanceChart(List<DocumentSnapshot> records) {
    // Group records by date
    Map<DateTime, int> dailyAttendance = {};
    for (var record in records) {
      final date = (record['date'] as Timestamp).toDate();
      final key = DateTime(date.year, date.month, date.day);
      dailyAttendance[key] = (dailyAttendance[key] ?? 0) + (record['status'] == 'present' ? 1 : 0);
    }

    // Convert to list of FlSpot
    final spots = dailyAttendance.entries.map((e) {
      return FlSpot(
        e.key.millisecondsSinceEpoch.toDouble(),
        e.value.toDouble(),
      );
    }).toList()..sort((a, b) => a.x.compareTo(b.x));

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Text(DateFormat('MM/dd').format(date));
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}