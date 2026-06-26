import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pyin_mal_app/models/product.dart';

/// Discovers products automatically from the pyin-mal-assets submodule folder structure.
///
/// Male:   assets/images/Male/{shop}/{category}/{colorCode}_{itemName}_{n}.jpg
/// Female: assets/images/Female/{dress.type}/{shop}/{colorCode}_{itemName}_{n}.jpg
///
/// Files ending in _p{n} are plain-background shots → gallery only.
/// Files ending in _{n} or {n} are lifestyle shots → default card image.
/// Files with no color code prefix → each numbered file is its own product (e.g. sets).
class AssetProductLoader {
  // Longest codes first so "bl" matches before "b", "gr" before "g", etc.
  static const _colorCodes = [
    'mix', 'mw', 'pu', 'gr', 'bl', 'br', 'b', 'r', 'y', 'g', 'p', 'w'
  ];


  // Folders under Female/ to skip entirely.
  static const _excludedFemaleFolders = {'dress.burmese'};

  static Future<List<Product>> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final all = manifest.listAssets();

    const prefix = 'pyin-mal-assets/assets/images/';

    debugPrint('📦 Total assets in manifest: ${all.length}');
    debugPrint('📦 Sample with prefix: ${all.where((p) => p.startsWith(prefix)).take(3).toList()}');

    final fashion = all.where((p) =>
      p.startsWith(prefix) &&
      (p.endsWith('.jpg') || p.endsWith('.png') || p.endsWith('.webp')),
    ).toList();

    debugPrint('📦 Fashion images found: ${fashion.length}');

    // Map: productKey → _Group
    final Map<String, _Group> groups = {};

    for (final path in fashion) {
      final img = _parse(path, prefix);
      if (img == null) continue;

      groups.putIfAbsent(img.key, () => _Group(
        key: img.key,
        name: img.name,
        gender: img.gender,
        brand: img.brand,
        category: img.category,
      ));

      if (img.isPlain) {
        groups[img.key]!.plain.add(path);
      } else {
        groups[img.key]!.lifestyle.add(path);
      }
    }

    return groups.values.map(_toProduct).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static _Img? _parse(String path, String prefix) {
    // Strip prefix
    final rel = path.startsWith(prefix)
        ? path.substring(prefix.length)
        : path;

    final parts = rel.split('/');
    if (parts.length < 2) return null;

    final gender = parts[0];
    if (gender != 'Male' && gender != 'Female') return null;

    String brand, category, filename;

    if (gender == 'Male') {
      if (parts.length == 2) {
        // Male/{file} — shouldn't happen but guard
        brand = 'Unknown';
        category = 'Other';
        filename = parts[1];
      } else if (parts.length == 3) {
        // Could be Male/{shop}/{file} (flat shop) OR Male/Set/{shop_as_file}
        // Check if parts[0] after Male is a known category word
        if (parts[1] == 'Set') {
          // Male/Set/{file} — treat whole "Set" as category, no separate shop
          brand = 'Sian Store';
          category = 'Set';
          filename = parts[2];
        } else {
          brand = parts[1];
          category = 'Other';
          filename = parts[2];
        }
      } else {
        // Male/{shop_or_category}/{sub}/{file}
        if (parts[1] == 'Set') {
          // Male/Set/{shop}/{file}
          brand = parts[2];
          category = 'Set';
          filename = parts[3];
        } else {
          brand = parts[1];
          category = _mapMaleCategory(parts[2]);
          filename = parts[3];
        }
      }
    } else {
      // Female
      if (parts.length < 3) return null;
      final dressType = parts[1];
      if (_excludedFemaleFolders.contains(dressType)) return null;

      category = _mapFemaleCategory(dressType);

      if (parts.length == 3) {
        // Female/{dress.type}/{file} — flat category folder
        brand = 'Unknown';
        filename = parts[2];
      } else {
        // Female/{dress.type}/{shop}/{file}
        brand = parts[2];
        filename = parts[3];
      }
    }

    final nameNoExt = _stripExt(filename);

    // Try to extract color code prefix
    String? colorCode;
    String itemBase = nameNoExt;

    for (final code in _colorCodes) {
      if (nameNoExt.toLowerCase().startsWith('${code}_')) {
        colorCode = code;
        itemBase = nameNoExt.substring(code.length + 1);
        break;
      }
    }

    if (colorCode == null) {
      // No color code → each unique numbered file = its own product
      // Strip trailing digits to get base name, use full nameNoExt as unique key
      final baseName = nameNoExt.replaceAll(RegExp(r'\s*\d+$'), '').trim();
      final key = _makeKey(gender, brand, nameNoExt);
      return _Img(
        key: key,
        name: _titleCase(baseName.isNotEmpty ? baseName : nameNoExt),
        gender: gender,
        brand: brand,
        category: category,
        isPlain: false,
      );
    }

    // Has color code — detect plain (_p{n} suffix)
    final isPlain = RegExp(r'_p\d+$', caseSensitive: false).hasMatch(itemBase);

    // Strip trailing _p{n} or _{n} or {space}{n} to get clean item name
    final cleanName = itemBase
        .replaceAll(RegExp(r'_p\d+$', caseSensitive: false), '')
        .replaceAll(RegExp(r'_\d+$'), '')
        .replaceAll(RegExp(r'\s+\d+$'), '')
        .trim();

    final key = _makeKey(gender, brand, cleanName);

    return _Img(
      key: key,
      name: _titleCase(cleanName),
      gender: gender,
      brand: brand,
      category: category,
      isPlain: isPlain,
    );
  }

