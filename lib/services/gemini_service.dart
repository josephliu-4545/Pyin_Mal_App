import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';

import 'package:pyin_mal_app/services/database_service.dart';

class GeminiService {
  final GenerativeModel _model;
  late ChatSession _chat;
  final DatabaseService _db = DatabaseService();

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: ApiConstants.geminiApiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        ) {
    _chat = _model.startChat();
  }

  /// Sends a message to Gemini and returns the AI's response as an AiMessage.
  Future<AiMessage> sendMessage(String text) async {
    // 1. Fetch user history context dynamically per request
    final userContext = await _db.getRecentHistoryContext();
    
    // 1b. Build the list of products for the prompt
    final productsContext = ProductRepository.allProducts.map((p) {
      return '- ${p.name} (ID: ${p.id}, Category: ${p.category}, Price: ${p.price})';
    }).join('\n');

    // 2. Build system instruction
    final systemInstruction = Content.system('''
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
''');

    // Update model system instruction temporarily for this chat
    final modelWithInstruction = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    final tempChat = modelWithInstruction.startChat(history: _chat.history.toList());


    const maxRetries = 2;
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await tempChat.sendMessage(Content.text(text));
        
        // Save the updated history back to the main session
        _chat = modelWithInstruction.startChat(history: tempChat.history.toList());
        
        final responseText = response.text;
        
        if (responseText == null) {
          return AiMessage(
            text: "I'm sorry, I couldn't process that. Could you try again?",
            isUser: false,
          );
        }

        // Parse JSON
        final Map<String, dynamic> jsonMap = jsonDecode(responseText);
        final String message = jsonMap['message'] ?? '...';
        final List<dynamic> productIds = jsonMap['recommended_product_ids'] ?? [];

        // Map IDs to actual Product objects
        final List<Product> recommendedProducts = [];
        for (final id in productIds) {
          final product = ProductRepository.getProductById(id.toString());
          if (product != null) {
            recommendedProducts.add(product);
          }
        }

        return AiMessage(
          text: message,
          isUser: false,
          recommendedProducts: recommendedProducts,
        );
      } catch (e) {
        print('🔴 Gemini Error (attempt ${attempt + 1}): $e');
        
        // If rate limited, wait and retry
        if (e.toString().contains('429') && attempt < maxRetries - 1) {
          await Future.delayed(const Duration(seconds: 15));
          continue;
        }
        
        return AiMessage(
          text: "I'm a bit busy right now 😅 Please wait a moment and try again!",
          isUser: false,
        );
      }
    }
    
    return AiMessage(
      text: "I'm a bit busy right now 😅 Please wait a moment and try again!",
      isUser: false,
    );
  }
}
