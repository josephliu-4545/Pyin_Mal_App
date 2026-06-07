import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/product_3d_viewer.dart';
import '../widgets/cdn_image.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final String price;
  final String image;
  final String brand;
  final String category;
  final String? description;
  final String? shopName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.brand,
    required this.category,
    this.description,
    this.shopName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedSize = 'M';
  bool _isFavorite = false;
  String _selectedColor = 'Black';

  // Hero view toggle — image (Photo) is default
  bool _show3DView = false;

  // Reviews: collapsed by default (show 2), expandable
  bool _showAllReviews = false;

  // Floating video pip state
  bool _showVideoPip = true;
  Offset _pipOffset = const Offset(220, 16);
  static const double _pipW = 100;
  static const double _pipH = 130;
  static const double _heroH = 420;

  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Gray',  'color': Colors.grey},
    {'name': 'Beige', 'color': Color(0xFFD4B896)},
    {'name': 'Navy',  'color': Color(0xFF001F3F)},
  ];

  final List<Map<String, dynamic>> _reviews = [
    {'name': 'Aye Myat', 'rating': 5, 'comment': 'Absolutely love it! Great quality and fits perfectly.', 'date': '2 days ago'},
    {'name': 'Ko Zaw',   'rating': 4, 'comment': 'Very good product, fast shipping. Would buy again.', 'date': '1 week ago'},
    {'name': 'Ma Thida', 'rating': 5, 'comment': 'The material feels premium. Highly recommended!',     'date': '2 weeks ago'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : const Color(0xFFF5F5F5);
    final cardBg  = isDark ? AppColors.darkWarm  : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavBtn(
                    icon: Icons.arrow_back_ios_rounded,
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _NavBtn(
                        icon: _isFavorite ? Icons.favorite : Icons.favorite_outline,
                        isDark: isDark,
                        iconColor: _isFavorite ? AppColors.burgundy : null,
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                      ),
                      const SizedBox(width: 10),
                      _NavBtn(icon: Icons.share_rounded, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── 1. IMAGE (with overlaid size selector + rotation) ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SizedBox(
                              height: _heroH,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // IMAGE VIEW (default)
                                  AnimatedOpacity(
                                    opacity: _show3DView ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeInOut,
                                    child: IgnorePointer(
                                      ignoring: _show3DView,
                                      child: Container(
                                        width: double.infinity,
                                        height: _heroH,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkWarm
                                              : const Color(0xFFF0EEF0),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: CdnImage(
                                            widget.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Icon(Icons.image_outlined,
                                                  size: 60,
                                                  color: isDark
                                                      ? Colors.white24
                                                      : Colors.grey
                                                          .withOpacity(0.4)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3D VIEW
                                  AnimatedOpacity(
                                    opacity: _show3DView ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeInOut,
                                    child: IgnorePointer(
                                      ignoring: !_show3DView,
                                      child: Product3DViewer(
                                        height: _heroH,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ),

                                  // VIEW TOGGLE PILL (top-center)
                                  Positioned(
                                    top: 14,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _viewTab(
                                              label: 'Photo',
                                              icon: Icons.image_rounded,
                                              active: !_show3DView,
                                              onTap: () => setState(
                                                  () => _show3DView = false),
                                            ),
                                            _viewTab(
                                              label: '360°',
                                              icon: Icons.view_in_ar_rounded,
                                              active: _show3DView,
                                              onTap: () => setState(
                                                  () => _show3DView = true),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Draggable video PiP
                                  if (_showVideoPip)
                                    Positioned(
                                      left: _pipOffset.dx,
                                      top:  _pipOffset.dy,
                                      child: GestureDetector(
                                        onPanUpdate: (d) {
                                          setState(() {
                                            double nx = (_pipOffset.dx + d.delta.dx)
                                                .clamp(0.0, _heroH * 0.6 - _pipW);
                                            double ny = (_pipOffset.dy + d.delta.dy)
                                                .clamp(0.0, _heroH - _pipH);
                                            _pipOffset = Offset(nx, ny);
                                          });
                                        },
                                        child: _FloatingVideoPip(
                                          isDark: isDark,
                                          image: widget.image,
                                          accent: accent,
                                          onClose: () =>
                                              setState(() => _showVideoPip = false),
                                        ),
                                      ),
                                    ),

                                  if (!_showVideoPip)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _showVideoPip = true;
                                          _pipOffset = const Offset(180, 16);
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.play_circle_outline_rounded,
                                                  color: Colors.white,
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text('Preview',
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  // SIZE SELECTOR — overlaid on the right edge
                                  Positioned(
                                    right: 12,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _sizes.map((size) {
                                          final sel = _selectedSize == size;
                                          return GestureDetector(
                                            onTap: () => setState(
                                                () => _selectedSize = size),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: sel
                                                    ? accent
                                                    : Colors.white.withOpacity(
                                                        isDark ? 0.16 : 0.9),
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  size,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: sel
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF333333),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // ── 2. COLOR STRIP (directly under product) ──────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Hint row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFF0F0F0),
                                ),
                                child: Icon(Icons.swap_horiz_rounded,
                                    size: 16,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF888888)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Swipe and dress up differently',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white54
                                      : const Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Circle thumbnails — original size, wide gap so only 3 fit
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: List.generate(_colors.length, (i) {
                                final c   = _colors[i];
                                final sel = _selectedColor == c['name'];
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedColor = c['name']),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                    margin: EdgeInsets.only(
                                        right: i < _colors.length - 1 ? 50 : 0),
                                    width:  sel ? 64 : 54,
                                    height: sel ? 64 : 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: sel
                                            ? (isDark
                                                ? Colors.white
                                                : AppColors.inkBlack)
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                              sel ? 0.22 : 0.08),
                                          blurRadius: sel ? 14 : 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Product image — clearly visible
                                          CdnImage(
                                            widget.image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    color: c['color'] as Color),
                                          ),
                                          // Subtle color tint
                                          Container(
                                            color: (c['color'] as Color)
                                                .withOpacity(
                                                    c['name'] == 'Black'
                                                        ? 0.0
                                                        : 0.22),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── 3. TRY ON + SHOP NOW buttons ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const TryOnScreen())),
                              icon: const Icon(
                                  Icons.face_retouching_natural_rounded,
                                  size: 16),
                              label: Text('Try On',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : const Color(0xFFCCCCCC),
                                    width: 1.5),
                                foregroundColor: isDark
                                    ? Colors.white
                                    : AppColors.inkBlack,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                CartService.instance.addToCart(CartItem(
                                  productId: widget.productId,
                                  name: widget.name,
                                  price: widget.price,
                                  image: widget.image,
                                  brand: widget.brand,
                                  size: _selectedSize,
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Added to cart'),
                                      duration: Duration(seconds: 2)),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 16),
                              label: Text('Shop Now',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                backgroundColor: isDark
                                    ? Colors.white
                                    : AppColors.inkBlack,
                                foregroundColor: isDark
                                    ? AppColors.charcoal
                                    : Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── 4. PRODUCT INFO CARD ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.2 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop name chip
                            if (widget.shopName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.storefront_rounded,
                                        size: 12, color: accent),
                                    const SizedBox(width: 5),
                                    Text(widget.shopName!,
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: accent)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Product name + category badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.inkBlack,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.category,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF777777),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Price row
                            Row(
                              children: [
                                Text(
                                  widget.price,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  // Fake original price (strikethrough)
                                  widget.price.replaceAll(RegExp(r'\d'), '0'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: isDark
                                        ? Colors.white30
                                        : const Color(0xFFBBBBBB),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Rating
                            Row(
                              children: [
                                ...List.generate(
                                    5,
                                    (_) => Icon(Icons.star_rounded,
                                        color: AppColors.gold, size: 15)),
                                const SizedBox(width: 6),
                                Text('4.8',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.inkBlack)),
                                const SizedBox(width: 4),
                                Text('(128 reviews)',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF999999))),
                              ],
                            ),

                            // Divider
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Divider(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFEEEEEE),
                                height: 1,
                              ),
                            ),

                            // Description
                            if (widget.description != null) ...[
                              Text(
                                widget.description!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  height: 1.65,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── 5. REVIEWS SECTION ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Reviews (${_reviews.length})',
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.inkBlack)),
                              GestureDetector(
                                onTap: _openReviewSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.rate_review_outlined,
                                          size: 14, color: accent),
                                      const SizedBox(width: 5),
                                      Text('Write a review',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: accent)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...(_showAllReviews
                                  ? _reviews
                                  : _reviews.take(2))
                              .map((r) => _ReviewCard(
                                    review: r,
                                    isDark: isDark,
                                    cardBg: cardBg,
                                  )),
                          // See all / Show less toggle (only if >2 reviews)
                          if (_reviews.length > 2)
                            GestureDetector(
                              onTap: () => setState(
                                  () => _showAllReviews = !_showAllReviews),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showAllReviews
                                          ? 'Show less'
                                          : 'See all ${_reviews.length} reviews',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showAllReviews
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── 6. SHOP BANNER ────────────────────────────────────────
                    if (widget.shopName != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.2 : 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Shop logo circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.store_rounded,
                                    color: accent, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.shopName!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.inkBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Official store · 4.9 ★ · 10k+ sales',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: accent, width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Visit',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: accent)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── 7. CHARACTERISTICS ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Characteristics',
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.inkBlack)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.2 : 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _CharRow('Comfort',  'Soft & breathable', isDark, isFirst: true),
                                _CharRow('Textile',  '100% Cotton',       isDark),
                                _CharRow('Style',    'Modern casual fit', isDark),
                                _CharRow('Fit',      'Regular fit',       isDark),
                                _CharRow('Material', 'Premium quality',   isDark, isLast: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open the "write a review" bottom sheet
  void _openReviewSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    int rating = 5;
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              // Lift above the keyboard
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Write a review',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.inkBlack)),
                    const SizedBox(height: 4),
                    Text('Share your experience with this product',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF888888))),
                    const SizedBox(height: 18),

                    // Star rating selector
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < rating;
                        return GestureDetector(
                          onTap: () => setSheet(() => rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 34,
                              color: filled
                                  ? AppColors.gold
                                  : (isDark
                                      ? Colors.white30
                                      : const Color(0xFFCCCCCC)),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Name field
                    _sheetField(
                      controller: nameCtrl,
                      hint: 'Your name',
                      isDark: isDark,
                      accent: accent,
                    ),
                    const SizedBox(height: 12),
                    // Comment field
                    _sheetField(
                      controller: commentCtrl,
                      hint: 'Write your comment...',
                      isDark: isDark,
                      accent: accent,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim().isEmpty
                              ? 'Anonymous'
                              : nameCtrl.text.trim();
                          final comment = commentCtrl.text.trim();
                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please write a comment'),
                                  duration: Duration(seconds: 2)),
                            );
                            return;
                          }
                          setState(() {
                            _reviews.insert(0, {
                              'name': name,
                              'rating': rating,
                              'comment': comment,
                              'date': 'Just now',
                            });
                          });
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Thanks for your review!'),
                                duration: Duration(seconds: 2)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.white : AppColors.inkBlack,
                          foregroundColor:
                              isDark ? AppColors.charcoal : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Submit review',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color accent,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
          fontSize: 13,
          color: isDark ? Colors.white : AppColors.inkBlack),
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

  // View toggle tab (Photo / 360°)
  Widget _viewTab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? const Color(0xFF1A1A1A) : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF1A1A1A) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small nav button ──────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, required this.isDark, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 20,
            color: iconColor ??
                (isDark ? Colors.white : AppColors.inkBlack)),
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isDark;
  final Color cardBg;
  const _ReviewCard({required this.review, required this.isDark, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.burgundy.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (review['name'] as String)[0],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['name'] as String,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.inkBlack)),
                    Row(
                      children: [
                        ...List.generate(
                            review['rating'] as int,
                            (_) => const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 12)),
                        const SizedBox(width: 4),
                        Text(review['date'] as String,
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFFAAAAAA))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment'] as String,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white60 : const Color(0xFF666666))),
        ],
      ),
    );
  }
}

// ── Characteristic row ────────────────────────────────────────────────────────
class _CharRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  const _CharRow(this.label, this.value, this.isDark,
      {this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF888888),
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.inkBlack)),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}

// ── Floating PiP video card ───────────────────────────────────────────────────
class _FloatingVideoPip extends StatefulWidget {
  final bool isDark;
  final String image;
  final Color accent;
  final VoidCallback onClose;

  const _FloatingVideoPip({
    required this.isDark,
    required this.image,
    required this.accent,
    required this.onClose,
  });

  @override
  State<_FloatingVideoPip> createState() => _FloatingVideoPipState();
}

class _FloatingVideoPipState extends State<_FloatingVideoPip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.image, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: widget.isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                    child: const Center(
                        child: Icon(Icons.videocam_rounded,
                            color: Colors.white54, size: 32)))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _scale,
                builder: (_, child) =>
                    Transform.scale(scale: _scale.value, child: child),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.25), blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.black87, size: 22),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: const Color(0xFFE53935),
                child: Text('Product Preview',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3)),
              ),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
            ),
            const Positioned(
              top: 6, left: 6,
              child: Icon(Icons.drag_indicator_rounded,
                  color: Colors.white54, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
