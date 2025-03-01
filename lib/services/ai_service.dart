import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String _apiKey = 'AIzaSyAZuQaKhxbTelIPtzFvMxyhDhoQAy_NMjg'; // Store this securely
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // Smart attendance insights
  static Future<String> getAttendanceInsights({
    required int totalDays,
    required int presentDays,
    required String studentName,
  }) async {
    try {
      final prompt = '''
        Analyze this student's attendance:
        Student: $studentName
        Total Days: $totalDays
        Present Days: $presentDays
        Attendance Rate: ${(presentDays / totalDays * 100).toStringAsFixed(1)}%

        Provide a brief, constructive insight about the attendance pattern and suggestions for improvement if needed.
        Keep the response within 2-3 sentences.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'Unable to generate insights at the moment.';
    } catch (e) {
      print('Error generating AI insights: $e');
      return 'Unable to generate insights at the moment.';
    }
  }

  // Smart class performance analysis
  static Future<String> getClassPerformanceInsights({
    required Map<String, dynamic> classStats,
    required String className,
  }) async {
    try {
      final prompt = '''
        Analyze this class's attendance pattern:
        Class: $className
        Total Students: ${classStats['totalStudents']}
        Average Attendance: ${classStats['averageAttendance']}%
        Lowest Attendance: ${classStats['lowestAttendance']}%
        Highest Attendance: ${classStats['highestAttendance']}%

        Provide insights about the class performance and suggestions for improvement.
        Keep the response within 2-3 sentences.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'Unable to generate insights at the moment.';
    } catch (e) {
      print('Error generating AI insights: $e');
      return 'Unable to generate insights at the moment.';
    }
  }

  // Predictive attendance analysis
  static Future<String> getPredictiveInsights({
    required List<Map<String, dynamic>> attendanceHistory,
    required String studentName,
  }) async {
    try {
      final historyText = attendanceHistory
          .map((day) => '${day['date']}: ${day['status']}')
          .join('\n');

      final prompt = '''
        Based on this student's attendance history:
        Student: $studentName
        History:
        $historyText

        Predict potential attendance patterns and suggest proactive measures.
        Keep the response within 2-3 sentences.
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      return 'Unable to generate predictions at the moment.';
    } catch (e) {
      print('Error generating AI predictions: $e');
      return 'Unable to generate predictions at the moment.';
    }
  }
}