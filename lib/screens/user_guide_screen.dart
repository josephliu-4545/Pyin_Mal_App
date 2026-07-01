import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';
import 'package:pyin_mal_app/widgets/guide_coach.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/screens/donate_screen.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';
import 'package:pyin_mal_app/screens/ar_fitting_room_screen.dart';
import 'package:pyin_mal_app/screens/haircut_screen.dart';
import 'package:pyin_mal_app/screens/scan_screen.dart';
import 'package:pyin_mal_app/screens/body_scan_screen.dart';
import 'package:pyin_mal_app/screens/resell_screen.dart';

// ── Topic (for the list) + its targeted tour steps ───────────────────────────
class GuideTopicInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<GuideStepTarget> steps;
  // Written, numbered how-to instructions shown on the detail page.
  final List<String> howTo;
  // Optional closing tip line.
  final String? tip;
  // Optional screen to open for "Show me on screen" when there is no
  // on-screen coach tour (e.g. features that live on their own page).
  final WidgetBuilder? open;
  const GuideTopicInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.steps = const [],
    this.howTo = const [],
    this.tip,
    this.open,
  });
}

const _homeC = Color(0xFF8B1A2F);
const _shopC = Color(0xFF1565C0);
const _prodC = Color(0xFF7C6AF7);
const _cartC = Color(0xFF2E7D32);
const _aiC = Color(0xFFC9A96E);
const _donateC = Color(0xFFE07A5F);
const _appearC = Color(0xFF00897B);
const _tryonC = Color(0xFF7C6AF7);
const _arC = Color(0xFF3D9BE9);
const _hairC = Color(0xFFB5651D);
const _scanC = Color(0xFF52B788);
const _bodyC = Color(0xFF00897B);
const _resellC = Color(0xFFCB7A2B);

