import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/screens/shop_screen.dart';
import 'package:pyin_mal_app/screens/haircut_screen.dart';
import 'package:pyin_mal_app/screens/favorites_screen.dart';
import 'package:pyin_mal_app/screens/login_screen.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    ShopScreen(),
    HaircutScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // body goes behind the bottom nav
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildGlassNav(isDark),
    );
  }

  Widget _buildGlassNav(bool isDark) {
    final bgColor = isDark
        ? Colors.black.withOpacity(0.55)
        : Colors.white.withOpacity(0.7);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home', isDark),
              _navItem(1, Icons.store_rounded, Icons.store_outlined, 'Shop', isDark),
              _navItem(2, Icons.content_cut_rounded, Icons.content_cut_outlined, 'Hair', isDark),
              _navItem(3, Icons.favorite_rounded, Icons.favorite_outline_rounded, 'Saved', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF0ea5e9)
        : (isDark ? Colors.white54 : Colors.black38);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0ea5e9).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? active : inactive,
                key: ValueKey(isSelected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.orbit(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnims = List.generate(6, (i) {
      final start = i * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOutCubic)),
      );
    });

    _fadeAnims = List.generate(6, (i) {
      final start = i * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end)),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 640;

    return CustomScrollView(
      slivers: [
        // ── App Bar ──
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF0ea5e9), shape: BoxShape.circle),
                child: const Text('PM', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text('Pyin Mal', style: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF38bdf8))),
            ],
          ),
          actions: [
            // Theme toggle ✅
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) => IconButton(
                tooltip: mode == ThemeMode.dark ? 'Switch to Light' : 'Switch to Dark',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    mode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    key: ValueKey(mode),
                    color: mode == ThemeMode.dark ? Colors.amber : const Color(0xFF6366f1),
                  ),
                ),
                onPressed: toggleTheme,
              ),
            ),
            IconButton(
              icon: Icon(Icons.person_outline_rounded, color: isDark ? Colors.white70 : Colors.black54),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
            const SizedBox(width: 8),
          ],
        ),

        SliverToBoxAdapter(
          child: Column(
            children: [
              // ── Hero ──
              _animated(0, _buildHero(context, isMobile)),

              // ── Category chips ──
              _animated(1, _buildCategories(context, isDark)),

              // ── Features ──
              _animated(2, _buildSectionTitle(context, 'Features', isDark)),
              _animated(3, _buildFeatureRow(context, isDark, isMobile)),

              // ── Trending ──
              _animated(4, _buildSectionTitle(context, 'Trending', isDark)),
              _animated(5, _buildTrendingRow(context, isDark)),

              const SizedBox(height: 100), // bottom nav clearance
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile) {
    return Container(
      height: isMobile ? 420 : 520,
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0ea5e9).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('AI-Powered Style', style: GoogleFonts.orbit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            Text('Discover Your\nPerfect Style', style: GoogleFonts.rufina(fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
            const SizedBox(height: 16),
            Row(
              children: [
                _heroBadge(context, Icons.content_cut_rounded, 'Hair Try-On', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen()))),
                const SizedBox(width: 12),
                _heroBadge(context, Icons.checkroom_outlined, 'Model Preview', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.orbit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context, bool isDark) {
    final cats = ['All', 'Fashion', 'Haircut', 'Sets', 'Grooming'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final sel = i == 0;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF0ea5e9) : (isDark ? const Color(0xFF242424) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(cats[i], style: GoogleFonts.orbit(
                fontSize: 13,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.rufina(fontSize: 26, fontWeight: FontWeight.bold)),
          Text('See all', style: GoogleFonts.orbit(fontSize: 13, color: const Color(0xFF0ea5e9))),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, bool isDark, bool isMobile) {
    final features = [
      {'title': 'Hair Analysis', 'img': 'assets/images/Hero/ai hair recommendation.jpg', 'icon': Icons.face_retouching_natural_rounded},
      {'title': 'Outfit Preview', 'img': 'assets/images/Hero/index.jpg', 'icon': Icons.checkroom_rounded},
      {'title': 'Style Studio', 'img': 'assets/images/Hero/pyin mal studio1.jpg', 'icon': Icons.auto_awesome_rounded},
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: features.length,
        itemBuilder: (_, i) {
          final f = features[i];
          return GestureDetector(
            onTap: () {
              if (i == 0) Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen()));
              if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen()));
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(f['img'] as String),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.darken),
                  onError: (e, s) {},
                ),
                color: isDark ? const Color(0xFF242424) : Colors.grey[200],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(f['icon'] as IconData, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(f['title'] as String, style: GoogleFonts.rufina(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingRow(BuildContext context, bool isDark) {
    final items = [
      {'name': 'Summer Collection', 'img': 'assets/images/Photo/summer collection.jpg', 'price': 'View →'},
      {'name': 'Trending Now', 'img': 'assets/images/Photo/Trendy now1.jpg', 'price': 'View →'},
      {'name': 'Featured Styles', 'img': 'assets/images/Photo/featured style.jpg', 'price': 'View →'},
    ];

    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.asset(
                    item['img']!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.image, color: Colors.grey, size: 40)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name']!, style: GoogleFonts.rufina(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(item['price']!, style: GoogleFonts.orbit(color: const Color(0xFF0ea5e9), fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
