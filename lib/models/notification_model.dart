import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  motivational,
  attendanceAlert,
  teacherNotification,
  dailyMotivation,
}

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String senderId;
  final String senderName;
  final String classId;
  final String recipientId;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final bool isParentNotification;
  final String? parentMobile;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.senderId,
    required this.senderName,
    required this.classId,
    required this.recipientId,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.isParentNotification = false,
    this.parentMobile,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      classId: data['classId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.teacherNotification,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      isParentNotification: data['isParentNotification'] ?? false,
      parentMobile: data['parentMobile'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'senderId': senderId,
      'senderName': senderName,
      'classId': classId,
      'recipientId': recipientId,
      'type': type.toString(),
      'createdAt': createdAt,
      'isRead': isRead,
      'isParentNotification': isParentNotification,
      'parentMobile': parentMobile,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? senderId,
    String? senderName,
    String? classId,
    String? recipientId,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isParentNotification,
    String? parentMobile,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      classId: classId ?? this.classId,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isParentNotification: isParentNotification ?? this.isParentNotification,
      parentMobile: parentMobile ?? this.parentMobile,
    );
  }
}
