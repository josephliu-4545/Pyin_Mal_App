import 'package:flutter/material.dart';

/// Where a garment's key points sit INSIDE its PNG, in normalized image space
/// (0,0 = top-left of the image, 1,1 = bottom-right). These are the source
/// control points for the thin-plate-spline warp: each one is pinned to the
/// matching body landmark at runtime. Keys must match those produced by the
/// warped overlay ('neck', 'lShoulder', 'rShoulder', 'lElbow', 'rElbow',
/// 'lHip', 'rHip').
///
/// Tuned for a typical front-facing top whose sleeves reach roughly to the
/// elbow. Override per-item for garments with a different cut (e.g. a long
/// jacket that extends past the hips). These are eyeball defaults — expect to
/// nudge them against a real garment PNG on-device.
const Map<String, Offset> kDefaultTopAnchors = {
  'neck': Offset(0.50, 0.08),
  'lShoulder': Offset(0.20, 0.20),
  'rShoulder': Offset(0.80, 0.20),
  'lElbow': Offset(0.07, 0.48),
  'rElbow': Offset(0.93, 0.48),
  'lHip': Offset(0.30, 0.96),
  'rHip': Offset(0.70, 0.96),
};

/// Represents a clothing item that can be overlaid in the AR Fitting Room.
class ClothingItem {
  final String id;
  final String name;
  final String assetPath; // Path to the transparent PNG in assets/clothes/
  final String price;
  final String category; // 'top', 'bottom', etc.
  final List<ClothingColor> availableColors;

  /// Garment control points for the TPS warp, in normalized image space.
  /// See [kDefaultTopAnchors].
  final Map<String, Offset> anchors;

  const ClothingItem({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.price,
    required this.category,
    this.availableColors = const [],
    this.anchors = kDefaultTopAnchors,
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
