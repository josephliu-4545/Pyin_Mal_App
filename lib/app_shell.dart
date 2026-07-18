import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/screens/shop_screen.dart';
import 'package:pyin_mal_app/screens/haircut_screen.dart';
import 'package:pyin_mal_app/screens/favorites_screen.dart';
import 'package:pyin_mal_app/screens/login_screen.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';
import 'package:pyin_mal_app/screens/ar_fitting_room_screen.dart';
import 'package:pyin_mal_app/screens/ar_studio_screen.dart';
import 'package:pyin_mal_app/screens/notification_screen.dart';
import 'package:pyin_mal_app/screens/ai_chat_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/screens/profile_screen.dart';
import 'package:pyin_mal_app/models/user_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pyin_mal_app/screens/subscription_screen.dart';
import 'package:pyin_mal_app/screens/scan_screen.dart';
import 'package:pyin_mal_app/screens/body_scan_screen.dart';
import 'package:pyin_mal_app/screens/donate_screen.dart';
import 'package:pyin_mal_app/screens/delivery_screen.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/screens/sale_screen.dart';
import 'package:pyin_mal_app/screens/resell_screen.dart';
import 'package:pyin_mal_app/screens/wardrobe_screen.dart';
import 'package:pyin_mal_app/screens/community_screen.dart';
import 'package:pyin_mal_app/screens/settings_screen.dart';
import 'package:pyin_mal_app/services/floating_scanner_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';
import 'package:pyin_mal_app/widgets/guide_coach.dart';
import 'package:pyin_mal_app/widgets/cart_bar.dart';
import 'package:pyin_mal_app/widgets/product_search_sheet.dart';
import 'package:pyin_mal_app/widgets/shop_showcase.dart';
import 'package:pyin_mal_app/core/constants/shop_constants.dart';
import 'package:pyin_mal_app/screens/shop_products_screen.dart';
import 'package:pyin_mal_app/screens/user_guide_screen.dart';

/// Foodpanda-style brand pink used for the bottom nav + home tabs accent.
const Color kBrandPink = Color(0xFFD70F64);

