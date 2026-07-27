const _cdnRoot = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/';

class ShopInfo {
  final String name;
  final String slug;
  final String tagline;
  /// Override the CDN poster URL when the file is at a non-standard path in git.
  final String? _posterCdnOverride;

  /// Override the video URL (use catbox.moe or similar for proper video streaming).
  final String? videoUrlOverride;

  /// Override the home-carousel banner path when the folder name in git does
  /// not match the slug (e.g. "sis burma").
  final String? bannerAssetOverride;

  const ShopInfo({
    required this.name,
    required this.slug,
    required this.tagline,
    String? posterCdnOverride,
    this.videoUrlOverride,
    this.bannerAssetOverride,
  }) : _posterCdnOverride = posterCdnOverride;

  /// Bundled asset path for the spotlight poster (standard location).
  String get posterAsset => 'pyin-mal-assets/assets/images/shops/$slug/poster.jpg';

  /// True when a CDN poster override is explicitly set.
  bool get hasCdnPoster => _posterCdnOverride != null;

  // Bundled asset paths (images only — loaded via Image.asset)
  String get logoAsset    => 'pyin-mal-assets/assets/images/shops/$slug/logo.png';
  String get bannerAsset  =>
      bannerAssetOverride ?? 'pyin-mal-assets/assets/images/shops/$slug/banner.jpg';
  String get coverAsset   => 'pyin-mal-assets/assets/images/shops/$slug/cover.jpg';
  String lookAsset(int n) => 'pyin-mal-assets/assets/images/shops/$slug/look_$n.jpg';

  // Poster served from CDN (avoids casing/bundling conflicts for shops like CLASSYDOCK)
  String get posterCdnUrl =>
      _posterCdnOverride ?? '${_cdnRoot}assets/images/shops/$slug/poster.jpg';

  // Video URL — use videoUrlOverride for catbox/external hosting, falls back to jsDelivr
  String get videoUrl =>
      videoUrlOverride ?? '${_cdnRoot}assets/videos/shops/$slug.mp4';
}

class ShopConstants {
  static const List<ShopInfo> shops = [
    ShopInfo(name: 'NRF Store',      slug: 'nrf_store',      tagline: 'Streetwear essentials'),
    ShopInfo(
      name: 'CLASSYDOCK',
      slug: 'classydock',
      tagline: 'Bold everyday fits',
      posterCdnOverride: '${_cdnRoot}assets/images/Shops/CLASSYDOCK/poster.png',
      videoUrlOverride: 'https://files.catbox.moe/cbhbt9.mp4',
    ),
    ShopInfo(name: 'Burmese Studio', slug: 'burmese_studio', tagline: 'Traditional meets modern'),
    ShopInfo(name: 'Malory',         slug: 'malory',         tagline: 'Curated Myanmar styles'),
    ShopInfo(name: 'Restyle',        slug: 'restyle',        tagline: 'Elevate your wardrobe'),
    ShopInfo(name: 'VAL3',           slug: 'val3',           tagline: 'Premium streetwear'),
    ShopInfo(name: 'Nami',           slug: 'nami',           tagline: 'Elegant womenswear'),
    ShopInfo(name: 'Oro',            slug: 'oro',            tagline: 'Timeless feminine style'),
    ShopInfo(name: 'Sew In Style',   slug: 'sew_in_style',   tagline: 'Fashion forward looks'),
    ShopInfo(
      name: 'SISBURMA',
      slug: 'sis_burma',
      tagline: 'Experience stores nationwide',
      bannerAssetOverride: 'pyin-mal-assets/assets/images/shops/sis burma/banner.jpg',
    ),
  ];

  /// Shops that ship a home-carousel banner.jpg. Used as the first-frame
  /// fallback before the asset manifest finishes loading, so the carousel
  /// never flashes shops that have no banner.
  static List<ShopInfo> get bannerShops => const ['classydock', 'restyle', 'sis_burma']
      .map((slug) => shops.firstWhere((s) => s.slug == slug))
      .toList();

  static ShopInfo? byName(String name) {
    try {
      return shops.firstWhere(
        (s) => s.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static ShopInfo? bySlug(String slug) {
    try {
      return shops.firstWhere((s) => s.slug == slug);
    } catch (_) {
      return null;
    }
  }

  static List<String> get allNames => shops.map((s) => s.name).toList();
}
