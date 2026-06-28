import 'package:flutter/material.dart';

class FavoritesNotifier extends ValueNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  void toggleFavorite(String productId) {
    final newSet = Set<String>.from(value);
    if (newSet.contains(productId)) {
      newSet.remove(productId);
    } else {
      newSet.add(productId);
    }
    value = newSet;
  }

  bool isFavorite(String productId) => value.contains(productId);
}

final favoritesNotifier = FavoritesNotifier();
