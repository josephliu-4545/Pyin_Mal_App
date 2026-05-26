class Product {
  final String id;
  final String name;
  final String price;
  final String image;
  final String category;
  final String gender;
  final String brand;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.gender,
    this.brand = 'NRF',
  });
}
