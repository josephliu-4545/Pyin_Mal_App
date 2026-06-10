// lib/services/bodygram_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
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
  }) {
    return _createScan({
      'photoScan': {
        'age': age,
        'gender': gender,
        'height': heightCm * 10, // Bodygram wants mm
        'weight': (weightKg * 1000).round(), // and grams
        'frontPhoto': base64Encode(frontPhotoJpeg),
        'rightPhoto': base64Encode(rightPhotoJpeg),
      },
    }, source: 'photoScan');
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
      throw BodygramException(
          'Scan failed — make sure your full body is visible in both photos.');
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
