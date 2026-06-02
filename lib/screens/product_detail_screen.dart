import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/cdn_image.dart';
import 'package:pyin_mal_app/services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final String price;
  final String image;
  final String brand;
  final String category;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.brand,
    required this.category,
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
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
                            color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_outline,
                            color: _isFavorite ? AppColors.burgundy : (isDark ? Colors.white : AppColors.inkBlack),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
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
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.info_rounded, size: 12, color: accent),
                          ),
                          const SizedBox(width: 8),
                          Text('${widget.brand} by Fartech', style: GoogleFonts.outfit(
                              fontSize: 12, color: isDark ? Colors.white70 : AppColors.inkGrey)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10,
                              color: isDark ? Colors.white54 : AppColors.inkGrey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Image with 360 Rotation - INTERACTIVE DRAG
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() => _rotation += details.delta.dx * 0.01);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 320,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkWarm : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Transform.rotate(
                                angle: _rotation,
                                child: CdnImage(
                                  widget.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                                    child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),
                                  ),
                                ),
                              ),
                            ),
                          // 360 Rotation Indicator with curved design at bottom - INTERACTIVE
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12, offset: const Offset(0, -2))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Left arrow - rotate left
                                    GestureDetector(
                                      onTap: () => setState(() => _rotation -= 0.3),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Text('<', style: GoogleFonts.outfit(
                                            fontSize: 18, fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.inkBlack)),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Progress slider
                                    Container(
                                      width: 40,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: (isDark ? AppColors.paleText : AppColors.inkGrey).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Right arrow - rotate right
                                    GestureDetector(
                                      onTap: () => setState(() => _rotation += 0.3),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Text('>', style: GoogleFonts.outfit(
                                            fontSize: 18, fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.inkBlack)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 20),

                    // Color Variants - ENHANCED STYLING
                    SizedBox(
                      height: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Colors',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.inkBlack,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _colors.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (_, i) {
                                final colorData = _colors[i];
                                final isSelected = _selectedColor == colorData['name'];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedColor = colorData['name']),
                                  child: AnimatedScale(
                                    scale: isSelected ? 1.1 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected ? accent : Colors.transparent,
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: isSelected ? [
                                          BoxShadow(
                                            color: accent.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ] : [],
                                      ),
                                      padding: const EdgeInsets.all(3),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorData['color'],
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(
                                            color: isDark ? AppColors.darkBorder : Colors.grey.withOpacity(0.2),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorData['color'].withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Product Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.brand,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: isDark ? AppColors.paleText : AppColors.inkGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.name,
                                style: GoogleFonts.rufina(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.inkBlack,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          widget.price,
                          style: GoogleFonts.rufina(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Rating Row
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) => Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 18,
                          )),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '4.8 (128 reviews)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? AppColors.paleText : AppColors.inkGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Size Selector
                    Text(
                      'Select Size',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.inkBlack,
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
                                color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? accent : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  size,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? Colors.white : AppColors.inkBlack),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    // Characteristics Section
                    Text(
                      'Characteristics',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCharacteristicCard('Comfort', 'Soft & breathable fabric', isDark),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard('Textile', '100% Cotton', isDark),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard('Style', 'Modern casual fit', isDark),
                    const SizedBox(height: 12),
                    _buildCharacteristicCard('Fit', 'Regular fit', isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarm : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Try On & Shop Now Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Try-On feature coming soon'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Try On',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.inkBlack,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            backgroundColor: isDark ? Colors.white : AppColors.inkBlack,
                            foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            'Shop Now',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Floating Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1A1A1A) : AppColors.charcoal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tool/Settings icon
                        _buildFloatingActionIcon(Icons.tune_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings'), duration: Duration(seconds: 1)),
                          );
                        }),
                        // Gear/Customize icon
                        _buildFloatingActionIcon(Icons.settings_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customize'), duration: Duration(seconds: 1)),
                          );
                        }),
                        // Profile/Avatar icon
                        _buildFloatingActionIcon(Icons.account_circle_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile'), duration: Duration(seconds: 1)),
                          );
                        }),
                        // Chat/Message icon
                        _buildFloatingActionIcon(Icons.chat_bubble_outline_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat'), duration: Duration(seconds: 1)),
                          );
                        }),
                        // Search icon
                        _buildFloatingActionIcon(Icons.search_rounded, () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Search'), duration: Duration(seconds: 1)),
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
