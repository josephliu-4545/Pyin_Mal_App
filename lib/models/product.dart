class Product {
  final String id;
  final String name;
  final String price;
  final String category;
  final String gender;
  final String brand;
  final String? description;
  final String? shopName;
  final List<String> tags;

  /// colorCode → ordered list of all photos for that color (lifestyle + plain).
  /// Empty map = OpenCart product with a single image (use [_fallbackImage]).
  final Map<String, List<String>> colorVariants;

  /// The color selected by default when opening the product.
  /// Prefers 'mix', otherwise the first key in [colorVariants].
  final String defaultColor;

  /// Fallback for OpenCart products that have no color variants.
  final String _fallbackImage;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.gender,
    this.brand = 'NRF',
    this.description,
    this.shopName,
    this.tags = const [],
    this.colorVariants = const {},
    String? defaultColor,
    String fallbackImage = '',
  })  : defaultColor = defaultColor ??
            (colorVariants.containsKey('mix')
                ? 'mix'
                : (colorVariants.keys.isNotEmpty
                    ? colorVariants.keys.first
                    : '')),
        _fallbackImage = fallbackImage;

  /// Default card/list image — first photo of the default color.
  String get image {
    if (colorVariants.isEmpty) return _fallbackImage;
    final photos = colorVariants[defaultColor] ?? colorVariants.values.first;
    return photos.isNotEmpty ? photos.first : _fallbackImage;
  }

  /// All photos of the default color (used in detail screen gallery).
  List<String> get images {
    if (colorVariants.isEmpty) return [];
    return colorVariants[defaultColor] ?? colorVariants.values.first;
  }

  // Parse a product from OpenCart's REST API JSON response.
  factory Product.fromOpenCart(Map<String, dynamic> json) {
    final rawPrice = json['price'] ?? '0';
    final numPrice = double.tryParse(rawPrice.toString().replaceAll(',', '')) ?? 0;
    final formattedPrice =
        '${numPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} MMK';

    final rawDesc = json['description']?.toString() ?? '';
    final cleanDesc = rawDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    final rawImage = json['image']?.toString() ?? '';
    final imageUrl = rawImage.startsWith('http')
        ? rawImage
        : 'http://192.168.1.8/opencart/image/$rawImage';

    return Product(
      id: json['product_id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: formattedPrice,
      category: json['category'] ?? 'Other',
      gender: _parseGender(json['category'] ?? ''),
      brand: json['manufacturer'] ?? 'Unknown',
      description: cleanDesc.isNotEmpty ? cleanDesc : null,
      shopName: null,
      fallbackImage: imageUrl,
    );
  }

  static String _parseGender(String tags) {
    final lower = tags.toLowerCase();
    if (lower.contains('female') || lower.contains('women')) return 'Female';
    if (lower.contains('male') || lower.contains('men')) return 'Male';
    return 'Unisex';
  }
}
