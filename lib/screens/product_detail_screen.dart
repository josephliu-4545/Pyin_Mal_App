import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class ProductDetailScreen extends StatefulWidget {
  final String name;
  final String price;
  final String image;
  final String brand;
  final String category;

  const ProductDetailScreen({
    super.key,
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

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];

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
                    // Product Image
                    Container(
                      width: double.infinity,
                      height: 350,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.asset(
                          widget.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                            child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Carousel Dots (Static)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(true, accent),
                        const SizedBox(width: 8),
                        _buildDot(false, accent),
                        const SizedBox(width: 8),
                        _buildDot(false, accent),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
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
              child: Row(
                children: [
                  // AR View Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AR Try-On demo coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.view_in_ar_rounded,
                        color: accent,
                        size: 22,
                      ),
                      label: Text(
                        'AR View',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: accent,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: accent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Add to Cart Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.shopping_bag_rounded,
                        color: isDark ? AppColors.charcoal : Colors.white,
                        size: 22,
                      ),
                      label: Text(
                        'Add to Cart',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.charcoal : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
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
