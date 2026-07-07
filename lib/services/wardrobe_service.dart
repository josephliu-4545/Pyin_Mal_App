import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/models/wardrobe_item.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/image_host_service.dart';

/// Builds a user's digital wardrobe: uploads a photo of an owned item,
/// classifies it with the same Groq vision model used by AiScanService
/// (but freely — no catalog matching), and persists it via [DatabaseService].
class WardrobeService {
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // Same PHP proxy AiScanService falls back to when Groq's DNS is blocked
  // on certain Myanmar mobile networks.
  static const _proxyUrl = 'https://tachatnhate.xo.je/ai-proxy.php';

  static const _promptHeader =
      'You are a fashion AI assistant for Pyin Mal, a Myanmar clothing app.\n'
      'A user is adding a clothing item they own to their digital wardrobe.\n'
      'Analyze the clothing item visible in this image.\n\n';

  static const _promptFooter =
      'Return ONLY valid JSON (no markdown, no extra text):\n'
      '{"category": "top|bottom|shoes|outerwear|dress|accessory", '
      '"color": "brief color description", '
      '"brand": "brand name if a logo/tag is visible, else null", '
      '"tags": ["style/detail tags, up to 5"]}';

  /// Classifies a wardrobe photo. Tries Groq directly first, falls back to
  /// the PHP proxy on DNS failure — same pattern as AiScanService.
  static Future<Map<String, dynamic>> classifyItem(Uint8List imageBytes) async {
    try {
      return await _callGroqDirect(imageBytes);
    } catch (directErr) {
      debugPrint('WardrobeService: direct Groq failed ($directErr) — trying proxy');
    }
    try {
      return await _callViaProxy(imageBytes);
    } catch (proxyErr) {
      debugPrint('WardrobeService: proxy classification failed ($proxyErr)');
      return const {'category': 'other', 'color': null, 'brand': null, 'tags': []};
    }
  }

  static Future<Map<String, dynamic>> _callGroqDirect(Uint8List imageBytes) async {
    final body = jsonEncode({
      'model': _groqModel,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
              },
            },
            {'type': 'text', 'text': '$_promptHeader$_promptFooter'},
          ],
        },
      ],
    });

    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Groq returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['choices'] as List).first['message']['content'] as String;
    return _parseClassification(content);
  }

  static Future<Map<String, dynamic>> _callViaProxy(Uint8List imageBytes) async {
    final body = jsonEncode({
      'imageBase64': base64Encode(imageBytes),
      'productsContext': '',
      'promptHeader': _promptHeader,
      'promptFooter': _promptFooter,
    });

    final response = await http
        .post(Uri.parse(_proxyUrl),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw Exception('Proxy returned ${response.statusCode}');
    }

    final proxyData = jsonDecode(response.body) as Map<String, dynamic>;
    if (proxyData.containsKey('error')) {
      throw Exception('Proxy error: ${proxyData['error']}');
    }
    final content = proxyData['text'] as String? ?? '';
    return _parseClassification(content);
  }

  static Map<String, dynamic> _parseClassification(String content) {
    final cleaned = content
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return {
      'category': json['category'] as String? ?? 'other',
      'color': json['color'] as String?,
      'brand': json['brand'] as String?,
      'tags': List<String>.from(json['tags'] ?? const []),
    };
  }

  /// Uploads [photo], classifies it, and saves it to the current user's
  /// wardrobe. Returns the new wardrobe item, or null on failure.
  static Future<WardrobeItem?> addItem(XFile photo) async {
    final bytes = await ImageHostService.compress(photo);
    final imageUrl = await ImageHostService.upload(bytes, 'wardrobe_item');
    if (imageUrl == null) return null;

    final classification = await classifyItem(bytes);

    final item = WardrobeItem(
      id: '',
      imageUrl: imageUrl,
      category: classification['category'] as String? ?? 'other',
      color: classification['color'] as String?,
      brand: classification['brand'] as String?,
      tags: List<String>.from(classification['tags'] ?? const []),
      source: WardrobeSource.manual,
      addedAt: DateTime.now(),
    );

    final id = await DatabaseService().addWardrobeItem(item);
    if (id == null) return null;
    return WardrobeItem(
      id: id,
      imageUrl: item.imageUrl,
      category: item.category,
      color: item.color,
      brand: item.brand,
      tags: item.tags,
      source: item.source,
      addedAt: item.addedAt,
    );
  }

  /// Adds an item straight from known catalog data (e.g. a purchase) — no AI
  /// roundtrip needed since the category/brand/image are already known.
  static Future<void> addFromCatalog({
    required String imageUrl,
    required String category,
    required String brand,
    required String productId,
    String source = WardrobeSource.purchase,
  }) async {
    await DatabaseService().addWardrobeItem(WardrobeItem(
      id: '',
      imageUrl: imageUrl,
      category: category,
      brand: brand,
      source: source,
      sourceProductId: productId,
      addedAt: DateTime.now(),
    ));
  }
}
