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
import 'package:pyin_mal_app/screens/try_on_screen.dart';

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
        ],
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
            // Profile Avatar
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.burgundy,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'H',
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
                // Greeting Section
                _buildGreetingSection(isDark),
                const SizedBox(height: 32),
                
                // Today's Outfit Suggestions
                _buildOutfitSuggestionsCard(isDark, isMobile),
                const SizedBox(height: 24),
                
                // Wardrobe Recommendations
                _buildSectionLabel('Wardrobe recommendations', isDark),
                const SizedBox(height: 16),
                _buildWardrobeRecommendations(isDark, isMobile),
                const SizedBox(height: 24),
                
                // AI Styling Tools
                _buildSectionLabel('Your AI styling tools', isDark),
                const SizedBox(height: 16),
                _buildAIToolsSection(isDark),
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
        child: Image.asset(
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
    return Row(
      children: [
        Expanded(
          child: _buildWardrobeCard(
            'Seasonal Additions',
            'assets/images/Photo/summer collection.jpg',
            '+3',
            isDark,
            true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildWardrobeCard(
            'Footwear Suggestions',
            'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
            '',
            isDark,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildWardrobeCard(String title, String imagePath, String badge, bool isDark, bool isAccent) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isAccent 
            ? (isDark ? AppColors.burgundy.withOpacity(0.15) : AppColors.burgundy.withOpacity(0.08))
            : (isDark ? AppColors.darkWarm : AppColors.creamCard),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rufina(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                      ),
                    ),
                    if (badge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                      ),
                  ],
                ),
                // Small thumbnails
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: isDark ? AppColors.paleText : AppColors.inkGrey,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.checkroom,
                        color: isDark ? AppColors.paleText : AppColors.inkGrey,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  // ── AI Styling Tools Section ─────────────────────────────────────────────────
  Widget _buildAIToolsSection(bool isDark) {
    return Column(
      children: [
        _buildAIToolCard(
          'Model Try-On',
          'Preview outfits on your virtual avatar',
          Icons.view_in_ar_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelPreviewScreen())),
          isDark,
        ),
        const SizedBox(height: 12),
        _buildAIToolCard(
          'Virtual Try-On',
          'See clothes on yourself using AI',
          Icons.checkroom_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TryOnScreen())),
          isDark,
        ),
        const SizedBox(height: 12),
        _buildAIToolCard(
          'Haircut Recommendation',
          'AI-powered hairstyle suggestions',
          Icons.face_retouching_natural_rounded,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaircutScreen())),
          isDark,
        ),
        const SizedBox(height: 12),
        _buildAIToolCard(
          'Shop Outfits',
          'Browse curated fashion collections',
          Icons.store_rounded,
          () => widget.onTabRequested?.call(1),
          isDark,
        ),
        const SizedBox(height: 12),
        _buildAIToolCard(
          'Saved Looks',
          'View your favorite outfits',
          Icons.favorite_rounded,
          () => widget.onTabRequested?.call(3),
          isDark,
        ),
      ],
    );
  }

  Widget _buildAIToolCard(String title, String subtitle, IconData icon, VoidCallback onTap, bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
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
