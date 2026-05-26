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
}