  static Product _toProduct(_Group g) {
    final defaultImage = g.lifestyle.isNotEmpty
        ? g.lifestyle.first
        : (g.plain.isNotEmpty ? g.plain.first : '');

    final gallery = [
      ...g.lifestyle.skip(1),
      ...g.plain,
    ];

    // Deterministic price 40k–80k rounded to nearest 5k
    final raw = 40000 + (g.key.hashCode.abs() % 40001);
    final rounded = ((raw / 5000).round() * 5000).clamp(40000, 80000);
    final price = '${_fmtNum(rounded)} MMK';

    return Product(
      id: g.key,
      name: g.name,
      price: price,
      image: defaultImage,
      images: gallery,
      category: g.category,
      gender: g.gender,
      brand: g.brand,
      shopName: g.brand != 'Unknown' ? g.brand : null,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static String _makeKey(String gender, String brand, String item) =>
      '${gender}_${brand}_$item'
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

  static String _stripExt(String filename) {
    var name = filename;
    // Handle double extensions like name.jpg.jpg
    while (name.contains('.') &&
        (name.endsWith('.jpg') || name.endsWith('.png') || name.endsWith('.webp'))) {
      name = name.substring(0, name.lastIndexOf('.'));
    }
    return name;
  }

  static String _titleCase(String s) => s
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static String _fmtNum(int n) => n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );

  static String _mapMaleCategory(String folder) {
    switch (folder.toLowerCase()) {
      case 'hoodie': return 'Hoodie';
      case 'tee': case 't shirt': return 'T-Shirt';
      case 'shirt': return 'Shirt';
      case 'jacket': return 'Jacket';
      case 'sweater': return 'Sweater';
      case 'coat': return 'Coat';
      case 'pant': case 'pants': return 'Pants';
      case 'jersey': return 'Jersey';
      case 'set': return 'Set';
      default: return folder;
    }
  }

  static String _mapFemaleCategory(String dressType) {
    switch (dressType) {
      case 'dress. top': case 'dress.top': return 'Top';
      case 'dress.dress': return 'Dress';
      case 'dress.set': return 'Set';
      case 'dress.skirt': return 'Skirt';
      default: return 'Other';
    }
  }
}

class _Img {
  final String key, name, gender, brand, category;
  final bool isPlain;
  _Img({required this.key, required this.name, required this.gender,
        required this.brand, required this.category, required this.isPlain});
}

class _Group {
  final String key, name, gender, brand, category;
  final List<String> lifestyle = [];
  final List<String> plain = [];
  _Group({required this.key, required this.name, required this.gender,
          required this.brand, required this.category});
}
