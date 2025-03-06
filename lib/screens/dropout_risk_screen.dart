import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/student_model.dart';

class DropoutRiskScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String teacherId;

  DropoutRiskScreen({
    required this.classId,
    required this.className,
    required this.teacherId,
  });

  @override
  _DropoutRiskScreenState createState() => _DropoutRiskScreenState();
}

class _DropoutRiskScreenState extends State<DropoutRiskScreen> {
  bool _isLoading = true;
  List<StudentModel> _students = [];
  Map<String, dynamic> _riskResults = {};

  @override
  void initState() {
    super.initState();
    _loadStudentsAndAnalyze();
  }

  Future<void> _loadStudentsAndAnalyze() async {
    try {
      // Load students from Firestore
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .get();

      setState(() {
        _students = studentsSnapshot.docs
            .map((doc) => StudentModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();
      });

      // Analyze each student's dropout risk
      await _analyzeDropoutRisk();
    } catch (e) {
      print('Error loading students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }

  Future<void> _analyzeDropoutRisk() async {
    try {
      for (var student in _students) {
        // Send data to ML model API
        final response = await http.post(
          Uri.parse('https://studentsdropoutprediction.streamlit.app/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(student.toDropoutAnalysisData()),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          setState(() {
            _riskResults[student.id] = result;
          });
        }
      }
    } catch (e) {
      print('Error analyzing dropout risk: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing dropout risk: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getRiskColor(double risk) {
    if (risk < 0.3) return Colors.green;
    if (risk < 0.7) return Colors.orange;
    return Colors.red;
  }

  String _getRiskLevel(double risk) {
    if (risk < 0.3) return 'Low Risk';
    if (risk < 0.7) return 'Medium Risk';
    return 'High Risk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dropout Risk Analysis'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final riskResult = _riskResults[student.id];
                final risk = riskResult?['risk'] ?? 0.0;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRiskColor(risk),
                      child: Text(
                        '${(risk * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(student.name),
                    subtitle: Text('Roll No: ${student.rollNumber}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getRiskLevel(risk),
                          style: TextStyle(
                            color: _getRiskColor(risk),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Class: ${widget.className}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Show detailed analysis
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Detailed Analysis'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Student: ${student.name}'),
                              Text('Roll No: ${student.rollNumber}'),
                              Text(
                                  'Education Board: ${student.educationBoard}'),
                              Text('Gender: ${student.gender}'),
                              Text(
                                  'Family Structure: ${student.familyStructure}'),
                              Text(
                                  'Parent Education: ${student.parentEducation}'),
                              Text(
                                  'Residential Area: ${student.residentialArea}'),
                              Text(
                                  'Last Year Marks: ${student.lastYearMarks}%'),
                              Text('Family Income: ₹${student.familyIncome}'),
                              SizedBox(height: 16),
                              Text(
                                'Risk Level: ${_getRiskLevel(risk)}',
                                style: TextStyle(
                                  color: _getRiskColor(risk),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Risk Score: ${(risk * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: _getRiskColor(risk),
                                  fontWeight: FontWeight.bold,
                                ),
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
                    },
                  ),
                );
              },
            ),
    );
  }
}
