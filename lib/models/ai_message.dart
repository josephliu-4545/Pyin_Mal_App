import 'package:pyin_mal_app/models/product.dart';

class AiMessage {
  final String text;
  final bool isUser;
  final List<Product> recommendedProducts;

  AiMessage({
    required this.text,
    required this.isUser,
    this.recommendedProducts = const [],
  });

  /// Serializable form for saving a conversation. Recommended products are
  /// stored by id and re-resolved from the catalog on load.
  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser,
        'productIds': recommendedProducts.map((p) => p.id).toList(),
      };
}
