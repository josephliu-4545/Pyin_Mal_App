import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String cdnBaseUrl = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/assets/images/';
  // Repo root on the CDN — used for non-image assets like shop videos
  // (e.g. '${cdnRootUrl}assets/videos/shops/<slug>.mp4').
  static const String cdnRootUrl = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/';
  
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get groqApiKey   => dotenv.env['GROQ_API_KEY']   ?? '';

  // Cloudflare Worker that relays Gemini calls (Gemini is geoblocked in
  // Myanmar; the Worker is reachable there and forwards the request).
  static String get aiRelayUrl   => dotenv.env['AI_RELAY_URL']   ?? '';

  static String get bodygramOrgId  => dotenv.env['BODYGRAM_ORG_ID']  ?? '';
  static String get bodygramApiKey => dotenv.env['BODYGRAM_API_KEY'] ?? '';
}
