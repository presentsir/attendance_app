import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String senderName;
  final String senderId;
  final String recipientId;
  final String? classId;
  final String? rollNumber;
  final bool isRead;
  final DateTime timestamp;
  final String notificationType; // 'class', 'individual'

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.senderName,
    required this.senderId,
    required this.recipientId,
    this.classId,
    this.rollNumber,
    required this.isRead,
    required this.timestamp,
    required this.notificationType,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'senderName': senderName,
      'senderId': senderId,
      'recipientId': recipientId,
      'classId': classId,
      'rollNumber': rollNumber,
      'isRead': isRead,
      'timestamp': timestamp,
      'notificationType': notificationType,
    };
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      senderName: data['senderName'] ?? '',
      senderId: data['senderId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      classId: data['classId'],
      rollNumber: data['rollNumber'],
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      notificationType: data['notificationType'] ?? 'individual',
    );
  }
}