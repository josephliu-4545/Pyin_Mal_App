import 'package:flutter/material.dart';

/// Shared, in-session store of favorited hairstyle asset paths, so the heart
/// state on the Hair screen persists across navigation and shows up on the
/// Saved (Favorites) screen.
class HairstyleFavoritesNotifier extends ValueNotifier<Set<String>> {
  HairstyleFavoritesNotifier() : super({});

  void toggle(String path) {
    final next = Set<String>.from(value);
    if (next.contains(path)) {
      next.remove(path);
    } else {
      next.add(path);
    }
    value = next;
  }

  bool isFavorite(String path) => value.contains(path);

  void hydrate(Set<String> paths) => value = Set<String>.from(paths);

  void clearAll() => value = {};
}

final hairstyleFavoritesNotifier = HairstyleFavoritesNotifier();
