import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/screens/shop_screen.dart';
import 'package:pyin_mal_app/screens/haircut_screen.dart';
import 'package:pyin_mal_app/screens/favorites_screen.dart';
import 'package:pyin_mal_app/screens/login_screen.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    _HomeTab(),
    ShopScreen(),
    HaircutScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _GlassNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        isDark: isDark,
      ),
    );
  }
}

// ── Glassmorphic Bottom Nav ───────────────────────────────────────────────────
class _GlassNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  const _GlassNav({required this.currentIndex, required this.onTap, required this.isDark});

  static const _items = [
    (icon: Icons.home_rounded,        outline: Icons.home_outlined,              label: 'Home'),
    (icon: Icons.store_rounded,       outline: Icons.store_outlined,             label: 'Shop'),
    (icon: Icons.content_cut_rounded, outline: Icons.content_cut_outlined,       label: 'Hair'),
    (icon: Icons.favorite_rounded,    outline: Icons.favorite_outline_rounded,   label: 'Saved'),
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
                        item.label,
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
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<Offset>> _slides;
  late final List<Animation<double>> _fades;
  int _selectedCategory = 0;

  static const _categories = ['All', 'Fashion', 'Haircut', 'Sets'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _slides = List.generate(6, (i) {
      final s = (i * 0.1).clamp(0.0, 1.0);
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOutCubic)));
    });
    _fades = List.generate(6, (i) {
      final s = (i * 0.1).clamp(0.0, 1.0);
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: _ctrl, curve: Interval(s, e)));
    });
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 640;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, isDark),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _anim(0, _buildHero(context, isMobile, isDark)),
              _anim(1, _buildCategories(context, isDark)),
              _anim(2, _buildSectionHeader(context, 'Features', isDark)),
              _anim(3, _buildFeatureRow(context, isDark)),
              _anim(4, _buildSectionHeader(context, 'Trending Now', isDark)),
              _anim(5, _buildTrendingRow(context, isDark)),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    return SliverAppBar(
      pinned: true,
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(children: [
        Container(
          width: 34, height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? AppColors.gold : AppColors.burgundy,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('PM', style: GoogleFonts.rufina(
            color: isDark ? AppColors.charcoal : Colors.white,
            fontSize: 13, fontWeight: FontWeight.bold,
          )),
        ),
        const SizedBox(width: 10),
        Text('Pyin Mal', style: GoogleFonts.rufina(
          fontSize: 22, fontWeight: FontWeight.bold,
          color: isDark ? AppColors.gold : AppColors.burgundy,
        )),
      ]),
      actions: [
        // Working theme toggle
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, __) => IconButton(
            tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                mode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey(mode),
                color: mode == ThemeMode.dark ? AppColors.gold : AppColors.inkGrey,
                size: 22,
              ),
            ),
            onPressed: toggleTheme,
          ),
        ),
        IconButton(
          icon: Icon(Icons.person_outline_rounded,
            color: isDark ? AppColors.paleText : AppColors.inkGrey, size: 22),
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────────────────
  Widget _buildHero(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      height: isMobile ? 440 : 540,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/Hero/index bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.charcoal.withOpacity(0.55),
              AppColors.charcoal.withOpacity(0.92),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('AI-Powered Style',
                style: GoogleFonts.outfit(
                  color: AppColors.charcoal, fontSize: 11,
                  fontWeight: FontWeight.bold, letterSpacing: 0.8,
                )),
            ),
            const SizedBox(height: 14),
            Text(
              'Discover Your\nPerfect Style',
              style: GoogleFonts.rufina(
                fontSize: isMobile ? 38 : 50,
                fontWeight: FontWeight.bold,
                color: Colors.white, height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-powered fashion & grooming, tailored for you.',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            // CTA buttons
            Wrap(spacing: 12, runSpacing: 12, children: [
              _heroButton(
                context, Icons.content_cut_rounded, 'Hair Try-On',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen())),
                isDark,
              ),
              _heroButton(
                context, Icons.checkroom_outlined, 'Model Preview',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen())),
                isDark,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _heroButton(BuildContext context, IconData icon, String label,
      VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withOpacity(0.55), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.goldLight, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(
            color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.bold,
          )),
        ]),
      ),
    );
  }

  // ── Category Pills ────────────────────────────────────────────────────────
  Widget _buildCategories(BuildContext context, bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        height: 42,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final sel = _selectedCategory == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 230),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: sel ? accent : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: sel ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(_categories[i],
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      color: sel ? Colors.white : (isDark ? AppColors.paleText : AppColors.inkGrey),
                    )),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.rufina(
            fontSize: 24, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
          )),
          Text('See all', style: GoogleFonts.outfit(
            fontSize: 13, color: accent, fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }

  // ── Feature Cards Row ─────────────────────────────────────────────────────
  Widget _buildFeatureRow(BuildContext context, bool isDark) {
    final features = [
      (title: 'Hair Analysis',   img: 'assets/images/Hero/ai hair recommendation.jpg', icon: Icons.face_retouching_natural_rounded,  screen: () => const HaircutScreen()),
      (title: 'Outfit Preview',  img: 'assets/images/Hero/index.jpg',                  icon: Icons.checkroom_rounded,                 screen: () => const ModelPreviewScreen()),
      (title: 'Style Studio',    img: 'assets/images/Hero/pyin mal studio1.jpg',       icon: Icons.auto_awesome_rounded,              screen: null),
    ];

    return SizedBox(
      height: 210,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: features.length,
        itemBuilder: (_, i) {
          final f = features[i];
          return GestureDetector(
            onTap: f.screen != null
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => f.screen!()))
                : null,
            child: Container(
              width: 165,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                image: DecorationImage(
                  image: AssetImage(f.img),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    AppColors.charcoal.withOpacity(0.45), BlendMode.darken,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                      ),
                      child: Icon(f.icon, color: AppColors.goldLight, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(f.title, style: GoogleFonts.rufina(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15,
                    )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Trending Cards Row ────────────────────────────────────────────────────
  Widget _buildTrendingRow(BuildContext context, bool isDark) {
    final cardBg = isDark ? AppColors.darkWarm : AppColors.creamCard;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final items = [
      (name: 'Summer Collection', img: 'assets/images/Photo/summer collection.jpg'),
      (name: 'Trending Now',      img: 'assets/images/Photo/Trendy now1.jpg'),
      (name: 'Featured Styles',   img: 'assets/images/Photo/featured style.jpg'),
    ];

    return SizedBox(
      height: 290,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 195,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 14, offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.asset(
                    item.img, fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                      child: const Icon(Icons.image, color: Colors.grey, size: 40),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, style: GoogleFonts.rufina(
                      fontWeight: FontWeight.bold, fontSize: 15,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    )),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('View →', style: GoogleFonts.outfit(
                          color: accent, fontSize: 13, fontWeight: FontWeight.bold,
                        )),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.favorite_outline_rounded,
                            color: accent, size: 16),
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
