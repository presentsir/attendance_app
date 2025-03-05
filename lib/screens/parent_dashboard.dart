import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../models/school_model.dart';
import '../services/notification_service.dart';
import '../services/user_session.dart';
import '../widgets/attendance_chart.dart';
import 'login_screen.dart';

class ParentDashboard extends StatefulWidget {
  final String mobileNumber;
  final School school;
  final List<Map<String, dynamic>> children;

  const ParentDashboard({
    Key? key,
    required this.mobileNumber,
    required this.school,
    required this.children,
  }) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _selectedChild;
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _classData;
  Map<String, dynamic>? _teacherData;
  double _attendancePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.children.isNotEmpty) {
      print('Initializing with ${widget.children.length} children');
      _selectedChild = widget.children.first;
      print('Selected child initial data:');
      print('- Name: ${_selectedChild!['name']}');
      print('- Class ID: ${_selectedChild!['classId']}');
      print('- ID: ${_selectedChild!['id']}');
      _loadChildData();
    }
  }

  Future<void> _loadChildData() async {
    if (_selectedChild == null) return;

    try {
      print('Loading data for child: ${_selectedChild!['name']}');

      // First, get the complete student data
      final studentDoc = await _firestore
          .collection('classes')
          .doc(_selectedChild!['classId'])
          .collection('students')
          .doc(_selectedChild!['id'])
          .get();

      if (!studentDoc.exists) {
        print('Student document not found');
        return;
      }

      final studentData = studentDoc.data();
      if (studentData == null) {
        print('Student data is null');
        return;
      }

      // Update selected child with complete data
      setState(() {
        _selectedChild = {
          ..._selectedChild!,
          'rollNumber': studentData['rollNumber'],
          'name': studentData['name'],
          'classId': _selectedChild!['classId'],
        };
      });

      print('Updated child data:');
      print('- Name: ${_selectedChild!['name']}');
      print('- Roll Number: ${_selectedChild!['rollNumber']}');
      print('- Class ID: ${_selectedChild!['classId']}');

      // Get class data
      final classDoc = await _firestore
          .collection('classes')
          .doc(_selectedChild!['classId'])
          .get();
      _classData = classDoc.data();

      // Get teacher data
      if (_classData != null && _classData!['teacherId'] != null) {
        final teacherDoc = await _firestore
            .collection('teachers')
            .doc(_classData!['teacherId'])
            .get();
        _teacherData = teacherDoc.data();
      }

      // Calculate attendance
      await _calculateAttendance();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading child data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAttendance() async {
    if (_selectedChild == null) return;

    try {
      final QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance_records')
          .where('classId', isEqualTo: _selectedChild!['classId'])
          .where('rollNumber', isEqualTo: _selectedChild!['rollNumber'])
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
    } catch (e) {
      print('Error calculating attendance: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
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

  Widget _buildChildSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Child',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: widget.children.firstWhere(
                (child) => child['id'] == _selectedChild?['id'],
                orElse: () => widget.children.first,
              ),
              items: widget.children.map((child) {
                return DropdownMenuItem(
                  value: child,
                  child: Text(child['name']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedChild = value;
                    _isLoading = true;
                  });
                  _loadChildData();
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a child',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildDetails() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Child Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            _buildInfoRow('Name', _selectedChild?['name'] ?? 'Not available'),
            _buildInfoRow(
                'Roll No.', _selectedChild?['rollNumber'] ?? 'Not available'),
            _buildInfoRow('Class', _classData?['name'] ?? 'Not available'),
            _buildInfoRow(
                'Class Teacher', _teacherData?['name'] ?? 'Not available'),
            _buildInfoRow('Teacher Contact',
                _teacherData?['phoneNumber'] ?? 'Not available'),
            SizedBox(height: 16),
            Text(
              'Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _attendancePercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _attendancePercentage >= 75 ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Attendance: ${_attendancePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            if (_selectedChild != null &&
                _selectedChild!['classId'] != null &&
                _selectedChild!['rollNumber'] != null)
              SizedBox(
                height: 200,
                child: AttendanceChart(
                  classId: _selectedChild!['classId'] as String,
                  rollNumber: _selectedChild!['rollNumber'] as String,
                ),
              )
            else
              SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
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
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Stream<List<NotificationModel>> _getNotificationsStream() {
    if (_selectedChild == null) {
      print('No child selected');
      return Stream.value([]);
    }

    // Get the child's data
    final rollNumber = _selectedChild!['rollNumber'] as String?;
    final classId = _selectedChild!['classId'] as String?;
    final parentMobile = widget.mobileNumber;

    if (rollNumber == null || classId == null) {
      print('Missing child data: rollNumber=$rollNumber, classId=$classId');
      return Stream.value([]);
    }

    print('Getting notifications for:');
    print('- Roll Number: $rollNumber');
    print('- Class ID: $classId');
    print('- Parent Mobile: $parentMobile');

    // For parents, we want to show:
    // 1. Notifications sent to their child
    // 2. Parent-specific notifications
    return _notificationService.getNotifications(
      userId: rollNumber,
      classId: classId,
      isTeacher: false,
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final dateFormat = DateFormat('MMM d, y HH:mm');
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isUnread ? Colors.blue[50] : null,
      child: ListTile(
        leading: _buildNotificationIcon(notification.type),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'From: ${notification.senderName}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(notification.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.motivational:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case NotificationType.attendanceAlert:
        iconData = Icons.calendar_today;
        iconColor = Colors.blue;
        break;
      case NotificationType.teacherNotification:
        iconData = Icons.school;
        iconColor = Colors.green;
        break;
      case NotificationType.dailyMotivation:
        iconData = Icons.lightbulb;
        iconColor = Colors.orange;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    final notifications = await _getNotificationsStream().first;
    for (final notification in notifications) {
      if (!notification.isRead) {
        await _markAsRead(notification.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChildSelector(),
              SizedBox(height: 16),
              _buildChildDetails(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: Icon(Icons.done_all),
                    label: Text('Mark all as read'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              StreamBuilder<List<NotificationModel>>(
                stream: _getNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading notifications'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final notifications = snapshot.data!;
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text('No notifications'),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(notifications[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
