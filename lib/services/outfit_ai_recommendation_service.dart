import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/database_service.dart';

/// Re-ranks a "Complete the Look" shortlist using the user's style profile —
/// backed by Groq (same provider as the chat stylist; Gemini/Cloudflare are
/// both geoblocked in Myanmar, see GeminiService).
///
/// This never introduces new items: it only reorders/narrows the candidates
/// it's given, which are already filtered to a different outfit slot by
/// [OutfitRecommendationService]. So even if the model errors, times out, or
/// returns nonsense, the category-exclusion guarantee (no shirt recommends
/// another shirt) can't be broken — worst case we just fall back to the
/// caller's original order.
class OutfitAiRecommendationService {
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.3-70b-versatile';

  /// In-memory cache so re-opening the same product this session doesn't
  /// re-call the model. Keyed by "productId:candidateIds".
  static final Map<String, List<String>> _cache = {};

  static final DatabaseService _db = DatabaseService();

  /// Returns [candidates] reordered/narrowed to [limit] items by how well
  /// they suit the user's style profile alongside [product]. Falls back to
  /// `candidates.take(limit)` on any failure.
  static Future<List<Product>> refine(
    Product product,
    List<Product> candidates, {
    int limit = 10,
  }) async {
    if (candidates.isEmpty) return candidates;

    final cacheKey = '${product.id}:${candidates.map((p) => p.id).join(',')}';
    final cachedIds = _cache[cacheKey];
    if (cachedIds != null) {
      return _applyOrder(candidates, cachedIds, limit);
    }

    try {
      final styleContext = await _db.getRecentHistoryContext();
      final candidateLines = candidates.map((p) =>
          '- ${p.name} (ID: ${p.id}, Category: ${p.category}, Brand: ${p.brand})').join('\n');

      final systemPrompt = '''
You are a personal stylist for the 'Ta Chat Nhate' fashion app choosing items that
"complete the look" for a shopper who is viewing this item:
${product.name} (Category: ${product.category}, Brand: ${product.brand}).

$styleContext

From the candidates below (already limited to complementary categories —
never recommend anything from the same category as the viewed item), pick
the $limit that best suit the user's style profile and would look best paired
with the viewed item. Order them best-first.

Candidates:
$candidateLines

Output valid JSON only, in this exact shape:
{"recommended_ids": ["id1", "id2", ...]}''';

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
              'messages': [
                {'role': 'system', 'content': systemPrompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('🔴 Outfit AI error: ${response.statusCode} ${response.body}');
        return candidates.take(limit).toList();
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String?;
      if (content == null) return candidates.take(limit).toList();

      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final ids = List<String>.from(parsed['recommended_ids'] ?? const []);
      if (ids.isEmpty) return candidates.take(limit).toList();

      _cache[cacheKey] = ids;
      return _applyOrder(candidates, ids, limit);
    } catch (e) {
      debugPrint('🔴 Outfit AI exception: $e');
      return candidates.take(limit).toList();
    }
  }

  /// Reorders [candidates] to match [ids] (ignoring any id the model
  /// invented that isn't actually in the candidate set), then fills any
  /// remaining slots from the original order.
  static List<Product> _applyOrder(
      List<Product> candidates, List<String> ids, int limit) {
    final byId = {for (final p in candidates) p.id: p};
    final ordered = <Product>[];
    for (final id in ids) {
      final p = byId[id];
      if (p != null && !ordered.contains(p)) ordered.add(p);
    }
    for (final p in candidates) {
      if (ordered.length >= limit) break;
      if (!ordered.contains(p)) ordered.add(p);
    }
    return ordered.take(limit).toList();
  }
}
