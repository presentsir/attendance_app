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

    // Add debug prints
    print('RecordsScreen initialized with:');
    print('Teacher ID: ${widget.teacherId}');
    print('Student Roll No: ${widget.studentRollNo}');
    print('Class ID: ${widget.classId}');

    Future.delayed(Duration.zero, () {
      _loadAttendanceStats();
    });
  }

  Future<void> _loadAttendanceStats() async {
    if (_selectedClass == null && widget.studentRollNo == null) return;

    setState(() => _isLoading = true);

    try {
      // Start with base query
      Query query = _firestore.collection('attendance_records');

      // Add class filter
      if (_selectedClass != null) {
        query = query.where('classId', isEqualTo: _selectedClass);
      }

      // Add student filter if viewing student records
      if (widget.studentRollNo != null) {
        query = query.where('rollNumber', isEqualTo: widget.studentRollNo);
      }

      // Add date range filters
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate));

      final records = await query.get();

      print('Found ${records.docs.length} records');
      for (var doc in records.docs) {
        print('Record: ${doc.data()}');
      }

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

      print('Stats updated: $_attendanceStats');
    } catch (e) {
      print('Error loading stats: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attendance records: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
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
          if (widget.teacherId != null) ...[
            IconButton(
              icon: Icon(Icons.chat),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIChatScreen(
                      classId: _selectedClass ?? '',
                      attendanceStats: _attendanceStats,
                      startDate: _startDate,
                      endDate: _endDate,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
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
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
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
                    _loadAttendanceStats();
                  },
                ),
                if (_selectedClass != null) ...[
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final selectedClassData = classes
                          .firstWhere((doc) => doc.id == _selectedClass)
                          .data() as Map<String, dynamic>;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditAttendanceScreen(
                            teacherId: widget.teacherId!,
                            classId: _selectedClass!,
                            className: selectedClassData['name'],
                            date: _startDate,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Class Attendance'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
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

    return FutureBuilder<Map<String, dynamic>>(
      future: _getDetailedInsights(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Analyzing attendance patterns...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Unable to generate insights'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final insights = snapshot.data;
        if (insights == null) return SizedBox();

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Attendance Insights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildInsightTile(
                  icon: Icons.trending_up,
                  title: 'Trend Analysis',
                  value: insights['trend'] ?? 'No trend data available',
                  color: Colors.blue,
                ),
                _buildInsightTile(
                  icon: Icons.calendar_today,
                  title: 'Best Attendance Day',
                  value: insights['bestDay'] ?? 'No day data available',
                  color: Colors.green,
                ),
                _buildInsightTile(
                  icon: Icons.warning,
                  title: 'Areas of Concern',
                  value: insights['concerns'] ?? 'No concerns identified',
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDetailedInsights() async {
    try {
      final insights = await MintlifyService.getAttendanceInsights(
        classId: _selectedClass ?? '',
        startDate: _startDate,
        endDate: _endDate,
        attendanceStats: {
          'total': _attendanceStats['total'],
          'present': _attendanceStats['present'],
          'absent': _attendanceStats['absent'],
          'percentage': _attendanceStats['total'] == 0
              ? 0
              : (_attendanceStats['present'] / _attendanceStats['total'] * 100).toStringAsFixed(1),
        },
      );

      // Parse the AI response into structured insights
      final content = insights['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return {};

      // Extract insights from the AI response
      final trend = _extractTrend(content);
      final bestDay = _extractBestDay(content);
      final concerns = _extractConcerns(content);

      return {
        'trend': trend,
        'bestDay': bestDay,
        'concerns': concerns,
      };
    } catch (e) {
      print('Error getting detailed insights: $e');
      return {};
    }
  }

  String _extractTrend(String content) {
    if (content.toLowerCase().contains('improving')) {
      return 'Attendance is showing improvement';
    } else if (content.toLowerCase().contains('declining')) {
      return 'Attendance is declining';
    } else if (content.toLowerCase().contains('stable')) {
      return 'Attendance is stable';
    }
    return 'No clear trend identified';
  }

  String _extractBestDay(String content) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    for (var day in days) {
      if (content.toLowerCase().contains(day.toLowerCase())) {
        return 'Highest attendance on $day';
      }
    }
    return 'Best day not identified';
  }

  String _extractConcerns(String content) {
    if (content.toLowerCase().contains('low attendance')) {
      return 'Low attendance rates need attention';
    } else if (content.toLowerCase().contains('irregular')) {
      return 'Irregular attendance patterns detected';
    } else if (content.toLowerCase().contains('improvement')) {
      return 'Room for improvement in attendance';
    }
    return 'No major concerns identified';
  }

  Widget _buildInsightTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
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
                      'Please create the following indexes in Firebase Console:',
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
                          Text('Collection: attendance_records (with "a", not "e")',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Index 1:'),
                          Text('1. classId (Ascending)'),
                          Text('2. date (Ascending)'),
                          Text('3. rollNumber (Ascending)'),
                          SizedBox(height: 8),
                          Text('Index 2:'),
                          Text('1. classId (Ascending)'),
                          Text('2. date (Ascending)'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Note: Make sure the collection name is "attendance_records" not "attendence_records"',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      onPressed: () {
                        setState(() {
                          // Trigger rebuild
                        });
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
    // Start with base query
    Query query = _firestore.collection('attendance_records');

    // Add class filter
    if (_selectedClass != null) {
      query = query.where('classId', isEqualTo: _selectedClass);
    }

    // Add student filter if viewing student records
    if (widget.studentRollNo != null) {
      query = query.where('rollNumber', isEqualTo: widget.studentRollNo);
    }

    // Add date range filters
    query = query
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_endDate));

    // Add ordering
    query = query.orderBy('date', descending: true);

    print('Query parameters:');
    print('Class ID: $_selectedClass');
    print('Student Roll No: ${widget.studentRollNo}');
    print('Start Date: $_startDate');
    print('End Date: $_endDate');

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                if (widget.teacherId != null) ...[
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditAttendanceDialog(record),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditAttendanceDialog(DocumentSnapshot record) async {
    final currentStatus = record['status'] == 'present';
    final studentName = record['studentName'];
    final date = DateFormat('MMM dd, yyyy').format((record['date'] as Timestamp).toDate());

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: $studentName'),
            Text('Date: $date'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Mark Present'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Mark Absent'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && result != currentStatus) {
      try {
        await _firestore
            .collection('attendance_records')
            .doc(record.id)
            .update({
          'status': result ? 'present' : 'absent',
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error updating attendance: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating attendance'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    HapticFeedback.selectionClick();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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