/// The off-white sheet "bump" that rises under the active tab, with a small
/// dot at the peak — the reference's caret-into-notch detail.
class _NotchBumpPainter extends CustomPainter {
  final Color sheetColor;
  final Color dotColor;
  _NotchBumpPainter(this.sheetColor, this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..cubicTo(w * 0.30, h, w * 0.34, 0, w * 0.5, 0)
      ..cubicTo(w * 0.66, 0, w * 0.70, h, w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = sheetColor);
    // Small dot at the peak.
    canvas.drawCircle(Offset(w / 2, 5), 2.6, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _NotchBumpPainter old) =>
      old.sheetColor != sheetColor || old.dotColor != dotColor;
}

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    pendingOverlayProduct.addListener(_onOverlayProduct);
    GuideNav.switchTab = _switchTab; // let the guided tour change tabs
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunGuideTour());
  }

  // Run the spotlight tour once for newly registered accounts.
  Future<void> _maybeRunGuideTour() async {
    final db = DatabaseService();
    final done = await db.isGuideCompleted();
    if (done || !mounted) return;
    GuideController.start(context, buildGuideTour(),
        onDone: () => db.markGuideCompleted());
  }

  @override
  void dispose() {
    pendingOverlayProduct.removeListener(_onOverlayProduct);
    super.dispose();
  }

  void _onOverlayProduct() {
    final p = pendingOverlayProduct.value;
    if (p == null) return;
    pendingOverlayProduct.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(
        productId:   p['id']          as String? ?? '',
        name:        p['name']        as String? ?? '',
        price:       p['price']       as String? ?? '',
        image:       p['image']       as String? ?? '',
        brand:       p['brand']       as String? ?? '',
        category:    p['category']    as String? ?? '',
        description: p['description'] as String?,
        shopName:    p['shopName']    as String?,
      )));
    });
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onTabRequested: _switchTab),
          // Shop tab relies on the shell-level cart bar (avoids a double bar).
          ShopScreen(showCartBar: false, cartIconKey: GuideKeys.shopCart),
          const HaircutScreen(),
          const FavoritesScreen(),
          const DeliveryScreen(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          key: GuideKeys.aiFab,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
          },
          backgroundColor: isDark ? AppColors.gold : AppColors.burgundy,
          child: Icon(Icons.auto_awesome_rounded, color: isDark ? AppColors.charcoal : Colors.white),
        ),
      ),
      // Cart bar stacked directly above the glass nav so both stay visible.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CartBar(),
          _GlassNav(
            key: GuideKeys.bottomNav,
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ── Glassmorphic Bottom Nav ───────────────────────────────────────────────────
class _GlassNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  const _GlassNav({super.key, required this.currentIndex, required this.onTap, required this.isDark});

  static const _items = [
    (icon: Icons.home_rounded,        outline: Icons.home_outlined,              label: 'nav.home'),
    (icon: Icons.store_rounded,       outline: Icons.store_outlined,             label: 'nav.shop'),
    (icon: Icons.content_cut_rounded, outline: Icons.content_cut_outlined,       label: 'nav.hair'),
    (icon: Icons.favorite_rounded,    outline: Icons.favorite_outline_rounded,   label: 'nav.saved'),
    (icon: Icons.local_shipping_rounded, outline: Icons.local_shipping_outlined, label: 'nav.delivery'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark
        ? AppColors.charcoal.withOpacity(0.75)
        : AppColors.creamCard.withOpacity(0.82);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.inkBlack.withOpacity(0.06),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = currentIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? accent.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          selected ? item.icon : item.outline,
                          key: ValueKey(selected),
                          color: selected ? accent : (isDark ? AppColors.paleText : AppColors.inkGrey),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: selected ? accent : (isDark ? AppColors.paleText : AppColors.inkGrey),
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final Function(int)? onTabRequested;
  const _HomeTab({this.onTabRequested});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  // ── Top tabs ──────────────────────────────────────────────────────────────
  int _homeTab = 0; // 0 = For You, 1 = My Closet

  // ── Advertisement carousel ────────────────────────────────────────────────
  final PageController _adController = PageController();
  Timer? _adTimer;
  int _adPage = 0;

  // ── Flash-sale countdown ──────────────────────────────────────────────────
  Timer? _saleTimer;
  late DateTime _saleEndsAt;
  Duration _saleRemaining = const Duration(hours: 2, minutes: 45, seconds: 30);

  // Static promo slides — always shown
  static const _staticAds = <(String, String, List<Color>, IconData, String, String, String)>[
    ('New season drop', 'Up to 40% off select styles',
        [Color(0xFF6B2737), Color(0xFFB0293F)], Icons.local_offer_rounded,
        'assets/images/ad_sale.jpg', 'HOT DEAL', 'Shop now'),
    ('AI styling, free', 'Get outfit ideas tailored to you',
        [Color(0xFF1F3A5F), Color(0xFF3D6CA8)], Icons.auto_awesome_rounded,
        'assets/images/ad_ai.jpg', 'NEW', 'Try now'),
    ('Donate & earn', 'Give clothes, earn reward points',
        [Color(0xFF2E6B4F), Color(0xFF4FA37A)], Icons.volunteer_activism_rounded,
        'assets/images/ad_donate.jpg', 'REWARDS', 'Donate'),
  ];

  // Shop slides — shops that have uploaded cover.jpg
  List<ShopInfo> _shopAdSlides = [];

  // Where each promo banner navigates when tapped (index-aligned with _ads).
  static Future<bool> _assetExists(String path) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets().contains(path);
    } catch (_) {
      return false;
    }
  }

  void _onAdTap(int i) {
    switch (i) {
      case 0:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SaleScreen()));
        break;
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AiChatScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DonateScreen()));
        break;
    }
  }

  // Bordered feature shortcuts — "For You" tools
  late final List<(String, IconData, VoidCallback)> _forYouFeatures = [
    ('AI Try-On', Icons.checkroom_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnScreen()))),
    ('AR Try-On', Icons.view_in_ar_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARFittingRoomScreen()))),
    ('360° Studio', Icons.threed_rotation_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARStudioScreen()))),
    ('Haircut', Icons.content_cut_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen()))),
    ('Scan', Icons.document_scanner_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()))),
    ('Body Measure', Icons.straighten_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BodyScanScreen()))),
  ];

  // Bordered feature shortcuts — "Services" tools
  late final List<(String, IconData, VoidCallback)> _servicesFeatures = [
    ('Donate', Icons.volunteer_activism_rounded,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonateScreen()))),
    ('Resell', Icons.sell_rounded,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ResellScreen()))),
    ('My Wardrobe', Icons.checkroom_rounded,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const WardrobeScreen()))),
    ('OOTD', Icons.auto_awesome_rounded,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CommunityScreen()))),
  ];

  List<(String, IconData, VoidCallback)> get _quickFeatures =>
      _homeTab == 0 ? _forYouFeatures : _servicesFeatures;

  List<ShopInfo> get _effectiveShopSlides =>
      _shopAdSlides.isNotEmpty ? _shopAdSlides : ShopConstants.shops;

  int get _totalAdCount => _staticAds.length + _effectiveShopSlides.length;

  @override
  void initState() {
    super.initState();
    // Let the guided tour open the custom menu overlay (Language lives there).
    GuideNav.openMenu = () => _showMenuBottomSheet(
        context, Theme.of(context).brightness == Brightness.dark);
    _loadShopAdSlides();
    _adTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_adController.hasClients) return;
      _adPage = (_adPage + 1) % _totalAdCount;
      _adController.animateToPage(
        _adPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });

    // Live flash-sale countdown that ticks every second and loops when it ends.
    _saleEndsAt = DateTime.now().add(_saleRemaining);
    _saleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      var remaining = _saleEndsAt.difference(DateTime.now());
      if (remaining.isNegative) {
        // Sale window elapsed — restart a fresh 3-hour window.
        _saleEndsAt = DateTime.now().add(const Duration(hours: 3));
        remaining = _saleEndsAt.difference(DateTime.now());
      }
      setState(() => _saleRemaining = remaining);
    });
  }

  Future<void> _loadShopAdSlides() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final shops = ShopConstants.shops
        .where((s) => assets.contains(s.bannerAsset))
        .toList();
    if (mounted) setState(() => _shopAdSlides = shops);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _saleTimer?.cancel();
    _adController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dim mode uses a layered look: a burgundy header with the tabs, then an
    // off-white rounded sheet (with a caret/notch) holding all the content.
    final isDim = themeNotifier.value == AppThemeMode.dim;

    // Content sections shown below the tabs/shortcuts (same in every mode).
    final sections = <Widget>[
      _buildAdCarousel(isDark),
      const SizedBox(height: 24),
      _buildAiHighlightSection(isDark),
      const SizedBox(height: 24),
      _buildSaleSection(isDark),
      const SizedBox(height: 24),
      _buildResellSection(isDark),
      const SizedBox(height: 28),
      ShopSpotlightSection(isDark: isDark),
      const SizedBox(height: 28),
      FeaturedShopsSection(isDark: isDark),
      const SizedBox(height: 28),
      ShopLookbookSection(isDark: isDark),
      const SizedBox(height: 28),
      UserGuideSection(isDark: isDark),
    ];

    // The header keeps each theme's own colour (burgundy only in Dim).
    final headerBand = isDim
        ? AppColors.burgundy
        : (isDark ? AppColors.charcoal : AppColors.cream);
    final headerChip = isDim
        ? Colors.white.withOpacity(0.18)
        : (isDark ? AppColors.darkWarm : AppColors.creamAlt);
    final headerIcon =
        isDim ? Colors.white : (isDark ? Colors.white : AppColors.inkBlack);
    // The content sheet that "bumps up" under the active tab.
    final sheetColor = isDim
        ? AppColors.dimSheet
        : (isDark ? AppColors.darkWarm : AppColors.creamCard);

    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: headerBand,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showMenuBottomSheet(context, isDark),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: headerChip,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: headerIcon,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showSearchBottomSheet(context, isDark),
                  child: Container(
                    key: GuideKeys.search,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: headerChip,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: headerIcon,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          leadingWidth: 104,
          actions: [

            // Notification
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()));
                  if (mounted) setState(() {}); // refresh unread badge
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: headerChip,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: headerIcon,
                        size: 20,
                      ),
                    ),
                    if (NotificationStore.unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 17, minHeight: 17),
                          child: Text(
                            '${NotificationStore.unreadCount}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Theme Toggle — cycles Light → Dim → Dark
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ValueListenableBuilder<AppThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) {
                  final icon = switch (mode) {
                    AppThemeMode.light => Icons.wb_sunny_rounded,
                    AppThemeMode.dim => Icons.brightness_4_rounded,
                    AppThemeMode.dark => Icons.nightlight_round,
                  };
                  return GestureDetector(
                    onTap: toggleTheme,
                    child: Container(
                      key: GuideKeys.theme,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: headerChip,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: headerIcon,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Subscription Plan Button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: headerChip,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Profile Avatar — opens Profile (no longer a bottom tab)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: StreamBuilder<UserProfile?>(
                  stream: DatabaseService().getUserProfile(),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final hasImage = profile?.avatarUrl?.isNotEmpty == true;
                    final initial = (profile?.displayName?.isNotEmpty == true)
                        ? profile!.displayName!.substring(0, 1).toUpperCase()
                        : 'P';
                        
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDim
                            ? Colors.white.withOpacity(0.22)
                            : AppColors.burgundy,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              placeholder: (context, url) =>
                                  const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.rufina(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.rufina(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    );
                  }
                ),
              ),
            ),
          ],
        ),
        // Main Content — burgundy header band with the tabs, then the content
        // sheet that "bumps up" under the active tab (every theme).
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: headerBand,
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  children: [
                    Padding(
                      key: GuideKeys.tabs,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildHomeTabs(isDark, onColor: isDim),
                    ),
                    // The sheet "bumps up" under the active tab (notch).
                    SizedBox(
                      height: 16,
                      child: Row(
                        children: List.generate(2, (i) {
                          final sel = _homeTab == i;
                          return Expanded(
                            child: sel
                                ? Center(
                                    child: CustomPaint(
                                      size: const Size(82, 16),
                                      painter:
                                          _NotchBumpPainter(sheetColor, headerBand),
                                    ),
                                  )
                                : const SizedBox(),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: sheetColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShortcutsCard(isDark),
                    const SizedBox(height: 20),
                    ...sections,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Greeting Section ──────────────────────────────────────────────────────
  // ── Row 1: Home tabs (For You / My Closet) ────────────────────────────────
  Widget _buildHomeTabs(bool isDark, {bool onColor = false}) {
    // onColor → tabs sit on the burgundy header (Dim): white text. The notch
    // bump below is the active indicator in every theme (no underline).
    final accent = onColor
        ? Colors.white
        : (isDark ? AppColors.gold : AppColors.burgundy);
    final muted = onColor
        ? Colors.white.withOpacity(0.6)
        : (isDark ? AppColors.paleText : AppColors.inkGrey);
    const tabs = ['For You', 'Services'];

    return Row(
      children: List.generate(tabs.length, (i) {
        final sel = _homeTab == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _homeTab = i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(tabs[i],
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? accent : muted)),
                const SizedBox(height: 2),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Row 2: Auto-sliding advertisement carousel ────────────────────────────
  Widget _buildAdCarousel(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _adController,
            itemCount: _totalAdCount,
            onPageChanged: (i) => setState(() => _adPage = i),
            itemBuilder: (_, i) {
              // Shop slides come after static slides
              if (i >= _staticAds.length) {
                final shop = _effectiveShopSlides[i - _staticAds.length];
                return _buildShopAdSlide(shop);
              }
              final ad = _staticAds[i];
              return GestureDetector(
                onTap: () => _onAdTap(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ad.$3.first.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gradient base (fallback + tint behind the image)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: ad.$3,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Optional banner image — only shown if asset exists.
                        // Place ad_sale.jpg / ad_ai.jpg / ad_donate.jpg in
                        // assets/images/ to enable; gradient shows as fallback.
                        if (ad.$5.isNotEmpty)
                          FutureBuilder<bool>(
                            future: _assetExists(ad.$5),
                            builder: (_, snap) => (snap.data == true)
                                ? Image.asset(ad.$5, fit: BoxFit.cover)
                                : const SizedBox(),
                          ),
                        // Decorative translucent circles (promo-banner feel)
                        Positioned(
                          top: -28,
                          right: -10,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -34,
                          right: 40,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        // Dark scrim so text stays readable over any image
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.10),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Badge tag (e.g. HOT DEAL / NEW / REWARDS)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.22),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(ad.$6,
                                          style: GoogleFonts.outfit(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                              color: Colors.white)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(ad.$1,
                                        style: GoogleFonts.rufina(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(ad.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            height: 1.3,
                                            color:
                                                Colors.white.withOpacity(0.9))),
                                    const SizedBox(height: 10),
                                    // Call-to-action button
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(ad.$7,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: ad.$3.last)),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_rounded,
                                              size: 13, color: ad.$3.last),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    Icon(ad.$4, color: Colors.white, size: 26),
                              ),
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
        const SizedBox(height: 10),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalAdCount, (i) {
            final sel = _adPage == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: sel ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: sel
                    ? (isDark ? AppColors.gold : AppColors.burgundy)
                    : (isDark
                        ? AppColors.paleText.withOpacity(0.4)
                        : AppColors.inkGrey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildShopAdSlide(ShopInfo shop) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ShopProductsScreen(shopName: shop.name))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(shop.bannerAsset, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A1A0E), Color(0xFF5C3317)],
                      ),
                    ),
                  )),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  ),
                ),
              ),
              Positioned(
                left: 20, right: 70, bottom: 0, top: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('SHOP SPOTLIGHT',
                          style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2)),
                    ),
                    const SizedBox(height: 8),
                    Text(shop.name,
                        style: GoogleFonts.rufina(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(shop.tagline,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Visit shop →',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkBlack)),
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

  // ── AI/AR/Scan highlight section (shown on both home tabs) ────────────────
  Widget _buildAiHighlightSection(bool isDark) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: isDark ? AppColors.gold : AppColors.burgundy),
              const SizedBox(width: 8),
              Text('Try before you buy',
                  style: GoogleFonts.rufina(
                      fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
            ],
          ),
          const SizedBox(height: 14),

          // One row — three equal feature cards
          Row(
            children: [
              Expanded(
                child: _aiFeatureCard(
                  colors: const [Color(0xFF5D4A9C), Color(0xFF8B6FD8)],
                  icon: Icons.checkroom_rounded,
                  title: 'AI Try-On',
                  desc: 'See it on your photo',
                  image:
                      'pyin-mal-assets/assets/images/Photo/featured style.jpg',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TryOnScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _aiFeatureCard(
                  colors: const [Color(0xFF1F5F8B), Color(0xFF3D9BE9)],
                  icon: Icons.threed_rotation_rounded,
                  title: '360° Studio',
                  desc: 'See every angle',
                  image:
                      'pyin-mal-assets/assets/images/Hero/pyin mal studio1.jpg',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ARStudioScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _aiFeatureCard(
                  colors: const [Color(0xFF2E6B4F), Color(0xFF52B788)],
                  icon: Icons.document_scanner_rounded,
                  title: 'Smart Scan',
                  desc: 'Scan & find it here',
                  image:
                      'pyin-mal-assets/assets/images/Male/Nrf/Tee/b_ABCD TEE_p1.jpg',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ScanScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiFeatureCard({
    required List<Color> colors,
    required IconData icon,
    required String title,
    required String desc,
    required String image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 138,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Feature photo
              CdnImage(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                ),
              ),
              // Neutral bottom scrim — keeps the photo's own colours while
              // making the white text readable.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            height: 1.25,
                            color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open',
                            style: GoogleFonts.outfit(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        const SizedBox(width: 3),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 11, color: Colors.white),
                      ],
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

  // ── Row 3: Bordered, horizontally scrollable feature shortcuts ────────────
  // Light "panel" card holding the For You/Services tabs and the feature
  // shortcuts (Foodpanda-style card on the page background).
  // The horizontal feature-shortcut row (AI Try-On, AR Try-On, Haircut, Scan).
  Widget _buildShortcutsList(bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    return SizedBox(
      key: GuideKeys.shortcuts,
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _quickFeatures.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          final f = _quickFeatures[i];
          return GestureDetector(
            onTap: f.$3,
            child: SizedBox(
              width: 62,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(f.$2, color: accent, size: 23),
                  ),
                  const SizedBox(height: 7),
                  Text(f.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ink)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Shortcuts wrapped in a card — used on the Dim-mode sheet (tabs live in the
  // burgundy header instead of this card).
  Widget _buildShortcutsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _buildShortcutsList(isDark),
    );
  }

  Widget _buildGreetingSection(bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'greeting.morning'.tr();
    } else if (hour < 17) {
      greeting = 'greeting.afternoon'.tr();
    } else {
      greeting = 'greeting.evening'.tr();
    }
    
    // Time-of-day emoji to accompany the greeting badge.
    final greetEmoji = hour < 12 ? '☀️' : (hour < 17 ? '🌤️' : '🌙');

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting badge — soft accent pill with the time-of-day emoji.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$greetEmoji  $greeting',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Name with a subtle accent underline accent.
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Hein',
                      style: GoogleFonts.rufina(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: ink,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: ' .',
                      style: GoogleFonts.rufina(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Date chip on the right.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkWarm : AppColors.creamCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
          ),
          child: Column(
            children: [
              Text(
                '${now.day}',
                style: GoogleFonts.rufina(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ink,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr.split(',').first.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: muted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, bool isDark) {
    return Text(
      title.tr(),
      style: GoogleFonts.rufina(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.inkBlack,
      ),
    );
  }

  // ── Points & Lucky Draw Banner ────────────────────────────────────────────
  Widget _buildPointsLuckyDrawBanner(bool isDark) {
    return GestureDetector(
      onTap: () => _showLuckyDrawDialog(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFC9A96E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '0 pts  ·  Bronze Rank',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Earn points for discounts',
                    style: GoogleFonts.rufina(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.casino_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Lucky Draw',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLuckyDrawDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, size: 52, color: Color(0xFFC9A96E)),
              const SizedBox(height: 16),
              Text(
                'Lucky Draw',
                style: GoogleFonts.rufina(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Reach Silver rank to unlock your first lucky draw and win exclusive discounts!',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A96E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Got it', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Outfit Suggestions Card ────────────────────────────────────────────────
  // ── On Sale section (shops with active discounts) ─────────────────────────
  // ── Resell section (community pre-loved listings) ─────────────────────────
  Widget _buildResellSection(bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final preview = resellPosts.take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.recycling_rounded, color: accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ResellScreen())),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Resell',
                              style: GoogleFonts.rufina(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: muted),
                        ],
                      ),
                      Text('Pre-loved fashion from the community',
                          style: GoogleFonts.outfit(fontSize: 11, color: muted)),
                    ],
                  ),
                ),
              ),
              // Sell yours chip
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ResellScreen())),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: accent, size: 14),
                      const SizedBox(width: 3),
                      Text('Sell',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal preview cards
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: preview.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                if (i == preview.length) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ResellScreen())),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accent.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: accent, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('See all',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accent)),
                        ],
                      ),
                    ),
                  );
                }
                final post = preview[i];
                final cc = conditionColor(post.condition);
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ResellScreen())),
                  child: Container(
                    width: 134,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              child: SizedBox(
                                height: 110,
                                width: double.infinity,
                                child: post.imageBytes != null
                                    ? Image.memory(post.imageBytes!,
                                        fit: BoxFit.cover)
                                    : CdnImage(post.displaySrc,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.creamAlt)),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cc,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(post.condition,
                                    style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.person_rounded,
                                      size: 10, color: muted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(post.seller,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                            fontSize: 10, color: muted)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(post.price,
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: accent)),
                            ],
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
      ),
    );
  }

  Widget _buildSaleSection(bool isDark) {
    const red = Color(0xFFE53935);
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    // Take a few products and pretend they carry a discount.
    final all = ProductRepository.allProducts;
    final saleItems = (all.length > 6 ? all.sublist(0, 6) : all);
    const discounts = [30, 25, 40, 20, 35, 15];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(isDark ? 0.25 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: red.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.local_fire_department_rounded,
                    color: red, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SaleScreen())),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('On Sale',
                              style: GoogleFonts.rufina(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: muted),
                        ],
                      ),
                      Text('Shops with active discounts',
                          style: GoogleFonts.outfit(fontSize: 11, color: muted)),
                    ],
                  ),
                ),
              ),
              // Countdown pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: red, size: 13),
                    const SizedBox(width: 4),
                    Text(_fmtDuration(_saleRemaining),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: red,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal product cards
          SizedBox(
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: saleItems.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                // Trailing "See all" card
                if (i == saleItems.length) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SaleScreen())),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: red.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: red, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('See all',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: red)),
                        ],
                      ),
                    ),
                  );
                }
                final p = saleItems[i];
                final off = discounts[i % discounts.length];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen.fromProduct(p, discount: off),
                    ),
                  ),
                  child: Container(
                    width: 134,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image + discount badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              child: SizedBox(
                                height: 110,
                                width: double.infinity,
                                child: CdnImage(p.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.creamAlt)),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('-$off%',
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                              const SizedBox(height: 3),
                              // Shop name
                              Row(
                                children: [
                                  Icon(Icons.storefront_rounded,
                                      size: 10, color: muted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(p.shopName ?? p.brand,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                            fontSize: 10, color: muted)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Sale price + original (strikethrough) — same layout as sale screen
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.price,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: red)),
                                  () {
                                    final match = RegExp(r'[\d,]+').firstMatch(p.price);
                                    if (match == null) return const SizedBox.shrink();
                                    final sale = int.tryParse(match.group(0)!.replaceAll(',', ''));
                                    if (sale == null) return const SizedBox.shrink();
                                    final original = (sale / (1 - off / 100)).round();
                                    final label = p.price.replaceFirst(RegExp(r'[\d,]+'), '').trim();
                                    final withSep = original.toString().replaceAllMapped(
                                        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
                                    final originalStr = '$withSep $label'.trim();
                                    return Text(originalStr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: muted,
                                            decoration: TextDecoration.lineThrough));
                                  }(),
                                ],
                              ),
                            ],
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
      ),
    );
  }

  // ── Wardrobe Recommendations ────────────────────────────────────────────────
  Widget _buildWardrobeRecommendations(bool isDark, bool isMobile) {
    final wardrobeCards = [
      _WardrobeSlide(
        title: 'Seasonal\nAdditions',
        sub: '+3 new picks',
        imagePath: 'assets/images/Photo/summer collection.jpg',
        gradient: [const Color(0xFFC9A96E), const Color(0xFFAA8550)],
      ),
      _WardrobeSlide(
        title: 'Footwear\nSuggestions',
        sub: 'Trending styles',
        imagePath: 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
        gradient: [const Color(0xFF7C6AF7), const Color(0xFF5A4DD6)],
      ),
      _WardrobeSlide(
        title: 'Top\nRated',
        sub: 'User favourites',
        imagePath: 'assets/images/Photo/summer collection.jpg',
        gradient: [const Color(0xFF52B788), const Color(0xFF3A9065)],
      ),
      _WardrobeSlide(
        title: 'New\nArrivals',
        sub: 'Just dropped',
        imagePath: 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
        gradient: [const Color(0xFF3D9BE9), const Color(0xFF2278C4)],
      ),
    ];

    final widgets = wardrobeCards.map((c) => GestureDetector(
      onTap: () => _comingSoon(c.title.replaceAll('\n', ' ')),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: c.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: c.gradient.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Opacity(
                  opacity: 0.18,
                  child: CdnImage(c.imagePath, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              ),
            ),
            Positioned(top: -20, right: -20,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.10)))),
            Positioned(top: 14, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(8)),
                child: Text('WARDROBE', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              )),
            Positioned(left: 14, bottom: 16, right: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, style: GoogleFonts.rufina(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                const SizedBox(height: 4),
                Text(c.sub, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.8))),
              ])),
          ],
        ),
      ),
    )).toList();

    return _AutoScrollRow(children: widgets, height: 200, reverse: false, pixelsPerSecond: 35);
  }


  // ── Menu Bottom Sheet ───────────────────────────────────────────────────────
  void _showMenuBottomSheet(BuildContext context, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Guest';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    late OverlayEntry entry;
    late AnimationController ctrl;

    ctrl = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 320),
    );

    final slideAnim = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));

    bool closed = false;
    void closeDrawer() {
      if (closed) return; // guard against a double-close (e.g. from the guide tour)
      closed = true;
      ctrl.reverse().then((_) {
        entry.remove();
        ctrl.dispose();
      });
    }
    // Let the guided tour close this overlay again once its step is done.
    GuideNav.closeMenu = closeDrawer;

    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dim backdrop
              GestureDetector(
                onTap: closeDrawer,
                child: FadeTransition(
                  opacity: fadeAnim,
                  child: Container(
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ),
              // Slide-in drawer panel
              SlideTransition(
                position: slideAnim,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.78,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkWarm : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 24,
                          offset: const Offset(6, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Profile header ──────────────────────────────
                          Container(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.creamAlt,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 36,
                                          color: isDark
                                              ? AppColors.paleText
                                              : AppColors.inkGrey,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                // Name
                                Text(
                                  displayName,
                                  style: GoogleFonts.rufina(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.inkBlack,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.paleText
                                          : AppColors.inkGrey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Divider
                          Divider(
                            height: 1,
                            indent: 24,
                            endIndent: 24,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.inkGrey.withOpacity(0.15),
                          ),
                          const SizedBox(height: 12),
                          // ── Menu items ──────────────────────────────────
                          _buildDrawerItem(
                            Icons.home_rounded,
                            'menu.home'.tr(),
                            () {
                              closeDrawer();
                              // Switch to Home tab in the shell
                              GuideNav.switchTab?.call(0);
                            },
                            isDark,
                          ),
                          _buildDrawerItem(
                            Icons.person_rounded,
                            'menu.profile'.tr(),
                            () {
                              closeDrawer();
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ProfileScreen()),
                                ),
                              );
                            },
                            isDark,
                          ),
                          _buildDrawerItem(
                            Icons.favorite_rounded,
                            'menu.favorites'.tr(),
                            () {
                              closeDrawer();
                              // Switch to Favourites tab (index 3) in the shell
                              GuideNav.switchTab?.call(3);
                            },
                            isDark,
                          ),
                          _buildDrawerItem(
                            Icons.settings_rounded,
                            'menu.settings'.tr(),
                            () {
                              closeDrawer();
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SettingsScreen()),
                                ),
                              );
                            },
                            isDark,
                          ),
                          _buildDrawerItem(
                            Icons.language_rounded,
                            'language.title'.tr(),
                            () {
                              closeDrawer();
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () => _showLanguageSheet(context, isDark),
                              );
                            },
                            isDark,
                            itemKey: GuideKeys.language,
                          ),
                          _buildDrawerItem(
                            Icons.help_outline_rounded,
                            'menu.user_guide'.tr(),
                            () {
                              closeDrawer();
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const UserGuideScreen()),
                                ),
                              );
                            },
                            isDark,
                          ),
                          _buildDrawerItem(
                            Icons.info_outline_rounded,
                            'menu.about'.tr(),
                            () {
                              closeDrawer();
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () => showAboutDialog(
                                  context: context,
                                  applicationName: 'Ta Chat Nhate',
                                  applicationVersion: '1.0.0',
                                  applicationLegalese:
                                      '© 2026 Ta Chat Nhate',
                                ),
                              );
                            },
                            isDark,
                          ),
                          const Spacer(),
                          // ── Sign-out ─────────────────────────────────────
                          Divider(
                            height: 1,
                            indent: 24,
                            endIndent: 24,
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.inkGrey.withOpacity(0.15),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              leading: Icon(Icons.logout_rounded,
                                  color: AppColors.burgundy, size: 22),
                              title: Text(
                                'Sign out',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.burgundy,
                                ),
                              ),
                              onTap: () {
                                closeDrawer();
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                  () => FirebaseAuth.instance.signOut(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    ctrl.forward();
  }

  Widget _buildDrawerItem(
      IconData icon, String title, VoidCallback onTap, bool isDark,
      {Key? itemKey}) {
    return Padding(
      key: itemKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: isDark ? AppColors.gold : AppColors.burgundy,
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
        ),
        onTap: onTap,
        hoverColor: isDark
            ? AppColors.darkBorder
            : AppColors.burgundy.withOpacity(0.06),
      ),
    );
  }

  // ── Search Bottom Sheet ─────────────────────────────────────────────────────
  void _showSearchBottomSheet(BuildContext context, bool isDark) {
    showProductSearch(context, isDark);
  }

  // ── AI Styling Tools Section ──────────────────────────────────────────────
  Widget _buildAIToolsSection(bool isDark) {
    final row1 = [
      _AICard(label: 'Model\nTry-On',      sub: 'Virtual avatar',    icon: Icons.view_in_ar_rounded,              color: const Color(0xFFC9A96E), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen()))),
      _AICard(label: 'Virtual\nTry-On',    sub: 'AI on yourself',    icon: Icons.checkroom_rounded,               color: const Color(0xFF7C6AF7), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnScreen()))),
      _AICard(label: '360°\nStudio',       sub: 'See every angle',   icon: Icons.threed_rotation_rounded,         color: const Color(0xFFE07A5F), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARStudioScreen()))),
      _AICard(label: 'AR Try-On\n& 3D',   sub: 'Augmented reality', icon: Icons.view_in_ar_rounded,              color: const Color(0xFF3D9BE9), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARFittingRoomScreen()))),
      _AICard(label: 'Haircut\nRec',       sub: 'AI hairstyle',      icon: Icons.face_retouching_natural_rounded, color: const Color(0xFF52B788), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen()))),
    ];
    final row2 = [
      _AICard(label: 'AI Closet\nRecs',    sub: 'Smart wardrobe',    icon: Icons.auto_awesome_rounded,            color: const Color(0xFFC9A96E), onTap: () => _comingSoon('AI Closet Recommendations')),
      _AICard(label: 'Voice\nAssistant',   sub: 'Style by voice',    icon: Icons.mic_rounded,                     color: const Color(0xFF52B788), onTap: () => _showVoiceAssistantSheet(context, isDark)),
      _AICard(label: 'Shop\nOutfits',      sub: 'Browse fashion',    icon: Icons.store_rounded,                   color: const Color(0xFFC9A96E), onTap: () => widget.onTabRequested?.call(1)),
      _AICard(label: 'Saved\nLooks',       sub: 'Your favourites',   icon: Icons.favorite_rounded,                color: const Color(0xFF7C6AF7), onTap: () => widget.onTabRequested?.call(3)),
    ];
    return Column(
      children: [
        _buildHorizontalCardRow(row1, isDark, reverse: false),
        const SizedBox(height: 12),
        _buildHorizontalCardRow(row2, isDark, reverse: true),
      ],
    );
  }

  // ── Discover & Explore Section ────────────────────────────────────────────
  Widget _buildDiscoverSection(bool isDark) {
    final items = [
      _AICard(label: 'Color\nAnalysis',     sub: 'Your palette',          icon: Icons.palette_rounded,                 color: const Color(0xFFE07A5F), onTap: () => _comingSoon('Color Analysis')),
      _AICard(label: 'Size\nRecommender',   sub: 'Perfect fit',           icon: Icons.straighten_rounded,              color: const Color(0xFF7C6AF7), onTap: () => _comingSoon('Size Recommender')),
      _AICard(label: 'Smart\nScan',         sub: 'Avoid duplicates',      icon: Icons.document_scanner_rounded,        color: const Color(0xFF52B788), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()))),
    ];
    return _buildHorizontalCardRow(items, isDark);
  }

  // ── Shared Auto-Scroll Row ────────────────────────────────────────────────
  Widget _buildHorizontalCardRow(List<_AICard> cards, bool isDark, {bool reverse = false}) {
    final widgets = cards.map((c) => _buildSlideCard(c, isDark)).toList();
    return _AutoScrollRow(children: widgets, height: 160, reverse: reverse);
  }

  Widget _buildSlideCard(_AICard card, bool isDark) {
    return GestureDetector(
      onTap: card.onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              card.color.withOpacity(isDark ? 0.85 : 0.9),
              card.color.withOpacity(isDark ? 0.55 : 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: card.color.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle top-right
            Positioned(
              top: -18, right: -18,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            // Decorative circle bottom-left
            Positioned(
              bottom: -12, left: -12,
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon pill
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(card.icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    card.label,
                    style: GoogleFonts.rufina(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    card.sub,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recycling Rewards Card ────────────────────────────────────────────────
  Widget _buildRecyclingRewardsCard(bool isDark) {
    const gold    = Color(0xFFC9A96E);
    final cardBg  = isDark ? AppColors.darkWarm   : AppColors.creamCard;
    final border  = isDark ? AppColors.darkBorder : AppColors.creamAlt;
    final titleClr = isDark ? Colors.white         : AppColors.inkBlack;
    final subClr  = isDark ? AppColors.paleText    : AppColors.inkGrey;

    return GestureDetector(
      onTap: () => _comingSoon('Clothing Recycling Rewards'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.recycling_rounded, color: gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clothing Recycling',
                      style: GoogleFonts.rufina(fontSize: 16, fontWeight: FontWeight.bold,
                          color: titleClr)),
                  Text('Recycle & earn rewards',
                      style: GoogleFonts.outfit(fontSize: 12,
                          color: subClr)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: gold),
          ],
        ),
      ),
    );
  }


  // ── Give Back Section ─────────────────────────────────────────────────────
  Widget _buildGiveBackSection(bool isDark) {
    const gold    = Color(0xFFC9A96E);
    final cardBg  = isDark ? AppColors.darkWarm   : AppColors.creamCard;
    final border  = isDark ? AppColors.darkBorder : AppColors.creamAlt;
    final titleClr = isDark ? Colors.white         : AppColors.inkBlack;
    final subClr  = isDark ? AppColors.paleText    : AppColors.inkGrey;

    return Column(
      children: [
        // ── Donate card ────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DonateScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Donate Clothes', style: GoogleFonts.rufina(
                          fontSize: 16, fontWeight: FontWeight.bold, color: titleClr)),
                      Text('Support shelters near you',
                          style: GoogleFonts.outfit(fontSize: 12, color: subClr)),
                    ],
                  )),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: gold),
                ]),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ('Hope Shelter',   Icons.home_rounded),
                      ('New Life Center', Icons.apartment_rounded),
                      ('Sunrise Home',   Icons.wb_sunny_rounded),
                      ('Safe Haven',     Icons.shield_rounded),
                    ].map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: gold.withOpacity(0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(s.$2, size: 12, color: gold),
                          const SizedBox(width: 5),
                          Text(s.$1, style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600, color: gold)),
                        ]),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Pickup + Eco row ───────────────────────────────────────────────
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _comingSoon('Pickup for Donation'),
              child: Container(
                height: 108,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_shipping_rounded, color: gold, size: 18)),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pickup', style: GoogleFonts.rufina(
                          fontSize: 14, fontWeight: FontWeight.bold, color: titleClr)),
                      Text('Schedule door pickup',
                          style: GoogleFonts.outfit(fontSize: 11, color: subClr)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _comingSoon('Sustainability Score'),
              child: Container(
                height: 108,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded, color: gold, size: 18)),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Eco Score', style: GoogleFonts.rufina(
                          fontSize: 14, fontWeight: FontWeight.bold, color: titleClr)),
                      Text('Wardrobe impact',
                          style: GoogleFonts.outfit(fontSize: 11, color: subClr)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  // ── Language Card ─────────────────────────────────────────────────────────
  // ── Helper: Coming Soon ───────────────────────────────────────────────────
  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Voice Assistant Sheet ─────────────────────────────────────────────────
  void _showVoiceAssistantSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.inkGrey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 28),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF52B788).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, size: 40, color: Color(0xFF52B788)),
            ),
            const SizedBox(height: 20),
            Text('Voice Assistant',
                style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 10),
            Text('Say something like:\n"Show me summer dresses" or "Suggest a haircut"',
                style: GoogleFonts.outfit(fontSize: 14, height: 1.6,
                    color: isDark ? AppColors.paleText : AppColors.inkGrey),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Text('Voice assistant coming soon',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold,
                    color: const Color(0xFF52B788))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Draggable Video Popup ─────────────────────────────────────────────────
  void _showDraggableVideo(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _DraggableVideoWidget(isDark: isDark),
    );
  }

  // ── Review Sheet ──────────────────────────────────────────────────────────
  void _showReviewSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 420,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.inkGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Community Reviews',
                style: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildReviewItem('Thida K.', 5, 'The quality is amazing! Fits perfectly.', isDark),
                  _buildReviewItem('Aung M.', 4, 'Great style, slightly long delivery.', isDark),
                  _buildReviewItem('Su Su', 5, 'Love the fabric, very comfortable.', isDark),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); _comingSoon('Write a Review'); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A96E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('Write a Review', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String name, int stars, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFFC9A96E).withOpacity(0.2),
              child: Text(name[0], style: GoogleFonts.rufina(color: const Color(0xFFC9A96E), fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13,
                      color: isDark ? Colors.white : AppColors.inkBlack)),
                  const SizedBox(width: 8),
                  Text('★' * stars, style: const TextStyle(color: Color(0xFFC9A96E), fontSize: 12)),
                ]),
                const SizedBox(height: 3),
                Text(text, style: GoogleFonts.outfit(fontSize: 13,
                    color: isDark ? AppColors.paleText : AppColors.inkGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Language Sheet ────────────────────────────────────────────────────────
  void _showLanguageSheet(BuildContext context, bool isDark) {
    final languages = [
      (code: '🇬🇧', name: 'English', native: 'English', locale: const Locale('en')),
      (code: '🇲🇲', name: 'Burmese', native: 'မြန်မာဘာသာ', locale: const Locale('my')),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.inkGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('language.select'.tr(), style: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 16),
            ...languages.map((l) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(l.code, style: const TextStyle(fontSize: 24)),
              title: Text(l.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.inkBlack)),
              subtitle: Text(l.native, style: GoogleFonts.outfit(fontSize: 13,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey)),
              trailing: context.locale == l.locale
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFC9A96E), borderRadius: BorderRadius.circular(8)),
                      child: Text('language.active'.tr(), style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)))
                  : Text('language.coming_soon'.tr(), style: GoogleFonts.outfit(fontSize: 11,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey)),
              onTap: () {
                Navigator.pop(context);
                if (l.locale != null) {
                  context.setLocale(l.locale!);
                } else {
                  _comingSoon('${l.name} language');
                }
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAIToolCard(String title, String subtitle, IconData icon, VoidCallback onTap, bool isDark, {Color? badgeColor}) {
    final accent = badgeColor ?? (isDark ? AppColors.gold : AppColors.burgundy);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.rufina(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: accent,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Draggable Video Widget ────────────────────────────────────────────────────
class _DraggableVideoWidget extends StatefulWidget {
  final bool isDark;
  const _DraggableVideoWidget({required this.isDark});
  @override
  State<_DraggableVideoWidget> createState() => _DraggableVideoWidgetState();
}

class _DraggableVideoWidgetState extends State<_DraggableVideoWidget> {
  Offset _position = const Offset(40, 120);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() => _position += d.delta),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Container(
                            height: 140,
                            color: const Color(0xFFC9A96E).withOpacity(0.2),
                            child: const Center(
                              child: Icon(Icons.play_circle_fill_rounded, size: 52, color: Color(0xFFC9A96E)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Style Lookbook', style: GoogleFonts.rufina(fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark ? Colors.white : AppColors.inkBlack)),
                          const SizedBox(height: 3),
                          Text('Drag me anywhere · Coming soon',
                              style: GoogleFonts.outfit(fontSize: 11,
                                  color: widget.isDark ? AppColors.paleText : AppColors.inkGrey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Auto-Scrolling Row Widget ─────────────────────────────────────────────────
class _AutoScrollRow extends StatelessWidget {
  final List<Widget> children;
  final bool reverse;
  final double height;
  final double pixelsPerSecond; // kept for call-site compatibility; unused

  const _AutoScrollRow({
    required this.children,
    required this.height,
    this.reverse = false,
    this.pixelsPerSecond = 45,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

// ── Data models for slide cards ───────────────────────────────────────────────
class _AICard {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AICard({required this.label, required this.sub, required this.icon, required this.color, required this.onTap});
}

class _WardrobeSlide {
  final String title;
  final String sub;
  final String imagePath;
  final List<Color> gradient;
  const _WardrobeSlide({required this.title, required this.sub, required this.imagePath, required this.gradient});
}

