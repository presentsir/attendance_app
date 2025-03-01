import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'records_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String teacherId;

  AttendanceScreen({required this.teacherId});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedClass;
  String? _selectedClassName;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _students = [];
  int _currentStudentIndex = 0;
  bool _isLoading = false;
  bool _attendanceTaken = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Take Attendance'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildClassSelector(),
                if (_selectedClass != null && _students.isNotEmpty) ...[
                  _buildDateHeader(),
                  _buildAttendanceUI(),
                ] else if (_selectedClass != null && _students.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, size: 64, color: Colors.orange),
                          SizedBox(height: 16),
                          Text(
                            'No students found in this class',
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            'Add students in the profile section',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          print('TeacherId: ${widget.teacherId}');
          print('Snapshot error: ${snapshot.error}');
          print('Has data: ${snapshot.hasData}');
          if (snapshot.hasData) {
            print('Number of classes: ${snapshot.data?.docs.length}');
            snapshot.data?.docs.forEach((doc) {
              print('Class data: ${doc.data()}');
            });
          }

          if (snapshot.hasError) {
            print('Error details: ${snapshot.error}');
            if (snapshot.error.toString().contains('failed-precondition') ||
                snapshot.error.toString().contains('requires an index')) {
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.build, color: Colors.orange),
                      SizedBox(height: 8),
                      Text(
                        'Database Setup Required',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Please create the required index in Firebase Console:',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '1. Go to Firebase Console\n2. Select Firestore Database\n3. Go to Indexes tab\n4. Add Index for "classes" collection:\n   - teacherId (Ascending)\n   - name (Ascending)',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 8),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data?.docs ?? [];

          print('Classes found: ${classes.length}');
          classes.forEach((classDoc) {
            print('Class ID: ${classDoc.id}');
            print('Class Data: ${classDoc.data()}');
          });

          if (classes.isEmpty) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(16),
        child: Column(
          children: [
                    Icon(Icons.warning, color: Colors.orange, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'No classes found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Add classes in your profile section',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
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
                  print('Creating dropdown item for class: ${classData['name']}');
                    return DropdownMenuItem<String>(
                      value: classDoc.id,
                    child: Text(classData['name'] ?? 'Unnamed Class'),
                    );
                  }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    print('Selected class ID: $value');
                    final selectedClass = classes.firstWhere((doc) => doc.id == value);
                    final classData = selectedClass.data() as Map<String, dynamic>;
                    print('Selected class data: $classData');

                    setState(() {
                      _selectedClass = value;
                      _selectedClassName = classData['name'];
                    });
                    _onClassSelected(value);
                  }
                  },
              ),
            ],
                );
              },
            ),
    );
  }

  Widget _buildDateHeader() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.calendar_today),
        title: Text(
          DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attendanceTaken)
              Icon(Icons.check_circle, color: Colors.green)
            else
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text('Change Date'),
              ),
            if (_attendanceTaken) ...[
              SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordsScreen(
                        teacherId: widget.teacherId,
                        classId: _selectedClass,
                      ),
                    ),
                  );
                },
                child: Text('View/Edit'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceUI() {
    if (_attendanceTaken) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Attendance Already Taken',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You can view or edit attendance in the Records section',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordsScreen(
                        teacherId: widget.teacherId,
                        classId: _selectedClass,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.edit),
                label: Text('View/Edit Records'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty || _currentStudentIndex >= _students.length) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Attendance Complete!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStudentIndex = 0;
                  });
                },
                child: Text('Start Over'),
              ),
            ],
          ),
        ),
      );
    }

    var currentStudent = _students[_currentStudentIndex];
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Roll No: ${currentStudent['rollNumber']}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              currentStudent['name'],
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttendanceButton(
                  true,
                  Icons.check_circle_outline,
                  Colors.green,
                  'Present',
                ),
                _buildAttendanceButton(
                  false,
                  Icons.cancel_outlined,
                  Colors.red,
                  'Absent',
                ),
              ],
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 32),
                  onPressed: _currentStudentIndex > 0
                      ? () => setState(() => _currentStudentIndex--)
                      : null,
                ),
                SizedBox(width: 40),
                Text(
                  '${_currentStudentIndex + 1}/${_students.length}',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(width: 40),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 32),
                  onPressed: _currentStudentIndex < _students.length - 1
                      ? () => setState(() => _currentStudentIndex++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(bool isPresent, IconData icon, Color color, String label) {
    return ElevatedButton(
      onPressed: () => _markAttendance(isPresent),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _onClassSelected(String classId) async {
    print('_onClassSelected called with classId: $classId');
    setState(() {
      _selectedClass = classId;
      _currentStudentIndex = 0;
      _isLoading = true;
    });

    await _loadStudents();
    await _checkAttendance();

    setState(() => _isLoading = false);
  }

  Future<void> _loadStudents() async {
    try {
      if (_selectedClass == null) {
        print('No class selected');
        return;
      }

      print('Loading students for class: $_selectedClass');
      setState(() => _isLoading = true);

      var studentsSnapshot = await _firestore
          .collection('classes')
          .doc(_selectedClass)
          .collection('students')
          .get();

      print('Students query completed. Found: ${studentsSnapshot.docs.length} students');
      for (var doc in studentsSnapshot.docs) {
        print('Student data: ${doc.data()}');
      }

      if (!mounted) return;

      setState(() {
        _students = studentsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList()
          ..sort((a, b) {
            // Convert roll numbers to integers for proper numerical sorting
            int aRoll = int.tryParse(a['rollNumber'].toString()) ?? 0;
            int bRoll = int.tryParse(b['rollNumber'].toString()) ?? 0;
            return aRoll.compareTo(bRoll);
          });
        _isLoading = false;
      });

      print('Students loaded and sorted: ${_students.length}');
      for (var student in _students) {
        print('Roll Number: ${student['rollNumber']}');
      }
    } catch (e) {
      print('Error loading students: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkAttendance() async {
    if (_selectedClass == null) return;

    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      var attendanceDoc = await _firestore
          .collection('attendance')
          .doc('${_selectedClass}_$dateStr')
          .get();

      if (!mounted) return;

      setState(() {
        _attendanceTaken = attendanceDoc.exists;
      });
    } catch (e) {
      print('Error checking attendance: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
    setState(() {
        _selectedDate = picked;
      _currentStudentIndex = 0;
    });
      await _checkAttendance();
    }
  }

  Future<void> _markAttendance(bool isPresent) async {
    if (_currentStudentIndex >= _students.length) return;

    final student = _students[_currentStudentIndex];
    final String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final String docId = '${_selectedClass}_$dateStr';

    try {
      // Update or create the main attendance document
      await _firestore.collection('attendance').doc(docId).set({
        'classId': _selectedClass,
        'date': Timestamp.fromDate(_selectedDate),
        'teacherId': widget.teacherId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Create individual attendance record
      await _firestore
          .collection('attendance_records')
          .doc('${docId}_${student['rollNumber']}')
          .set({
        'classId': _selectedClass,
        'date': Timestamp.fromDate(_selectedDate),
        'rollNumber': student['rollNumber'],
        'studentName': student['name'],
        'status': isPresent ? 'present' : 'absent',
        'teacherId': widget.teacherId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Move to next student automatically
      if (_currentStudentIndex < _students.length - 1) {
        setState(() {
          _currentStudentIndex++;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance completed for all students!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}