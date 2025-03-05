import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_manager.dart';

class ChatbotService {
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  final ServerManager _serverManager = ServerManager();
  String _currentModel = 'mistral-7b';

  Future<String> getResponse(String message) async {
    try {
      // First try to get a predefined response
      String response = getPredefinedResponse(message);

      // If no predefined response matches, use the AI model
      if (response.contains('Could you please provide more details')) {
        // Ensure the model is running
        await _serverManager.startModel(_currentModel);

        // Get the response from the model
        response =
            await _serverManager.generateResponse(_currentModel, message);
      }

      return response;
    } catch (e) {
      print('Error in getResponse: $e');
      return 'I apologize, but I\'m having trouble processing your request right now. Please try again later.';
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    return await _serverManager.getSystemInfo();
  }

  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    return _serverManager.availableModels
        .map((model) => model.toJson())
        .toList();
  }

  Future<Map<String, dynamic>> getModelStatus(String modelName) async {
    return await _serverManager.getModelStatus(modelName);
  }

  Future<bool> startModel(String modelName) async {
    return await _serverManager.startModel(modelName);
  }

  Future<bool> stopModel(String modelName) async {
    return await _serverManager.stopModel(modelName);
  }

  // Predefined responses for common queries
  static String getPredefinedResponse(String message) {
    final lowerMessage = message.toLowerCase();

    // Greetings and Basic Interactions
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! I\'m your school assistant. How can I help you today?';
    }

    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    }

    if (lowerMessage.contains('bye') || lowerMessage.contains('goodbye')) {
      return 'Goodbye! Have a great day!';
    }

    if (lowerMessage.contains('how are you')) {
      return 'I\'m doing well, thank you for asking! How can I help you today?';
    }

    // Attendance Related
    if (lowerMessage.contains('attendance') ||
        lowerMessage.contains('present')) {
      if (lowerMessage.contains('mark')) {
        return 'To mark attendance, please go to the attendance section and select your class. Teachers can mark attendance for their students, and students can view their attendance records.';
      } else if (lowerMessage.contains('check') ||
          lowerMessage.contains('view')) {
        return 'You can view your attendance records in the attendance section. The records show your daily attendance status and monthly attendance percentage.';
      } else if (lowerMessage.contains('policy')) {
        return 'The school\'s attendance policy requires a minimum of 75% attendance. Students falling below this may need to attend extra classes or face disciplinary action.';
      }
      return 'To check your attendance, please go to the attendance section. You can view your daily attendance records and monthly attendance percentage there.';
    }

    // Grades and Academics
    if (lowerMessage.contains('grade') || lowerMessage.contains('marks')) {
      if (lowerMessage.contains('check') || lowerMessage.contains('view')) {
        return 'You can view your grades in the academic section. The grades are updated by teachers after each assessment.';
      } else if (lowerMessage.contains('policy')) {
        return 'The grading system follows a 10-point scale. A grade of 9-10 is excellent, 7-8 is good, 5-6 is satisfactory, and below 5 requires improvement.';
      } else if (lowerMessage.contains('update')) {
        return 'Teachers can update grades through the grade management system. The updates are reflected immediately in the student portal.';
      }
      return 'You can view your grades in the academic section. Teachers can update grades through the grade management system.';
    }

    // Holidays and Events
    if (lowerMessage.contains('holiday') || lowerMessage.contains('leave')) {
      if (lowerMessage.contains('check') || lowerMessage.contains('view')) {
        return 'Holiday information is available in the calendar section. You can view upcoming holidays and events there.';
      } else if (lowerMessage.contains('request')) {
        return 'To request a leave, please submit a leave application through the portal. Include the reason and duration of leave.';
      } else if (lowerMessage.contains('calendar')) {
        return 'The school calendar is available in the calendar section. It includes all holidays, events, and important dates.';
      }
      return 'Holiday information is available in the calendar section. You can also check the announcements for any updates.';
    }

    // Contact and Support
    if (lowerMessage.contains('contact') || lowerMessage.contains('help')) {
      if (lowerMessage.contains('teacher')) {
        return 'You can find your teachers\' contact information in the staff directory. Each teacher\'s email and office hours are listed there.';
      } else if (lowerMessage.contains('admin')) {
        return 'For administrative support, please contact the school office at admin@school.edu or call (555) 123-4567.';
      } else if (lowerMessage.contains('emergency')) {
        return 'For emergencies, please contact the school emergency hotline at (555) 999-9999 or visit the school office immediately.';
      }
      return 'For support, you can contact your class teacher or the school administration. Their contact details are available in the contact section.';
    }

    // Fees and Payments
    if (lowerMessage.contains('fee') || lowerMessage.contains('payment')) {
      if (lowerMessage.contains('check') || lowerMessage.contains('view')) {
        return 'You can view your fee structure and payment history in the fees section. All transactions are recorded there.';
      } else if (lowerMessage.contains('pay')) {
        return 'To pay fees, go to the fees section and select the payment option. You can pay online using various payment methods.';
      } else if (lowerMessage.contains('due')) {
        return 'Fee due dates are displayed in the fees section. Late payments may incur additional charges.';
      }
      return 'Fee payment information can be found in the fees section. You can view your fee structure and payment history there.';
    }

    // Library
    if (lowerMessage.contains('library') || lowerMessage.contains('book')) {
      if (lowerMessage.contains('borrow')) {
        return 'To borrow books, visit the library section. You can check book availability and request to borrow them.';
      } else if (lowerMessage.contains('return')) {
        return 'Books can be returned at the library counter. Make sure to return them before the due date to avoid fines.';
      } else if (lowerMessage.contains('search')) {
        return 'You can search for books in the library catalog. Use keywords like title, author, or subject to find books.';
      }
      return 'The library section provides access to books, journals, and digital resources. You can search, borrow, and return books there.';
    }

    // Sports and Activities
    if (lowerMessage.contains('sport') || lowerMessage.contains('activity')) {
      if (lowerMessage.contains('schedule')) {
        return 'Sports and activity schedules are posted in the activities section. You can view upcoming events and practice sessions.';
      } else if (lowerMessage.contains('join')) {
        return 'To join a sports team or activity, visit the activities section and submit an application. Coaches will review your request.';
      } else if (lowerMessage.contains('team')) {
        return 'Team information and rosters are available in the sports section. You can view team members and upcoming matches.';
      }
      return 'Information about sports and activities is available in the activities section. You can view schedules and join teams there.';
    }

    // Transportation
    if (lowerMessage.contains('bus') || lowerMessage.contains('transport')) {
      if (lowerMessage.contains('route')) {
        return 'Bus routes and schedules are available in the transportation section. You can view your assigned route and timings.';
      } else if (lowerMessage.contains('request')) {
        return 'To request a change in bus route or schedule, please contact the transportation office or submit a request through the portal.';
      }
      return 'Transportation information, including bus routes and schedules, is available in the transportation section.';
    }

    // Cafeteria
    if (lowerMessage.contains('food') || lowerMessage.contains('cafeteria')) {
      if (lowerMessage.contains('menu')) {
        return 'The cafeteria menu is posted weekly in the cafeteria section. You can view daily specials and regular items.';
      } else if (lowerMessage.contains('order')) {
        return 'You can pre-order meals through the cafeteria section. Orders must be placed at least one day in advance.';
      }
      return 'Information about the cafeteria, including menus and ordering options, is available in the cafeteria section.';
    }

    // Health and Medical
    if (lowerMessage.contains('health') || lowerMessage.contains('medical')) {
      if (lowerMessage.contains('nurse')) {
        return 'The school nurse is available in the medical room during school hours. For emergencies, contact the office immediately.';
      } else if (lowerMessage.contains('medicine')) {
        return 'To request medication administration, please submit a medical form through the health section. Include prescription details.';
      }
      return 'Health and medical information is available in the health section. You can find details about the school nurse and medical procedures.';
    }

    // General Information
    if (lowerMessage.contains('school') || lowerMessage.contains('about')) {
      if (lowerMessage.contains('history')) {
        return 'The school was established in 1990 and has a rich history of academic excellence. You can learn more in the about section.';
      } else if (lowerMessage.contains('facility')) {
        return 'School facilities include modern classrooms, laboratories, sports fields, and a library. Details are available in the facilities section.';
      }
      return 'General information about the school is available in the about section. You can find details about history, facilities, and achievements.';
    }

    // Default response for unknown queries
    return 'I understand you\'re asking about "$message". Could you please provide more details so I can better assist you?';
  }
}
