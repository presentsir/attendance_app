import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserSession {
  static const String _userTypeKey = 'userType';
  static const String _userDataKey = 'userData';

  static Future<void> saveUserSession({
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType);
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString == null) return null;
    return jsonDecode(userDataString);
  }

  static Future<bool> isLoggedIn() async {
    final userType = await getUserType();
    final userData = await getUserData();
    return userType != null && userData != null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userDataKey);
  }
}
