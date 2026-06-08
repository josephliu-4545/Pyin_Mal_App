import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/screens/shop_screen.dart';
import 'package:pyin_mal_app/screens/haircut_screen.dart';
import 'package:pyin_mal_app/screens/favorites_screen.dart';
import 'package:pyin_mal_app/screens/login_screen.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';
import 'package:pyin_mal_app/screens/ai_chat_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/screens/profile_screen.dart';
import 'package:pyin_mal_app/screens/scan_screen.dart';
import 'package:pyin_mal_app/screens/donate_screen.dart';

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

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
          const ShopScreen(),
          const HaircutScreen(),
          const FavoritesScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
          },
          backgroundColor: isDark ? AppColors.gold : AppColors.burgundy,
          child: Icon(Icons.auto_awesome_rounded, color: isDark ? AppColors.charcoal : Colors.white),
        ),
      ),
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
    (icon: Icons.person_rounded,      outline: Icons.person_outline_rounded,     label: 'Profile'),
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
  final Function(int)? onTabRequested;
  const _HomeTab({this.onTabRequested});
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: GestureDetector(
              onTap: () => _showMenuBottomSheet(context, isDark),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                  size: 20,
                ),
              ),
            ),
          ),
          actions: [
            // Search
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showSearchBottomSheet(context, isDark),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Notification
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications')),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Theme Toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) => GestureDetector(
                  onTap: toggleTheme,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mode == ThemeMode.dark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Profile Avatar - Removed from top nav since we have a bottom tab
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => widget.onTabRequested?.call(4),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.burgundy,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'P',
                      style: GoogleFonts.rufina(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Main Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──────────────────────────────────────────────
                _buildGreetingSection(isDark),
                const SizedBox(height: 20),

                // ── Points & Lucky Draw ────────────────────────────────────
                _buildPointsLuckyDrawBanner(isDark),
                const SizedBox(height: 24),

                // ── Weather Suggestion ─────────────────────────────────────
                _buildWeatherSuggestionCard(isDark),
                const SizedBox(height: 24),

                // ── Today's Outfit ─────────────────────────────────────────
                _buildOutfitSuggestionsCard(isDark, isMobile),
                const SizedBox(height: 28),

                // ── AI Styling Tools ───────────────────────────────────────
                _buildSectionLabel('AI styling tools', isDark),
                const SizedBox(height: 16),
                _buildAIToolsSection(isDark),
                const SizedBox(height: 28),

                // ── Discover & Explore ─────────────────────────────────────
                _buildSectionLabel('Discover & explore', isDark),
                const SizedBox(height: 16),
                _buildDiscoverSection(isDark),
                const SizedBox(height: 28),

                // ── Wardrobe & Recycling ───────────────────────────────────
                _buildSectionLabel('Your wardrobe', isDark),
                const SizedBox(height: 16),
                _buildWardrobeRecommendations(isDark, isMobile),
                const SizedBox(height: 16),
                _buildRecyclingRewardsCard(isDark),
                const SizedBox(height: 28),

                // ── Community ─────────────────────────────────────────────
                _buildSectionLabel('Community', isDark),
                const SizedBox(height: 16),
                _buildCommunitySection(isDark),
                const SizedBox(height: 28),

                // ── Give Back ─────────────────────────────────────────────
                _buildSectionLabel('Give back', isDark),
                const SizedBox(height: 16),
                _buildGiveBackSection(isDark),
                const SizedBox(height: 28),

                // ── Delivery ──────────────────────────────────────────────
                _buildSectionLabel('Your orders', isDark),
                const SizedBox(height: 16),
                _buildDeliverySection(isDark),
                const SizedBox(height: 28),

                // ── Language ──────────────────────────────────────────────
                _buildLanguageCard(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Greeting Section ──────────────────────────────────────────────────────
  Widget _buildGreetingSection(bool isDark) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'good morning,';
    } else if (hour < 17) {
      greeting = 'good afternoon,';
    } else {
      greeting = 'good evening,';
    }
    
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.rufina(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.paleText : AppColors.inkGrey,
            height: 1.2,
          ),
        ),
        Text(
          'Hein',
          style: GoogleFonts.rufina(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? AppColors.paleText : AppColors.inkGrey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String title, bool isDark) {
    return Text(
      title,
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

  // ── Weather-Based Suggestion Card ─────────────────────────────────────────
  Widget _buildWeatherSuggestionCard(bool isDark) {
    final hour = DateTime.now().hour;
    final isHot = hour >= 10 && hour <= 17;
    final weatherLabel = isHot ? 'Warm & Sunny' : 'Cool & Breezy';
    final suggestion = isHot
        ? 'Light fabrics — linen shirts, breathable tees'
        : 'Layer up — a jacket or cardigan works great';
    final weatherIcon = isHot ? Icons.wb_sunny_rounded : Icons.air_rounded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.gold : AppColors.burgundy).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(weatherIcon, color: isDark ? AppColors.gold : AppColors.burgundy, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Weather Pick  ·  ',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? AppColors.paleText : AppColors.inkGrey,
                      ),
                    ),
                    Text(
                      weatherLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.gold : AppColors.burgundy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Outfit Suggestions Card ────────────────────────────────────────────────
  Widget _buildOutfitSuggestionsCard(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's outfit suggestions",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Casual',
                    style: GoogleFonts.rufina(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Perfect for creative workspaces, weekend brunches, or urban exploring',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Clothing Thumbnails
          Row(
            children: [
              _buildClothingThumbnail('assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg', isDark),
              const SizedBox(width: 12),
              _buildClothingThumbnail('assets/images/Male/Nrf/Tee/ABCD TEE.jpg', isDark),
              const SizedBox(width: 12),
              _buildClothingThumbnail('assets/images/Male/Set/outfit set from sian store/', isDark),
              const SizedBox(width: 12),
              _buildClothingThumbnail('assets/images/Female/dress.set/Luna/luna set1.jpg', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClothingThumbnail(String assetPath, bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CdnImage(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Icon(
            Icons.image_outlined,
            color: isDark ? AppColors.paleText : AppColors.inkGrey,
            size: 24,
          ),
        ),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.inkGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuItem(Icons.person_rounded, 'Profile', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            }, isDark),
            _buildMenuItem(Icons.settings_rounded, 'Settings', () => Navigator.pop(context), isDark),
            _buildMenuItem(Icons.info_outline_rounded, 'About Pyin Mal', () => Navigator.pop(context), isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : AppColors.inkBlack),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: isDark ? Colors.white : AppColors.inkBlack,
        ),
      ),
      onTap: onTap,
    );
  }

  // ── Search Bottom Sheet ─────────────────────────────────────────────────────
  void _showSearchBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Search',
              style: GoogleFonts.rufina(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products, styles...',
                  hintStyle: GoogleFonts.outfit(
                    color: isDark ? AppColors.paleText : AppColors.inkGrey,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? AppColors.paleText : AppColors.inkGrey,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : AppColors.inkBlack,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search coming soon',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? AppColors.paleText : AppColors.inkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Styling Tools Section ──────────────────────────────────────────────
  Widget _buildAIToolsSection(bool isDark) {
    final row1 = [
      _AICard(label: 'Model\nTry-On',      sub: 'Virtual avatar',    icon: Icons.view_in_ar_rounded,              color: const Color(0xFFC9A96E), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen()))),
      _AICard(label: 'Virtual\nTry-On',    sub: 'AI on yourself',    icon: Icons.checkroom_rounded,               color: const Color(0xFF7C6AF7), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnScreen()))),
      _AICard(label: 'AR Try-On\n& 3D',   sub: 'Augmented reality', icon: Icons.view_in_ar_rounded,              color: const Color(0xFF3D9BE9), onTap: () => _comingSoon('AR Try-On & 3D Models')),
      _AICard(label: 'Fitting\nRoom',      sub: 'Virtual dressing',  icon: Icons.door_sliding_rounded,            color: const Color(0xFFE07A5F), onTap: () => _comingSoon('Virtual Fitting Room')),
      _AICard(label: 'Haircut\nRec',       sub: 'AI hairstyle',      icon: Icons.face_retouching_natural_rounded, color: const Color(0xFF52B788), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen()))),
    ];
    final row2 = [
      _AICard(label: 'Body\nMeasure',      sub: 'AI precision',      icon: Icons.straighten_rounded,              color: const Color(0xFFE07A5F), onTap: () => _comingSoon('Body Measurement AI')),
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
      _AICard(label: 'Regional\nFashion',   sub: 'Trending near you',     icon: Icons.public_rounded,                  color: const Color(0xFF3D9BE9), onTap: () => _comingSoon('Regional Fashion')),
      _AICard(label: 'Size\nRecommender',   sub: 'Perfect fit',           icon: Icons.straighten_rounded,              color: const Color(0xFF7C6AF7), onTap: () => _comingSoon('Size Recommender')),
      _AICard(label: 'Outfit\nSharing',     sub: 'Community looks',       icon: Icons.people_alt_rounded,              color: const Color(0xFFE07A5F), onTap: () => _comingSoon('Outfit Sharing')),
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

  // ── Community Section ─────────────────────────────────────────────────────
  // ── Community Section ─────────────────────────────────────────────────────
  Widget _buildCommunitySection(bool isDark) {
    const gold = Color(0xFFC9A96E);
    final reviews = [
      (name: 'Thida K.',  stars: 5, text: '"Amazing quality, fits perfectly!"',   avatar: 'T'),
      (name: 'Aung M.',   stars: 4, text: '"Great style, slightly long delivery"', avatar: 'A'),
      (name: 'Su Su',     stars: 5, text: '"Love the fabric, super comfortable"',  avatar: 'S'),
      (name: 'Kyaw Z.',   stars: 4, text: '"Nice colour, would buy again"',        avatar: 'K'),
    ];

    final cardBg   = isDark ? AppColors.darkWarm    : AppColors.creamCard;
    final border   = isDark ? AppColors.darkBorder  : AppColors.creamAlt;
    final titleClr = isDark ? Colors.white           : AppColors.inkBlack;
    final subClr   = isDark ? AppColors.paleText     : AppColors.inkGrey;

    return Column(
      children: [
        // ── Reviews card ───────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showReviewSheet(context, isDark),
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
                    child: const Icon(Icons.star_rounded, color: gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Community Reviews', style: GoogleFonts.rufina(
                          fontSize: 16, fontWeight: FontWeight.bold, color: titleClr)),
                      Text('Real feedback from the community',
                          style: GoogleFonts.outfit(fontSize: 12, color: subClr)),
                    ],
                  )),
                  GestureDetector(
                    onTap: () => _showReviewSheet(context, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: gold.withOpacity(0.3)),
                      ),
                      child: Text('See all', style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.bold, color: gold)),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final r = reviews[i];
                      return Container(
                        width: 195,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.charcoal : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(radius: 12,
                                backgroundColor: gold.withOpacity(0.15),
                                child: Text(r.avatar, style: GoogleFonts.rufina(
                                    fontSize: 11, color: gold, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 7),
                              Text(r.name, style: GoogleFonts.outfit(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: titleClr)),
                              const Spacer(),
                              Row(children: List.generate(r.stars, (_) =>
                                Icon(Icons.star_rounded, size: 10, color: gold))),
                            ]),
                            const SizedBox(height: 8),
                            Text(r.text, style: GoogleFonts.outfit(
                                fontSize: 11, color: subClr, height: 1.4),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showReviewSheet(context, isDark),
                    icon: Icon(Icons.edit_rounded, size: 14, color: gold),
                    label: Text('Write a Review', style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.bold, color: gold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: BorderSide(color: gold.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Style Videos ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showDraggableVideo(context, isDark),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.play_circle_rounded, color: gold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Style Videos', style: GoogleFonts.rufina(
                      fontSize: 15, fontWeight: FontWeight.bold, color: titleClr)),
                  Text('Drag-around fashion lookbooks',
                      style: GoogleFonts.outfit(fontSize: 12, color: subClr)),
                ],
              )),
              Icon(Icons.arrow_forward_ios_rounded, size: 13, color: gold),
            ]),
          ),
        ),
      ],
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

  // ── Delivery Section ──────────────────────────────────────────────────────
  Widget _buildDeliverySection(bool isDark) {
    const gold    = Color(0xFFC9A96E);
    final cardBg  = isDark ? AppColors.darkWarm   : AppColors.creamCard;
    final border  = isDark ? AppColors.darkBorder : AppColors.creamAlt;
    final titleClr = isDark ? Colors.white         : AppColors.inkBlack;
    final subClr  = isDark ? AppColors.paleText    : AppColors.inkGrey;

    return Column(
      children: [
        // ── Live tracking card ─────────────────────────────────────────────
        GestureDetector(
          onTap: () => _comingSoon('Live Delivery Tracking'),
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
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: gold, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Delivery Tracking', style: GoogleFonts.rufina(
                          fontSize: 16, fontWeight: FontWeight.bold, color: titleClr)),
                      Text('Track your orders in real-time',
                          style: GoogleFonts.outfit(fontSize: 12, color: subClr)),
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withOpacity(0.3)),
                    ),
                    child: Text('LIVE', style: GoogleFonts.outfit(
                        fontSize: 9, fontWeight: FontWeight.bold, color: gold, letterSpacing: 1)),
                  ),
                ]),
                const SizedBox(height: 16),
                // Order tracker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Order #PM2048', style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.bold, color: titleClr)),
                        Text('Est. 2:30 PM', style: GoogleFonts.outfit(
                            fontSize: 12, color: gold, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        _buildTrackStep('Placed',    true,  isDark),
                        _buildTrackLine(true),
                        _buildTrackStep('Packed',    true,  isDark),
                        _buildTrackLine(true),
                        _buildTrackStep('On way',    true,  isDark),
                        _buildTrackLine(false),
                        _buildTrackStep('Delivered', false, isDark),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── AI prediction card ─────────────────────────────────────────────
        GestureDetector(
          onTap: () => _comingSoon('AI Delivery Prediction'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: gold, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Delivery Prediction', style: GoogleFonts.rufina(
                      fontSize: 15, fontWeight: FontWeight.bold, color: titleClr)),
                  Text('Smarter ETA powered by AI',
                      style: GoogleFonts.outfit(fontSize: 12, color: subClr)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: Text('Soon', style: GoogleFonts.outfit(
                    fontSize: 10, fontWeight: FontWeight.bold, color: gold)),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackStep(String label, bool done, bool isDark) {
    return Column(
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? const Color(0xFFC9A96E) : (isDark ? AppColors.darkBorder : AppColors.creamAlt),
            border: Border.all(
              color: done ? const Color(0xFFC9A96E) : (isDark ? AppColors.darkBorder : AppColors.creamAlt),
              width: 2,
            ),
          ),
          child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
        ),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600,
            color: done ? const Color(0xFFC9A96E) : (isDark ? AppColors.paleText : AppColors.inkGrey))),
      ],
    );
  }

  Widget _buildTrackLine(bool done) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFC9A96E) : (AppColors.inkGrey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Language Card ─────────────────────────────────────────────────────────
  Widget _buildLanguageCard(bool isDark) {
    return GestureDetector(
      onTap: () => _showLanguageSheet(context, isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A96E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFFC9A96E), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Language / ဘာသာစကား',
                      style: GoogleFonts.rufina(fontSize: 15, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.inkBlack)),
                  Text('English · မြန်မာ · Multi-language support',
                      style: GoogleFonts.outfit(fontSize: 13,
                          color: isDark ? AppColors.paleText : AppColors.inkGrey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC9A96E)),
          ],
        ),
      ),
    );
  }

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
      (code: '🇬🇧', name: 'English', native: 'English'),
      (code: '🇲🇲', name: 'Burmese', native: 'မြန်မာဘာသာ'),
      (code: '🇨🇳', name: 'Chinese', native: '中文'),
      (code: '🇯🇵', name: 'Japanese', native: '日本語'),
      (code: '🇹🇭', name: 'Thai', native: 'ภาษาไทย'),
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
            Text('Select Language', style: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.inkBlack)),
            const SizedBox(height: 16),
            ...languages.map((l) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(l.code, style: const TextStyle(fontSize: 24)),
              title: Text(l.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.inkBlack)),
              subtitle: Text(l.native, style: GoogleFonts.outfit(fontSize: 13,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey)),
              trailing: l.name == 'English'
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFC9A96E), borderRadius: BorderRadius.circular(8)),
                      child: Text('Active', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)))
                  : Text('Coming soon', style: GoogleFonts.outfit(fontSize: 11,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey)),
              onTap: () { Navigator.pop(context); if (l.name != 'English') _comingSoon('${l.name} language'); },
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
class _AutoScrollRow extends StatefulWidget {
  final List<Widget> children;
  final bool reverse;
  final double height;
  final double pixelsPerSecond;

