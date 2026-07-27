import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pyin_mal_app/core/favorites_notifier.dart';
import 'package:pyin_mal_app/core/hairstyle_favorites_notifier.dart';
import 'package:pyin_mal_app/services/database_service.dart';

/// Keeps the in-memory favorites (products + hairstyles) in sync with Firestore
/// per account, so a user who logs out and back in with the same account sees
/// their saved items again.
class FavoritesSyncService {
  FavoritesSyncService._();
  static final FavoritesSyncService instance = FavoritesSyncService._();

  final _db = DatabaseService();
  bool _initialized = false;
  bool _hydrating = false; // guards against saving while loading
  Timer? _debounce;

  /// Call once at app startup. Loads favorites on login, clears on logout, and
  /// writes changes back to Firestore.
  void init() {
    if (_initialized) return;
    _initialized = true;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _hydrating = true;
        favoritesNotifier.clearAll();
        hairstyleFavoritesNotifier.clearAll();
        _hydrating = false;
      } else {
        _load();
      }
    });

    favoritesNotifier.addListener(_scheduleSave);
    hairstyleFavoritesNotifier.addListener(_scheduleSave);
  }

  Future<void> _load() async {
    _hydrating = true;
    try {
      final data = await _db.getUserData();
      final rawProducts = (data?['favoriteProducts'] as List?) ?? const [];
      final all = rawProducts
          .map((m) =>
              FavoriteProductInfo.fromMap(Map<String, dynamic>.from(m as Map)))
          .where((i) => i.id.isNotEmpty)
          .toList();
      // Every id is a favorite; keep display info only for those that have it.
      final ids = all.map((i) => i.id).toSet();
      final infos = all.where((i) => i.title.isNotEmpty).toList();
      favoritesNotifier.hydrate(ids, infos);

      final rawHair = (data?['favoriteHairstyles'] as List?) ?? const [];
      hairstyleFavoritesNotifier
          .hydrate(rawHair.map((e) => e.toString()).toSet());
    } catch (e) {
      debugPrint('Favorites load failed: $e');
    } finally {
      _hydrating = false;
    }
  }

  void _scheduleSave() {
    if (_hydrating) return; // don't echo a load back to the server
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      // Persist every favorited id; include display info when we have it so the
      // Saved screen can show items that aren't in the local catalog.
      final products = favoritesNotifier.value.map((id) {
        final info = favoritesNotifier.infoCache[id];
        return info?.toMap() ?? {'id': id};
      }).toList();
      await _db.saveFavorites(
        products: products,
        hairstyles: hairstyleFavoritesNotifier.value.toList(),
      );
    } catch (e) {
      debugPrint('Favorites save failed: $e');
    }
  }
}
