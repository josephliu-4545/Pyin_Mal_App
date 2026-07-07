// lib/services/image_host_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

/// Shared image hosting for any feature that needs a public URL for a user
/// photo (NanoBanana try-on, digital wardrobe, OOTD posts). catbox.moe is
/// used because it's free, requires no account, and — unlike Firebase
/// Storage, which isn't set up in this project — is reliably reachable from
/// Myanmar networks.
class ImageHostService {
  static const String _catboxUrl = 'https://catbox.moe/user/api.php';

  /// Compress an XFile to a smaller JPEG.
  static Future<Uint8List> compress(
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

  /// Uploads an image to catbox.moe and returns its public URL, or null on
  /// failure. catbox returns the URL as a plain-text body.
  static Future<String?> upload(Uint8List bytes, String name) async {
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
}
