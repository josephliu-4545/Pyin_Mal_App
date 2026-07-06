import 'package:cloud_firestore/cloud_firestore.dart';

/// Where a [WardrobeItem] came from — drives whether it needed an AI
/// classification pass or was populated straight from known catalog data.
class WardrobeSource {
  static const manual = 'manual';
  static const purchase = 'purchase';
  static const tryOn = 'tryon';
}

/// A single item in a user's digital wardrobe.
class WardrobeItem {
  final String id;
  final String imageUrl;
  final String category; // top / bottom / shoes / accessory / outerwear
  final String? color;
  final String? brand;
  final List<String> tags;
  final String source; // see WardrobeSource
  final String? sourceProductId;
  final DateTime addedAt;
  final int timesWorn;
  final DateTime? lastWornAt;

  const WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.category,
    this.color,
    this.brand,
    this.tags = const [],
    this.source = WardrobeSource.manual,
    this.sourceProductId,
    required this.addedAt,
    this.timesWorn = 0,
    this.lastWornAt,
  });

  factory WardrobeItem.fromMap(Map<String, dynamic> data, String id) {
    return WardrobeItem(
      id: id,
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String? ?? 'other',
      color: data['color'] as String?,
      brand: data['brand'] as String?,
      tags: List<String>.from(data['tags'] ?? const []),
      source: data['source'] as String? ?? WardrobeSource.manual,
      sourceProductId: data['sourceProductId'] as String?,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timesWorn: data['timesWorn'] as int? ?? 0,
      lastWornAt: (data['lastWornAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'category': category,
      'color': color,
      'brand': brand,
      'tags': tags,
      'source': source,
      'sourceProductId': sourceProductId,
      'addedAt': FieldValue.serverTimestamp(),
      'timesWorn': timesWorn,
      'lastWornAt': lastWornAt != null ? Timestamp.fromDate(lastWornAt!) : null,
    };
  }
}
