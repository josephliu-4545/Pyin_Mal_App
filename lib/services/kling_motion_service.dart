// lib/services/kling_motion_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'fal_video_service.dart' show VideoGenStatus;

/// Video-to-video try-on via Kling's official Motion Control API: takes the
/// try-on image (appearance) plus a video the user recorded of themselves
/// moving (motion reference), and generates a video of them wearing the
/// outfit while performing their own recorded movement.
///
/// API shape (docs: kling.ai/document-api → Motion Control 3.0):
///   POST /motion-control/kling-3.0 → { data: { id } }
///   GET  /tasks?task_ids=<id>      → { data: [ { status, outputs: [{url}] } ] }
/// Auth is a single Bearer API key (KLING_API_KEY in .env).
class KlingMotionService {
  static String get _apiKey => dotenv.env['KLING_API_KEY'] ?? '';
  static const String _base = 'https://api-singapore.klingai.com';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  /// Generates a motion-transfer video. Returns the mp4 URL or null.
  /// Kling clears result URLs after 30 days; fine for immediate playback.
  static Future<String?> generateMotionVideo({
    required String imageUrl,
    required String motionVideoUrl,
    void Function(VideoGenStatus status)? onStatus,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('❗ KLING_API_KEY missing from .env');
      onStatus?.call(VideoGenStatus.failed);
      return null;
    }

    onStatus?.call(VideoGenStatus.submitting);

    // 1️⃣ Create the task.
    final String taskId;
    try {
      final submit = await http.post(
        Uri.parse('$_base/motion-control/kling-3.0'),
        headers: _headers,
        body: jsonEncode({
          'contents': [
            {
              'type': 'prompt',
              'text':
                  'The person wears the outfit exactly as shown in the '
                  'reference image while moving. Keep the clothing, face and '
                  'body consistent. Clean background, realistic.',
            },
            {'type': 'image', 'url': imageUrl},
            {'type': 'video', 'url': motionVideoUrl},
          ],
          'settings': {
            // Follow the recorded video's orientation: allows up to 30s of
            // motion and matches "whatever movement the user did".
            'character_orientation': 'video',
            'resolution': '720p', // cheaper units than 1080p
            'audio': 'off',
          },
        }),
      );
      debugPrint('🕺 kling submit status: ${submit.statusCode}');
      final data = jsonDecode(submit.body) as Map<String, dynamic>;
      if (submit.statusCode != 200 || data['code'] != 0) {
        debugPrint('❗ kling submit failed: ${submit.body}');
        onStatus?.call(VideoGenStatus.failed);
        return null;
      }
      taskId = data['data']['id'] as String;
      debugPrint('🕺 kling task created: $taskId');
    } catch (e) {
      debugPrint('🚨 kling submit exception: $e');
      onStatus?.call(VideoGenStatus.failed);
      return null;
    }

    // 2️⃣ Poll (motion control can take several minutes — allow ~15).
    onStatus?.call(VideoGenStatus.queued);
    for (int i = 0; i < 180; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final poll = await http.get(
          Uri.parse('$_base/tasks?task_ids=$taskId'),
          headers: _headers,
        );
        if (poll.statusCode != 200) {
          debugPrint('❗ kling poll HTTP ${poll.statusCode}: ${poll.body}');
          continue;
        }
        final body = jsonDecode(poll.body) as Map<String, dynamic>;
        final tasks = body['data'];
        if (tasks is! List || tasks.isEmpty) continue;
        final task = tasks.first as Map<String, dynamic>;
        final status = task['status'];
        debugPrint('🕺 kling status: $status');

        if (status == 'processing') {
          onStatus?.call(VideoGenStatus.generating);
        } else if (status == 'succeeded') {
          final outputs = task['outputs'];
          if (outputs is List) {
            for (final o in outputs) {
              if (o is Map && o['type'] == 'video' && o['url'] != null) {
                onStatus?.call(VideoGenStatus.done);
                return o['url'] as String;
              }
            }
          }
          debugPrint('❗ kling succeeded but no video output: ${poll.body}');
          onStatus?.call(VideoGenStatus.failed);
          return null;
        } else if (status == 'failed') {
          debugPrint('❗ kling task failed: ${task['message']}');
          onStatus?.call(VideoGenStatus.failed);
          return null;
        }
        // submitted → keep waiting.
      } catch (e) {
        debugPrint('🚨 kling poll exception: $e');
      }
    }
    debugPrint('❗ kling polling timed out');
    onStatus?.call(VideoGenStatus.failed);
    return null;
  }
}
