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
  });
}
