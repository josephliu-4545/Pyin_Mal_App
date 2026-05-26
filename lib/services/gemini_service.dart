import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/models/ai_message.dart';
import 'package:pyin_mal_app/models/product.dart';

class GeminiService {
  late ChatSession _chat;
  
  GeminiService() {
    // 1. Build the list of products for the prompt
    final productsContext = ProductRepository.allProducts.map((p) {
      return '- ${p.name} (ID: ${p.id}, Category: ${p.category}, Price: ${p.price})';
    }).join('\n');

    // 2. Define the system instruction
    final systemInstruction = Content.system('''
You are an expert AI fashion stylist and haircut advisor for the Pyin Mal App. 
Your ONLY purpose is to discuss fashion, clothing, style advice, and haircuts. 
If a user asks about anything else (e.g., coding, politics, math, general knowledge), politely refuse and guide the conversation back to fashion or haircuts.

When giving advice, you can recommend products from our shop. 
Here are the available products you can recommend:
$productsContext

IMPORTANT: You must ALWAYS respond in valid JSON format matching this exact schema:
{
  "message": "Your conversational text response here...",
  "recommended_product_ids": ["id1", "id2"] // Only include IDs of products you genuinely recommend based on the user's query. Empty list if none.
}
''');

    // 3. Initialize the model
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    // 4. Start chat session
    _chat = model.startChat();
  }

  /// Sends a message to Gemini and returns the AI's response as an AiMessage.
  Future<AiMessage> sendMessage(String text) async {
    const maxRetries = 2;
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await _chat.sendMessage(Content.text(text));
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
