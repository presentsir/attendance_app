import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../models/notification_model.dart';
import '../config/api_keys.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  static const String _huggingFaceApiUrl =
      'https://api-inference.huggingface.co/models/facebook/opt-350m';

  NotificationService() {
    // No initialization needed for Hugging Face API
  }

  // Comprehensive list of motivational messages
  final List<String> _fallbackMessages = [
    // Casual Greetings
    "Hey there! Ready to make today amazing?",
    "Good morning! Time to start your learning adventure!",
    "Hey student! Up for some learning today?",
    "Still scrolling? Let's get to class!",
    "Wakey wakey! Time for some learning!",
    "Hey! Ready to rock your studies?",
    "Good day! Let's make it count!",
    "Hey there! Ready to learn something new?",
    "Morning! Time to shine in class!",
    "Hey student! Ready to conquer today?",

    // Fun Learning
    "Learning is like a game - let's play to win!",
    "Time to level up your knowledge!",
    "Ready to unlock new achievements in class?",
    "Let's make learning fun today!",
    "Time to collect some knowledge points!",
    "Ready to power up your brain?",
    "Let's make today's lesson epic!",
    "Time to add some skills to your character!",
    "Ready to complete today's learning quest?",
    "Let's make learning an adventure!",

    // Social Motivation
    "Your friends are waiting in class!",
    "Don't miss out on the fun in class!",
    "Your study buddies miss you!",
    "Join the learning party in class!",
    "Be the cool kid who shows up!",
    "Your classmates are counting on you!",
    "Don't be the one who's always late!",
    "Be the one who makes class fun!",
    "Your presence makes class better!",
    "Join the learning squad today!",

    // Time Management
    "Tick tock! Time for class!",
    "Don't let time slip away!",
    "Make the most of your day!",
    "Time is precious - use it wisely!",
    "Don't waste your learning time!",
    "Every minute counts in class!",
    "Be the early bird who catches the knowledge!",
    "Don't be fashionably late to class!",
    "Time to show up and shine!",
    "Make every moment count!",

    // Future Focus
    "Your future self will thank you!",
    "Today's effort = tomorrow's success!",
    "Invest in your future today!",
    "Your dreams start in class!",
    "Build your future one class at a time!",
    "Your success story starts here!",
    "Make today count for tomorrow!",
    "Your future is in your hands!",
    "Shape your destiny in class!",
    "Your future is worth showing up for!",

    // Achievement Focus
    "Be the student who makes it happen!",
    "Show up and show off your potential!",
    "Make today your best day yet!",
    "Be the one who stands out!",
    "Your achievements start in class!",
    "Be the student who makes a difference!",
    "Show up and be amazing!",
    "Your success starts with showing up!",
    "Be the student who inspires others!",
    "Make your mark in class today!",

    // Personal Growth
    "Grow stronger with every class!",
    "Level up your skills today!",
    "Be better than yesterday!",
    "Your growth starts in class!",
    "Challenge yourself to show up!",
    "Be the student who never gives up!",
    "Your potential is waiting in class!",
    "Grow into your best self!",
    "Be the student who keeps improving!",
    "Your journey to greatness starts here!",

    // Learning Attitude
    "Be curious, be present, be amazing!",
    "Your mind is ready to learn!",
    "Be the student who loves learning!",
    "Your brain is hungry for knowledge!",
    "Be excited about learning today!",
    "Your curiosity leads to success!",
    "Be the student who asks questions!",
    "Your learning journey continues!",
    "Be passionate about your education!",
    "Your love for learning shows!",

    // Success Mindset
    "Success starts with showing up!",
    "Be the student who makes it happen!",
    "Your success is in your hands!",
    "Be the one who never misses class!",
    "Your dedication leads to success!",
    "Be the student who stands out!",
    "Your commitment shows in class!",
    "Be the one who makes a difference!",
    "Your hard work pays off!",
    "Be the student who inspires others!",

    // Daily Motivation
    "Make today count!",
    "Be the best version of you!",
    "Your day starts in class!",
    "Be the student who makes it happen!",
    "Your potential is limitless!",
    "Be the one who shows up!",
    "Your success story continues!",
    "Be the student who never gives up!",
    "Your journey to greatness continues!",
    "Be the one who makes a difference!",

    // Fun Facts
    "Did you know? Learning makes you smarter!",
    "Fun fact: Showing up is half the battle!",
    "Here's a secret: Class is where magic happens!",
    "Did you know? Your brain loves learning!",
    "Fun fact: Success starts in class!",
    "Here's a tip: Be present to be powerful!",
    "Did you know? Your future is in class!",
    "Fun fact: Learning is the key to success!",
    "Here's a secret: Your potential is waiting!",
    "Did you know? Every class counts!",

    // Encouragement
    "You've got this!",
    "Believe in yourself!",
    "You're capable of amazing things!",
    "Your potential is endless!",
    "You're stronger than you know!",
    "Your determination is inspiring!",
    "You're making great progress!",
    "Your hard work shows!",
    "You're on the right track!",
    "Your effort is worth it!",

    // Positive Vibes
    "Spread positivity in class!",
    "Your energy makes class better!",
    "Be the light in the classroom!",
    "Your presence brings joy!",
    "Be the student who lifts others!",
    "Your smile brightens the class!",
    "Be the one who spreads happiness!",
    "Your attitude is contagious!",
    "Be the student who makes others smile!",
    "Your positivity makes a difference!",

    // Achievement Focus
    "Be the student who makes history!",
    "Your achievements start here!",
    "Be the one who breaks records!",
    "Your success is in your hands!",
    "Be the student who sets the bar high!",
    "Your excellence shows in class!",
    "Be the one who makes it happen!",
    "Your dedication leads to greatness!",
    "Be the student who inspires others!",
    "Your hard work pays off!",

    // Learning Journey
    "Your learning adventure continues!",
    "Be the student who explores!",
    "Your journey to knowledge continues!",
    "Be the one who discovers!",
    "Your path to success continues!",
    "Be the student who learns!",
    "Your growth journey continues!",
    "Be the one who evolves!",
    "Your development continues!",
    "Be the student who improves!",

    // Future Focus
    "Your future is bright!",
    "Be the student who shapes tomorrow!",
    "Your destiny is in your hands!",
    "Be the one who creates the future!",
    "Your success story continues!",
    "Be the student who makes history!",
    "Your legacy starts here!",
    "Be the one who changes the world!",
    "Your impact starts in class!",
    "Be the student who makes a difference!",

    // Personal Development
    "Grow into your best self!",
    "Be the student who evolves!",
    "Your development continues!",
    "Be the one who improves!",
    "Your growth journey continues!",
    "Be the student who learns!",
    "Your progress shows!",
    "Be the one who develops!",
    "Your improvement continues!",
    "Be the student who grows!",

    // Success Mindset
    "Success is your destiny!",
    "Be the student who wins!",
    "Your victory starts here!",
    "Be the one who succeeds!",
    "Your triumph is coming!",
    "Be the student who achieves!",
    "Your accomplishment awaits!",
    "Be the one who conquers!",
    "Your success is guaranteed!",
    "Be the student who prevails!",

    // Learning Attitude
    "Love learning, love life!",
    "Be the student who learns!",
    "Your knowledge grows daily!",
    "Be the one who studies!",
    "Your wisdom increases!",
    "Be the student who understands!",
    "Your learning continues!",
    "Be the one who comprehends!",
    "Your education progresses!",
    "Be the student who masters!",

    // Daily Inspiration
    "Make today amazing!",
    "Be the student who shines!",
    "Your day starts here!",
    "Be the one who excels!",
    "Your morning begins in class!",
    "Be the student who thrives!",
    "Your success starts now!",
    "Be the one who flourishes!",
    "Your potential is unleashed!",
    "Be the student who prospers!",
  ];

  // Send a notification
  Future<void> sendNotification({
    required String title,
    required String description,
    required String senderId,
    required String senderName,
    required String classId,
    String? recipientId,
    required NotificationType type,
  }) async {
    try {
      final notification = {
        'title': title,
        'description': description,
        'senderId': senderId,
        'senderName': senderName,
        'classId': classId,
        'recipientId':
            recipientId ?? '', // Use empty string for class-wide notifications
        'type': type.toString(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add notification to Firestore
      await _firestore.collection('notifications').add(notification);

      // If this is a notification sent to a specific student, also send it to their parent
      if (recipientId != null && recipientId.isNotEmpty) {
        // Get the student's mobile number
        final studentDoc = await _firestore
            .collection('classes')
            .doc(classId)
            .collection('students')
            .doc(recipientId)
            .get();

        if (studentDoc.exists) {
          final studentData = studentDoc.data() as Map<String, dynamic>;
          final parentMobile = studentData['mobileNumber'] as String?;

          if (parentMobile != null) {
            // Create a parent notification
            final parentNotification = {
              'title': title,
              'description': description,
              'senderId': senderId,
              'senderName': senderName,
              'classId': classId,
              'recipientId': recipientId,
              'type': type.toString(),
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
              'isParentNotification': true,
              'parentMobile': parentMobile,
            };

            await _firestore
                .collection('notifications')
                .add(parentNotification);
          }
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  // Get notifications stream for a user
  Stream<List<NotificationModel>> getNotifications({
    required String userId,
    required String classId,
    required bool isTeacher,
  }) {
    Query query = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (isTeacher) {
      // For teachers, get notifications where they are the sender
      query = query.where('senderId', isEqualTo: userId);
      // Only filter by classId if it's not empty
      if (classId.isNotEmpty) {
        query = query.where('classId', isEqualTo: classId);
      }
    } else {
      // For students, get notifications where:
      // 1. recipientId matches the student's ID (specific notifications)
      // 2. recipientId is empty string (class-wide notifications)
      // 3. classId matches the student's class
      query = query.where('classId', isEqualTo: classId).where('recipientId',
          whereIn: [
            userId,
            ''
          ]); // Include both specific and class-wide notifications
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // For students, filter out parent notifications
            if (!isTeacher && data['isParentNotification'] == true) {
              return null;
            }
            return NotificationModel.fromFirestore(doc);
          })
          .whereType<NotificationModel>()
          .toList();
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadCount(String userId, String classId) {
    return _firestore
        .collection('notifications')
        .where('classId', isEqualTo: classId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Skip parent notifications for students
        if (data['isParentNotification'] == true) {
          return false;
        }
        final recipientId = data['recipientId'];
        return recipientId == '' ||
            recipientId == userId; // Check for empty string
      }).length;
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Generate motivational message using Hugging Face API or fallback
  Future<String> generateMotivationalMessage(String studentName) async {
    try {
      final response = await http.post(
        Uri.parse(_huggingFaceApiUrl),
        headers: {
          'Authorization': 'Bearer ${ApiKeys.huggingFaceApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs':
              'Generate a short, one-line motivational message for $studentName about education. Keep it under 15 words.',
          'parameters': {
            'max_length': 50, // Reduced from 100 to 50
            'temperature': 0.7,
            'num_return_sequences': 1,
            'do_sample': true,
            'top_p': 0.9,
            'repetition_penalty': 1.2,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is Map) {
          final generatedText = data[0]['generated_text'] as String;
          // Clean up the text to ensure it's a single line
          final cleanText = generatedText
              .split('\n')[0] // Take only the first line
              .trim()
              .replaceAll(RegExp(r'\s+'),
                  ' '); // Replace multiple spaces with single space

          // If the message is too long, fall back to predefined message
          if (cleanText.split(' ').length > 15) {
            return _getRandomFallbackMessage();
          }

          return cleanText;
        }
      }
      print(
          'Falling back to predefined message. Status code: ${response.statusCode}');
      return _getRandomFallbackMessage();
    } catch (e) {
      print('Error generating motivational message: $e');
      return _getRandomFallbackMessage();
    }
  }

  String _getRandomFallbackMessage() {
    return _fallbackMessages[_random.nextInt(_fallbackMessages.length)];
  }

  // Send instant welcome notification to student
  Future<void> sendWelcomeNotification({
    required String studentId,
    required String studentName,
    required String classId,
  }) async {
    // Use predefined message instead of generating one
    final message = _getRandomFallbackMessage();

    await sendNotification(
      title: 'Welcome to RANI PUBLIC SCHOOL!',
      description: message,
      senderId: 'system',
      senderName: 'School System',
      classId: classId,
      recipientId: studentId,
      type: NotificationType.motivational,
    );
  }

  // Schedule daily motivational message
  Future<void> scheduleDailyMotivation({
    required String studentId,
    required String studentName,
    required double attendancePercentage,
  }) async {
    // Generate a random time between 8 AM and 6 PM
    final now = DateTime.now();
    final randomHour = 8 + _random.nextInt(11); // Random hour between 8 and 18
    final randomMinute = _random.nextInt(60);

    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      randomHour,
      randomMinute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    final targetTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    // Store the scheduled time in Firestore
    await _firestore.collection('notification_schedules').doc(studentId).set({
      'nextNotificationTime': Timestamp.fromDate(targetTime),
      'studentName': studentName,
      'attendancePercentage': attendancePercentage,
    });
  }

  // Send attendance alert to teacher and parent
  Future<void> sendAttendanceAlert({
    required String studentId,
    required String studentName,
    required String classId,
    required String teacherId,
    required String teacherName,
    required double attendancePercentage,
  }) async {
    String title;
    String description;

    if (attendancePercentage < 60) {
      title = 'Low Attendance Alert';
      description =
          '$studentName has critically low attendance ($attendancePercentage%). Please take immediate action.';
    } else if (attendancePercentage < 75) {
      title = 'Attendance Warning';
      description =
          '$studentName has low attendance ($attendancePercentage%). Please monitor.';
    } else if (attendancePercentage > 90) {
      title = 'Excellent Attendance';
      description =
          '$studentName has excellent attendance ($attendancePercentage%). Great job!';
    } else {
      title = 'Attendance Update';
      description = '$studentName has $attendancePercentage% attendance.';
    }

    // Send to student
    await sendNotification(
      title: title,
      description: description,
      senderId: 'system',
      senderName: 'System',
      classId: classId,
      recipientId: studentId,
      type: NotificationType.attendanceAlert,
    );

    // Get student's parent mobile number
    final studentDoc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('students')
        .doc(studentId)
        .get();

    if (studentDoc.exists) {
      final studentData = studentDoc.data() as Map<String, dynamic>;
      final parentMobile = studentData['mobileNumber'] as String?;

      if (parentMobile != null) {
        // Create a parent notification
        final parentNotification = {
          'title': title,
          'description': description,
          'senderId': 'system',
          'senderName': 'System',
          'classId': classId,
          'recipientId': studentId,
          'type': NotificationType.attendanceAlert.toString(),
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'isParentNotification': true,
          'parentMobile': parentMobile,
        };

        await _firestore.collection('notifications').add(parentNotification);
      }
    }
  }

  // Send daily motivational message to student
  Future<void> sendDailyMotivation({
    required String studentId,
    required String studentName,
    required String classId,
  }) async {
    // Use predefined message instead of generating one
    final message = _getRandomFallbackMessage();

    await sendNotification(
      title: 'Daily Motivation',
      description: message,
      senderId: 'system',
      senderName: 'School System',
      classId: classId,
      recipientId: studentId,
      type: NotificationType.dailyMotivation,
    );
  }

  // Check and send scheduled notifications
  Future<void> checkScheduledNotifications() async {
    final now = DateTime.now();
    final schedules = await _firestore
        .collection('notification_schedules')
        .where('nextNotificationTime', isLessThan: Timestamp.fromDate(now))
        .get();

    for (final schedule in schedules.docs) {
      final data = schedule.data();
      await sendDailyMotivation(
        studentId: schedule.id,
        studentName: data['studentName'],
        classId: data['classId'],
      );
    }
  }
}
