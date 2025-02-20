import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WiFiService {
  static final WiFiService _instance = WiFiService._internal();
  factory WiFiService() => _instance;
  WiFiService._internal();

  final String esp32SSID = "AttendanceDevice";
  final String esp32Password = "12345678";
  final String esp32ServerURL = "http://192.168.4.1/attendance.json";

  bool isConnectedToESP32 = false;

  Future<bool> connectToESP32() async {
    try {
      // Connect to ESP32's WiFi network
      bool connected = await WiFiForIoTPlugin.connect(
        esp32SSID,
        password: esp32Password,
        security: NetworkSecurity.WPA,
      );

      if (connected) {
        // Wait for connection to establish
        await Future.delayed(Duration(seconds: 2));

        // Verify we're connected to ESP32
        String? currentSSID = await WiFiForIoTPlugin.getSSID();
        isConnectedToESP32 = currentSSID == esp32SSID;

        return isConnectedToESP32;
      }
      return false;
    } catch (e) {
      print('Error connecting to ESP32: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchAttendanceData() async {
    try {
      if (!isConnectedToESP32) {
        throw Exception('Not connected to ESP32');
      }

      final response = await http.get(Uri.parse(esp32ServerURL));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      return null;
    }
  }

  Future<void> disconnectFromESP32() async {
    try {
      await WiFiForIoTPlugin.disconnect();
      isConnectedToESP32 = false;
    } catch (e) {
      print('Error disconnecting from ESP32: $e');
    }
  }
}