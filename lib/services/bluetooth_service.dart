import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;

  // UUIDs matching ESP32
  final String SERVICE_UUID = "A5A5A5A5-5A5A-5A5A-5A5A-5A5A5A5A5A5A";
  final String CHARACTERISTIC_UUID = "B5B5B5B5-5B5B-5B5B-5B5B-5B5B5B5B5B5B";

  Future<List<BluetoothDevice>> scanForDevices() async {
    List<BluetoothDevice> devices = [];

    await flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name.contains('ESP32-Attendance')) {
          if (!devices.contains(r.device)) {
            devices.add(r.device);
          }
        }
      }
    });

    await flutterBlue.stopScan();
    return devices;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      connectedDevice = device;
    } catch (e) {
      print('Error connecting to device: $e');
      throw e;
    }
  }

  Future<void> sendClassData(String classId, List<Map<String, dynamic>> students) async {
    if (connectedDevice == null) throw Exception('No device connected');

    try {
      List<BluetoothService> services = await connectedDevice!.discoverServices();
      var service = services.firstWhere(
        (s) => s.uuid.toString() == SERVICE_UUID
      );

      var characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toString() == CHARACTERISTIC_UUID
      );

      final data = {
        'type': 'class_data',
        'students': students
      };

      await characteristic.write(utf8.encode(json.encode(data)));
    } catch (e) {
      print('Error sending class data: $e');
      throw e;
    }
  }

  Stream<List<int>> getAttendanceData() {
    if (connectedDevice == null) throw Exception('No device connected');

    return connectedDevice!
      .discoverServices()
      .asStream()
      .expand((services) => services)
      .where((s) => s.uuid.toString() == SERVICE_UUID)
      .expand((s) => s.characteristics)
      .where((c) => c.uuid.toString() == CHARACTERISTIC_UUID)
      .expand((c) => c.value);
  }
}