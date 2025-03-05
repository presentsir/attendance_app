import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ai_service.dart';
import 'package:flutter/services.dart';
import 'edit_attendance_screen.dart';
import 'ai_chat_screen.dart';
import '../services/mintlify_service.dart';

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
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<FlSpot> _attendanceData = [];
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.classId;
    _selectedStudent = widget.studentRollNo;
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (_selectedClass == null) return;

    setState(() => _isLoading = true);

    try {
      // Get total students in class
      final classDoc =
          await _firestore.collection('classes').doc(_selectedClass).get();
      _totalStudents = (classDoc.data()?['students'] as List?)?.length ?? 0;

      // Get attendance records
      final records = await _firestore
          .collection('attendance_records')
          .where('classId', isEqualTo: _selectedClass)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .orderBy('date')
          .get();

      // Process attendance data
      Map<DateTime, int> dailyAttendance = {};
      for (var doc in records.docs) {
        final date = (doc['date'] as Timestamp).toDate();
        final dateKey = DateTime(date.year, date.month, date.day);
        final status = doc['status'] as String;

        if (status == 'present') {
          dailyAttendance[dateKey] = (dailyAttendance[dateKey] ?? 0) + 1;
        }
      }

      // Convert to FlSpot list for graph
      _attendanceData = dailyAttendance.entries.map((entry) {
        return FlSpot(
          entry.key.millisecondsSinceEpoch.toDouble(),
          entry.value.toDouble(),
        );
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading attendance data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance records: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Records'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAttendanceData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClassSelector(),
                    SizedBox(height: 16),
                    _buildDateRangeCard(),
                    SizedBox(height: 16),
                    _buildAttendanceGraph(),
                    SizedBox(height: 16),
                    _buildRecordsList(),
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
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data!.docs;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_),
              ),
              items: classes.map((classDoc) {
                final classData = classDoc.data() as Map<String, dynamic>;
                return DropdownMenuItem<String>(
                  value: classDoc.id,
                  child: Text(classData['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClass = value;
                  _selectedStudent = null;
                });
                _loadAttendanceData();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date Range',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                    onPressed: () => _selectDate(true),
                  ),
                ),
                Icon(Icons.arrow_forward),
                Expanded(
                  child: TextButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    onPressed: () => _selectDate(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceGraph() {
    if (_attendanceData.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No attendance data available for the selected period'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Text(DateFormat('MMM dd').format(date));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _attendanceData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildRecordsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('attendance_records')
          .where('classId', isEqualTo: _selectedClass)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!.docs;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Records',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final date = (record['date'] as Timestamp).toDate();
                    return ListTile(
                      title: Text(DateFormat('MMM dd, yyyy').format(date)),
                      subtitle: Text('Roll No: ${record['rollNumber']}'),
                      trailing: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: record['status'] == 'present'
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record['status'].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _loadAttendanceData();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Records'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Start Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
              onTap: () {
                Navigator.pop(context);
                _selectDate(true);
              },
            ),
            ListTile(
              title: Text('End Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
              onTap: () {
                Navigator.pop(context);
                _selectDate(false);
              },
            ),
          ],
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
}
