import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';
import 'package:pyin_mal_app/widgets/guide_coach.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/screens/donate_screen.dart';

// ── Topic (for the list) + its targeted tour steps ───────────────────────────
class GuideTopicInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<GuideStepTarget> steps;
  const GuideTopicInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.steps,
  });
}

const _homeC = Color(0xFF8B1A2F);
const _shopC = Color(0xFF1565C0);
const _prodC = Color(0xFF7C6AF7);
const _cartC = Color(0xFF2E7D32);
const _aiC = Color(0xFFC9A96E);
const _donateC = Color(0xFFE07A5F);
const _appearC = Color(0xFF00897B);

// Sample product page for the Product topic.
Widget _productScreen(BuildContext _) {
  final products = ProductRepository.allProducts;
  if (products.isEmpty) {
    return const Scaffold(body: Center(child: Text('No products to preview')));
  }
  final p = products.first;
  return ProductDetailScreen(
    productId: p.id,
    name: p.name,
    price: p.price,
    image: p.image,
    brand: p.brand,
    category: p.category,
    description: p.description,
    shopName: p.shopName,
  );
}

final List<GuideTopicInfo> kGuideTopics = [
  GuideTopicInfo(
    title: 'Home & Navigation',
    subtitle: 'Find your way around the app',
    icon: Icons.home_rounded,
    color: _homeC,
    steps: [
      GuideStepTarget(
        key: GuideKeys.tabs,
        sceneId: 'home',
        tabIndex: 0,
        color: _homeC,
        where: 'Top of Home',
        title: 'For You / Services',
        body:
            '"For You" holds your personal tools. Switch to "Services" for Donate and Resell.',
      ),
      GuideStepTarget(
        key: GuideKeys.shortcuts,
        sceneId: 'home',
        tabIndex: 0,
        color: _homeC,
        where: 'Home, under the tabs',
        title: 'Quick shortcuts',
        body:
            'Tap a shortcut to jump into a tool — AI Try-On, AR Try-On, Haircut or Scan.',
      ),
      GuideStepTarget(
        key: GuideKeys.search,
        sceneId: 'home',
        tabIndex: 0,
        color: _homeC,
        where: 'Home top bar',
        title: 'Search',
        body: 'Tap here to search products by name, brand or style.',
      ),
      GuideStepTarget(
        key: GuideKeys.theme,
        sceneId: 'home',
        tabIndex: 0,
        color: _homeC,
        where: 'Home top bar',
        title: 'Theme button',
        body: 'Cycles the look: Light → Dim → Dark.',
      ),
      GuideStepTarget(
        key: GuideKeys.aiFab,
        sceneId: 'home',
        tabIndex: 0,
        color: _homeC,
        where: 'Bottom-right, any screen',
        title: 'AI stylist (✨)',
        body: 'Opens the AI chat — ask it for outfit ideas anytime.',
      ),
      GuideStepTarget(
        key: GuideKeys.bottomNav,
        sceneId: 'home',
        tabIndex: 0,
        color: _homeC,
        where: 'Bottom of every screen',
        title: 'Bottom navigation',
        body: 'Switch between Home, Shop, Hair, Saved and Delivery.',
      ),
    ],
  ),
  GuideTopicInfo(
    title: 'Finding Products',
    subtitle: 'Search and browse the shop',
    icon: Icons.storefront_rounded,
    color: _shopC,
    steps: [
      GuideStepTarget(
        key: GuideKeys.shopSearch,
        sceneId: 'shop',
        tabIndex: 1,
        color: _shopC,
        where: 'Shop tab',
        title: 'Search the shop',
        body:
            'On the Shop tab, tap the search bar and type a product, brand or style.',
      ),
    ],
  ),
  GuideTopicInfo(
    title: 'Product Page & Try-On',
    subtitle: 'View, try on and add to cart',
    icon: Icons.checkroom_rounded,
    color: _prodC,
    steps: [
      GuideStepTarget(
        key: GuideKeys.productAddToCart,
        sceneId: 'product',
        pushBuilder: _productScreen,
        color: _prodC,
        where: "A product's page",
        title: 'Add to cart',
        body:
            'Opens a sheet to choose colour, size and quantity. Swipe the photo for more angles, or use 360° / Try On above it.',
        tip: 'A size is suggested if you have done a body scan.',
      ),
    ],
  ),
  GuideTopicInfo(
    title: 'Cart & Checkout',
    subtitle: 'From cart to placing your order',
    icon: Icons.shopping_bag_rounded,
    color: _cartC,
    steps: [
      GuideStepTarget(
        sceneId: 'home',
        tabIndex: 0,
        color: _cartC,
        where: 'Bottom of shopping screens',
        title: 'View Cart bar',
        body:
            'When you add an item, a "View Cart" bar appears at the bottom with the count and total. Tap it to open your cart.',
      ),
      GuideStepTarget(
        sceneId: 'home',
        tabIndex: 0,
        color: _cartC,
        where: 'Checkout screen',
        title: 'Checkout & payment',
        body:
            'In Checkout you set your name, phone and address, pick a payment method (KBZPay, WavePay, AYA, UAB, card or cash), then Place Order.',
      ),
    ],
  ),
  GuideTopicInfo(
    title: 'AI Stylist & Tools',
    subtitle: 'Smart features that help you decide',
    icon: Icons.auto_awesome_rounded,
    color: _aiC,
    steps: [
      GuideStepTarget(
        key: GuideKeys.aiFab,
        sceneId: 'home',
        tabIndex: 0,
        color: _aiC,
        where: 'Bottom-right, any screen',
        title: 'AI Chat',
        body:
            'Describe an occasion ("office look", "weekend casual") and the assistant suggests outfits.',
      ),
      GuideStepTarget(
        key: GuideKeys.shortcuts,
        sceneId: 'home',
        tabIndex: 0,
        color: _aiC,
        where: 'Home shortcuts',
        title: 'Scan & tools',
        body:
            'Open Scan from here to find clothing in the catalog, and do a body scan once for size recommendations.',
      ),
    ],
  ),
  GuideTopicInfo(
    title: 'Donate & Give Back',
    subtitle: 'Share clothes with those in need',
    icon: Icons.volunteer_activism_rounded,
    color: _donateC,
    steps: [
      GuideStepTarget(
        key: GuideKeys.donateDirections,
        sceneId: 'donate',
        pushBuilder: (_) => const DonateScreen(),
        color: _donateC,
        where: 'Donate screen',
        title: 'Shelters near you',
        body:
            'Tap a shelter card to read about it. Use "Directions" to open Google Maps, or request a pickup / drop off your donation.',
      ),
    ],
  ),
  GuideTopicInfo(
    title: 'Appearance & Language',
    subtitle: 'Make the app yours',
    icon: Icons.palette_rounded,
    color: _appearC,
    steps: [
      GuideStepTarget(
        key: GuideKeys.theme,
        sceneId: 'home',
        tabIndex: 0,
        color: _appearC,
        where: 'Home top bar',
        title: 'Theme modes',
        body: 'Cycle Light → Dim → Dark. "Dim" is a softer light theme.',
      ),
      GuideStepTarget(
        key: GuideKeys.language,
        sceneId: 'home',
        tabIndex: 0,
        color: _appearC,
        where: 'Home top bar',
        title: 'Language',
        body: 'Switch between English and Burmese (မြန်မာ).',
      ),
    ],
  ),
];

