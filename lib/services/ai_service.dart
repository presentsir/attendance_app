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
      final double attendance = double.parse(classStats['averageAttendance']);
      final int totalDays = int.parse(classStats['presentDays']) + int.parse(classStats['absentDays']);

      if (totalDays == 0) return '';

      String insight = 'Class $className has ${classStats['averageAttendance']}% attendance ';

      if (attendance >= 90) {
        insight += 'which is excellent! Keep up the good work.';
      } else if (attendance >= 75) {
        insight += 'which is good, but there\'s room for improvement.';
      } else {
        insight += 'which needs attention. Consider implementing attendance improvement strategies.';
      }

      insight += '\nTotal days: $totalDays (Present: ${classStats['presentDays']}, Absent: ${classStats['absentDays']})';
      insight += '\nPeriod: ${classStats['dateRange']}';

      return insight;
    } catch (e) {
      print('Error generating insights: $e');
      return '';
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

  static Future<Map<String, dynamic>> getDetailedAttendanceInsights({
    required Map<String, dynamic> stats,
  }) async {
    try {
      final weeklyTrends = stats['weeklyTrends'] as List<double>;
      final trend = _analyzeTrend(weeklyTrends);

      return {
        'trend': _getTrendDescription(trend),
        'bestDay': _analyzeBestDay(stats['dayWiseAttendance']),
        'concerns': _identifyConcerns(stats),
      };
    } catch (e) {
      print('Error generating detailed insights: $e');
      return {};
    }
  }

  static String _getTrendDescription(double trend) {
    if (trend > 5) {
      return 'Attendance is showing significant improvement';
    } else if (trend > 0) {
      return 'Slight positive trend in attendance';
    } else if (trend < -5) {
      return 'Significant decline in attendance rates';
    } else if (trend < 0) {
      return 'Minor decline in attendance';
    }
    return 'Attendance rates are stable';
  }

  static double _analyzeTrend(List<double> weeklyTrends) {
    if (weeklyTrends.length < 2) return 0;
    return weeklyTrends.last - weeklyTrends.first;
  }

  static String _analyzeBestDay(Map<String, int> dayWiseAttendance) {
    if (dayWiseAttendance.isEmpty) return 'Not enough data';

    final bestDay = dayWiseAttendance.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return 'Highest attendance on $bestDay';
  }

  static String _identifyConcerns(Map<String, dynamic> stats) {
    final attendance = double.parse(stats['averageAttendance']);

    if (attendance < 75) {
      return 'Attendance below required threshold';
    } else if (attendance < 85) {
      return 'Room for improvement in overall attendance';
    }
    return 'No major concerns';
  }
}