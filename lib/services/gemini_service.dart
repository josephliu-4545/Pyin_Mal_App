import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/database_service.dart';

/// AI stylist chat backed by Gemini.
///
/// Gemini's API is geoblocked in Myanmar (it returns HTTP 400 "user location is
/// not supported"), so the app calls a Cloudflare Worker relay
/// (see cloudflare-worker/ai-relay.js) which forwards the request to Gemini
/// from outside Myanmar. A direct Gemini call is kept only as a fallback for
/// development/testing on networks where Gemini is reachable.
class GeminiService {
  static const _model = 'gemini-2.5-flash';

  static String get _directUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model'
      ':generateContent?key=${ApiConstants.geminiApiKey}';

  final DatabaseService _db = DatabaseService();

  /// Conversation history in Gemini REST shape:
  /// `{ "role": "user"|"model", "parts": [ { "text": ... } ] }`.
  final List<Map<String, dynamic>> _history = [];

  /// Sends a message to Gemini and returns the AI's response as an AiMessage.
  Future<AiMessage> sendMessage(String text) async {
    // 1. Live per-request context: survey prefs, recent purchases/views/searches.
    final userContext = await _db.getRecentHistoryContext();

    // 1b. Catalog the model is allowed to recommend from.
    final productsContext = ProductRepository.allProducts.map((p) {
      return '- ${p.name} (ID: ${p.id}, Category: ${p.category}, Price: ${p.price})';
    }).join('\n');

    final systemInstruction = '''
You are an expert personal stylist and shopping assistant for the 'Pyin Mal' fashion app.
Your job is to help users find the perfect outfits, provide fashion advice, and recommend specific items from our catalog.

Here are the available products you can recommend:
$productsContext

$userContext

You MUST output your response in valid JSON format.
The JSON must have this exact structure:
{
  "message": "Your conversational text response here.",
  "recommended_product_ids": ["id1", "id2"] // Only include IDs of products you genuinely recommend based on the user's query and their history. Empty list if none.
}
''';

    // Add the user's turn to history before sending.
    _history.add({
      'role': 'user',
      'parts': [
        {'text': text}
      ],
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ],
      },
      'contents': _history,
      'generationConfig': {'responseMimeType': 'application/json'},
    };

    final String? responseText = await _generate(requestBody);

    if (responseText == null) {
      // Drop the user turn so a retry doesn't replay a dangling message.
      _history.removeLast();
      return AiMessage(
        text: "I'm a bit busy right now 😅 Please wait a moment and try again!",
        isUser: false,
      );
    }

    // Record the model's turn so the conversation stays coherent.
    _history.add({
      'role': 'model',
      'parts': [
        {'text': responseText}
      ],
    });

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(responseText);
      final String message = jsonMap['message'] ?? '...';
      final List<dynamic> productIds = jsonMap['recommended_product_ids'] ?? [];

      final List<Product> recommendedProducts = [];
      for (final id in productIds) {
        final product = ProductRepository.getProductById(id.toString());
        if (product != null) recommendedProducts.add(product);
      }

      return AiMessage(
        text: message,
        isUser: false,
        recommendedProducts: recommendedProducts,
      );
    } catch (e) {
      debugPrint('🔴 Gemini JSON parse error: $e');
      return AiMessage(
        text: "I'm sorry, I couldn't process that. Could you try again?",
        isUser: false,
      );
    }
  }

  /// Returns the model's response text. Calls the Cloudflare Worker relay first
  /// (works in Myanmar); falls back to a direct Gemini call for dev/testing on
  /// networks where Gemini is reachable. Returns null if both fail.
  Future<String?> _generate(Map<String, dynamic> requestBody) async {
    final relayUrl = ApiConstants.aiRelayUrl;

    if (relayUrl.isNotEmpty) {
      try {
        return await _callRelay(relayUrl, requestBody);
      } catch (relayErr) {
        debugPrint('GeminiService: relay failed ($relayErr) — trying direct');
      }
    } else {
      debugPrint('GeminiService: AI_RELAY_URL not set — calling Gemini directly '
          '(will fail in Myanmar; configure the Cloudflare Worker)');
    }

    try {
      return await _callDirect(requestBody);
    } catch (directErr) {
      debugPrint('GeminiService: direct call failed ($directErr)');
      return null;
    }
  }

  // ── Cloudflare Worker relay ────────────────────────────────────────────────

  Future<String?> _callRelay(
      String relayUrl, Map<String, dynamic> requestBody) async {
    final response = await _postWithRetry(
      Uri.parse(relayUrl),
      jsonEncode({'model': _model, 'body': requestBody}),
    );
    return _extractText(jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Direct Gemini call (dev fallback) ──────────────────────────────────────

  Future<String?> _callDirect(Map<String, dynamic> requestBody) async {
    final response =
        await _postWithRetry(Uri.parse(_directUrl), jsonEncode(requestBody));
    return _extractText(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// POSTs JSON, retrying once on 429/503. Throws on a non-200 result so the
  /// caller can fall through to the next path.
  Future<http.Response> _postWithRetry(Uri url, String body) async {
    const maxRetries = 2;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return response;

      if ((response.statusCode == 429 || response.statusCode == 503) &&
          attempt < maxRetries - 1) {
        await Future.delayed(const Duration(seconds: 15));
        continue;
      }

      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    throw Exception('Retries exhausted');
  }

  /// Pulls the response text out of a Gemini generateContent payload.
  String? _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;
    return parts.first['text'] as String?;
  }
}
