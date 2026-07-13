import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' show ImageFilter;
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/core/constants/shop_constants.dart';
import 'package:pyin_mal_app/screens/shop_products_screen.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

const _cdnPfx = 'https://cdn.jsdelivr.net/gh/josephliu-4545/pyin-mal-assets@main/';

// ── Helpers ───────────────────────────────────────────────────────────────────

void _openShop(BuildContext context, ShopInfo shop) {
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => ShopProductsScreen(shopName: shop.name)));
}

Widget _sectionHeader(String title, String subtitle, bool isDark) {
  final ink = isDark ? Colors.white : AppColors.inkBlack;
  final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: GoogleFonts.rufina(
              fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
      const SizedBox(height: 2),
      Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: muted)),
    ],
  );
}

/// Loads asset manifest once and caches it for the widget tree.
Future<List<String>> _loadManifestAssets() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest.listAssets();
}

// ── Section 1: Shop Spotlight (videos) ───────────────────────────────────────

class ShopSpotlightSection extends StatefulWidget {
  final bool isDark;
  const ShopSpotlightSection({super.key, required this.isDark});

  @override
  State<ShopSpotlightSection> createState() => _ShopSpotlightSectionState();
}

class _ShopSpotlightSectionState extends State<ShopSpotlightSection> {
  // shop → poster URL (bundled asset path or CDN URL)
  final Map<ShopInfo, String> _shopPosters = {};

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final assets = (await _loadManifestAssets()).toSet();
    final result = <ShopInfo, String>{};
    for (final shop in ShopConstants.shops) {
      if (shop.hasCdnPoster) {
        // Explicit CDN poster (e.g. CLASSYDOCK at non-standard path)
        result[shop] = shop.posterCdnUrl;
      } else if (assets.contains(shop.posterAsset)) {
        // Standard bundled poster — serve via CDN
        result[shop] = '${_cdnPfx}assets/images/shops/${shop.slug}/poster.jpg';
      } else if (assets.contains(shop.coverAsset)) {
        // Fall back to cover image for shops without a poster
        result[shop] = '${_cdnPfx}assets/images/shops/${shop.slug}/cover.jpg';
      }
    }
    if (mounted) setState(() { _shopPosters..clear()..addAll(result); });
  }

  @override
  Widget build(BuildContext context) {
    if (_shopPosters.isEmpty) return const SizedBox.shrink();
    final entries = _shopPosters.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
            'Shop Spotlight', 'Tap to watch the latest from our shops', widget.isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ShopVideoCard(
              shop: entries[i].key,
              posterAsset: entries[i].value,
              isDark: widget.isDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopVideoCard extends StatefulWidget {
  final ShopInfo shop;
  final String posterAsset;
  final bool isDark;
  const _ShopVideoCard({required this.shop, required this.posterAsset, required this.isDark});

  @override
  State<_ShopVideoCard> createState() => _ShopVideoCardState();
}

class _ShopVideoCardState extends State<_ShopVideoCard> {
  VideoPlayerController? _ctrl;
  bool _loading = false;
  bool _muted = true;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final c = _ctrl;
    if (c == null) {
      setState(() => _loading = true);
      final controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.shop.videoUrl));
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
        if (!mounted) { controller.dispose(); return; }
        setState(() { _ctrl = controller; _loading = false; });
      } catch (_) {
        controller.dispose();
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video coming soon')),
        );
      }
    } else {
      setState(() => c.value.isPlaying ? c.pause() : c.play());
    }
  }

  void _toggleMute() {
    final c = _ctrl;
    if (c == null) return;
    setState(() { _muted = !_muted; c.setVolume(_muted ? 0 : 1); });
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    final ready = c != null && c.value.isInitialized;
    final playing = ready && c.value.isPlaying;

    return GestureDetector(
      onTap: _toggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 160,
          height: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (ready)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: c.value.size.width,
                    height: c.value.size.height,
                    child: VideoPlayer(c),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: widget.posterAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => Container(
                    color: widget.isDark ? AppColors.darkWarm : AppColors.creamAlt,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: widget.isDark ? AppColors.darkWarm : AppColors.creamAlt,
                    child: Icon(Icons.storefront_rounded, size: 42,
                        color: widget.isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(playing ? 0.15 : 0.55),
                    ],
                  ),
                ),
              ),
              if (!playing)
                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                  ),
                ),
              if (playing)
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              Positioned(
                left: 12, right: 12, bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rufina(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _openShop(context, widget.shop),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Visit shop',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkBlack)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section 2: Featured Shops (cover + logo) ──────────────────────────────────

class FeaturedShopsSection extends StatefulWidget {
  final bool isDark;
  const FeaturedShopsSection({super.key, required this.isDark});

  @override
  State<FeaturedShopsSection> createState() => _FeaturedShopsSectionState();
}

class _FeaturedShopsSectionState extends State<FeaturedShopsSection> {
  List<ShopInfo> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    final assets = await _loadManifestAssets();
    final available = ShopConstants.shops
        .where((s) => assets.contains(s.coverAsset))
        .toList();
    if (mounted) setState(() => _shops = available);
  }

  @override
  Widget build(BuildContext context) {
    final shops = _shops.isEmpty ? ShopConstants.shops : _shops;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Featured Shops', 'Discover stores on Pyin Mal', widget.isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = shops[i];
              return GestureDetector(
                onTap: () => _openShop(context, s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 280,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          s.coverAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: widget.isDark
                                ? AppColors.darkWarm
                                : AppColors.creamAlt,
                            child: Icon(Icons.storefront_rounded, size: 40,
                                color: widget.isDark
                                    ? Colors.white24
                                    : Colors.black26),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.black.withOpacity(0.10),
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14, right: 14, bottom: 14,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Image.asset(
                                    s.logoAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.store_rounded,
                                        size: 20,
                                        color: AppColors.burgundy),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(s.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.rufina(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    Text(s.tagline,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.85))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Section 3: Shop Lookbook ──────────────────────────────────────────────────

class ShopLookbookSection extends StatefulWidget {
  final bool isDark;
  const ShopLookbookSection({super.key, required this.isDark});

  @override
  State<ShopLookbookSection> createState() => _ShopLookbookSectionState();
}

class _ShopLookbookSectionState extends State<ShopLookbookSection> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Products power the per-shop trending collections.
    ProductRepository.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // One collection per shop: that shop's most popular / trending pieces.
    final collections = <({ShopInfo shop, List<Product> products})>[
      for (final s in ShopConstants.shops)
        (
          shop: s,
          products: ProductRepository.allProducts
              .where((p) => p.shopName == s.name)
              .take(4)
              .toList(),
        ),
    ].where((c) => c.products.isNotEmpty).toList();

    if (!_loaded && collections.isEmpty) return const SizedBox.shrink();
    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Shop Lookbook',
            'Trending collections from every shop', widget.isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = collections[i];
              return _CollectionCard(
                shop: c.shop,
                products: c.products,
                isDark: widget.isDark,
                onTap: () => _openWardrobe(context, c.shop, widget.isDark),
              );
            },
          ),
        ),
      ],
    );
  }
}