  const _AutoScrollRow({
    required this.children,
    required this.height,
    this.reverse = false,
    this.pixelsPerSecond = 45,
  });

  @override
  State<_AutoScrollRow> createState() => _AutoScrollRowState();
}

class _AutoScrollRowState extends State<_AutoScrollRow> with SingleTickerProviderStateMixin {
  late final ScrollController _ctrl;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _ready = false;
  bool _userTouching = false;

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    if (!mounted || !_ctrl.hasClients) return;
    final max = _ctrl.position.maxScrollExtent;
    _ctrl.jumpTo(max / 3);
    _ready = true;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_ready || !mounted || !_ctrl.hasClients || _userTouching) {
      _last = elapsed; // keep time in sync so no position jump on resume
      return;
    }
    final dt = _last == Duration.zero ? 0.0 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final max = _ctrl.position.maxScrollExtent;
    if (max <= 0) return;

    double next;
    if (widget.reverse) {
      next = _ctrl.offset - widget.pixelsPerSecond * dt;
      if (next <= 0) next = max / 3 * 2;
    } else {
      next = _ctrl.offset + widget.pixelsPerSecond * dt;
      if (next >= max) next = max / 3;
    }
    _ctrl.jumpTo(next.clamp(0, max));
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final looped = [...widget.children, ...widget.children, ...widget.children];
    return Listener(
      onPointerDown: (_) => _userTouching = true,
      onPointerUp: (_) => _userTouching = false,
      onPointerCancel: (_) => _userTouching = false,
      child: SizedBox(
        height: widget.height,
        child: ListView.separated(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          // Allow user to fling/drag freely
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: looped.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => looped[i],
        ),
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
