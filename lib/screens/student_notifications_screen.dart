import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final String classId;
  final String rollNumber;

  const StudentNotificationsScreen({
    Key? key,
    required this.classId,
    required this.rollNumber,
  }) : super(key: key);

  @override
  _StudentNotificationsScreenState createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getStudentNotifications(
          widget.classId,
          widget.rollNumber,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notifications: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Check back later for updates from your teacher',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              // Mark notification as read when viewed
              if (!notification.isRead) {
                _notificationService.markNotificationAsRead(notification.id);
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.notificationType == 'class'
                        ? Colors.blue
                        : Colors.green,
                    child: Icon(
                      notification.notificationType == 'class'
                          ? Icons.group
                          : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: notification.isRead ? null : Colors.blue,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(notification.message),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'From: ${notification.senderName}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy - hh:mm a')
                                .format(notification.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    _showNotificationDetails(notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.message),
              SizedBox(height: 16),
              Text(
                'From: ${notification.senderName}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              Text(
                'Sent: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(notification.timestamp)}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                'Type: ${notification.notificationType == 'class' ? 'Class Announcement' : 'Personal Message'}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}