import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/school_model.dart';
import '../services/notification_service.dart';
import '../widgets/theme_toggle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  final bool isTeacher;
  final School school;
  final String classId;

  const NotificationScreen({
    Key? key,
    required this.userId,
    required this.isTeacher,
    required this.school,
    required this.classId,
  }) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedClass;
  String? _selectedStudent;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  NotificationType? _selectedType;

  @override
  void initState() {
    super.initState();
    if (widget.isTeacher) {
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('schoolId', isEqualTo: widget.school.affNo.toString())
          .get();

      setState(() {
        _classes = classesSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'schoolId': doc['schoolId'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading classes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStudents(String classId) async {
    try {
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      setState(() {
        _students = studentsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
            'rollNumber': doc['rollNumber'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading students: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a class')),
        );
        return;
      }

      final notificationService = NotificationService();

      if (_selectedStudent != null) {
        // Send to specific student
        await notificationService.sendNotification(
          title: _titleController.text,
          description: _descriptionController.text,
          senderId: widget.userId,
          senderName: 'Teacher',
          classId: _selectedClass!,
          recipientId: _selectedStudent,
          type: NotificationType.teacherNotification,
        );
      } else {
        // Send to entire class with null recipientId
        await notificationService.sendNotification(
          title: _titleController.text,
          description: _descriptionController.text,
          senderId: widget.userId,
          senderName: 'Teacher',
          classId: _selectedClass!,
          recipientId: null, // null recipientId means it's for the entire class
          type: NotificationType.teacherNotification,
        );
      }

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedClass = null;
        _selectedStudent = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: $e')),
      );
    }
  }

  Stream<List<NotificationModel>> _getNotificationsStream() {
    if (widget.isTeacher) {
      // For teachers, get all notifications they've sent
      return _notificationService.getNotifications(
        userId: widget.userId,
        classId:
            '', // Empty classId for teachers to see all their notifications
        isTeacher: true,
      );
    } else {
      // For students, get notifications for their specific class
      return _notificationService.getNotifications(
        userId: widget.userId,
        classId: widget.classId,
        isTeacher: false,
      );
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text('All'),
            selected: _selectedType == null,
            onSelected: (selected) {
              setState(() {
                _selectedType = null;
              });
            },
          ),
          SizedBox(width: 8),
          ...NotificationType.values.map((type) {
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.toString().split('.').last),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final dateFormat = DateFormat('MMM d, y HH:mm');
    final isUnread = !notification.isRead && !widget.isTeacher;

    if (_selectedType != null && notification.type != _selectedType) {
      return SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isUnread ? Colors.blue[50] : null,
      child: ListTile(
        leading: _buildNotificationIcon(notification.type),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'From: ${notification.senderName}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(notification.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          if (!widget.isTeacher && !notification.isRead) {
            _markAsRead(notification.id);
          }
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.motivational:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case NotificationType.attendanceAlert:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case NotificationType.teacherNotification:
        icon = Icons.message;
        color = Colors.blue;
        break;
      case NotificationType.dailyMotivation:
        icon = Icons.lightbulb;
        color = Colors.green;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.motivational:
        return Colors.amber;
      case NotificationType.attendanceAlert:
        return Colors.red;
      case NotificationType.teacherNotification:
        return Colors.blue;
      case NotificationType.dailyMotivation:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacher ? 'Sent Notifications' : 'Notifications'),
        actions: [
          if (!widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => _markAllAsRead(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final notifications = snapshot.data!;

                if (notifications.isEmpty) {
                  return Center(
                    child: Text(
                      widget.isTeacher
                          ? 'No notifications sent yet'
                          : 'No notifications received yet',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: const ThemeToggle(),
          ),
        ],
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton(
              onPressed: () => _showCreateNotificationDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showCreateNotificationDialog() async {
    final formKey = GlobalKey<FormState>();
    String? selectedClassId;
    String? selectedStudentId;
    String title = '';
    String message = '';
    NotificationType type = NotificationType.teacherNotification;
    bool sendToAllStudents = false;

    // Get classes for the teacher's school
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('schoolId', isEqualTo: widget.school.affNo.toString())
        .get();

    final classes = classesSnapshot.docs;
    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No classes found for your school')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Create Notification'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(),
                    ),
                    items: classes.map((classDoc) {
                      return DropdownMenuItem<String>(
                        value: classDoc.id,
                        child: Text(classDoc['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClassId = value;
                        selectedStudentId = null;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Please select a class';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  if (selectedClassId != null) ...[
                    CheckboxListTile(
                      title: Text('Send to all students'),
                      value: sendToAllStudents,
                      onChanged: (value) {
                        setState(() {
                          sendToAllStudents = value ?? false;
                          if (sendToAllStudents) {
                            selectedStudentId = null;
                          }
                        });
                      },
                    ),
                    if (!sendToAllStudents) ...[
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(selectedClassId)
                            .collection('students')
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircularProgressIndicator();
                          }

                          final students = snapshot.data!.docs;
                          return DropdownButtonFormField<String>(
                            value: selectedStudentId,
                            decoration: InputDecoration(
                              labelText: 'Select Student',
                              border: OutlineInputBorder(),
                            ),
                            items: students.map((studentDoc) {
                              return DropdownMenuItem<String>(
                                value: studentDoc.id,
                                child: Text(studentDoc['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStudentId = value;
                              });
                            },
                            validator: (value) {
                              if (!sendToAllStudents && value == null) {
                                return 'Please select a student';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ],
                  ],
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    onSaved: (value) => title = value ?? '',
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                    onSaved: (value) => message = value ?? '',
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<NotificationType>(
                    value: type,
                    decoration: InputDecoration(
                      labelText: 'Notification Type',
                      border: OutlineInputBorder(),
                    ),
                    items: NotificationType.values.map((type) {
                      return DropdownMenuItem<NotificationType>(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        type = value ?? NotificationType.teacherNotification;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  try {
                    final notificationService = NotificationService();

                    if (sendToAllStudents) {
                      // Send a single class-wide notification
                      await notificationService.sendNotification(
                        title: title,
                        description: message,
                        senderId: widget.userId,
                        senderName: 'Teacher',
                        classId: selectedClassId!,
                        recipientId:
                            null, // null means it's for the entire class
                        type: type,
                      );
                    } else {
                      await notificationService.sendNotification(
                        title: title,
                        description: message,
                        senderId: widget.userId,
                        senderName: 'Teacher',
                        classId: selectedClassId!,
                        recipientId: selectedStudentId,
                        type: type,
                      );
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification sent successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sending notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> _markAllAsRead() async {
    final notifications = await _notificationService
        .getNotifications(
          userId: widget.userId,
          classId: widget.classId,
          isTeacher: widget.isTeacher,
        )
        .first;

    for (var notification in notifications) {
      if (!notification.isRead) {
        await _markAsRead(notification.id);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
