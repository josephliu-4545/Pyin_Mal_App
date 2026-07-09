import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/screens/resell_chat_screen.dart';
import 'package:pyin_mal_app/screens/resell_inbox_screen.dart';

class ResellPost {
  final String title;
  final String price;
  final String image; // asset path (used when imageBytes is null)
  final Uint8List? imageBytes; // uploaded photo
  final String condition; // Like New / Good / Fair
  final String seller;
  final String size;
  final bool isSoldOut;
  final bool isMine; // posted by the current user

  const ResellPost({
    required this.title,
    required this.price,
    required this.image,
    this.imageBytes,
    required this.condition,
    required this.seller,
    required this.size,
    this.isSoldOut = false,
    this.isMine = false,
  });

  ResellPost copyWith({bool? isSoldOut}) => ResellPost(
        title: title,
        price: price,
        image: image,
        imageBytes: imageBytes,
        condition: condition,
        seller: seller,
        size: size,
        isSoldOut: isSoldOut ?? this.isSoldOut,
        isMine: isMine,
      );
}

/// In-memory store so user-posted items persist for the session.
class ResellStore {
  static final List<ResellPost> posts = [
    const ResellPost(
      title: 'NRF Deathwish Hoodie',
      price: '28,000 MMK',
      image: 'pyin-mal-assets/assets/images/Male/Nrf/Hoodie/b_NRF Deathwish hoodie_p1.jpg',
      condition: 'Like New',
      seller: 'Aung M.',
      size: 'L',
    ),
    const ResellPost(
      title: 'AJOHN V2 Hoodie',
      price: '22,000 MMK',
      image: 'pyin-mal-assets/assets/images/Male/Nrf/Hoodie/bl_V2 LOGO Hoodie_p1.jpg',
      condition: 'Good',
      seller: 'Thida K.',
      size: 'M',
    ),
    const ResellPost(
      title: 'ABCD Zip Up Hoodie',
      price: '19,000 MMK',
      image: 'pyin-mal-assets/assets/images/Male/Nrf/Hoodie/b_ABCD 2XL ZIP UP HOODIE_p1.jpg',
      condition: 'Good',
      seller: 'Ko Zaw',
      size: '2XL',
      isSoldOut: true,
    ),
    const ResellPost(
      title: 'ABCD Tee',
      price: '8,000 MMK',
      image: 'pyin-mal-assets/assets/images/Male/Nrf/Tee/b_ABCD TEE_p1.jpg',
      condition: 'Fair',
      seller: 'Su Su',
      size: 'M',
      isSoldOut: true,
    ),
    const ResellPost(
      title: 'Luna Set 1',
      price: '30,000 MMK',
      image: 'pyin-mal-assets/assets/images/Female/dress.set/Luna/luna set1.jpg',
      condition: 'Like New',
      seller: 'Ma Thida',
      size: 'S',
    ),
    const ResellPost(
      title: 'ACID T-Shirt',
      price: '9,500 MMK',
      image: 'pyin-mal-assets/assets/images/Male/Nrf/Tee/b_ACID TSHIRT_p1.jpg',
      condition: 'Good',
      seller: 'Kyaw Z.',
      size: 'L',
    ),
  ];
}

// Kept for backward-compat with the home preview section.
List<ResellPost> get resellPosts => ResellStore.posts;

Color conditionColor(String c) {
  switch (c) {
    case 'Like New':
      return const Color(0xFF2E7D32);
    case 'Good':
      return const Color(0xFF1565C0);
    default:
      return const Color(0xFFB26A00);
  }
}

class ResellScreen extends StatefulWidget {
  const ResellScreen({super.key});

  @override
  State<ResellScreen> createState() => _ResellScreenState();
}

