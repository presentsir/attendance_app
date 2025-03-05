import 'package:flutter/material.dart';
import '../services/mintlify_service.dart';

class AIChatScreen extends StatefulWidget {
  final String classId;
  final Map<String, dynamic> attendanceStats;
  final DateTime startDate;
  final DateTime endDate;

  const AIChatScreen({
    Key? key,
    required this.classId,
    required this.attendanceStats,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialInsights();
  }

  Future<void> _loadInitialInsights() async {
    setState(() => _isLoading = true);
    try {
      final insights = await MintlifyService.getAttendanceInsights(
        classId: widget.classId,
        startDate: widget.startDate,
        endDate: widget.endDate,
        attendanceStats: widget.attendanceStats,
      );

      print('Received insights: $insights'); // Debug print

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': insights['choices']?[0]?['message']?['content'] ??
                    'Unable to generate insights at the moment. Please try again.',
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadInitialInsights: $e'); // Debug print
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading insights: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });

    _messageController.clear();

    try {
      final response = await MintlifyService.getChatResponse(userMessage);
      print('Received chat response: $response');

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response['message'] ?? 'Unable to generate response at the moment. Please try again.',
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _sendMessage: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting response: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Attendance Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message['content']),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about attendance...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}