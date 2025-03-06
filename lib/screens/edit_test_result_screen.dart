import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/academic_marks_service.dart';

class EditTestResultScreen extends StatefulWidget {
  final String testId;
  final String classId;
  final String testName;
  final String subject;
  final DateTime testDate;
  final List<Map<String, dynamic>> studentMarks;

  EditTestResultScreen({
    required this.testId,
    required this.classId,
    required this.testName,
    required this.subject,
    required this.testDate,
    required this.studentMarks,
  });

  @override
  _EditTestResultScreenState createState() => _EditTestResultScreenState();
}

class _EditTestResultScreenState extends State<EditTestResultScreen> {
  final AcademicMarksService _marksService = AcademicMarksService();
  late List<Map<String, dynamic>> _editedMarks;
  bool _isLoading = false;
  final Map<String, TextEditingController> _markControllers = {};

  @override
  void initState() {
    super.initState();
    _editedMarks = List.from(widget.studentMarks);
    // Initialize controllers for each student
    for (var student in _editedMarks) {
      _markControllers[student['studentId']] = TextEditingController(
        text: student['marks'].toString(),
      );
    }
  }

  @override
  void dispose() {
    _markControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveMarks() async {
    setState(() => _isLoading = true);
    try {
      // Update marks from controllers
      for (var student in _editedMarks) {
        final controller = _markControllers[student['studentId']];
        if (controller != null) {
          student['marks'] = int.tryParse(controller.text) ?? 0;
        }
      }

      await _marksService.updateTestResult(
        testId: widget.testId,
        studentMarks: _editedMarks,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating marks: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Test Result'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.testName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${widget.subject} • ${widget.testDate.toString().split(' ')[0]}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Roll No',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Marks',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Divider(),
                          ..._editedMarks.map((student) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(student['rollNumber']),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(student['name']),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: _markControllers[
                                          student['studentId']],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveMarks,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
