// lib/services/bodygram_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';

class BodygramException implements Exception {
  final String message;
  BodygramException(this.message);
  @override
  String toString() => message;
}

/// Bodygram Platform API — body measurements from two photos (front + right
/// side) plus height/weight/age/gender, or a stats-only estimation.
/// Docs: https://docs.bodygram.com/platform
class BodygramService {
  static String get _orgId => ApiConstants.bodygramOrgId;
  static String get _apiKey => ApiConstants.bodygramApiKey;

  static Uri get _scansUri =>
      Uri.parse('https://platform.bodygram.com/api/orgs/$_orgId/scans');

  /// False until BODYGRAM_ORG_ID / BODYGRAM_API_KEY are set in .env.
  static bool get isConfigured => _orgId.isNotEmpty && _apiKey.isNotEmpty;

  /// Full photo scan. [gender] must be 'male' or 'female' (Bodygram only
  /// accepts these two). Photos must be JPEG bytes, subject standing upright,
  /// full body in frame.
  static Future<BodyMeasurements> photoScan({
    required int age,
    required String gender,
    required int heightCm,
    required double weightKg,
    required Uint8List frontPhotoJpeg,
    required Uint8List rightPhotoJpeg,
  }) async {
    // Bodygram only accepts portrait JPEGs between 720x1280 and 1080x1920.
    final front = await compute(_normalizePhoto, frontPhotoJpeg);
    final right = await compute(_normalizePhoto, rightPhotoJpeg);
    return _createScan({
      'photoScan': {
        'age': age,
        'gender': gender,
        'height': heightCm * 10, // Bodygram wants mm
        'weight': (weightKg * 1000).round(), // and grams
        'frontPhoto': base64Encode(front),
        'rightPhoto': base64Encode(right),
      },
    }, source: 'photoScan');
  }

  /// Translate Bodygram failure codes (frontPhotoNotInFrame,
  /// rightPhotoLeftArmAngle, ...) into instructions the user can act on.
  static String _friendlyError(String code) {
    final photo = code.startsWith('rightPhoto')
        ? 'bodygram.err_right_photo'.tr()
        : 'bodygram.err_front_photo'.tr();
    if (code.contains('NotInFrame')) {
      return '$photo${'bodygram.err_not_in_frame'.tr()}';
    }
    if (code.contains('ArmAngle')) {
      return '$photo${'bodygram.err_arm_angle'.tr()}';
    }
    if (code.contains('Leg') || code.contains('Foot') || code.contains('Feet')) {
      return '$photo${'bodygram.err_leg_angle'.tr()}';
    }
    return 'bodygram.err_generic'.tr(args: [code.isEmpty ? 'unknown' : code]);
  }

  /// Bodygram requires exactly 9:16 portrait, 720x1280–1080x1920.
  /// Center-crop to 9:16 and resize to 1080x1920.
  /// Runs in a background isolate via [compute].
  static Uint8List _normalizePhoto(Uint8List bytes) {
    var im = img.decodeImage(bytes);
    if (im == null) {
      throw BodygramException('Could not read the photo.');
    }
    im = img.bakeOrientation(im); // apply EXIF rotation
    if (im.width > im.height) {
      // Landscape: rotate so the standing body stays upright.
      im = img.copyRotate(im, angle: 90);
    }
    const tw = 1080, th = 1920;
    const targetAspect = tw / th;
    final aspect = im.width / im.height;
    if (aspect > targetAspect) {
      final cw = (im.height * targetAspect).round();
      im = img.copyCrop(im,
          x: (im.width - cw) ~/ 2, y: 0, width: cw, height: im.height);
    } else if (aspect < targetAspect) {
      final ch = (im.width / targetAspect).round();
      im = img.copyCrop(im,
          x: 0, y: (im.height - ch) ~/ 2, width: im.width, height: ch);
    }
    im = img.copyResize(im, width: tw, height: th);
    return Uint8List.fromList(img.encodeJpg(im, quality: 90));
  }

  /// Statistical estimation from demographics alone — no photos. Less
  /// accurate, but instant and works as a fallback.
  static Future<BodyMeasurements> statsEstimation({
    required int age,
    required String gender,
    required int heightCm,
    required double weightKg,
  }) {
    return _createScan({
      'statsEstimations': {
        'age': age,
        'gender': gender,
        'height': heightCm * 10,
        'weight': (weightKg * 1000).round(),
      },
    }, source: 'statsEstimation');
  }

  static Future<BodyMeasurements> _createScan(
    Map<String, dynamic> body, {
    required String source,
  }) async {
    if (!isConfigured) {
      throw BodygramException(
          'Bodygram is not configured. Add BODYGRAM_ORG_ID and BODYGRAM_API_KEY to .env');
    }

    final http.Response res;
    try {
      res = await http
          .post(
            _scansUri,
            headers: {
              'Authorization': _apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } catch (e) {
      debugPrint('Bodygram request failed: $e');
      throw BodygramException('Could not reach Bodygram. Check your connection.');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw BodygramException('Bodygram rejected the API key (HTTP ${res.statusCode}).');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('Bodygram HTTP ${res.statusCode}: ${res.body}');
      throw BodygramException('Bodygram error (HTTP ${res.statusCode}).');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final entry = json['entry'] as Map<String, dynamic>?;
    if (entry == null || entry['status'] != 'success') {
      debugPrint('Bodygram scan failed: ${res.body}');
      final code =
          ((entry?['error'] as Map<String, dynamic>?)?['code'] as String?) ?? '';
      throw BodygramException(_friendlyError(code));
    }

    final valuesMm = <String, double>{};
    for (final m in (entry['measurements'] as List? ?? const [])) {
      final name = m['name'] as String?;
      final value = m['value'] as num?;
      if (name != null && value != null && m['unit'] == 'mm') {
        valuesMm[name] = value.toDouble();
      }
    }
    if (valuesMm.isEmpty) {
      throw BodygramException('Bodygram returned no measurements.');
    }

    return BodyMeasurements(
      scanId: entry['id'] as String? ?? '',
      source: source,
      valuesMm: valuesMm,
      measuredAt: DateTime.now(),
    );
  }
}
