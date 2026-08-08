import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/models/product.dart';

/// Shared AI product identification logic used by both the in-app ScanScreen
/// and the floating overlay scanner.
class AiScanService {
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // Vision-capable. meta-llama/llama-4-scout-17b-16e-instruct was decommissioned
  // by Groq and now 404s; qwen3.6 is the vision model available on this account.
  static const _groqModel = 'qwen/qwen3.6-27b';

  // PHP proxy on the OpenCart server — used as fallback when
  // api.groq.com DNS fails on certain Myanmar mobile networks.
  static const _proxyUrl = 'https://tachatnhate.xo.je/ai-proxy.php';

  static const _promptHeader =
      'You are a fashion AI assistant for Ta Chat Nhate, a Myanmar clothing app.\n'
      'Analyze the clothing item visible in this image. The photo may be taken in Myanmar.\n'
      'You understand both English and Burmese (မြန်မာဘာသာ) clothing terms.\n\n'
      'Step 1 — Describe what you see:\n'
      '  • Clothing type (hoodie, t-shirt, set, dress, jacket, etc.)\n'
      '  • Color(s) — be specific (black, oatmeal/cream, navy, etc.)\n'
      '  • Style (graphic print, plain/minimal, sporty, feminine, streetwear, etc.)\n'
      '  • Key visual details (zipper, skull graphic, logo, embroidery, wide-leg, wrap, etc.)\n'
      '  • Gender presentation (male/menswear, female/womenswear, unisex)\n\n'
      'Step 2 — Match against the catalog below using the visual description and tags.\n'
      'Focus on: clothing TYPE first → COLOR second → STYLE/DETAILS third.\n'
      'A match is valid even if not identical — similar style counts.\n\n'
      'Available products:\n';

  static const _promptFooter =
      '\n\nStep 3 — Return ONLY valid JSON (no markdown, no extra text):\n'
      '{"matched_product_ids": ["id1", "id2", "id3"], "item_type": "brief description"}\n\n'
      'Rules:\n'
      '- Include 1 to 4 IDs ranked best match first.\n'
      '- Only include a product if it genuinely resembles the scanned item.\n'
      '- Return matched_product_ids as [] if nothing is similar.\n'
      '- Do NOT invent IDs — only use IDs from the list above.';

  /// Identifies up to 4 similar products from the catalog.
  /// Tries Groq directly first, falls back to the PHP proxy on DNS failure.
  static Future<List<Product>> identifyProducts(Uint8List imageBytes) async {
    final productsContext = _buildProductsContext();

    // Try Groq directly first
    try {
      return await _callGroqDirect(imageBytes, productsContext);
    } catch (directErr) {
      debugPrint('AiScanService: direct Groq failed ($directErr) — trying proxy');
    }

    // Fallback: PHP proxy on OpenCart server (bypasses Myanmar DNS block)
    return await _callViaProxy(imageBytes, productsContext);
  }

  // ── Catalog context ──────────────────────────────────────────────────────

  // The Groq free tier caps this account at 8000 tokens per minute, and the
  // scanned image alone costs ~1300. Sending the whole catalog verbatim blew
  // past that ("Request too large ... Requested 13330"), so each entry is kept
  // terse and the list is capped to a character budget (~4 chars per token).
  static const _maxCatalogChars = 12000;
  static const _maxDescChars    = 90;

  static String _buildProductsContext() {
    final buffer  = StringBuffer();
    var   used    = 0;
    var   include = 0;
    final all     = ProductRepository.allProducts;

    for (final p in all) {
      var desc = (p.description ?? p.name).replaceAll(RegExp(r'\s+'), ' ').trim();
      if (desc.length > _maxDescChars) {
        desc = '${desc.substring(0, _maxDescChars)}…';
      }
      final tagStr = p.tags.isNotEmpty ? p.tags.take(5).join(', ') : p.category;
      final line   = '- ID: "${p.id}" | ${p.category} | ${p.brand} | $desc | $tagStr';

      if (used + line.length + 1 > _maxCatalogChars) break;
      buffer.writeln(line);
      used += line.length + 1;
      include++;
    }

    if (include < all.length) {
      debugPrint('AiScanService: catalog truncated to $include/${all.length} '
          'products to stay under the token budget');
    }
    return buffer.toString();
  }

  // ── Direct Groq call ─────────────────────────────────────────────────────

  static Future<List<Product>> _callGroqDirect(
      Uint8List imageBytes, String productsContext) async {
    final body = jsonEncode({
      'model': _groqModel,
      'response_format': {'type': 'json_object'},
      // qwen3.6 is a reasoning model. Left on, it can spend the whole completion
      // budget in the reasoning field and return empty content, which Groq then
      // rejects with json_validate_failed. Disabling it also cuts the request
      // from ~5400 to ~1600 tokens, which matters against the 8000 TPM cap.
      'reasoning_effort': 'none',
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
            {
              'type': 'text',
              'text': '$_promptHeader$productsContext$_promptFooter',
            },
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
      // Unlike the text-only chat calls, this uploads a base64 image plus the
      // catalog. On Myanmar mobile uplinks 30s was not enough to finish sending.
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      // Include the body — a bare status code gives nothing to debug with.
      throw Exception(
          'Groq returned ${response.statusCode}: ${response.body}');
    }

    final data    = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['choices'] as List).first['message']['content'] as String;
    return _parseProductIds(content);
  }

  // ── PHP proxy call ───────────────────────────────────────────────────────

  static Future<List<Product>> _callViaProxy(
      Uint8List imageBytes, String productsContext) async {
    final body = jsonEncode({
      'imageBase64':     base64Encode(imageBytes),
      'productsContext': productsContext,
      'promptHeader':    _promptHeader,
      'promptFooter':    _promptFooter,
    });

    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode != 200) {
      throw Exception('Proxy returned ${response.statusCode}');
    }

    // The free host fronts the proxy with a JS anti-bot challenge, which answers
    // 200 with an HTML page. Decoding that as JSON throws an opaque
    // FormatException, so detect it and say what actually happened.
    final raw = response.body.trimLeft();
    if (!raw.startsWith('{') && !raw.startsWith('[')) {
      throw Exception(
          'Proxy did not return JSON (likely an anti-bot/interstitial page)');
    }

    final proxyData = jsonDecode(raw) as Map<String, dynamic>;
    if (proxyData.containsKey('error')) {
      throw Exception('Proxy error: ${proxyData['error']}');
    }

    final content = proxyData['text'] as String? ?? '';
    return _parseProductIds(content);
  }

  // ── Shared result parser ─────────────────────────────────────────────────

  static List<Product> _parseProductIds(String content) {
    var cleaned = content
        // qwen emits a <think>…</think> preamble whenever it is not constrained
        // by response_format; strip it before looking for the payload.
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Fall back to the first {...} block if the model wrapped it in prose.
    if (!cleaned.startsWith('{')) {
      final start = cleaned.indexOf('{');
      final end   = cleaned.lastIndexOf('}');
      if (start == -1 || end <= start) {
        throw const FormatException('No JSON object in model response');
      }
      cleaned = cleaned.substring(start, end + 1);
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final ids  = (json['matched_product_ids'] as List?)?.cast<String>() ?? [];

    return ids
        .map((id) => ProductRepository.getProductById(id))
        .whereType<Product>()
        .toList();
  }
}
