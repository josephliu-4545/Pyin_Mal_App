// lib/services/nanobanana_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Virtual try-on / hair-style generation backed by NanoBanana.
///
/// Images are uploaded to catbox.moe (a free, no-account image host that
/// returns a public URL) because NanoBanana requires a real URL, not base64.
/// The previous host (corsproxy.io → uguu.se) is dead: corsproxy now returns
/// 403 "server-side requests not allowed on your plan" and uguu.se is offline.
class NanoBananaApiService {
  // API key loaded securely from .env file
  static String get _apiKey => dotenv.env['NANOBANANA_API_KEY'] ?? '';
  static const String _endpoint =
      'https://api.nanobananaapi.ai/api/v1/nanobanana/generate';
  static const String _recordInfo =
      'https://api.nanobananaapi.ai/api/v1/nanobanana/record-info';

  static const String _catboxUrl = 'https://catbox.moe/user/api.php';

  /// Compress an XFile to a smaller JPEG.
  static Future<Uint8List> _compressImage(
    XFile file, {
    int maxWidth = 500,
    int maxHeight = 500,
    int quality = 50,
  }) async {
    final raw = await file.readAsBytes();

    // If the file is already tiny, return it unchanged.
    if (raw.lengthInBytes <= 100 * 1024) return raw;

    // Web platform can use the compressor directly.
    if (kIsWeb) {
      return await FlutterImageCompress.compressWithList(
        raw,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    }

    // Windows currently has no native implementation – fall back to raw.
    if (Platform.isWindows) return raw;

    // Android / iOS / macOS – compress.
    return await FlutterImageCompress.compressWithList(
      raw,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
      format: CompressFormat.jpeg,
    );
  }

  // ── Image upload (catbox.moe) ───────────────────────────────────────────────

  /// Uploads an image to catbox.moe and returns its public URL, or null on
  /// failure. catbox returns the URL as a plain-text body.
  static Future<String?> _uploadToTempStorage(
    Uint8List bytes,
    String name,
  ) async {
    try {
      debugPrint('Uploading $name to catbox.moe...');
      final request = http.MultipartRequest('POST', Uri.parse(_catboxUrl))
        ..fields['reqtype'] = 'fileupload'
        ..files.add(
          http.MultipartFile.fromBytes('fileToUpload', bytes,
              filename: '$name.jpg'),
        );

      final response = await http.Response.fromStream(await request.send());
      final body = response.body.trim();

      if (response.statusCode == 200 && body.startsWith('https://')) {
        debugPrint('✅ $name uploaded: $body');
        return body;
      }
      debugPrint('❗ Failed to upload $name: ${response.statusCode} - $body');
      return null;
    } catch (e) {
      debugPrint('🚨 Exception uploading $name: $e');
      return null;
    }
  }

  // ── Generation requests ─────────────────────────────────────────────────────

  /// Starts a generation task. Returns the decoded NanoBanana response, or null
  /// on a network/HTTP failure.
  static Future<Map<String, dynamic>?> _startGeneration(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      debugPrint('🔁 Generate status: ${response.statusCode}');
      return _decode(response.statusCode, response.body);
    } catch (e) {
      debugPrint('🚨 NanoBanana generate failed ($e)');
      return null;
    }
  }

  /// Polls a task by id. Returns the decoded response, or null on failure.
  static Future<Map<String, dynamic>?> _pollTask(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$_recordInfo?taskId=$taskId'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      return _decode(response.statusCode, response.body);
    } catch (e) {
      debugPrint('🚨 NanoBanana poll failed ($e)');
      return null;
    }
  }

  static Map<String, dynamic>? _decode(int statusCode, String body) {
    if (statusCode != 200) {
      debugPrint('❗ API error: $statusCode – $body');
      return null;
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  // ── Shared generation flow ──────────────────────────────────────────────────

  /// Uploads the supplied images, starts a generation task, and polls until it
  /// finishes. Returns the result image URL, or null on any failure.
  /// [images] is keyed by upload name (insertion order is preserved).
  static Future<String?> _runGeneration({
    required Map<String, XFile?> images,
    required String prompt,
  }) async {
    try {
      // 1️⃣ Compress and upload each image to get public URLs.
      final List<String> publicImageUrls = [];
      for (final entry in images.entries) {
        if (entry.value == null) continue;
        final bytes = await _compressImage(entry.value!);
        final url = await _uploadToTempStorage(bytes, entry.key);
        if (url != null) publicImageUrls.add(url);
      }

      if (publicImageUrls.isEmpty) {
        debugPrint('❗ Failed to get any public URLs for the images.');
        return null;
      }

      // 2️⃣ Start the generation task.
      final payload = <String, dynamic>{
        'prompt': prompt,
        'type': 'IMAGETOIAMGE',
        'numImages': 1,
        'imageUrls': publicImageUrls,
        'callBackUrl': 'https://example.com/webhook', // Dummy URL
      };

      debugPrint('Sending request to NanoBanana with URLs: $publicImageUrls');
      final data = await _startGeneration(payload);
      if (data == null) return null;
      if (data['code'] != 200) {
        debugPrint('❗ API error message: ${data['msg']}');
        return null;
      }

      final taskId = data['data']?['taskId'];
      if (taskId == null) {
        debugPrint('❗ No taskId returned.');
        return null;
      }
      debugPrint('✅ Task created: $taskId. Polling for results...');

      // 3️⃣ Poll for task completion.
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 3));

        final pollData = await _pollTask(taskId.toString());
        if (pollData != null && pollData['code'] == 200) {
          final status = pollData['data']?['successFlag'];
          // 0: GENERATING, 1: SUCCESS, 2: CREATE_TASK_FAILED, 3: GENERATE_FAILED
          if (status == 1) {
            return pollData['data']['response']?['resultImageUrl'] ??
                pollData['data']['response']?['originImageUrl'];
          } else if (status == 2 || status == 3) {
            debugPrint('❗ Task failed: ${pollData['data']?['errorMessage']}');
            return null;
          }
          // If status == 0, continue polling.
        }
      }
      debugPrint('❗ Polling timed out.');
      return null;
    } catch (e, stack) {
      debugPrint('🚨 Exception in _runGeneration: $e');
      debugPrint('Stacktrace: $stack');
      return null;
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Virtual clothing try-on.
  static Future<String?> generateTryOnImage({
    required XFile userPhoto,
    XFile? shirtPhoto,
    XFile? pantsPhoto,
    XFile? shoesPhoto,
  }) {
    return _runGeneration(
      images: {
        'person': userPhoto,
        'shirt': shirtPhoto,
        'pants': pantsPhoto,
        'shoes': shoesPhoto,
      },
      prompt:
          'Virtual try-on of these clothes on this person. Create a realistic image.',
    );
  }

  /// Virtual hair-style try-on.
  static Future<String?> generateHairStyleImage({
    required XFile userPhoto,
    XFile? referenceHairPhoto,
    String? promptOverride,
  }) {
    return _runGeneration(
      images: {
        'person_hair': userPhoto,
        'reference_hair': referenceHairPhoto,
      },
      prompt: promptOverride ??
          'Virtual hair try-on, replace the person\'s hairstyle with the reference hairstyle or style described, realistic, high quality.',
    );
  }
}
