import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class NotificationBackgroundService {
  static final NotificationBackgroundService _instance =
      NotificationBackgroundService._internal();
  factory NotificationBackgroundService() => _instance;
  NotificationBackgroundService._internal();

  final NotificationService _notificationService = NotificationService();
  Timer? _checkTimer;

  void start() {
    // Check for notifications every 5 minutes
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkScheduledNotifications();
    });
  }

  void stop() {
    _checkTimer?.cancel();
  }

  Future<void> _checkScheduledNotifications() async {
    try {
      await _notificationService.checkScheduledNotifications();
    } catch (e) {
      print('Error checking scheduled notifications: $e');
    }
  }
}
