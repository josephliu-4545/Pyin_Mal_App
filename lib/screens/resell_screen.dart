import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/screens/resell_chat_screen.dart';
import 'package:pyin_mal_app/services/cart_service.dart';

class ResellPost {
  final String title;
  final String price;
  final String image; // asset path (used when imageBytes is null)
  final Uint8List? imageBytes; // uploaded photo
  final String condition; // Like New / Good / Fair
  final String seller;
  final String size;

  const ResellPost({
    required this.title,
    required this.price,
    required this.image,
    this.imageBytes,
    required this.condition,
    required this.seller,
    required this.size,
  });
}

/// In-memory store so user-posted items persist for the session.
class ResellStore {
  static final List<ResellPost> posts = [
    const ResellPost(
      title: 'NRF Deathwish Hoodie',
      price: '28,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
      condition: 'Like New',
      seller: 'Aung M.',
      size: 'L',
    ),
    const ResellPost(
      title: 'AJOHN V2 Hoodie',
      price: '22,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/AJOHN V2 HOODIE.jpg',
      condition: 'Good',
      seller: 'Thida K.',
      size: 'M',
    ),
    const ResellPost(
      title: 'ABCD Zip Up Hoodie',
      price: '19,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/ABCD 2XL ZIP UP HOODIE0.jpg',
      condition: 'Good',
      seller: 'Ko Zaw',
      size: '2XL',
    ),
    const ResellPost(
      title: 'ABCD Tee',
      price: '8,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/ABCD TEE.jpg',
      condition: 'Fair',
      seller: 'Su Su',
      size: 'M',
    ),
    const ResellPost(
      title: 'Luna Set 1',
      price: '30,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set1.jpg',
      condition: 'Like New',
      seller: 'Ma Thida',
      size: 'S',
    ),
    const ResellPost(
      title: 'ACID T-Shirt',
      price: '9,500 MMK',
      image: 'assets/images/Male/Nrf/Tee/ACID TSHIRT 0.jpg',
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final posts = ResellStore.posts;
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
        label: Text('Sell yours',
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
                    Text('Resell',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
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
                            Text('Buy & sell pre-loved fashion',
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            const SizedBox(height: 3),
                            Text('Give clothes a second life and earn a little back.',
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

            // Label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Community listings',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    Text('${posts.length} items',
                        style:
                            GoogleFonts.outfit(fontSize: 12, color: muted)),
                  ],
                ),
              ),
            ),

            // Grid
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
                    onTap: () => _openDetailSheet(posts[i], isDark, accent),
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
                SnackBar(content: Text('Could not pick image: $e')),
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
                    Text('List an item for resale',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text('Add a photo, set your price, and post to the community.',
                        style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                    const SizedBox(height: 16),

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
                                        child: Text('Change',
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
                                  Text('Add photos',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accent)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(nameCtrl, 'Item name', isDark, accent),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _field(priceCtrl, 'Price (e.g. 20,000)',
                                isDark, accent,
                                keyboard: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _field(sizeCtrl, 'Size', isDark, accent)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Condition',
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
                              child: Text(c,
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
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter an item name')),
                            );
                            return;
                          }
                          // Normalise price -> "X MMK".
                          final rawPrice = priceCtrl.text.trim();
                          final priceLabel = rawPrice.isEmpty
                              ? 'Negotiable'
                              : (rawPrice.toUpperCase().contains('MMK')
                                  ? rawPrice
                                  : '$rawPrice MMK');
                          // Insert at the top so it shows first.
                          ResellStore.posts.insert(
                            0,
                            ResellPost(
                              title: name,
                              price: priceLabel,
                              image: '',
                              imageBytes: photo,
                              condition: condition,
                              seller: 'You',
                              size: sizeCtrl.text.trim().isEmpty
                                  ? 'One size'
                                  : sizeCtrl.text.trim(),
                            ),
                          );
                          Navigator.pop(sheetCtx);
                          setState(() {}); // refresh grid
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Your item has been posted!'),
                                duration: Duration(seconds: 2)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor:
                              isDark ? AppColors.charcoal : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Post item',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
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
  void _openDetailSheet(ResellPost post, bool isDark, Color accent) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(post.title,
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                      ),
                      Text(post.price,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: accent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _tag('Size ${post.size}', muted, isDark),
                      const SizedBox(width: 8),
                      _tag(post.condition, conditionColor(post.condition),
                          isDark,
                          filled: true),
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
                      Text('Sold by ${post.seller}',
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
                          label: Text('Message',
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
                          onPressed: () {
                            CartService.instance.addToCart(
                              CartItem(
                                productId: 'resell_${post.title}_${post.seller}',
                                name: post.title,
                                price: post.price,
                                image: post.image,
                                brand: 'Resell · ${post.seller}',
                                size: post.size,
                              ),
                            );
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('${post.title} added to cart'),
                                  duration: const Duration(seconds: 2)),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                          label: Text('Buy now',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            backgroundColor:
                                isDark ? Colors.white : AppColors.inkBlack,
                            foregroundColor:
                                isDark ? AppColors.charcoal : Colors.white,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
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
                            color: accent)),
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
