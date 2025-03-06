import 'package:flutter/material.dart';
import '../models/school_model.dart'; // Import your School model
import 'profile_screen.dart'; // Import your profile screen
import 'attendance_screen.dart'; // Import your attendance screen
import 'records_screen.dart'; // Import your records screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user email
import 'login_screen.dart';
import '../services/user_session.dart';
import 'notification_screen.dart';
import '../services/notification_service.dart';
import 'test_results_screen.dart';
import 'student_details_screen.dart';
import 'bulk_student_upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'scan_dropout_risk_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final School school; // School data passed from the login screen
  final String teacherName; // Teacher name passed from the login screen
  final String teacherId; // Add teacherId
  final String classId; // Add classId

  TeacherDashboard({
    required this.school,
    required this.teacherName,
    required this.teacherId, // Add teacherId parameter
    required this.classId, // Add classId parameter
  });

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex =
      0; // Track the selected index for the bottom navigation bar
  final NotificationService _notificationService = NotificationService();
  int _unreadNotifications = 0;

  // Define the screens corresponding to the bottom navigation bar items
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with the required data
    _screens = [
      AttendanceScreen(teacherId: widget.teacherId), // Pass teacherId
      RecordsScreen(teacherId: widget.teacherId), // Pass teacherId
      TestResultsScreen(
        teacherId: widget.teacherId,
        classId: widget.classId,
        className:
            widget.classId, // You might want to pass the actual class name
      ),
      ProfileScreen(
        school: widget.school,
        userEmail: widget.teacherName,
        numberOfClasses: 0,
        studentsPerClass: {},
        teacherId: widget.teacherId, // Add teacherId here
      ),
    ];
    _loadUnreadNotifications();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadUnreadNotifications() {
    _notificationService
        .getUnreadCount(widget.teacherId, widget.classId)
        .listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotifications = count;
        });
      }
    });
  }

  Future<void> _handleLogout() async {
    await UserSession.clearSession();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _showClassOptions(
      BuildContext context, String classId, String className) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.neonOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Class Options',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.upload_file, color: AppTheme.neonOrange),
              title: Text('Bulk Upload',
                  style: TextStyle(color: AppTheme.textColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BulkStudentUpload(
                      classId: classId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.neonGreen),
              title: Text('Modify Class',
                  style: TextStyle(color: AppTheme.textColor)),
              onTap: () {
                Navigator.pop(context);
                _showModifyClassDialog(context, classId, className);
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: AppTheme.neonBlue),
              title: Text('Student Details',
                  style: TextStyle(color: AppTheme.textColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsScreen(
                      classId: classId,
                      className: className,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics, color: AppTheme.neonGreen),
              title: Text('WOP feature',
                  style: TextStyle(color: AppTheme.textColor)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanDropoutRiskScreen(
                      classId: classId,
                      className: className,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Class', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteClass(context, classId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showModifyClassDialog(
      BuildContext context, String classId, String className) {
    final nameController = TextEditingController(text: className);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text('Modify Class Details',
            style: TextStyle(color: AppTheme.textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                labelText: 'Class Name',
                labelStyle: TextStyle(color: AppTheme.secondaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.neonOrange),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.secondaryTextColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.neonOrange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.neonBlue)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .update({
                  'name': nameController.text,
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Class details updated successfully',
                        style: TextStyle(color: AppTheme.textColor)),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating class details: $e',
                        style: TextStyle(color: AppTheme.textColor)),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(BuildContext context, String classId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Class deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting class: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(
                        userId: widget.teacherId,
                        isTeacher: true,
                        school: widget.school,
                        classId: widget.classId,
                      ),
                    ),
                  );
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    school: widget.school,
                    userEmail: widget.teacherName,
                    numberOfClasses: 0,
                    studentsPerClass: {},
                    teacherId: widget.teacherId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grade),
            label: 'Test Results',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