// One shop's trending collection: a 2×2 collage of its top pieces.
class _CollectionCard extends StatelessWidget {
  final ShopInfo shop;
  final List<Product> products;
  final bool isDark;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.shop,
    required this.products,
    required this.isDark,
    required this.onTap,
  });

  Widget _tile(Product? p) {
    if (p == null) {
      return Container(
        color: isDark ? Colors.white10 : const Color(0xFFF0EDE8),
        child: Icon(Icons.checkroom_rounded,
            size: 20, color: isDark ? Colors.white24 : Colors.black26),
      );
    }
    return CdnImage(
      p.image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: isDark ? Colors.white10 : const Color(0xFFF0EDE8),
        child: Icon(Icons.checkroom_rounded,
            size: 20, color: isDark ? Colors.white24 : Colors.black26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2×2 product collage + TRENDING badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(17)),
                    child: Column(
                      children: [
                        for (var row = 0; row < 2; row++)
                          Expanded(
                            child: Row(
                              children: [
                                for (var col = 0; col < 2; col++)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          right: col == 0 ? 1 : 0,
                                          bottom: row == 0 ? 1 : 0),
                                      child: _tile(
                                          row * 2 + col < products.length
                                              ? products[row * 2 + col]
                                              : null),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              size: 10, color: Color(0xFFFF7043)),
                          const SizedBox(width: 3),
                          Text('TRENDING',
                              style: GoogleFonts.outfit(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Shop name + item count
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.style_rounded, size: 10, color: muted),
                      const SizedBox(width: 3),
                      Text('${products.length} trending pieces',
                          style: GoogleFonts.outfit(
                              fontSize: 10, color: muted)),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12, color: muted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product wardrobe viewer ───────────────────────────────────────────────────

void _openWardrobe(BuildContext context, ShopInfo shop, bool isDark) {
  final shopProducts = ProductRepository.allProducts
      .where((p) => p.shopName == shop.name)
      .toList();
  final source =
      shopProducts.isNotEmpty ? shopProducts : ProductRepository.allProducts;
  if (source.isEmpty) {
    _openShop(context, shop);
    return;
  }
  final products = source.take(12).toList();

  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) =>
          _WardrobeViewer(products: products, shop: shop, isDark: isDark),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position:
                Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _WardrobeViewer extends StatefulWidget {
  final List<Product> products;
  final ShopInfo shop;
  final bool isDark;
  const _WardrobeViewer(
      {required this.products, required this.shop, required this.isDark});

  @override
  State<_WardrobeViewer> createState() => _WardrobeViewerState();
}

class _WardrobeViewerState extends State<_WardrobeViewer> {
  late final PageController _pc;
  late double _page;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.6);
    _page = 0;
    _pc.addListener(() => setState(() => _page = _pc.page ?? _page));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _jumpTo(int i) {
    _pc.animateToPage(i,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final current = _page.round().clamp(0, widget.products.length - 1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── On-brand dark backdrop ──
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A2320), Color(0xFF17130F)],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${current + 1} / ${widget.products.length}',
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                // Header
                Text('MY WARDROBE',
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Drag to rotate · Tap to view',
                    style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                        color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 12),
                // 3D wheel carousel
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pc,
                        itemCount: widget.products.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (_, i) {
                          final diff = i - _page;
                          final cd = diff.clamp(-1.5, 1.5);
                          final absd = diff.abs().clamp(0.0, 1.0);
                          final isCenter = i == current;
                          final rotateY = -cd * 0.55;
                          final scale = isCenter ? 1.06 : (1 - 0.12 * absd);
                          final opacity = 1 - 0.4 * absd;
                          return Center(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 1 / 1200) // perspective 1200px
                                ..rotateY(rotateY)
                                ..scale(scale),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: GestureDetector(
                                  onTap: () => isCenter
                                      ? _openProductModal(widget.products[i])
                                      : _jumpTo(i),
                                  child: _glassCard(widget.products[i], isCenter),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _chevron(Icons.chevron_left_rounded, current > 0),
                                _chevron(Icons.chevron_right_rounded,
                                    current < widget.products.length - 1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openProductModal(widget.products[current]),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded,
                            size: 16, color: AppColors.inkBlack),
                        const SizedBox(width: 6),
                        Text('View item',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkBlack)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chevron(IconData icon, bool visible) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // Frosted-glass hanger card showing the garment + name (+ price when active).
  Widget _glassCard(Product p, bool isCenter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 20,
            child: CustomPaint(
              painter: _HookPainter(Colors.white.withOpacity(0.75)),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 168,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isCenter ? 0.92 : 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: isCenter
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.25),
                      blurRadius: isCenter ? 30 : 14,
                      offset: Offset(0, isCenter ? 0 : 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CdnImage(
                          p.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.creamAlt,
                            child: const Icon(Icons.checkroom_rounded,
                                size: 40, color: Colors.black26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkBlack)),
                    if (isCenter) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.inkBlack,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(p.price,
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Product details modal (blur background, fade + scale in).
  void _openProductModal(Product p) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'product',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogCtx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (dialogCtx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Stack(
          children: [
            // Heavy background blur
            FadeTransition(
              opacity: anim,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
            // Dismiss on tap outside
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogCtx),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(curved),
                child: Center(
                  child: _ProductModalCard(product: p),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// The floating product card shown when an item is selected.
class _ProductModalCard extends StatefulWidget {
  final Product product;
  const _ProductModalCard({required this.product});

  @override
  State<_ProductModalCard> createState() => _ProductModalCardState();
}

class _ProductModalCardState extends State<_ProductModalCard> {
  static const _sizes = ['S', 'M', 'L', 'XL'];
  String _size = 'M';

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded,
                      size: 22, color: Colors.black38),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 170,
                  height: 210,
                  child: CdnImage(
                    p.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.creamAlt,
                      child: const Icon(Icons.checkroom_rounded,
                          size: 44, color: Colors.black26),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(p.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E2E2E))),
              const SizedBox(height: 2),
              Text(p.category,
                  style: GoogleFonts.outfit(
                      fontSize: 12.5, color: Colors.grey.shade500)),
              const SizedBox(height: 10),
              Text(p.price,
                  style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.burgundy)),
              const SizedBox(height: 14),
              // Size selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _sizes.map((s) {
                  final sel = _size == s;
                  return GestureDetector(
                    onTap: () => setState(() => _size = s),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF2E2E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF2E2E2E)
                                : Colors.grey.shade300,
                            width: 1.4),
                      ),
                      child: Text(s,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : Colors.black54)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Add to Cart CTA (mustard/gold)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    CartService.instance.addToCart(CartItem(
                      productId: p.id,
                      name: p.name,
                      price: p.price,
                      image: p.image,
                      brand: p.brand,
                      size: _size,
                    ));
                    Navigator.pop(context); // modal
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('${p.name} added to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.inkBlack,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Add to Cart',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Draws a small clothes-hanger hook that appears to hang over the rail.
class _HookPainter extends CustomPainter {
  final Color color;
  _HookPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx, size.height)
      ..lineTo(cx, size.height * 0.45);
    path.arcToPoint(
      Offset(cx - size.width * 0.28, size.height * 0.2),
      radius: Radius.circular(size.width * 0.18),
      clockwise: false,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HookPainter old) => old.color != color;
}
