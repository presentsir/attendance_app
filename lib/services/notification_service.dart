import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification to an entire class
  Future<void> sendClassNotification({
    required String classId,
    required String title,
    required String message,
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      // Create the notification document
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'senderName': teacherName,
        'senderId': teacherId,
        'recipientId': classId, // For class notifications, recipientId is the classId
        'classId': classId,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'notificationType': 'class',
      });
    } catch (e) {
      print('Error sending class notification: $e');
      throw e;
    }
  }

  // Send notification to a specific student
  Future<void> sendStudentNotification({
    required String classId,
    required String rollNumber,
    required String title,
    required String message,
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      // Get the student from Firebase
      final studentQuery = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('rollNumber', isEqualTo: rollNumber)
          .get();

      if (studentQuery.docs.isEmpty) {
        throw 'Student not found';
      }

      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();

      // Create the notification document
      await _firestore.collection('notifications').add({
        'title': title,
        'message': message,
        'senderName': teacherName,
        'senderId': teacherId,
        'recipientId': studentDoc.id,
        'classId': classId,
        'rollNumber': rollNumber,
        'studentName': studentData['name'] ?? 'Student',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'notificationType': 'individual',
      });
    } catch (e) {
      print('Error sending student notification: $e');
      throw e;
    }
  }

  // Get notifications for a specific student
  Stream<List<NotificationModel>> getStudentNotifications(String classId, String rollNumber) {
    return _firestore
        .collection('notifications')
        .where('classId', isEqualTo: classId)
        .where('notificationType', whereIn: ['class', 'individual'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                // Include notifications that are:
                // 1. For the entire class OR
                // 2. Specifically for this student
                return data['notificationType'] == 'class' ||
                    (data['notificationType'] == 'individual' &&
                     data['rollNumber'] == rollNumber);
              })
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      throw e;
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String classId, String rollNumber) {
    return getStudentNotifications(classId, rollNumber).map(
      (notifications) => notifications.where((n) => !n.isRead).length,
    );
  }
}