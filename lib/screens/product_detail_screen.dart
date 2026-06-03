import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/cdn_image.dart';
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
  double _rotation = 0;

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

                    // Product 3D Viewer (HERO IMAGE)
                    Product3DViewer(
                      height: 400,
                      isDark: isDark,
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

                    // Color Variants - INLINE LAYOUT (Design Plan: Label + Swatches)
                    Row(
                      children: [
                        Text(
                          'Colors',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(_colors.length, (i) {
                                final colorData = _colors[i];
                                final isSelected =
                                    _selectedColor == colorData['name'];
                                return Padding(
                                  padding: EdgeInsets.only(
                                      right: i < _colors.length - 1 ? 12 : 0),
                                  child: GestureDetector(
                                    onTap: () => setState(() =>
                                        _selectedColor = colorData['name']),
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.08 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected
                                                ? accent
                                                : Colors.transparent,
                                            width: 2.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: accent
                                                        .withOpacity(0.25),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(isDark
                                                            ? 0.15
                                                            : 0.06),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: colorData['color'],
                                            borderRadius:
                                                BorderRadius.circular(11),
                                            border: Border.all(
                                              color: isDark
                                                  ? AppColors.darkBorder
                                                      .withOpacity(0.3)
                                                  : Colors.grey
                                                      .withOpacity(0.1),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
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

            // Bottom Area - Floating Action Bar (Fixed)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkWarm
                    : Color(0xFFFAF8F6), // Same as background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Action Bar - REFINED (Design Plan: Dark, rounded, 5 icons)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1F1F1F) : Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tool/Settings icon
                        _buildFloatingActionIcon(Icons.tune_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Settings'),
                                duration: Duration(seconds: 1)),
                          );
                        }),
                        // Gear/Customize icon
                        _buildFloatingActionIcon(Icons.settings_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Customize'),
                                duration: Duration(seconds: 1)),
                          );
                        }),
                        // Profile/Avatar icon
                        _buildFloatingActionIcon(Icons.account_circle_rounded,
                            () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Profile'),
                                duration: Duration(seconds: 1)),
                          );
                        }),
                        // Chat/Message icon
                        _buildFloatingActionIcon(
                            Icons.chat_bubble_outline_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Chat'),
                                duration: Duration(seconds: 1)),
                          );
                        }),
                        // Search icon
                        _buildFloatingActionIcon(Icons.search_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Search'),
                                duration: Duration(seconds: 1)),
                          );
                        }),
                      ],
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

  Widget _buildFloatingActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
