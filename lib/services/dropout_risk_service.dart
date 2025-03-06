import 'dart:convert';
import 'package:http/http.dart' as http;

class DropoutRiskService {
  Map<String, dynamic> analyzeDropoutRisk(Map<String, dynamic> data) {
    double riskScore = 0.0;
    String riskLevel = 'Low';
    List<String> riskFactors = [];
    List<String> recommendations = [];

    // Analyze education board
    if (data['educationBoard'] != 'CBSE') {
      riskScore += 0.1;
      riskFactors.add('Non-CBSE board may have different curriculum standards');
      recommendations
          .add('Consider providing additional CBSE-specific study materials');
    }

    // Analyze gender
    if (data['gender'] == 'Female') {
      riskScore += 0.15;
      riskFactors.add('Gender-based educational challenges');
      recommendations.add('Implement gender-sensitive support programs');
    }

    // Analyze family structure
    if (data['familyStructure'] == 'Single Parent') {
      riskScore += 0.2;
      riskFactors.add('Single parent household may face additional challenges');
      recommendations.add('Offer family support and counseling services');
    }

    // Analyze residential area
    if (data['residentialArea'] == 'Rural') {
      riskScore += 0.15;
      riskFactors.add('Rural area may have limited educational resources');
      recommendations
          .add('Provide additional educational resources and support');
    }

    // Analyze last year marks
    double lastYearMarks =
        double.tryParse(data['lastYearMarks'].toString()) ?? 0.0;
    if (lastYearMarks < 60) {
      riskScore += 0.2;
      riskFactors.add('Low academic performance in previous year');
      recommendations.add('Implement remedial classes and academic support');
    }

    // Analyze family income
    double familyIncome =
        double.tryParse(data['familyIncome'].toString()) ?? 0.0;
    if (familyIncome < 50000) {
      riskScore += 0.2;
      riskFactors.add('Low family income may affect educational resources');
      recommendations
          .add('Provide financial assistance and scholarship information');
    }

    // Determine risk level
    if (riskScore >= 0.7) {
      riskLevel = 'High';
    } else if (riskScore >= 0.4) {
      riskLevel = 'Medium';
    }

    // Add general recommendations based on risk level
    if (riskLevel == 'High') {
      recommendations.add('Schedule regular counseling sessions');
      recommendations.add('Assign a mentor for additional support');
    } else if (riskLevel == 'Medium') {
      recommendations.add('Monitor academic progress closely');
      recommendations.add('Provide regular feedback and guidance');
    }

    return {
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'riskFactors': riskFactors,
      'recommendations': recommendations,
    };
  }
}
