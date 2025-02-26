import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../esp32/esp32_service.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class ESP32ConnectionStatus extends StatefulWidget {
  @override
  _ESP32ConnectionStatusState createState() => _ESP32ConnectionStatusState();
}

class _ESP32ConnectionStatusState extends State<ESP32ConnectionStatus> {
  final ESP32Service _esp32Service = ESP32Service();
  bool _isConnected = false;
  Timer? _refreshTimer;
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    // Start periodic refresh
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        _refreshDevices();
      }
    });
  }

  Future<void> _initBluetooth() async {
    try {
      // Check if all permissions are granted
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please grant all required permissions to use Bluetooth'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      await _esp32Service.init();

      // Listen for connection state changes
      _esp32Service.connectionState.listen((connected) {
        if (mounted) {
          setState(() => _isConnected = connected);
        }
      });

      // Listen for discovered devices
      _esp32Service.discoveredDevices.listen((devices) {
        if (mounted) {
          setState(() {
            _devices = devices;
            print('Updated devices list: ${devices.length} devices');
            devices.forEach((device) {
              print('Device: ${device.name ?? 'Unknown'} (${device.address})');
            });
          });
        }
      });

      await _refreshDevices();
    } catch (e) {
      print('Error initializing Bluetooth: $e');
    }
  }

  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _refreshDevices() async {
    if (!_isScanning) {
      setState(() {
        _isScanning = true;
        _devices.clear(); // Clear existing devices before new scan
      });

      try {
        await _esp32Service.updateDevicesList();
      } finally {
        if (mounted) {
          setState(() => _isScanning = false);
        }
      }
    }
  }

  Widget _buildDeviceList() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Devices',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!_isConnected) IconButton(
              icon: Icon(_isScanning ? Icons.sync : Icons.refresh),
              onPressed: _isScanning ? null : _refreshDevices,
            ),
          ],
        ),
        SizedBox(height: 8),
        if (_isScanning)
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Scanning for devices...'),
              ],
            ),
          ),
        if (_devices.isEmpty && !_isScanning)
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('No devices found'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshDevices,
                  child: Text('Scan Again'),
                ),
              ],
            ),
          ),
        if (_devices.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              bool isThisDeviceConnected = _esp32Service.isDeviceConnected(device);
              bool isPaired = device.isBonded;

              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.bluetooth,
                    color: isPaired ? Colors.blue : Colors.grey,
                  ),
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.address),
                      Text(
                        isPaired ? 'Paired' : 'Not Paired',
                        style: TextStyle(
                          color: isPaired ? Colors.blue : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPaired && !isThisDeviceConnected)
                        IconButton(
                          icon: Icon(Icons.link_off),
                          onPressed: () async {
                            await _esp32Service.unpairDevice(device);
                            _refreshDevices();
                          },
                          tooltip: 'Unpair',
                        ),
                      if (!isPaired)
                        IconButton(
                          icon: Icon(Icons.link),
                          onPressed: () async {
                            await _esp32Service.pairDevice(device);
                            _refreshDevices();
                          },
                          tooltip: 'Pair',
                        ),
                      if (isPaired)
                        ElevatedButton(
                          onPressed: isThisDeviceConnected
                              ? () => _esp32Service.disconnect()
                              : () => _esp32Service.connectToDevice(device),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isThisDeviceConnected ? Colors.red : Colors.blue,
                          ),
                          child: Text(isThisDeviceConnected ? 'Disconnect' : 'Connect'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_esp32Service.isPlatformSupported) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Bluetooth Not Supported',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Text(
                'This feature is only available on Android devices.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ESP32 Connection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(
                  Icons.circle,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_isConnected)
              ElevatedButton(
                onPressed: () => _esp32Service.disconnect(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(double.infinity, 36),
                ),
                child: Text('Disconnect'),
              )
            else
              _buildDeviceList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _esp32Service.dispose();
    super.dispose();
  }
}