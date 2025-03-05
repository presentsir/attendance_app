import 'package:http/http.dart' as http;
import 'dart:convert';

class MintlifyService {
  static const String _baseUrl = 'https://api.mintlify.com/v1';
  static const String _adminKey = 'mint_3Zgym6GhV6NBRhQPsJSZhW8q';
  static const String _chatKey = 'mint_dsc_3ZHrRrgbFqnEdY1WhXQXGZJQ';
  static const String _projectId = '67c7156a4411ac230079d384';

  static Future<Map<String, dynamic>> getAttendanceInsights({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> attendanceStats,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_adminKey',
          'X-Project-ID': _projectId,
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an AI assistant specialized in analyzing attendance patterns and providing insights for teachers.
              Focus on providing specific, actionable insights about attendance trends, patterns, and recommendations.
              Include information about best attendance days and areas of concern.''',
            },
            {
              'role': 'user',
              'content': '''
                Analyze this attendance data and provide detailed insights:
                Class ID: $classId
                Period: ${startDate.toString()} to ${endDate.toString()}
                Total Days: ${attendanceStats['total']}
                Present Days: ${attendanceStats['present']}
                Absent Days: ${attendanceStats['absent']}
                Attendance Rate: ${attendanceStats['percentage']}%

                Please provide:
                1. Overall attendance trend (improving, declining, or stable)
                2. Best attendance day of the week
                3. Specific areas of concern or improvement opportunities
                4. Actionable recommendations for teachers
              ''',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to get insights: ${response.body}');
      }
    } catch (e) {
      print('Error getting Mintlify insights: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getChatResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_chatKey',
          'X-Project-ID': _projectId,
        },
        body: jsonEncode({
          'message': message,
          'projectId': _projectId,
        }),
      );

      print('Chat response status: ${response.statusCode}');
      print('Chat response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get chat response: ${response.body}');
      }
    } catch (e) {
      print('Error in chat response: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> authenticateUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_adminKey',
          'X-Project-ID': _projectId,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Auth response status: ${response.statusCode}');
      print('Auth response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Authentication failed: ${response.body}');
      }
    } catch (e) {
      print('Error authenticating with Mintlify: $e');
      rethrow;
    }
  }
}