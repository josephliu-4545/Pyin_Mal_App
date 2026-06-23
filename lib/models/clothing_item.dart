import 'package:flutter/material.dart';

/// Represents a clothing item that can be overlaid in the AR Fitting Room.
class ClothingItem {
  final String id;
  final String name;
  final String assetPath; // Path to the transparent PNG in assets/clothes/
  final String price;
  final String category; // 'top', 'bottom', etc.
  final List<ClothingColor> availableColors;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.price,
    required this.category,
    this.availableColors = const [],
  });
}

/// A named color option for a clothing item.
class ClothingColor {
  final String name;
  final Color color;
  final String? assetPath; // Optional: different asset per color variant

  const ClothingColor({
    required this.name,
    required this.color,
    this.assetPath,
  });
}

/// Mock clothing data used for MVP — replace with real product data later.
final List<ClothingItem> mockClothingItems = [
  ClothingItem(
    id: 'black_tshirt',
    name: 'Black T-Shirt',
    assetPath: 'assets/clothes/black_tshirt.png',
    price: '12,000 Ks',
    category: 'top',
    availableColors: const [
      ClothingColor(name: 'Black', color: Colors.black),
      ClothingColor(name: 'White', color: Colors.white),
      ClothingColor(name: 'Grey', color: Colors.grey),
    ],
  ),
  ClothingItem(
    id: 'white_hoodie',
    name: 'White Hoodie',
    assetPath: 'assets/clothes/white_hoodie.png',
    price: '28,000 Ks',
    category: 'top',
    availableColors: const [
      ClothingColor(name: 'White', color: Colors.white),
      ClothingColor(name: 'Black', color: Colors.black),
      ClothingColor(name: 'Cream', color: Color(0xFFE8DCC8)),
    ],
  ),
  ClothingItem(
    id: 'blue_jacket',
    name: 'Blue Jacket',
    assetPath: 'assets/clothes/blue_jacket.png',
    price: '45,000 Ks',
    category: 'top',
    availableColors: const [
      ClothingColor(name: 'Blue', color: Color(0xFF1565C0)),
      ClothingColor(name: 'Black', color: Colors.black),
      ClothingColor(name: 'Brown', color: Color(0xFF5D4037)),
    ],
  ),
];
