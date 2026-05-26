import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String cdnBaseUrl = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/assets/images/';
  
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
