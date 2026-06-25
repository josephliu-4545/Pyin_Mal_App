import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String name;
  final String price; // e.g., "15,000 MMK"
  final String image;
  final String brand;
  final String size;
  final String color;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.brand,
    required this.size,
    this.color = '',
    this.quantity = 1,
  });

  double get parsedPrice {
    // Convert "15,000 MMK" -> 15000.0
    final numericString = price.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
}

class CartService extends ChangeNotifier {
  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  static CartService get instance => _instance;

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item.parsedPrice * item.quantity));
  }

  void addToCart(CartItem newItem) {
    // Check if we already have this product + size + color in cart
    final existingIndex = _items.indexWhere((item) =>
        item.productId == newItem.productId &&
        item.size == newItem.size &&
        item.color == newItem.color);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }
  
  void updateQuantity(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(item);
      return;
    }
    
    final existingIndex = _items.indexOf(item);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