class _ResellScreenState extends State<ResellScreen> {
  // false = all community listings, true = only the user's own posts
  bool _showMine = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final posts = _showMine
        ? ResellStore.posts.where((p) => p.isMine).toList()
        : ResellStore.posts;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        screenWidth >= 1024 ? 4 : (screenWidth >= 640 ? 3 : 2);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostSheet,
        backgroundColor: accent,
        foregroundColor: isDark ? AppColors.charcoal : Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
        label: Text('resell.sell_yours'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(isDark ? 0.2 : 0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_rounded,
                            size: 18, color: ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('resell.title'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const Spacer(),
                    // Seller inbox — all buyer chats in one place
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ResellInboxScreen()));
                        if (mounted) setState(() {});
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.2 : 0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Icon(Icons.forum_rounded,
                                size: 19, color: accent),
                          ),
                          if (ResellInboxStore.unreadCount > 0)
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
                                  '${ResellInboxStore.unreadCount}',
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
                  ],
                ),
              ),
            ),

            // Intro banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.18), accent.withOpacity(0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.recycling_rounded,
                            color: accent, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('resell.hero_title'.tr(),
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            const SizedBox(height: 3),
                            Text('resell.hero_desc'.tr(),
                                style: GoogleFonts.outfit(
                                    fontSize: 12, height: 1.35, color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Label + All / My posts toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          _showMine ? 'My posts' : 'resell.community'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                    ),
                    // Toggle pills
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final mine in [false, true])
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showMine = mine),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _showMine == mine
                                      ? accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(mine ? 'My posts' : 'All',
                                    style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _showMine == mine
                                            ? (isDark
                                                ? AppColors.charcoal
                                                : Colors.white)
                                            : ink)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grid (or empty state for "My posts")
            if (posts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 50, 40, 90),
                  child: Column(
                    children: [
                      Icon(Icons.sell_outlined, size: 48, color: muted),
                      const SizedBox(height: 14),
                      Text('You haven\'t posted anything yet',
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      const SizedBox(height: 6),
                      Text(
                          'Tap "Sell yours" below to list your first pre-loved item.',
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.outfit(fontSize: 12, color: muted)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ResellCard(
                      post: posts[i],
                      isDark: isDark,
                      cardBg: cardBg,
                      ink: ink,
                      muted: muted,
                      accent: accent,
                      onTap: () => _openDetailSheet(posts[i],
                          ResellStore.posts.indexOf(posts[i]), isDark, accent),
                    ),
                    childCount: posts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Post item sheet (functional) ───────────────────────────────────────────
  void _openPostSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    String condition = 'Like New';
    Uint8List? photo;
    // Step 2 — pickup / delivery arrangement
    int step = 0; // 0 = item details, 1 = pickup
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String pickupMethod = 'pickup'; // 'pickup' | 'dropoff'
    String timeSlot = 'morning'; // 'morning' | 'afternoon' | 'evening'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          Future<void> pickPhoto() async {
            try {
              final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1200,
                  imageQuality: 85);
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              setSheet(() => photo = bytes);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('resell.pick_error'.tr(args: [e.toString()]))),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text(
                        step == 0
                            ? 'resell.list_title'.tr()
                            : 'Arrange delivery pickup',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text(
                        step == 0
                            ? 'resell.list_desc'.tr()
                            : 'Tell us how the item gets to its buyer once sold.',
                        style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                    const SizedBox(height: 10),
                    // Step indicator (1 · item, 2 · pickup)
                    Row(
                      children: List.generate(2, (i) {
                        final active = i <= step;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: active
                                  ? accent
                                  : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFE8E4DF)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    if (step == 0) ...[
                    // Photo picker (shows preview once chosen)
                    GestureDetector(
                      onTap: pickPhoto,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(0.35)),
                        ),
                        child: photo != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child:
                                        Image.memory(photo!, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: pickPhoto,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text('resell.change'.tr(),
                                            style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      color: accent, size: 28),
                                  const SizedBox(height: 6),
                                  Text('resell.add_photos'.tr(),
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accent)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(nameCtrl, 'resell.item_name'.tr(), isDark, accent),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _field(priceCtrl, 'resell.price_hint'.tr(),
                                isDark, accent,
                                keyboard: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _field(
                                sizeCtrl, 'resell.size'.tr(), isDark, accent)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('resell.condition'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: muted)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Like New', 'Good', 'Fair'].map((c) {
                        final sel = condition == c;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheet(() => condition = c),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel
                                    ? conditionColor(c).withOpacity(0.14)
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFF4F4F4)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel
                                        ? conditionColor(c)
                                        : Colors.transparent,
                                    width: 1.5),
                              ),
                              child: Text('resell.conditions.$c'.tr(),
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? conditionColor(c) : ink)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('resell.err_name'.tr())),
                            );
                            return;
                          }
                          setSheet(() => step = 1);
                        },
                        icon: const Icon(Icons.local_shipping_rounded, size: 17),
                        label: Text('Next: Delivery & pickup',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor:
                              isDark ? AppColors.charcoal : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    ] else ...[
                      // ── Step 2: pickup / delivery arrangement ──
                      // Method chips
                      Row(
                        children: [
                          for (final m in ['pickup', 'dropoff'])
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setSheet(() => pickupMethod = m),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: m == 'pickup' ? 8 : 0),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: pickupMethod == m
                                        ? accent.withOpacity(0.14)
                                        : (isDark
                                            ? Colors.white10
                                            : const Color(0xFFF4F4F4)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: pickupMethod == m
                                            ? accent
                                            : Colors.transparent,
                                        width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                          m == 'pickup'
                                              ? Icons.local_shipping_rounded
                                              : Icons.store_rounded,
                                          size: 22,
                                          color: pickupMethod == m
                                              ? accent
                                              : muted),
                                      const SizedBox(height: 5),
                                      Text(
                                          m == 'pickup'
                                              ? 'Rider pickup'
                                              : 'Drop off',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: pickupMethod == m
                                                  ? accent
                                                  : ink)),
                                      Text(
                                          m == 'pickup'
                                              ? 'We collect from your address'
                                              : 'Bring it to a partner point',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                              fontSize: 10, color: muted)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(phoneCtrl, 'Phone number (09xxxxxxxxx)', isDark,
                          accent,
                          keyboard: TextInputType.phone),
                      if (pickupMethod == 'pickup') ...[
                        const SizedBox(height: 10),
                        _field(addressCtrl, 'Pickup address', isDark, accent),
                        const SizedBox(height: 14),
                        Text('Preferred pickup time',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: muted)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final t in [
                              'morning',
                              'afternoon',
                              'evening'
                            ])
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setSheet(() => timeSlot = t),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        right: t == 'evening' ? 0 : 8),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: timeSlot == t
                                          ? accent
                                          : (isDark
                                              ? Colors.white10
                                              : const Color(0xFFF4F4F4)),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                        t == 'morning'
                                            ? '9–12 AM'
                                            : (t == 'afternoon'
                                                ? '12–4 PM'
                                                : '4–7 PM'),
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: timeSlot == t
                                                ? (isDark
                                                    ? AppColors.charcoal
                                                    : Colors.white)
                                                : ink)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Back
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setSheet(() => step = 0),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFCCCCCC)),
                                foregroundColor: ink,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: Text('Back',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Post
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                if (phoneCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text(
                                              'Please enter your phone number')));
                                  return;
                                }
                                if (pickupMethod == 'pickup' &&
                                    addressCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          content: Text(
                                              'Please enter a pickup address')));
                                  return;
                                }
                                // Normalise price -> "X MMK".
                                final rawPrice = priceCtrl.text.trim();
                                final priceLabel = rawPrice.isEmpty
                                    ? 'resell.negotiable'.tr()
                                    : (rawPrice
                                            .toUpperCase()
                                            .contains('MMK')
                                        ? rawPrice
                                        : '$rawPrice MMK');
                                // Insert at the top so it shows first.
                                ResellStore.posts.insert(
                                  0,
                                  ResellPost(
                                    title: nameCtrl.text.trim(),
                                    price: priceLabel,
                                    image: '',
                                    imageBytes: photo,
                                    condition: condition,
                                    seller: 'resell.you'.tr(),
                                    size: sizeCtrl.text.trim().isEmpty
                                        ? 'resell.one_size'.tr()
                                        : sizeCtrl.text.trim(),
                                    isMine: true,
                                  ),
                                );
                                Navigator.pop(sheetCtx);
                                setState(() {}); // refresh grid
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(pickupMethod == 'pickup'
                                          ? 'Item posted! A rider will collect it once it sells.'
                                          : 'Item posted! Drop it off at a partner point once it sells.'),
                                      duration:
                                          const Duration(seconds: 3)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: isDark
                                    ? AppColors.charcoal
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: Text('resell.post_item'.tr(),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _field(TextEditingController controller, String hint, bool isDark,
      Color accent,
      {TextInputType? keyboard}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.outfit(
          fontSize: 13, color: isDark ? Colors.white : AppColors.inkBlack),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: isDark ? Colors.white10 : const Color(0xFFF4F4F4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }

  // ── Listing detail sheet ────────────────────────────────────────────────────
  void _openDetailSheet(ResellPost post, int postIndex, bool isDark, Color accent) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: post.imageBytes != null
                    ? Image.memory(post.imageBytes!, fit: BoxFit.cover)
                    : CdnImage(post.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.creamAlt)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sold-out banner ──────────────────────────────────────
                  if (post.isSoldOut)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel_rounded,
                              color: Color(0xFFE53935), size: 18),
                          const SizedBox(width: 8),
                          Text('resell.sold_msg'.tr(),
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE53935))),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(post.title,
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: post.isSoldOut
                                    ? ink.withOpacity(0.45)
                                    : ink)),
                      ),
                      Text(post.price,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: post.isSoldOut
                                  ? muted
                                  : accent,
                              decoration: post.isSoldOut
                                  ? TextDecoration.lineThrough
                                  : null)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _tag('resell.size_tag'.tr(args: [post.size]), muted,
                          isDark),
                      const SizedBox(width: 8),
                      _tag('resell.conditions.${post.condition}'.tr(),
                          conditionColor(post.condition), isDark,
                          filled: true),
                      if (post.isSoldOut) ...[
                        const SizedBox(width: 8),
                        _tag('resell.sold_out'.tr(), const Color(0xFFE53935),
                            isDark,
                            filled: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: accent.withOpacity(0.15),
                        child: Text(post.seller[0],
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent)),
                      ),
                      const SizedBox(width: 8),
                      Text('resell.sold_by'.tr(args: [post.seller]),
                          style:
                              GoogleFonts.outfit(fontSize: 13, color: ink)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResellChatScreen(
                                  seller: post.seller,
                                  itemTitle: post.title,
                                  itemPrice: post.price,
                                  itemImageAsset: post.image,
                                  itemImageBytes: post.imageBytes,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 16),
                          label: Text('resell.message'.tr(),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : const Color(0xFFCCCCCC)),
                            foregroundColor: ink,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: post.isSoldOut
                              ? null
                              : () {
                                  CartService.instance.addToCart(
                                    CartItem(
                                      productId:
                                          'resell_${post.title}_${post.seller}',
                                      name: post.title,
                                      price: post.price,
                                      image: post.image,
                                      brand: 'Resell · ${post.seller}',
                                      size: post.size,
                                    ),
                                  );
                                  // Mark as sold out in the store.
                                  setState(() {
                                    ResellStore.posts[postIndex] =
                                        ResellStore.posts[postIndex]
                                            .copyWith(isSoldOut: true);
                                  });
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('resell.added_to_cart'
                                            .tr(args: [post.title])),
                                        duration:
                                            const Duration(seconds: 2)),
                                  );
                                },
                          icon: Icon(
                              post.isSoldOut
                                  ? Icons.block_rounded
                                  : Icons.shopping_bag_rounded,
                              size: 16),
                          label: Text(
                              post.isSoldOut
                                  ? 'resell.sold_out'.tr()
                                  : 'resell.buy_now'.tr(),
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            backgroundColor: post.isSoldOut
                                ? (isDark
                                    ? Colors.white24
                                    : const Color(0xFFDDDDDD))
                                : (isDark ? Colors.white : AppColors.inkBlack),
                            foregroundColor: post.isSoldOut
                                ? (isDark ? Colors.white38 : Colors.grey)
                                : (isDark ? AppColors.charcoal : Colors.white),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
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

  Widget _tag(String text, Color color, bool isDark, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled
            ? color.withOpacity(0.14)
            : (isDark ? Colors.white10 : const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ResellCard extends StatelessWidget {
  final ResellPost post;
  final bool isDark;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final Color accent;
  final VoidCallback onTap;

  const _ResellCard({
    required this.post,
    required this.isDark,
    required this.cardBg,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cc = conditionColor(post.condition);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: ColorFiltered(
                        colorFilter: post.isSoldOut
                            ? const ColorFilter.matrix([
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0,      0,      0,      1, 0,
                              ])
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply),
                        child: post.imageBytes != null
                            ? Image.memory(post.imageBytes!, fit: BoxFit.cover)
                            : CdnImage(post.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.creamAlt)),
                      ),
                    ),
                  ),
                  // Condition badge (top-left)
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
                      child: Text('resell.conditions.${post.condition}'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  // Sold-out overlay
                  if (post.isSoldOut)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('resell.sold_out_caps'.tr(),
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
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
                            Icon(Icons.person_rounded, size: 10, color: muted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text('${post.seller} · ${post.size}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 10, color: muted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(post.price,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: post.isSoldOut ? muted : accent,
                            decoration: post.isSoldOut ? TextDecoration.lineThrough : null)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
