import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ESP32Service {
  static final ESP32Service _instance = ESP32Service._internal();
  factory ESP32Service() => _instance;
  ESP32Service._internal();

  // Check if platform is supported
  bool get isPlatformSupported => !kIsWeb && Platform.isAndroid;

  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  StreamController<bool> connectionStateController = StreamController<bool>.broadcast();
  StreamController<List<BluetoothDevice>> devicesController = StreamController<List<BluetoothDevice>>.broadcast();
  bool isConnected = false;
  bool connected = false;
  StreamSubscription? _discoveryStreamSubscription;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? connectedDevice;

  Future<void> init() async {
    if (!isPlatformSupported) {
      print('Platform not supported for Bluetooth operations');
      return;
    }

    try {
      // Request all necessary permissions first
      await _requestPermissions();

      // Enable Bluetooth if it's not enabled
      bool? isEnabled = await bluetooth.isEnabled;
      if (isEnabled != true) {
        await bluetooth.requestEnable();
      }

      // Check if Bluetooth is on
      BluetoothState state = await bluetooth.state;
      if (state == BluetoothState.STATE_ON) {
        await updateDevicesList();
      }

      // Listen to Bluetooth state changes
      bluetooth.onStateChanged().listen((BluetoothState state) {
        if (state == BluetoothState.STATE_ON) {
          updateDevicesList();
        } else if (state == BluetoothState.STATE_OFF) {
          _devices.clear();
          devicesController.add(_devices);
        }
      });

    } catch (e) {
      print('Error initializing Bluetooth: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request location permission (required for Bluetooth scanning on Android)
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothAdvertise.request();
  }

  Future<void> updateDevicesList() async {
    if (!isPlatformSupported) {
      print('Platform not supported for Bluetooth operations');
      return;
    }

    try {
      // Cancel any existing discovery
      await _discoveryStreamSubscription?.cancel();
      _devices.clear();

      print('Starting Bluetooth scan...');

      // Get paired devices first
      List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices();
      print('Found ${bondedDevices.length} bonded devices');
      _devices.addAll(bondedDevices);
      devicesController.add(_devices);

      // Start discovery
      _discoveryStreamSubscription = bluetooth.startDiscovery().listen(
        (event) {
          print('Found device: ${event.device.name ?? 'Unknown'} (${event.device.address})');
          if (!_devices.any((d) => d.address == event.device.address)) {
            _devices.add(event.device);
            devicesController.add(_devices);
          }
        },
        onDone: () {
          print('Discovery finished');
        },
        onError: (error) {
          print('Error during discovery: $error');
        },
      );

    } catch (e) {
      print('Error updating devices list: $e');
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (!isPlatformSupported) {
      print('Platform not supported for Bluetooth operations');
      return false;
    }

    try {
      print('Connecting to device: ${device.name} (${device.address})');
      connection = await BluetoothConnection.toAddress(device.address);
      isConnected = connection?.isConnected ?? false;
      connected = isConnected;

      if (isConnected) {
        connectedDevice = device;  // Store the connected device
        print('Connected successfully');
        await sendMessage('CONNECTED');
      }

      connectionStateController.add(isConnected);
      return isConnected;
    } catch (e) {
      print('Error connecting to device: $e');
      isConnected = false;
      connected = false;
      connectedDevice = null;
      connectionStateController.add(false);
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      if (connection?.isConnected ?? false) {
        await sendMessage('DISCONNECTED');
        await connection?.close();
      }
      isConnected = false;
      connected = false;
      connectedDevice = null;
      connectionStateController.add(false);
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  Future<void> sendMessage(String message) async {
    try {
      connection?.output.add(Uint8List.fromList(message.codeUnits));
      await connection?.output.allSent;
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<bool> pairDevice(BluetoothDevice device) async {
    if (!isPlatformSupported) {
      print('Platform not supported for Bluetooth operations');
      return false;
    }

    try {
      print('Pairing with device: ${device.name} (${device.address})');
      bool? bondState = await bluetooth.bondDeviceAtAddress(device.address);
      print('Pairing result: $bondState');
      return bondState ?? false;
    } catch (e) {
      print('Error pairing device: $e');
      return false;
    }
  }

  Future<bool> unpairDevice(BluetoothDevice device) async {
    if (!isPlatformSupported) {
      print('Platform not supported for Bluetooth operations');
      return false;
    }

    try {
      print('Unpairing device: ${device.name} (${device.address})');
      bool? unbondState = await bluetooth.removeDeviceBondWithAddress(device.address);
      print('Unpairing result: $unbondState');
      return unbondState ?? false;
    } catch (e) {
      print('Error unpairing device: $e');
      return false;
    }
  }

  Stream<bool> get connectionState => connectionStateController.stream;
  Stream<List<BluetoothDevice>> get discoveredDevices => devicesController.stream;

  bool isDeviceConnected(BluetoothDevice device) {
    return isConnected &&
           connectedDevice != null &&
           device.address == connectedDevice!.address;
  }

  void dispose() {
    _discoveryStreamSubscription?.cancel();
    connectionStateController.close();
    devicesController.close();
    disconnect();
  }
}