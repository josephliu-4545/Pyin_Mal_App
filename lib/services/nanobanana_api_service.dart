// lib/services/nanobanana_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class NanoBananaApiService {
  // API key loaded securely from .env file
  static String get _apiKey => dotenv.env['NANOBANANA_API_KEY'] ?? '';
  static const String _endpoint =
      'https://api.nanobananaapi.ai/api/v1/nanobanana/generate';

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

  /// Uploads an image to a temporary public image host to get a public URL.
  /// NanoBanana API requires a real public URL, not a base64 string.
  static Future<String?> _uploadToTempStorage(
    Uint8List bytes,
    String name,
  ) async {
    try {
      debugPrint('Uploading $name to temp storage...');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://tmpfiles.org/api/v1/upload'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: '$name.jpg'),
      );

      final response = await request.send();
      final bodyStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(bodyStr);
        final String url = data['data']['url'];
        // tmpfiles.org returns a view page URL. To get the direct image URL, we insert /dl/
        final directUrl = url.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
        debugPrint('✅ $name uploaded: $directUrl');
        return directUrl;
      } else {
        debugPrint(
          '❗ Failed to upload $name: ${response.statusCode} - $bodyStr',
        );
        return null;
      }
    } catch (e) {
      debugPrint('🚨 Exception uploading $name: $e');
      return null;
    }
  }

  /// Build the payload, upload images to get URLs, and call NanoBanana.
  static Future<String?> generateTryOnImage({
    required XFile userPhoto,
    XFile? shirtPhoto,
    XFile? pantsPhoto,
    XFile? shoesPhoto,
  }) async {
    try {
      // -------------------------------------------------
      // 1️⃣ Compress and upload each image to get public URLs
      // -------------------------------------------------
      final List<String> publicImageUrls = [];

      Future<void> processAndUpload(String name, XFile? file) async {
        if (file == null) return;
        final bytes = await _compressImage(file);
        final publicUrl = await _uploadToTempStorage(bytes, name);
        if (publicUrl != null) {
          publicImageUrls.add(publicUrl);
        }
      }

      await processAndUpload('person', userPhoto);
      await processAndUpload('shirt', shirtPhoto);
      await processAndUpload('pants', pantsPhoto);
      await processAndUpload('shoes', shoesPhoto);

      if (publicImageUrls.isEmpty) {
        debugPrint('❗ Failed to get any public URLs for the images.');
        return null;
      }

      // -------------------------------------------------
      // 2️⃣ Build JSON payload
      // -------------------------------------------------
      final Map<String, dynamic> payload = {
        'prompt':
            'Virtual try-on of these clothes on this person. Create a realistic image.',
        'type': 'IMAGETOIAMGE',
        'numImages': 1,
        'imageUrls': publicImageUrls,
        'callBackUrl': 'https://example.com/webhook', // Dummy URL
      };

      // -------------------------------------------------
      // 3️⃣ Send request to NanoBanana
      // -------------------------------------------------
      debugPrint('Sending request to NanoBanana with URLs: $publicImageUrls');
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('🔁 Generate Response status: ${response.statusCode}');
      debugPrint('🔁 Generate Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

        // -------------------------------------------------
        // 4️⃣ Poll for task completion
        // -------------------------------------------------
        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(seconds: 3));

          final pollResponse = await http.get(
            Uri.parse(
              'https://api.nanobananaapi.ai/api/v1/nanobanana/record-info?taskId=$taskId',
            ),
            headers: {'Authorization': 'Bearer $_apiKey'},
          );

          if (pollResponse.statusCode == 200) {
            final pollData = jsonDecode(pollResponse.body);
            if (pollData['code'] == 200) {
              final status = pollData['data']?['successFlag'];
              // 0: GENERATING, 1: SUCCESS, 2: CREATE_TASK_FAILED, 3: GENERATE_FAILED
              if (status == 1) {
                return pollData['data']['response']?['resultImageUrl'] ??
                    pollData['data']['response']?['originImageUrl'];
              } else if (status == 2 || status == 3) {
                debugPrint(
                  '❗ Task failed: ${pollData['data']?['errorMessage']}',
                );
                return null;
              }
              // If status == 0, continue polling
            }
          }
        }
        debugPrint('❗ Polling timed out.');
        return null;
      } else {
        debugPrint('❗ API error: ${response.statusCode} – ${response.body}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('🚨 Exception in generateTryOnImage: $e');
      debugPrint('Stacktrace: $stack');
      return null;
    }
  }

  /// Build the payload, upload images to get URLs, and call NanoBanana for Hair Style.
  static Future<String?> generateHairStyleImage({
    required XFile userPhoto,
    XFile? referenceHairPhoto,
    String? promptOverride,
  }) async {
    try {
      final List<String> publicImageUrls = [];

      Future<void> processAndUpload(String name, XFile? file) async {
        if (file == null) return;
        final bytes = await _compressImage(file);
        final publicUrl = await _uploadToTempStorage(bytes, name);
        if (publicUrl != null) {
          publicImageUrls.add(publicUrl);
        }
      }

      await processAndUpload('person_hair', userPhoto);
      await processAndUpload('reference_hair', referenceHairPhoto);

      if (publicImageUrls.isEmpty) {
        debugPrint('❗ Failed to get any public URLs for the images.');
        return null;
      }

      final Map<String, dynamic> payload = {
        'prompt': promptOverride ?? 'Virtual hair try-on, replace the person\'s hairstyle with the reference hairstyle or style described, realistic, high quality.',
        'type': 'IMAGETOIAMGE', // Assuming NanoBanana uses this type for hair generation as well
        'numImages': 1,
        'imageUrls': publicImageUrls,
        'callBackUrl': 'https://example.com/webhook',
      };

      debugPrint('Sending request to NanoBanana with URLs: $publicImageUrls');
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('🔁 Generate Response status: ${response.statusCode}');
      debugPrint('🔁 Generate Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

        for (int i = 0; i < 30; i++) {
          await Future.delayed(const Duration(seconds: 3));

          final pollResponse = await http.get(
            Uri.parse(
              'https://api.nanobananaapi.ai/api/v1/nanobanana/record-info?taskId=$taskId',
            ),
            headers: {'Authorization': 'Bearer $_apiKey'},
          );

          if (pollResponse.statusCode == 200) {
            final pollData = jsonDecode(pollResponse.body);
            if (pollData['code'] == 200) {
              final status = pollData['data']?['successFlag'];
              if (status == 1) {
                return pollData['data']['response']?['resultImageUrl'] ??
                    pollData['data']['response']?['originImageUrl'];
              } else if (status == 2 || status == 3) {
                debugPrint(
                  '❗ Task failed: ${pollData['data']?['errorMessage']}',
                );
                return null;
              }
            }
          }
        }
        debugPrint('❗ Polling timed out.');
        return null;
      } else {
        debugPrint('❗ API error: ${response.statusCode} – ${response.body}');
        return null;
      }
    } catch (e, stack) {
      debugPrint('🚨 Exception in generateHairStyleImage: $e');
      debugPrint('Stacktrace: $stack');
      return null;
    }
  }
}