/// The full ordered tour (used for the new-user walkthrough).
List<GuideStepTarget> buildGuideTour() =>
    [for (final t in kGuideTopics) ...t.steps];

// ── Guide list screen ─────────────────────────────────────────────────────────
class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('User Guide',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text('Show me how it works',
              style: GoogleFonts.rufina(
                  fontSize: 24, fontWeight: FontWeight.bold, color: ink)),
          const SizedBox(height: 4),
          Text(
              'Tap a topic and the app will point to the real button on screen and tell you what it does.',
              style:
                  GoogleFonts.outfit(fontSize: 13, height: 1.4, color: muted)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              final nav = Navigator.of(context, rootNavigator: true);
              nav.pop();
              GuideController.startNav(nav, buildGuideTour());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill_rounded,
                      color: isDark ? AppColors.charcoal : Colors.white,
                      size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Take the full tour',
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? AppColors.charcoal : Colors.white)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: isDark ? AppColors.charcoal : Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...kGuideTopics.map((t) => _TopicCard(topic: t, isDark: isDark)),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final GuideTopicInfo topic;
  final bool isDark;
  const _TopicCard({required this.topic, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return GestureDetector(
      onTap: () {
        // Close the list, then run the tour on the real app underneath.
        final nav = Navigator.of(context, rootNavigator: true);
        nav.pop();
        GuideController.startNav(nav, topic.steps);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(topic.icon, color: topic.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(height: 2),
                  Text(topic.subtitle,
                      style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

// ── Home-screen section that links to the guide ──────────────────────────────
class UserGuideSection extends StatelessWidget {
  final bool isDark;
  const UserGuideSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const UserGuideScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.menu_book_rounded, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Guide',
                      style: GoogleFonts.rufina(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ink)),
                  const SizedBox(height: 2),
                  Text('New here? Learn what every button does',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.paleText
                              : AppColors.inkGrey)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Open',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.charcoal : Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
