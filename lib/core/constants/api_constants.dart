import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String cdnBaseUrl = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/assets/images/';
  
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get groqApiKey   => dotenv.env['GROQ_API_KEY']   ?? '';

  static String get bodygramOrgId  => dotenv.env['BODYGRAM_ORG_ID']  ?? '';
  static String get bodygramApiKey => dotenv.env['BODYGRAM_API_KEY'] ?? '';
}
