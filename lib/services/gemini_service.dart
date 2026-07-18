import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/database_service.dart';

/// AI stylist chat — backed by Groq.
///
/// Gemini is geoblocked in Myanmar (HTTP 400 "user location is not supported"),
/// and relaying it through Cloudflare failed too (Myanmar tampers with the
/// workers.dev connection → error 1042). Groq is the one backend confirmed to
/// work on the Myanmar network — it's what the scanner uses. So the chat calls
/// Groq directly with the same GROQ_API_KEY. No geoblock, no relay, no proxy.
///
/// (Class name kept as GeminiService to avoid touching the chat screen.)
class GeminiService {
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.3-70b-versatile';

  final DatabaseService _db = DatabaseService();

  /// Conversation history as Groq/OpenAI chat messages:
  /// `{ "role": "user"|"assistant", "content": ... }`. The system message is
  /// rebuilt per request (it carries live, changing context), so it is not
  /// stored here.
  final List<Map<String, String>> _history = [];

  /// Sends a message to the model and returns the AI's response as an AiMessage.
  Future<AiMessage> sendMessage(String text) async {
    // 1. Live per-request context: survey prefs, recent purchases/views/searches.
    final userContext = await _db.getRecentHistoryContext();

    // 1b. Catalog the model is allowed to recommend from.
    final productsContext = ProductRepository.allProducts.map((p) {
      return '- ${p.name} (ID: ${p.id}, Category: ${p.category}, Price: ${p.price})';
    }).join('\n');

    final systemPrompt = '''
You are an expert personal stylist and shopping assistant for the 'Ta Chat Nhate' fashion app.
Your job is to help users find the perfect outfits, provide fashion advice, and recommend specific items from our catalog.

Here are the available products you can recommend:
$productsContext

$userContext

You MUST output your response in valid JSON format.
The JSON must have this exact structure:
{
  "message": "Your conversational text response here.",
  "recommended_product_ids": ["id1", "id2"]
}
Only include IDs of products you genuinely recommend based on the user's query and their history. Use an empty list if none.''';

    // Add the user's turn to history before sending.
    _history.add({'role': 'user', 'content': text});

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ..._history,
    ];

    final String? responseText = await _complete(messages);

    if (responseText == null) {
      // Drop the user turn so a retry doesn't replay a dangling message.
      _history.removeLast();
      return AiMessage(
        text: "I'm a bit busy right now 😅 Please wait a moment and try again!",
        isUser: false,
      );
    }

    // Record the model's turn so the conversation stays coherent.
    _history.add({'role': 'assistant', 'content': responseText});

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
      debugPrint('🔴 Chat JSON parse error: $e');
      return AiMessage(
        text: "I'm sorry, I couldn't process that. Could you try again?",
        isUser: false,
      );
    }
  }

  /// Calls Groq and returns the assistant's message text, retrying once on a
  /// rate-limit / unavailable response. Returns null on failure.
  Future<String?> _complete(List<Map<String, String>> messages) async {
    const maxRetries = 2;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_groqUrl),
              headers: {
                'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': _groqModel,
                'response_format': {'type': 'json_object'},
                'messages': messages,
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return (data['choices'] as List).first['message']['content']
              as String?;
        }

        if ((response.statusCode == 429 || response.statusCode == 503) &&
            attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        debugPrint('🔴 Groq chat error: ${response.statusCode} ${response.body}');
        return null;
      } catch (e) {
        debugPrint('🔴 Groq chat exception (attempt ${attempt + 1}): $e');
        if (attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        return null;
      }
    }
    return null;
  }
}
