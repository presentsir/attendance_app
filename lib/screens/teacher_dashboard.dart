import 'package:flutter/material.dart';
import '../models/school_model.dart'; // Import your School model
import 'profile_screen.dart'; // Import your profile screen
import 'attendance_screen.dart'; // Import your attendance screen
import 'records_screen.dart'; // Import your records screen
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for user email
import 'login_screen.dart';
import '../services/user_session.dart';
import '../services/wifi_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDashboard extends StatefulWidget {
  final School school; // School data passed from the login screen
  final String teacherName; // Teacher name passed from the login screen
  final String teacherId;  // Add teacherId

  TeacherDashboard({
    required this.school,
    required this.teacherName,
    required this.teacherId,  // Add teacherId parameter
  });

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0; // Track the selected index for the bottom navigation bar

  // Define the screens corresponding to the bottom navigation bar items
  late final List<Widget> _screens;

  final WiFiService _wifiService = WiFiService();
  bool _isConnectingToESP32 = false;
  String? _syncStatus;

  @override
  void initState() {
    super.initState();
    // Initialize the screens with the required data
    _screens = [
      AttendanceScreen(teacherId: widget.teacherId),  // Pass teacherId
      RecordsScreen(teacherId: widget.teacherId),  // Pass teacherId
      ProfileScreen(
        school: widget.school,
        userEmail: widget.teacherName,
        numberOfClasses: 0,
        studentsPerClass: {},
        teacherId: widget.teacherId,  // Add teacherId here
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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

  Widget _buildESP32Status() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: _wifiService.isConnectedToESP32 ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'ESP32 Device',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (_isConnectingToESP32)
                  CircularProgressIndicator(strokeWidth: 2)
              ],
            ),
            SizedBox(height: 8),
            Text(
              _wifiService.isConnectedToESP32
                ? 'Connected to ESP32'
                : 'Not connected',
              style: TextStyle(
                color: _wifiService.isConnectedToESP32 ? Colors.green : Colors.grey,
              ),
            ),
            if (_syncStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_syncStatus!),
              ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isConnectingToESP32 ? null : _connectAndSync,
              icon: Icon(Icons.sync),
              label: Text('Connect & Sync ESP32'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectAndSync() async {
    setState(() {
      _isConnectingToESP32 = true;
      _syncStatus = 'Connecting to ESP32...';
    });

    try {
      bool connected = await _wifiService.connectToESP32();

      if (!connected) {
        throw Exception('Failed to connect to ESP32');
      }

      setState(() => _syncStatus = 'Fetching attendance data...');

      final attendanceData = await _wifiService.fetchAttendanceData();

      if (attendanceData == null) {
        throw Exception('Failed to fetch attendance data');
      }

      setState(() => _syncStatus = 'Processing attendance data...');

      // Update Firestore with the attendance data
      await _updateAttendanceRecords(attendanceData);

      setState(() => _syncStatus = 'Attendance records updated successfully!');

    } catch (e) {
      setState(() => _syncStatus = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isConnectingToESP32 = false);
    }
  }

  Future<void> _updateAttendanceRecords(Map<String, dynamic> attendanceData) async {
    final batch = FirebaseFirestore.instance.batch();
    final timestamp = FieldValue.serverTimestamp();

    for (var entry in attendanceData.entries) {
      String classId = entry.key;
      Map<String, dynamic> classData = entry.value;

      for (var studentEntry in classData.entries) {
        String rollNumber = studentEntry.key;
        String status = studentEntry.value;

        // Create a unique document ID for this attendance record
        String docId = '${classId}_${DateTime.now().toIso8601String()}_$rollNumber';

        batch.set(
          FirebaseFirestore.instance.collection('attendance_records').doc(docId),
          {
            'classId': classId,
            'rollNumber': rollNumber,
            'status': status,
            'date': timestamp,
            'teacherId': widget.teacherId,
            'syncedFromESP32': true,
          }
        );
      }
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildESP32Status(),
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}