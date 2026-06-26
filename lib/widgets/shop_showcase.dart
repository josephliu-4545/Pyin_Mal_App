import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/screens/shop_products_screen.dart';

/// A shop featured on the home page. Media is served from the assets CDN.
///
/// Expected files in the `josephliu-4545/pyin-mal-assets` repo (branch `main`):
///   assets/images/shops/<slug>/cover.jpg     ← banner + video poster
///   assets/images/shops/<slug>/logo.png      ← small transparent logo
///   assets/images/shops/<slug>/look_1.jpg    ← lookbook photos (1..3)
///   assets/images/shops/<slug>/look_2.jpg
///   assets/images/shops/<slug>/look_3.jpg
///   assets/videos/shops/<slug>.mp4           ← short vertical spotlight clip
class ShopShowcase {
  final String name; // must match Product.shopName so we can open the shop
  final String slug;
  final String tagline;
  const ShopShowcase(
      {required this.name, required this.slug, required this.tagline});

  String get cover => 'assets/images/shops/$slug/cover.jpg';
  String get logo => 'assets/images/shops/$slug/logo.png';
  String look(int i) => 'assets/images/shops/$slug/look_$i.jpg';
  String get videoUrl => '${ApiConstants.cdnRootUrl}assets/videos/shops/$slug.mp4';
}

const kShopShowcases = <ShopShowcase>[
  ShopShowcase(
      name: 'Pyin Mal Official',
      slug: 'pyin_mal_official',
      tagline: 'The flagship store'),
  ShopShowcase(
      name: 'Luna Boutique', slug: 'luna_boutique', tagline: 'Elegant womenswear'),
  ShopShowcase(
      name: 'NRF Store', slug: 'nrf_store', tagline: 'Streetwear essentials'),
  ShopShowcase(
      name: 'ABCD Fashion', slug: 'abcd_fashion', tagline: 'Bold everyday fits'),
  ShopShowcase(
      name: 'AJOHN Official', slug: 'ajohn_official', tagline: 'Premium basics'),
];

void _openShop(BuildContext context, ShopShowcase s) {
  Navigator.push(context,
      MaterialPageRoute(builder: (_) => ShopProductsScreen(shopName: s.name)));
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

// ── Section 1: Shop Spotlight (videos) ────────────────────────────────────────
class ShopSpotlightSection extends StatelessWidget {
  final bool isDark;
  const ShopSpotlightSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Shop Spotlight', 'Tap to watch the latest from our shops',
            isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: kShopShowcases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) =>
                _ShopVideoCard(shop: kShopShowcases[i], isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _ShopVideoCard extends StatefulWidget {
  final ShopShowcase shop;
  final bool isDark;
  const _ShopVideoCard({required this.shop, required this.isDark});

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
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.shop.videoUrl));
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
        if (!mounted) {
          controller.dispose();
          return;
        }
        setState(() {
          _ctrl = controller;
          _loading = false;
        });
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
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
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
              // Video (when playing) or poster image
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
                CdnImage(
                  widget.shop.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: widget.isDark
                        ? AppColors.darkWarm
                        : AppColors.creamAlt,
                    child: Icon(Icons.storefront_rounded,
                        size: 42,
                        color: widget.isDark
                            ? Colors.white24
                            : Colors.black26),
                  ),
                ),
              // Scrim
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
              // Play / loading indicator
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
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 28),
                  ),
                ),
              // Mute toggle (only while playing)
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
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 16),
                    ),
                  ),
                ),
              // Shop name + visit
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
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

