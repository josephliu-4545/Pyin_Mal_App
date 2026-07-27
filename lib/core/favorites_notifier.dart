import 'package:flutter/material.dart';

/// Minimal display info for a favorited product, cached so the Saved screen can
/// show it even when the product isn't in ProductRepository.allProducts (some
/// items are opened with a synthetic product that never lived in the catalog).
class FavoriteProductInfo {
  final String id;
  final String title;
  final String image;
  final String category;
  final String shop;
  final String description;

  const FavoriteProductInfo({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.shop,
    this.description = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'image': image,
        'category': category,
        'shop': shop,
        'description': description,
      };

  factory FavoriteProductInfo.fromMap(Map<String, dynamic> m) =>
      FavoriteProductInfo(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        image: m['image'] as String? ?? '',
        category: m['category'] as String? ?? '',
        shop: m['shop'] as String? ?? '',
        description: m['description'] as String? ?? '',
      );
}

class FavoritesNotifier extends ValueNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  /// id → cached display info (populated whenever something is favorited).
  final Map<String, FavoriteProductInfo> infoCache = {};

  /// Toggle a favorite. Pass [info] so the Saved screen can render the item
  /// without needing it to exist in the product catalog.
  void toggleFavorite(String productId, {FavoriteProductInfo? info}) {
    final newSet = Set<String>.from(value);
    if (newSet.contains(productId)) {
      newSet.remove(productId);
    } else {
      newSet.add(productId);
      if (info != null) infoCache[productId] = info;
    }
    value = newSet;
  }

  bool isFavorite(String productId) => value.contains(productId);

  /// Replace the whole state from a loaded source (e.g. Firestore on login).
  void hydrate(Set<String> ids, List<FavoriteProductInfo> infos) {
    infoCache
      ..clear()
      ..addEntries(infos.map((i) => MapEntry(i.id, i)));
    value = Set<String>.from(ids);
  }

  /// Clear everything (e.g. on logout).
  void clearAll() {
    infoCache.clear();
    value = {};
  }
}

final favoritesNotifier = FavoritesNotifier();
