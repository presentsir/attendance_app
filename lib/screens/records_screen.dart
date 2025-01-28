import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/ai_service.dart';
import 'package:flutter/services.dart';

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
  Map<String, dynamic> _attendanceStats = {
    'present': 0,
    'absent': 0,
    'total': 0,
  };

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.classId;
    _selectedStudent = widget.studentRollNo;
    _loadAttendanceStats();
  }

  Future<void> _loadAttendanceStats() async {
    if (_selectedClass == null) return;

    setState(() => _isLoading = true);

    try {
      var query = _firestore
          .collection('attendance_records')
          .where('classId', isEqualTo: _selectedClass)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate));

      if (_selectedStudent != null) {
        query = query.where('rollNumber', isEqualTo: _selectedStudent);
      }

      final records = await query.get();

      int present = 0;
      int absent = 0;

      for (var doc in records.docs) {
        if (doc['status'] == 'present') {
          present++;
        } else {
          absent++;
        }
      }

      setState(() {
        _attendanceStats = {
          'present': present,
          'absent': absent,
          'total': present + absent,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attendance records'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading records...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await _loadAttendanceStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Records refreshed'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.teacherId != null) _buildClassSelector(),
                    SizedBox(height: 16),
                    _buildDateRangeCard(),
                    SizedBox(height: 16),
                    _buildAttendanceStatsCards(),
                    SizedBox(height: 16),
                    _buildAttendanceChart(),
                    SizedBox(height: 16),
                    _buildAIInsights(),
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
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 8),
                    Text('Loading classes...'),
                  ],
                ),
              ),
            ),
          );
        }

        final classes = snapshot.data!.docs;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                labelText: 'Select Class',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_),
              ),
              items: classes.map((classDoc) {
                return DropdownMenuItem<String>(
                  value: classDoc.id,
                  child: Text(classDoc['name']),
                );
              }).toList(),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedClass = value;
                  _selectedStudent = null;
                });
                _loadAttendanceStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Class selected: ${classes.firstWhere((doc) => doc.id == value)['name']}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
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
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildAttendanceStatsCards() {
    final percentage = _attendanceStats['total'] == 0
        ? 0.0
        : (_attendanceStats['present'] / _attendanceStats['total']) * 100;

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Present',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${_attendanceStats['present']}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Absent',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${_attendanceStats['absent']}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.percent, color: Colors.blue, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Percentage',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsights() {
    if (_selectedClass == null || _attendanceStats['total'] == 0) return SizedBox();

    return FutureBuilder<String>(
      future: AIService.getClassPerformanceInsights(
        classStats: {
          'totalStudents': _attendanceStats['total'],
          'averageAttendance': (_attendanceStats['present'] / _attendanceStats['total'] * 100).toStringAsFixed(1),
          'lowestAttendance': '60', // You can calculate this from actual data
          'highestAttendance': '100', // You can calculate this from actual data
        },
        className: _selectedClass ?? 'Unknown',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 8),
                  Text('Generating AI insights...'),
                ],
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
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'AI Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.data ?? 'No insights available',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: _attendanceStats['present'].toDouble(),
                      title: 'Present',
                      radius: 80,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: _attendanceStats['absent'].toDouble(),
                      title: 'Absent',
                      radius: 80,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_selectedClass == null) {
      return Center(
        child: Text('Please select a class to view records'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _buildAttendanceQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('failed-precondition') ||
              snapshot.error.toString().contains('requires an index')) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Database Setup Required',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please create the following index in Firebase Console:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Collection: attendance_records',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Fields:'),
                          Text('1. classId (Ascending)'),
                          Text('2. date (Ascending)'),
                          if (_selectedStudent != null)
                            Text('3. rollNumber (Ascending)'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.open_in_new),
                      label: Text('Open Firebase Console'),
                      onPressed: () {
                        // You can implement URL launcher here if needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please open Firebase Console to create the index'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        return _buildRecordsListView(snapshot);
      },
    );
  }

  Stream<QuerySnapshot> _buildAttendanceQuery() {
    Query query = _firestore
        .collection('attendance_records')
        .where('classId', isEqualTo: _selectedClass);

    // Add date range filters
    query = query.where('date', 
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .where('date', 
        isLessThanOrEqualTo: Timestamp.fromDate(_endDate));

    // Add student filter if selected
    if (_selectedStudent != null) {
      query = query.where('rollNumber', isEqualTo: _selectedStudent);
    }

    // Add ordering
    query = query.orderBy('date', descending: true);
    if (_selectedStudent == null) {
      query = query.orderBy('rollNumber', descending: false);
    }

    return query.snapshots();
  }

  Widget _buildRecordsListView(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('Loading records...'),
          ],
        ),
      );
    }

    final records = snapshot.data!.docs;

    if (records.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 48),
              SizedBox(height: 8),
              Text(
                'No Records Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'No attendance records for the selected period',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final date = (record['date'] as Timestamp).toDate();
        final isPresent = record['status'] == 'present';

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green : Colors.red,
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(
              record['studentName'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Roll No: ${record['rollNumber']} • ${DateFormat('MMM dd, yyyy').format(date)}',
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPresent ? 'Present' : 'Absent',
                style: TextStyle(
                  color: isPresent ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    HapticFeedback.selectionClick();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
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
      _loadAttendanceStats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date updated'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showFilterDialog() {
    // Implement filter dialog if needed
  }
}