// Sample product page for the Product topic.
Widget _productScreen(BuildContext _) {
  final products = ProductRepository.allProducts;
  if (products.isEmpty) {
    return Scaffold(body: Center(child: Text('guide.no_preview'.tr())));
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
    howTo: [
      'The Home screen opens on the "For You" tab — your personal tools and recommendations.',
      'Tap "Services" next to it to reach Donate and Resell.',
      'Under the tabs is a row of quick shortcuts: AI Try-On, AR Try-On, Haircut, Scan and Body Measure.',
      'Use the bottom navigation bar to move between Home, Shop, Hair, Saved and Delivery.',
      'The ✨ button at the bottom-right opens the AI stylist chat from any screen.',
      'Use the search bar and theme button in the top bar to find items or change the light/dark look.',
    ],
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
    howTo: [
      'Tap "Shop" in the bottom navigation bar.',
      'Use the search bar at the top to type a product, brand or style.',
      'Tap a category pill (Women, Men, Coats…) to filter what you see.',
      'Browse the shops row to open a single shop and view all of its products.',
      'Tap any product card to open its full product page.',
    ],
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
    title: 'Product Page & Add to Cart',
    subtitle: 'View, choose options and buy',
    icon: Icons.checkroom_rounded,
    color: _prodC,
    howTo: [
      'Swipe the main photo to see more angles, or tap 360° to spin the item.',
      'Use the colour thumbnails to preview different colourways.',
      'Open "Size Guide" and switch to the Body Chart tab to get a recommended size from your measurements.',
      'Tap "Add to cart", then pick colour, size and quantity in the sheet.',
      'Scroll down to read reviews, the shop info and product details.',
    ],
    tip: 'A size is suggested automatically if you have done a body scan.',
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
    title: 'AI Try-On (Virtual Try-On)',
    subtitle: 'See clothes on your own photo',
    icon: Icons.auto_fix_high_rounded,
    color: _tryonC,
    howTo: [
      'Open AI Try-On from the Home shortcuts, or tap "Try On" on a product page.',
      'Add a clear, full-body photo of yourself — take a new one or pick from your gallery.',
      'Add the clothing you want to try: choose a catalog item, or upload a photo of a top, bottom or shoes.',
      'Tap "Try On" / "Generate" and wait a few seconds while the AI dresses your photo.',
      'Review the result. Swap garments and generate again to compare looks.',
      'Save the image or go straight to the product to add it to your cart.',
    ],
    tip: 'Use good lighting and a plain background for the most realistic result.',
    open: (_) => const TryOnScreen(),
  ),
  GuideTopicInfo(
    title: 'AR Try-On & 3D',
    subtitle: 'Live camera augmented reality',
    icon: Icons.view_in_ar_rounded,
    color: _arC,
    howTo: [
      'Open AR Try-On from the Home shortcuts.',
      'Allow camera permission the first time you use it.',
      'Stand back so your upper body is fully in the frame — the app tracks your shoulders and hips.',
      'Pick a garment from the selector at the bottom; it appears overlaid on you in real time.',
      'Move around to see the fit from different angles.',
      'Tap the capture button to save a snapshot, or add the item to your cart.',
    ],
    tip: 'Front camera works best for a selfie-style try-on.',
    open: (_) => const ARFittingRoomScreen(),
  ),
  GuideTopicInfo(
    title: 'Haircut & Booking',
    subtitle: 'Try hairstyles and book a salon',
    icon: Icons.content_cut_rounded,
    color: _hairC,
    howTo: [
      'Open "Hair" from the bottom navigation, or Haircut from the Home shortcuts.',
      'Use the Women / Men toggle, then browse the hairstyle gallery by category.',
      'Tap a style to preview it; some styles let you try the look on a photo.',
      'Tap "Book now" (or "Book now with this style") to start a booking.',
      'Choose a salon (V47, VIP Salon, T8, Tony Tun Tun or Neighborhood) and tick the services you want.',
      'Tap "Confirm booking", fill in your name, phone, branch, date and time, then confirm.',
    ],
    tip: 'Only one salon can be in a single booking — switching salons resets your selection.',
    open: (_) => const HaircutScreen(),
  ),
  GuideTopicInfo(
    title: 'Smart Scan',
    subtitle: 'Find clothing with your camera',
    icon: Icons.document_scanner_rounded,
    color: _scanC,
    howTo: [
      'Open Scan from the Home shortcuts, or the scan icon in the Shop search bar.',
      'Point your camera at a garment, or upload a photo of one.',
      'The app analyses it and shows matching or similar items from the catalog.',
      'Tap a result to open its product page and add it to your cart.',
    ],
    tip: 'Scan items you already own to avoid buying duplicates.',
    open: (_) => const ScanScreen(),
  ),
  GuideTopicInfo(
    title: 'Body Measurements',
    subtitle: 'Scan once for better sizes',
    icon: Icons.straighten_rounded,
    color: _bodyC,
    howTo: [
      'Open Body Measure from the Home shortcuts.',
      'Follow the on-screen prompts and allow camera access.',
      'Stand at the suggested distance and hold the pose while it captures your measurements.',
      'Review your saved measurements (bust, waist, hips and more).',
      'From now on, product pages will suggest the size that fits you best.',
    ],
    tip: 'You only need to do this once; you can re-scan anytime to update it.',
    open: (_) => const BodyScanScreen(),
  ),
  GuideTopicInfo(
    title: 'Cart & Checkout',
    subtitle: 'From cart to placing your order',
    icon: Icons.shopping_bag_rounded,
    color: _cartC,
    howTo: [
      'When you add an item, a "View Cart" bar appears at the bottom with the count and total.',
      'Tap it to open your cart, where you can change quantities or remove items.',
      'Tap "Checkout" to continue.',
      'Enter your name, phone and delivery address.',
      'Pick a payment method: KBZPay, WavePay, AYA, UAB, card or cash on delivery.',
      'Tap "Place Order" to confirm. Track it later from the Delivery tab.',
    ],
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
    title: 'AI Stylist Chat',
    subtitle: 'Ask for outfit ideas anytime',
    icon: Icons.auto_awesome_rounded,
    color: _aiC,
    howTo: [
      'Tap the ✨ button at the bottom-right of any screen.',
      'Describe an occasion or mood, e.g. "office look" or "weekend casual".',
      'The assistant suggests outfits and pieces that match.',
      'Tap a suggested item to open it and add it to your cart.',
      'Keep chatting to refine the look or ask for alternatives.',
    ],
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
    howTo: [
      'Open the "Services" tab on Home, then tap Donate.',
      'Browse shelters and drop-off points near you.',
      'Tap a shelter card to read about it and what it accepts.',
      'Use "Directions" to open it in Google Maps.',
      'Request a pickup or drop off your donation to earn reward points.',
    ],
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
    title: 'Resell Your Clothes',
    subtitle: 'List items and chat with buyers',
    icon: Icons.sell_rounded,
    color: _resellC,
    howTo: [
      'Open the "Services" tab on Home, then tap Resell.',
      'Tap "+ Sell" to create a listing.',
      'Add a photo, then fill in the name, price, size and condition.',
      'Post it — your item appears in the Resell feed for others to see.',
      'Buyers tap "Message" to chat with you about the item.',
      'When ready, the buyer taps "Buy now" to add it to their cart.',
    ],
    tip: 'Clear photos and honest condition labels sell faster.',
    open: (_) => const ResellScreen(),
  ),
  GuideTopicInfo(
    title: 'Appearance & Language',
    subtitle: 'Make the app yours',
    icon: Icons.palette_rounded,
    color: _appearC,
    howTo: [
      'Use the theme button in the Home top bar to cycle Light → Dim → Dark.',
      '"Dim" is a softer light theme that is easier on the eyes.',
      'Tap the language option (top bar or side menu) to switch language.',
      'Choose between English and Burmese (မြန်မာ) — the whole app updates instantly.',
    ],
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
        title: Text('guide.title'.tr(),
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text('guide.show_how'.tr(),
              style: GoogleFonts.rufina(
                  fontSize: 24, fontWeight: FontWeight.bold, color: ink)),
          const SizedBox(height: 4),
          Text('guide.intro'.tr(),
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
                    child: Text('guide.full_tour'.tr(),
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
        // Open the written step-by-step detail page for this topic.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _GuideDetailScreen(topic: topic)),
        );
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

// ── Detailed how-to page for a single topic ──────────────────────────────────
class _GuideDetailScreen extends StatelessWidget {
  final GuideTopicInfo topic;
  const _GuideDetailScreen({required this.topic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final cardBg = isDark ? AppColors.darkWarm : AppColors.creamCard;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        title: Text('User Guide',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: topic.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(topic.icon, color: topic.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.title,
                        style: GoogleFonts.rufina(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: ink)),
                    const SizedBox(height: 2),
                    Text(topic.subtitle,
                        style:
                            GoogleFonts.outfit(fontSize: 13, color: muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('guide.step_by_step'.tr(),
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: muted)),
          const SizedBox(height: 12),

          // Numbered steps
          ...List.generate(topic.howTo.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: topic.color,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(topic.howTo[i],
                          style: GoogleFonts.outfit(
                              fontSize: 14, height: 1.45, color: ink)),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Optional tip
          if (topic.tip != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: topic.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: topic.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(topic.tip!,
                        style: GoogleFonts.outfit(
                            fontSize: 13, height: 1.4, color: ink)),
                  ),
                ],
              ),
            ),
          ],

          // "Show me on screen" — runs the live coach tour where the topic has
          // on-screen targets, otherwise opens the feature's own screen.
          if (topic.steps.isNotEmpty || topic.open != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (topic.steps.isNotEmpty) {
                  final nav = Navigator.of(context, rootNavigator: true);
                  nav.pop(); // close detail
                  nav.pop(); // close guide list
                  GuideController.startNav(nav, topic.steps);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: topic.open!),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: topic.color.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                        topic.steps.isNotEmpty
                            ? Icons.touch_app_rounded
                            : Icons.open_in_new_rounded,
                        color: topic.color,
                        size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          topic.steps.isNotEmpty
                              ? 'guide.show_on_screen'.tr()
                              : 'guide.open_feature'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                    ),
                    Icon(Icons.chevron_right_rounded, color: muted),
                  ],
                ),
              ),
            ),
          ],
        ],
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
                  Text('guide.title'.tr(),
                      style: GoogleFonts.rufina(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ink)),
                  const SizedBox(height: 2),
                  Text('guide.home_subtitle'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.paleText
                              : AppColors.inkGrey)),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
