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
  });

  // Parse a product from OpenCart's REST API JSON response.
  // OpenCart returns prices as plain numbers (e.g. "15000"), images as full URLs.
  factory Product.fromOpenCart(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? '0';
    // Format: "15000" → "15,000 MMK"
    final numPrice = double.tryParse(rawPrice.toString().replaceAll(',', '')) ?? 0;
    final formattedPrice =
        '${numPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} MMK';

    return Product(
      id: json['product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: formattedPrice,
      image: json['image'] ?? '',
      category: json['categories']?.isNotEmpty == true
          ? json['categories'][0]['name']
          : 'Other',
      gender: _parseGender(json['tags'] ?? ''),
      brand: json['manufacturer'] ?? 'Unknown',
      description: json['description'],
      shopName: json['store_name'],
    );
  }

  static String _parseGender(String tags) {
    final lower = tags.toLowerCase();
    if (lower.contains('female') || lower.contains('women')) return 'Female';
    if (lower.contains('male') || lower.contains('men')) return 'Male';
    return 'Unisex';
  }
}
