import 'package:flutter/services.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/asset_product_loader.dart';
import 'package:pyin_mal_app/services/opencart_service.dart';

class ProductRepository {
  static List<Product> _assetProducts = [];
  static List<Product> _opencartProducts = [];
  static bool _assetsLoaded = false;

  static List<Product> get allProducts => [
    ..._assetProducts,
    ..._opencartProducts,
  ];

  /// Call once at startup (e.g. in ShopScreen.initState).
  static Future<void> load() async {
    await Future.wait([
      _loadAssets(),
      _loadOpenCart(),
    ]);
  }

  static Future<void> _loadAssets() async {
    if (_assetsLoaded) return;
    try {
      _assetProducts = await AssetProductLoader.load(rootBundle);
      _assetsLoaded = true;
    } catch (e) {
      // Assets unavailable — no products shown from local store
    }
  }

  static Future<void> _loadOpenCart() async {
    try {
      final products = await OpenCartService.fetchProducts();
      if (products.isNotEmpty) {
        final assetIds = _assetProducts.map((p) => p.id).toSet();
        _opencartProducts = products.where((p) => !assetIds.contains(p.id)).toList();
      }
    } catch (_) {}
  }

  // Keep for backwards compat — used by shop_screen and elsewhere.
  static Future<void> loadFromOpenCart() => load();

  /// Product ids pinned to the front of the shop grid, in this order.
  static const List<String> featuredIds = [
    'male_classydock_star_wear',
  ];

  /// Returns a new list with any [featuredIds] moved to the front,
  /// preserving the original order of everything else.
  static List<Product> pinFeatured(List<Product> products) {
    final featured = <Product>[];
    final rest = <Product>[];
    for (final p in products) {
      if (featuredIds.contains(p.id)) {
        featured.add(p);
      } else {
        rest.add(p);
      }
    }
    featured.sort((a, b) =>
        featuredIds.indexOf(a.id).compareTo(featuredIds.indexOf(b.id)));
    return [...featured, ...rest];
  }

  static Product? getProductById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
