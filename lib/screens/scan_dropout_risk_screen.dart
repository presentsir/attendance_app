import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dropout_risk_service.dart';

class ScanDropoutRiskScreen extends StatelessWidget {
  final String classId;
  final String className;
  final DropoutRiskService _riskService = DropoutRiskService();

  ScanDropoutRiskScreen({
    required this.classId,
    required this.className,
  });

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Dropout Risk - $className'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('students')
            .orderBy('rollNumber')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading student details',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(
              child: Text(
                'No students found in this class',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final data = student.data() as Map<String, dynamic>;

              // Perform risk analysis synchronously
              final riskAnalysis = _riskService.analyzeDropoutRisk({
                'educationBoard': data['educationBoard'] ?? 'CBSE',
                'gender': data['gender'] ?? 'Male',
                'familyStructure': data['familyStructure'] ?? 'Nuclear',
                'residentialArea': data['residentialArea'] ?? 'Urban',
                'lastYearMarks': data['lastYearMarks']?.toString() ?? '0',
                'familyIncome': data['familyIncome']?.toString() ?? '0',
              });

              final riskLevel = riskAnalysis['riskLevel'] as String;
              final riskScore = riskAnalysis['riskScore'] as double;
              final riskFactors = riskAnalysis['riskFactors'] as List<String>;
              final recommendations =
                  riskAnalysis['recommendations'] as List<String>;

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          data['rollNumber']?.toString() ?? 'N/A',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name']?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Roll No: ${data['rollNumber']?.toString() ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRiskColor(riskLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: _getRiskColor(riskLevel),
                            ),
                            SizedBox(width: 4),
                            Text(
                              riskLevel,
                              style: TextStyle(
                                color: _getRiskColor(riskLevel),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risk Analysis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow('Risk Score',
                              '${(riskScore * 100).toStringAsFixed(1)}%'),
                          _buildDetailRow('Risk Level', riskLevel),
                          if (riskFactors.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              'Risk Factors:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            ...riskFactors.map((factor) => Padding(
                                  padding: EdgeInsets.only(left: 16, top: 4),
                                  child: Text('• $factor'),
                                )),
                          ],
                          if (recommendations.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(
                              'Recommendations:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            ...recommendations.map((rec) => Padding(
                                  padding: EdgeInsets.only(left: 16, top: 4),
                                  child: Text('• $rec'),
                                )),
                          ],
                          Divider(height: 32),
                          Text(
                            'Student Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow('Education Board',
                              data['educationBoard']?.toString() ?? 'N/A'),
                          _buildDetailRow(
                              'Gender', data['gender']?.toString() ?? 'N/A'),
                          _buildDetailRow('Family Structure',
                              data['familyStructure']?.toString() ?? 'N/A'),
                          _buildDetailRow('Residential Area',
                              data['residentialArea']?.toString() ?? 'N/A'),
                          _buildDetailRow('Last Year Marks',
                              '${data['lastYearMarks']?.toString() ?? 'N/A'}%'),
                          _buildDetailRow('Family Income',
                              '₹${data['familyIncome']?.toString() ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
