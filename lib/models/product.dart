class Product {
  final String id;
  final String name;
  final String price;
  final String image;
  final String category;
  final String gender;
  final String brand;
  final String? description;
  final String? shopName;
  /// Visual search tags: color, clothing type, style keywords, graphics details.
  /// Used by the AI scan feature to match camera photos against the catalog.
  final List<String> tags;

  /// Additional gallery images shown in the product detail screen.
  /// Plain-background shots (_p) go here; [image] holds the default lifestyle shot.
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.gender,
    this.brand = 'NRF',
    this.description,
    this.shopName,
    this.tags = const [],
    this.images = const [],
  });

  // Parse a product from OpenCart's REST API JSON response.
  // OpenCart returns prices as plain numbers (e.g. "15000"), images as full URLs.
  factory Product.fromOpenCart(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? '0';
    final numPrice = double.tryParse(rawPrice.toString().replaceAll(',', '')) ?? 0;
    final formattedPrice =
        '${numPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} MMK';

    // Strip HTML tags from description
    final rawDesc = json['description']?.toString() ?? '';
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    // Image URL — prepend base URL if it's a relative path
    final rawImage = json['image']?.toString() ?? '';
    final imageUrl = rawImage.startsWith('http')
        ? rawImage
        : 'http://192.168.1.8/opencart/image/$rawImage';

    return Product(
      id: json['product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: formattedPrice,
      image: imageUrl,
      category: json['category'] ?? 'Other',
      gender: _parseGender(json['category'] ?? ''),
      brand: json['manufacturer'] ?? 'Unknown',
      description: cleanDesc.isNotEmpty ? cleanDesc : null,
      shopName: null,
    );
  }

  static String _parseGender(String tags) {
    final lower = tags.toLowerCase();
    if (lower.contains('female') || lower.contains('women')) return 'Female';
    if (lower.contains('male') || lower.contains('men')) return 'Male';
    return 'Unisex';
  }
}
