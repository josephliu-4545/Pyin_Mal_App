// lib/services/fal_video_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Progress states surfaced to the UI while a video generates.
enum FalVideoStatus { submitting, queued, generating, done, failed }

/// Image-to-video generation via fal.ai's queue API (Wan 2.5).
///
/// Takes the public URL of a try-on image (the NanoBanana result URL works
/// directly — it is already public) and returns the URL of a short video of
/// that person turning 360°. Uses the queue endpoints so the app can poll
/// instead of holding one long HTTP request open (~1-3 min generations).
class FalVideoService {
  static String get _apiKey => dotenv.env['FAL_API_KEY'] ?? '';

  /// Wan 2.5 preview: cheapest solid image-to-video on fal (~$0.05/s at 720p).
  static const String _model = 'fal-ai/wan-25-preview/image-to-video';
  static const String _queueBase = 'https://queue.fal.run';

  static const String _turnaroundPrompt =
      'The person slowly rotates a full 360 degrees in place, turning at a '
      'steady speed to show the outfit from every angle. The camera stays '
      'completely fixed. Clothing moves naturally with the body. Studio '
      'lighting, plain background, photorealistic.';

  static Map<String, String> get _headers => {
        'Authorization': 'Key $_apiKey',
        'Content-Type': 'application/json',
      };

  /// Generates a 360° turnaround video from [imageUrl].
  ///
  /// Reports progress via [onStatus] and returns the mp4 URL, or null on any
  /// failure (details are debug-logged).
  static Future<String?> generateTurnaroundVideo({
    required String imageUrl,
    void Function(FalVideoStatus status)? onStatus,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('❗ FAL_API_KEY missing from .env');
      onStatus?.call(FalVideoStatus.failed);
      return null;
    }

    onStatus?.call(FalVideoStatus.submitting);

    // 1️⃣ Submit to the queue.
    final String statusUrl;
    final String responseUrl;
    try {
      final submit = await http.post(
        Uri.parse('$_queueBase/$_model'),
        headers: _headers,
        body: jsonEncode({
          'prompt': _turnaroundPrompt,
          'image_url': imageUrl,
          'resolution': '720p', // 1080p costs ~2x and adds little on a phone
          'duration': '5',
        }),
      );
      debugPrint('🎬 fal submit status: ${submit.statusCode}');
      if (submit.statusCode != 200) {
        debugPrint('❗ fal submit failed: ${submit.body}');
        onStatus?.call(FalVideoStatus.failed);
        return null;
      }
      final data = jsonDecode(submit.body) as Map<String, dynamic>;
      // fal returns ready-made polling URLs — use them verbatim rather than
      // reconstructing paths, so endpoint layout changes can't break us.
      statusUrl = data['status_url'] as String;
      responseUrl = data['response_url'] as String;
    } catch (e) {
      debugPrint('🚨 fal submit exception: $e');
      onStatus?.call(FalVideoStatus.failed);
      return null;
    }

    // 2️⃣ Poll until the queue reports COMPLETED (up to ~5 min).
    onStatus?.call(FalVideoStatus.queued);
    for (int i = 0; i < 100; i++) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final poll = await http.get(Uri.parse(statusUrl), headers: _headers);
        if (poll.statusCode != 200 && poll.statusCode != 202) {
          debugPrint('❗ fal poll HTTP ${poll.statusCode}: ${poll.body}');
          continue; // transient — keep polling
        }
        final status =
            (jsonDecode(poll.body) as Map<String, dynamic>)['status'];
        debugPrint('🎬 fal status: $status');
        if (status == 'IN_PROGRESS') {
          onStatus?.call(FalVideoStatus.generating);
        } else if (status == 'COMPLETED') {
          return _fetchResult(responseUrl, onStatus);
        }
        // IN_QUEUE → keep waiting.
      } catch (e) {
        debugPrint('🚨 fal poll exception: $e'); // transient — keep polling
      }
    }
    debugPrint('❗ fal polling timed out');
    onStatus?.call(FalVideoStatus.failed);
    return null;
  }

  static Future<String?> _fetchResult(
    String responseUrl,
    void Function(FalVideoStatus status)? onStatus,
  ) async {
    try {
      final res = await http.get(Uri.parse(responseUrl), headers: _headers);
      if (res.statusCode != 200) {
        debugPrint('❗ fal result HTTP ${res.statusCode}: ${res.body}');
        onStatus?.call(FalVideoStatus.failed);
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      // REST responses put the payload at the top level; the JS SDK nests it
      // under `data`. Accept both.
      final video = (data['video'] ?? data['data']?['video']);
      final url = video is Map ? video['url'] as String? : null;
      if (url == null) {
        debugPrint('❗ fal result missing video url: ${res.body}');
        onStatus?.call(FalVideoStatus.failed);
        return null;
      }
      onStatus?.call(FalVideoStatus.done);
      return url;
    } catch (e) {
      debugPrint('🚨 fal result exception: $e');
      onStatus?.call(FalVideoStatus.failed);
      return null;
    }
  }
}