// ── Section 2: Featured Shops (image banners) ─────────────────────────────────
class FeaturedShopsSection extends StatelessWidget {
  final bool isDark;
  const FeaturedShopsSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Featured Shops', 'Discover stores on Pyin Mal', isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: kShopShowcases.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final s = kShopShowcases[i];
              return GestureDetector(
                onTap: () => _openShop(context, s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 280,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CdnImage(
                          s.cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark
                                ? AppColors.darkWarm
                                : AppColors.creamAlt,
                            child: Icon(Icons.storefront_rounded,
                                size: 40,
                                color: isDark
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
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Row(
                            children: [
                              // Logo bubble
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
                                  child: CdnImage(
                                    s.logo,
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
                                            color: Colors.white
                                                .withOpacity(0.85))),
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

// ── Section 3: Shop Lookbook (image gallery) ──────────────────────────────────
class ShopLookbookSection extends StatelessWidget {
  final bool isDark;
  const ShopLookbookSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Flatten 3 looks per shop into one scrollable row.
    final looks = <({ShopShowcase shop, String path})>[
      for (final s in kShopShowcases)
        for (var i = 1; i <= 3; i++) (shop: s, path: s.look(i)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Shop Lookbook', 'Styles straight from the shops', isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: looks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final l = looks[i];
              return GestureDetector(
                onTap: () => _openLookbook(context, looks, i, isDark),
                child: SizedBox(
                  width: 150,
                  child: Stack(
                    children: [
                      // Stacked-card edges peeking behind (implies a gallery)
                      Positioned(
                        top: 6,
                        right: 0,
                        bottom: 6,
                        left: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 5,
                        bottom: 3,
                        left: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // The front photo
                      Padding(
                        padding: const EdgeInsets.only(left: 0, right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 140,
                            height: 180,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CdnImage(
                                  l.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: isDark
                                        ? AppColors.darkWarm
                                        : AppColors.creamAlt,
                                    child: Icon(Icons.checkroom_rounded,
                                        size: 30,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                  ),
                                ),
                                // "Gallery" badge — photo count + tap hint
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.collections_rounded,
                                            size: 11, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text('${looks.length}',
                                            style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                // Bottom gradient + shop name + "Tap to view"
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 18, 10, 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l.shop.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.touch_app_rounded,
                                                size: 10,
                                                color: Colors.white70),
                                            const SizedBox(width: 3),
                                            Text('Tap to view',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                    color: Colors.white70)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ── Immersive lookbook viewer (coverflow / circular motion) ───────────────────
void _openLookbook(
    BuildContext context,
    List<({ShopShowcase shop, String path})> looks,
    int index,
    bool isDark) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) =>
          _LookbookViewer(looks: looks, initialIndex: index, isDark: isDark),
      transitionsBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _LookbookViewer extends StatefulWidget {
  final List<({ShopShowcase shop, String path})> looks;
  final int initialIndex;
  final bool isDark;
  const _LookbookViewer({
    required this.looks,
    required this.initialIndex,
    required this.isDark,
  });

  @override
  State<_LookbookViewer> createState() => _LookbookViewerState();
}

class _LookbookViewerState extends State<_LookbookViewer> {
  late final PageController _pc;
  late double _page;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.66, initialPage: widget.initialIndex);
    _page = widget.initialIndex.toDouble();
    _pc.addListener(() {
      setState(() => _page = _pc.page ?? _page);
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _page.round().clamp(0, widget.looks.length - 1);
    final currentShop = widget.looks[current].shop;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Tap outside to dismiss
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Column(
              children: [
                // Top bar: position counter (centre) + close (right)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('${current + 1} / ${widget.looks.length}',
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
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
                // Coverflow carousel + swipe chevrons
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pc,
                        itemCount: widget.looks.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (_, i) {
                          final diff = i - _page; // 0 = centred
                          final absd = diff.abs().clamp(0.0, 1.0);
                          // Circular/arc motion: side cards shrink, drop and tilt.
                          final scale = 1 - 0.22 * absd;
                          final translateY = 46.0 * absd;
                          final rotate = 0.20 * diff.clamp(-1.0, 1.0);
                          final opacity = 1 - 0.45 * absd;
                          final l = widget.looks[i];
                          return Center(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translate(0.0, translateY)
                                ..rotateZ(rotate)
                                ..scale(scale),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: _bigCard(l),
                              ),
                            ),
                          );
                        },
                      ),
                      // Directional hints — show only where more images exist
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _chevron(Icons.chevron_left_rounded,
                                    current > 0),
                                _chevron(Icons.chevron_right_rounded,
                                    current < widget.looks.length - 1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Swipe hint
                if (widget.looks.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swipe_rounded,
                          size: 14, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 6),
                      Text('Swipe to see more',
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                const SizedBox(height: 12),
                // Caption + Visit
                Text(currentShop.name,
                    style: GoogleFonts.rufina(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(currentShop.tagline,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _openShop(context, currentShop);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_rounded,
                            size: 16, color: AppColors.inkBlack),
                        const SizedBox(width: 6),
                        Text('Visit shop',
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
          ],
        ),
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

  Widget _bigCard(({ShopShowcase shop, String path}) l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CdnImage(
                l.path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.darkWarm,
                  child: const Icon(Icons.checkroom_rounded,
                      size: 48, color: Colors.white24),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
