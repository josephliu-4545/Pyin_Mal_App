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


  // Male brand folder → display shop name
  static const _maleBrandMap = {
    'nrf': 'NRF Store',
    'classydock': 'CLASSYDOCK',
    'burmese studio': 'Burmese Studio',
    'malory': 'Malory',
    'restyle': 'Restyle',
    'val3': 'VAL3',
  };

  // Female shop folder → display shop name
  static const _femaleBrandMap = {
    'nami': 'Nami',
    'oro': 'Oro',
    'saw in style': 'Sew In Style',
    'sew in style': 'Sew In Style',
  };

  // Male brand folders to skip
  static const _excludedMaleBrands = {
    'burmese dress for men', 'set', 'photo', 'outfits',
  };

  // Female dress-type folders to skip
  static const _excludedFemaleFolders = {'dress.burmese'};

  // Female shop folders to skip
  static const _excludedFemaleShops = {
    't shirt collection', 'luna', 'oro set',
  };

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

    // Collect video paths separately → map itemKey → CDN URL
    const cdnBase = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/';
    final Map<String, String> videoUrls = {};
    for (final path in all.where((p) => p.startsWith(prefix) && p.endsWith('.mp4'))) {
      final img = _parse(path.replaceAll('.mp4', '.jpg'), prefix);
      if (img == null) continue;
      final rel = path.substring('pyin-mal-assets/'.length);
      videoUrls[img.itemKey] = '$cdnBase$rel';
    }

    debugPrint('📦 Fashion images found: ${fashion.length}');

    // Map: itemKey → _Group (one group per item, colors nested inside)
    final Map<String, _Group> groups = {};

    for (final path in fashion) {
      final img = _parse(path, prefix);
      if (img == null) continue;

      groups.putIfAbsent(img.itemKey, () => _Group(
        key: img.itemKey,
        name: img.name,
        gender: img.gender,
        brand: img.brand,
        category: img.category,
      ));

      final group = groups[img.itemKey]!;
      group.colorPhotos.putIfAbsent(img.colorCode ?? '_', () => []);
      group.colorPhotos[img.colorCode ?? '_']!.add(path);
    }

    // Attach video URLs to groups
    for (final entry in videoUrls.entries) {
      if (groups.containsKey(entry.key)) {
        groups[entry.key]!.videoUrl = entry.value;
      }
    }

    final products = groups.values.map(_toProduct).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final femaleCount = products.where((p) => p.gender == 'Female').length;
    debugPrint('👗 Female products: $femaleCount / ${products.length} total');
    return products;
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
      if (parts.length < 3) return null;
      final brandFolder = parts[1].toLowerCase();
      if (_excludedMaleBrands.contains(brandFolder)) return null;
      brand = _maleBrandMap[brandFolder] ?? parts[1];
      if (parts.length == 3) {
        category = 'Other';
        filename = parts[2];
      } else {
        category = _mapMaleCategory(parts[2]);
        filename = parts[3];
      }
    } else {
      // Female
      if (parts.length < 3) return null;
      final dressType = parts[1];
      if (_excludedFemaleFolders.contains(dressType)) return null;
      category = _mapFemaleCategory(dressType);
      if (parts.length == 3) {
        return null; // no shop subfolder — skip
      }
      final shopFolder = parts[2].toLowerCase();
      if (_excludedFemaleShops.contains(shopFolder)) return null;
      brand = _femaleBrandMap[shopFolder] ?? _titleCase(parts[2]);
      filename = parts[3];
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
      // No color code → strip trailing digits to group numbered shots of same item
      final baseName = nameNoExt.replaceAll(RegExp(r'\s*\d+$'), '').trim();
      final itemKey = _makeKey(gender, brand, baseName.isNotEmpty ? baseName : nameNoExt);
      return _Img(
        itemKey: itemKey,
        colorCode: null,
        name: _titleCase(baseName.isNotEmpty ? baseName : nameNoExt),
        gender: gender,
        brand: brand,
        category: category,
      );
    }

    // Strip trailing _p{n} or _{n} or {space}{n} to get clean item name
    final cleanName = itemBase
        .replaceAll(RegExp(r'_p\d+$', caseSensitive: false), '')
        .replaceAll(RegExp(r'_\d+$'), '')
        .replaceAll(RegExp(r'\s+\d+$'), '')
        .trim();

    final itemKey = _makeKey(gender, brand, cleanName);

    return _Img(
      itemKey: itemKey,
      colorCode: colorCode,
      name: _titleCase(cleanName),
      gender: gender,
      brand: brand,
      category: category,
    );
  }

  static Product _toProduct(_Group g) {
    // Deterministic price 40k–80k rounded to nearest 5k
    final raw = 40000 + (g.key.hashCode.abs() % 40001);
    final rounded = ((raw / 5000).round() * 5000).clamp(40000, 80000);
    final price = '${_fmtNum(rounded)} MMK';

    // Preferred default: mix first, then alphabetical
    final String defaultColor;
    if (g.colorPhotos.containsKey('mix')) {
      defaultColor = 'mix';
    } else {
      defaultColor = g.colorPhotos.keys.isNotEmpty ? g.colorPhotos.keys.first : '';
    }

    return Product(
      id: g.key,
      name: g.name,
      price: price,
      category: g.category,
      gender: g.gender,
      brand: g.brand,
      shopName: g.brand != 'Unknown' ? g.brand : null,
      colorVariants: Map.unmodifiable(g.colorPhotos),
      defaultColor: defaultColor,
      videoUrl: g.videoUrl,
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
  final String itemKey, name, gender, brand, category;
  final String? colorCode;
  _Img({required this.itemKey, required this.colorCode, required this.name,
        required this.gender, required this.brand, required this.category});
}

class _Group {
  final String key, name, gender, brand, category;
  /// colorCode → ordered list of photo paths (lifestyle + plain mixed, insertion order)
  final Map<String, List<String>> colorPhotos = {};
  String? videoUrl;
  _Group({required this.key, required this.name, required this.gender,
          required this.brand, required this.category});
}
