// lib/services/image_host_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

/// Shared image hosting for any feature that needs a public URL for a user
/// photo (NanoBanana try-on, digital wardrobe, OOTD posts). Every host must
/// return a *direct* image URL (not a viewer page) so remote services like
/// NanoBanana can fetch the bytes.
///
/// Uploads try several independent hosts in order and return the first URL
/// that succeeds. This guards against any single host disappearing — which is
/// exactly how try-on broke before: catbox.moe (the sole host) went
/// permanently offline and every upload timed out, so no public URL could ever
/// be obtained. The hosts sit on different infrastructure on purpose, so a
/// network that blocks one may still allow another.
class ImageHostService {
  /// Per-host request timeout. A dead host must fail fast so the chain can move
  /// on instead of hanging the whole try-on (catbox used to hang ~20s+ each).
  static const Duration _hostTimeout = Duration(seconds: 30);

  /// Public/demo API key for freeimage.host. Override with your own free key
  /// (from freeimage.host) by setting IMAGE_HOST_API_KEY in .env.
  static String get _freeimageKey =>
      dotenv.env['IMAGE_HOST_API_KEY']?.isNotEmpty == true
          ? dotenv.env['IMAGE_HOST_API_KEY']!
          : '6d207e02198a847aa98d0a2a901485a5';

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

  /// An uploader takes the image bytes + a name and returns a direct public
  /// URL, or null if that host declined/failed.
  ///
  /// imgbb is first because it's the only host that sends CORS headers
  /// (`Access-Control-Allow-Origin: *`), so it's the ONLY one that works when
  /// the app runs on Flutter Web — a browser blocks freeimage.host/pixhost with
  /// "Failed to fetch". imgbb needs a free key (IMGBB_API_KEY); without it, it's
  /// skipped and the native-only hosts are used (fine on Android/iOS/desktop).
  static final List<({String name, _Uploader upload})> _hosts = [
    // Own Cloudflare relay first: works everywhere (CORS *) and from any
    // region. Skipped automatically when AI_RELAY_URL isn't configured.
    (name: 'relay', upload: _uploadViaRelay),
    (name: 'imgbb', upload: _uploadImgbb), // skipped unless IMGBB_API_KEY set
    (name: 'tmpfiles.org', upload: _uploadTmpfiles), // keyless + CORS-open (web OK)
    (name: 'freeimage.host', upload: _uploadFreeimage),
    (name: 'pixhost', upload: _uploadPixhost),
  ];

  /// Uploads an image and returns a direct public URL, trying each host in
  /// turn until one succeeds. Returns null only if every host fails.
  static Future<String?> upload(Uint8List bytes, String name) async {
    for (final host in _hosts) {
      try {
        final url = await host.upload(bytes, name).timeout(_hostTimeout);
        if (url != null && url.startsWith('https://')) {
          debugPrint('✅ $name uploaded via ${host.name}: $url');
          return url;
        }
        debugPrint('↪️ ${host.name} declined $name, trying next host...');
      } catch (e) {
        debugPrint('🚨 ${host.name} failed for $name ($e), trying next host...');
      }
    }
    debugPrint('❗ All image hosts failed for $name.');
    return null;
  }

  // ── Individual hosts ────────────────────────────────────────────────────────

  /// Own Cloudflare Worker relay (cloudflare-worker/ai-relay.js): forwards the
  /// base64 image to freeimage.host from Cloudflare's edge. This is the only
  /// path that works on Flutter Web from networks where the public hosts are
  /// CORS-blocked or IP-banned. Skipped when AI_RELAY_URL isn't configured.
  static Future<String?> _uploadViaRelay(Uint8List bytes, String name) async {
    final relay = dotenv.env['AI_RELAY_URL'] ?? '';
    if (relay.isEmpty || relay.contains('your-subdomain')) return null;
    final response = await http.post(
      Uri.parse(relay),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'upload': true,
        'name': name,
        'image': base64Encode(bytes),
      }),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String?;
  }

  /// freeimage.host (Chevereto API): base64 in a form field, JSON back, direct
  /// URL at `image.url` (served from the iili.io CDN).
  static Future<String?> _uploadFreeimage(Uint8List bytes, String name) async {
    final response = await http.post(
      Uri.parse('https://freeimage.host/api/1/upload'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'key': _freeimageKey,
        'format': 'json',
        'source': base64Encode(bytes),
      },
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['image']?['url'] as String?;
  }

  /// imgbb: only attempted when IMGBB_API_KEY is set in .env (it needs a free
  /// account key). base64 image field, direct URL at `data.url`.
  static Future<String?> _uploadImgbb(Uint8List bytes, String name) async {
    final key = dotenv.env['IMGBB_API_KEY'];
    if (key == null || key.isEmpty) return null; // not configured → skip
    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload?key=$key'),
      body: {'image': base64Encode(bytes)},
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['data']?['url'] as String?;
  }

  /// tmpfiles.org: keyless multipart upload with permissive CORS, so it works
  /// from Flutter Web where freeimage.host/pixhost are blocked by the browser.
  /// Files live for 60 minutes — plenty for NanoBanana to fetch them.
  /// The API returns a viewer URL (`https://tmpfiles.org/123/x.jpg`); the
  /// direct image URL inserts `/dl/` after the host.
  static Future<String?> _uploadTmpfiles(Uint8List bytes, String name) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://tmpfiles.org/api/v1/upload'),
    )..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: '$name.jpg'));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final viewer = data['data']?['url'] as String?;
    if (viewer == null) return null;
    return viewer
        .replaceFirst('http://', 'https://')
        .replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
  }

  /// pixhost: multipart upload. The API returns only a viewer `show_url` and a
  /// thumbnail `th_url`; the direct full-size image is derived from `th_url` by
  /// mapping the `tN.pixhost.to/thumbs/...` host/path to `imgN.pixhost.to/images/...`.
  static Future<String?> _uploadPixhost(Uint8List bytes, String name) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.pixhost.to/images'),
    )
      ..fields['content_type'] = '0'
      ..files.add(http.MultipartFile.fromBytes('img', bytes,
          filename: '$name.jpg'));

    final response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final thumb = data['th_url'] as String?;
    if (thumb == null) return null;
    return thumb
        .replaceFirst('https://t', 'https://img')
        .replaceFirst('/thumbs/', '/images/');
  }
}

typedef _Uploader = Future<String?> Function(Uint8List bytes, String name);
