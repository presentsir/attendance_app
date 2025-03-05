import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  // Replace this with your Gemini API key when you get one
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  // Replace this with your Hugging Face API key
  static String get huggingFaceApiKey =>
      dotenv.env['HUGGING_FACE_API_KEY'] ?? '';
}
