import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/dropout_risk_service.dart';

class StudentDetailsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final DropoutRiskService _riskService = DropoutRiskService();

  StudentDetailsScreen({
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
        return AppTheme.secondaryTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Details - $className'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
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
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonOrange),
              ),
            );
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.secondaryTextColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final data = student.data() as Map<String, dynamic>;

              // Perform risk analysis
              final riskAnalysis = _riskService.analyzeDropoutRisk({
                'educationBoard': data['educationBoard'] ?? 'CBSE',
                'gender': data['gender'] ?? 'Male',
                'familyStructure': data['familyStructure'] ?? 'Nuclear',
                'residentialArea': data['residentialArea'] ?? 'Urban',
                'lastYearMarks': data['lastYearMarks']?.toString() ?? '0',
                'familyIncome': data['familyIncome']?.toString() ?? '0',
              });

              final riskLevel = riskAnalysis['riskLevel'] as String;
              final riskColor = _getRiskColor(riskLevel);

              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Text(
                        '${data['rollNumber'] ?? 'N/A'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonOrange,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['name'] ?? 'Unknown',
                          style: TextStyle(color: AppTheme.textColor),
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: riskColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              riskLevel,
                              style: TextStyle(
                                color: riskColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.neonBlue.withOpacity(0.1),
                    child: Text(
                      data['name']?[0] ?? '?',
                      style: TextStyle(
                        color: AppTheme.neonBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow('Risk Score',
                              '${((riskAnalysis['riskScore'] as double) * 100).toStringAsFixed(1)}%'),
                          _buildDetailRow('Risk Level', riskLevel),
                          if ((riskAnalysis['riskFactors'] as List<String>)
                              .isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              'Risk Factors:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            ...(riskAnalysis['riskFactors'] as List<String>)
                                .map((factor) => Padding(
                                      padding:
                                          EdgeInsets.only(left: 16, top: 4),
                                      child: Text('• $factor',
                                          style: TextStyle(
                                              color: AppTheme.textColor)),
                                    )),
                          ],
                          if ((riskAnalysis['recommendations'] as List<String>)
                              .isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(
                              'Recommendations:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ),
                            ...(riskAnalysis['recommendations'] as List<String>)
                                .map((rec) => Padding(
                                      padding:
                                          EdgeInsets.only(left: 16, top: 4),
                                      child: Text('• $rec',
                                          style: TextStyle(
                                              color: AppTheme.textColor)),
                                    )),
                          ],
                          Divider(height: 32),
                          Text(
                            'Student Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildDetailRow(
                              'Mobile Number', data['mobileNumber'] ?? 'N/A'),
                          _buildDetailRow('Gender', data['gender'] ?? 'N/A'),
                          _buildDetailRow('Family Structure',
                              data['familyStructure'] ?? 'N/A'),
                          _buildDetailRow('Parent Education',
                              data['parentEducation'] ?? 'N/A'),
                          _buildDetailRow('Residential Area',
                              data['residentialArea'] ?? 'N/A'),
                          _buildDetailRow('Last Year Marks',
                              '${data['lastYearMarks'] ?? 'N/A'}%'),
                          _buildDetailRow('Family Income',
                              '₹${data['familyIncome'] ?? 'N/A'}'),
                          _buildDetailRow(
                              'Academic Trend', data['academicTrend'] ?? 'N/A'),
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
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
