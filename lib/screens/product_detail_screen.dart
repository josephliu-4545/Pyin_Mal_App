import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/product_3d_viewer.dart';
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

  // Floating video pip state
  bool _showVideoPip = true;
  Offset _pipOffset = const Offset(220, 16); // top-right start
  static const double _pipW = 100;
  static const double _pipH = 130;
  static const double _heroH = 400;

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  final List<Map<String, dynamic>> _colors = [
    {'name': 'Black', 'color': Colors.black},
    {'name': 'White', 'color': Colors.white},
    {'name': 'Gray', 'color': Colors.grey},
    {'name': 'Beige', 'color': Color(0xFFD4B896)},
    {'name': 'Navy', 'color': Color(0xFF001F3F)},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    // Adaptive background: Off-white for light, dark charcoal for dark
    final bgColor =
        isDark ? AppColors.charcoal : Color(0xFFFAF8F6); // Off-white cream

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                        size: 20,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkWarm
                                : AppColors.creamAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            color: _isFavorite
                                ? AppColors.burgundy
                                : (isDark ? Colors.white : AppColors.inkBlack),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkWarm : AppColors.creamAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.share_rounded,
                          color: isDark ? Colors.white : AppColors.inkBlack,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content - REFINED PADDING
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkBorder : AppColors.creamAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.info_rounded,
                                size: 12, color: accent),
                          ),
                          const SizedBox(width: 8),
                          Text('${widget.brand} by Fartech',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.inkGrey)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color:
                                  isDark ? Colors.white54 : AppColors.inkGrey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3D Product Viewer - Hero View with floating PiP
                    SizedBox(
                      height: _heroH,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // The 3D viewer fills the whole hero
                          Product3DViewer(
                            height: _heroH,
                            isDark: isDark,
                          ),

                          // Floating draggable video card
                          if (_showVideoPip)
                            Positioned(
                              left: _pipOffset.dx,
                              top: _pipOffset.dy,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    double nx = _pipOffset.dx + details.delta.dx;
                                    double ny = _pipOffset.dy + details.delta.dy;
                                    // Clamp inside hero bounds
                                    nx = nx.clamp(0.0, _heroH * 0.75 - _pipW);
                                    ny = ny.clamp(0.0, _heroH - _pipH);
                                    _pipOffset = Offset(nx, ny);
                                  });
                                },
                                child: _FloatingVideoPip(
                                  isDark: isDark,
                                  image: widget.image,
                                  accent: accent,
                                  onClose: () => setState(() => _showVideoPip = false),
                                ),
                              ),
                            ),

                          // Re-open button when dismissed
                          if (!_showVideoPip)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _showVideoPip = true;
                                  _pipOffset = const Offset(220, 16);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.play_circle_outline_rounded,
                                          color: Colors.white, size: 14),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Details - MINIMAL & REFINED (Design Plan Spec)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand/Category Label
                              Text(
                                widget.brand,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.paleText
                                      : Color(0xFF999999),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Product Name (Hero Text)
                              Text(
                                widget.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.inkBlack,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Price (Right Aligned)
                        Text(
                          widget.price,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating - MINIMAL STYLE
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                              5,
                              (index) => Icon(
                                    Icons.star_rounded,
                                    color: AppColors.gold,
                                    size: 13,
                                  )),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '4.8 (128 reviews)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color:
                                isDark ? Color(0xFFAAAAAA) : Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // CTA Buttons - REFINED (Design Plan Spec: 13px, 600w, 44px touch targets)
                    Row(
                      children: [
                        // Try On Button (Outlined)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TryOnScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDark
                                    ? Color(0xFF444444)
                                    : AppColors.inkBlack,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.transparent,
                            ),
                            child: Text(
                              'Try On',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : AppColors.inkBlack,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Shop Now Button (Filled/Elevated)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              CartService.instance.addToCart(
                                CartItem(
                                  productId: widget.productId,
                                  name: widget.name,
                                  price: widget.price,
                                  image: widget.image,
                                  brand: widget.brand,
                                  size: _selectedSize,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to cart'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.white : AppColors.inkBlack,
                              foregroundColor:
                                  isDark ? AppColors.charcoal : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              'Shop Now',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Color Variants — product thumbnail style (reference design)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hint row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFF0F0F0),
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                size: 17,
                                color: isDark ? Colors.white54 : const Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(width: 10),
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
                        const SizedBox(height: 14),
                        // Thumbnail strip
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_colors.length, (i) {
                              final colorData = _colors[i];
                              final isSelected = _selectedColor == colorData['name'];
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedColor = colorData['name']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  margin: EdgeInsets.only(
                                      right: i < _colors.length - 1 ? 10 : 0),
                                  width: isSelected ? 62 : 54,
                                  height: isSelected ? 62 : 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark ? Colors.white : AppColors.inkBlack)
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.18),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: ClipOval(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Color fill as background
                                        Container(color: colorData['color'] as Color),
                                        // Product image overlay (semi-transparent)
                                        Image.asset(
                                          widget.image,
                                          fit: BoxFit.cover,
                                          color: (colorData['color'] as Color)
                                              .withOpacity(0.35),
                                          colorBlendMode: BlendMode.srcATop,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(),
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
                    const SizedBox(height: 18),

                    // Shop Info - MINIMAL STYLE
                    if (widget.shopName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkWarm : Color(0xFFF5F3F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 14, color: accent),
                            const SizedBox(width: 6),
                            Text(
                              widget.shopName!,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Color(0xFFDDDDDD)
                                    : AppColors.inkBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description Section
                    if (widget.description != null) ...[
                      Text(
                        'Description',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.inkBlack,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Color(0xFFCCCCCC) : Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Size Selector Section
                    Text(
                      'Select Size',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _sizes.map((size) {
                        final isSelected = _selectedSize == size;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSize = size),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent
                                    : (isDark
                                        ? AppColors.darkWarm
                                        : AppColors.creamAlt),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isSelected ? accent : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  size,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (isDark
                                            ? AppColors.charcoal
                                            : Colors.white)
                                        : (isDark
                                            ? Colors.white
                                            : AppColors.inkBlack),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Characteristics Section
                    Text(
                      'Characteristics',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard(
                        'Comfort', 'Soft & breathable fabric', isDark),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard('Textile', '100% Cotton', isDark),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard(
                        'Style', 'Modern casual fit', isDark),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard('Fit', 'Regular fit', isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive, Color accent) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? accent : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCharacteristicCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Picture-in-Picture video card ──────────────────────────────────
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
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
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
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail — use the product's own image as stand-in
            Image.asset(
              widget.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                child: const Center(
                  child: Icon(Icons.videocam_rounded, color: Colors.white54, size: 32),
                ),
              ),
            ),

            // Dark scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),

            // Pulsing play button centre
            Center(
              child: AnimatedBuilder(
                animation: _scale,
                builder: (_, child) => Transform.scale(
                  scale: _scale.value,
                  child: child,
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              ),
            ),

            // Red "Product Preview" label at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: const Color(0xFFE53935),
                child: Text(
                  'Product Preview',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Close ✕ button top-right
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                ),
              ),
            ),

            // Drag handle hint — top-left dots
            const Positioned(
              top: 6,
              left: 6,
              child: Icon(Icons.drag_indicator_rounded, color: Colors.white54, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
