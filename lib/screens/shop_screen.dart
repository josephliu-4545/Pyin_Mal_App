import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/services/database_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Track favorite items locally
  final Set<String> _favorites = {};
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Shoes',
    'T-Shirts',
    'Pants',
    'Hoodie',
    'Sets',
    'Burmese Wear',
  ];

  List<Product> get _filtered {
    if (_selectedCategory == 'All') return ProductRepository.allProducts;
    return ProductRepository.allProducts
        .where(
          (p) =>
              p.category == _selectedCategory || p.gender == _selectedCategory,
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1024
        ? 4
        : (screenWidth >= 640 ? 3 : 2);
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.charcoal : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.charcoal : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: isDark
                ? AppColors.paleText
                : AppColors.inkGrey,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Fashion'),
              Tab(text: 'Barber Shop'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Fashion Tab
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(isDark),
                  const SizedBox(height: 24),

                  // Search Bar with Filter
                  _buildSearchBar(isDark, accent),
                  const SizedBox(height: 24),

                  // Category Chips
                  _buildCategoryChips(isDark, accent),
                  const SizedBox(height: 24),

                  // Product Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final product = _filtered[index];
                      return _buildProductCard(
                        context,
                        product,
                        isDark,
                        accent,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Barber Shop Tab (keep existing design)
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      image: const DecorationImage(
                        image: CachedNetworkImageProvider('${ApiConstants.cdnBaseUrl}Hero/baber.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black54,
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'BOOK YOUR STYLE',
                          style: GoogleFonts.outfit(
                            color: AppColors.gold,
                            letterSpacing: 3,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a Barber Shop',
                          style: GoogleFonts.rufina(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Professional grooming, curated for you',
                          style: GoogleFonts.outfit(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildBarberCard(
                          context,
                          'Yangon Classic Barber',
                          '4.8',
                          '95',
                          'Bogyoke Market, Yangon',
                          [
                            'Classic Haircut — 8,000 MMK',
                            'Fade Cut — 12,000 MMK',
                            'Beard Trim — 5,000 MMK',
                          ],
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildBarberCard(
                          context,
                          'Mandalay Heritage Salon',
                          '4.9',
                          '112',
                          '84th Street, Mandalay',
                          [
                            'Pompadour — 15,000 MMK',
                            'Textured Crop — 12,000 MMK',
                            'Full Groom — 20,000 MMK',
                          ],
                          isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildBarberCard(
                          context,
                          'Golden Scissors Studio',
                          '4.7',
                          '78',
                          'Sanchaung, Yangon',
                          [
                            'Undercut — 10,000 MMK',
                            'Buzz Cut — 7,000 MMK',
                            'Skin Fade — 13,000 MMK',
                          ],
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Section ─────────────────────────────────────────────────────
  Widget _buildHeaderSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Put together your',
          style: GoogleFonts.rufina(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
            height: 1.2,
          ),
        ),
        Text(
          'Perfect Look',
          style: GoogleFonts.rufina(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover pieces that match your style and body preview.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? AppColors.paleText : AppColors.inkGrey,
          ),
        ),
      ],
    );
  }

  // ── Search Bar with Filter ─────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark, Color accent) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: GoogleFonts.outfit(
                  color: isDark ? AppColors.paleText : AppColors.inkGrey,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : AppColors.inkBlack,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => _showFilterBottomSheet(isDark, accent),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isDark ? AppColors.charcoal : Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ── Category Chips ────────────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark, Color accent) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent
                      : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? AppColors.charcoal : Colors.white)
                        : (isDark ? AppColors.paleText : AppColors.inkGrey),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Product Card ───────────────────────────────────────────────────────
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    bool isDark,
    Color accent,
  ) {
    final isFav = _favorites.contains(product.name);
    return GestureDetector(
      onTap: () {
        DatabaseService().trackProductView(product.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              name: product.name,
              price: product.price,
              image: product.image,
              brand: product.brand,
              category: product.category,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: CdnImage(
                      product.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (c, e, s) => Container(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.creamAlt,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFav) {
                            _favorites.remove(product.name);
                          } else {
                            _favorites.add(product.name);
                          }
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_outline,
                          size: 18,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: GoogleFonts.outfit(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: accent,
                          size: 14,
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

  // ── Filter Bottom Sheet ────────────────────────────────────────────────
  void _showFilterBottomSheet(bool isDark, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.inkGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.rufina(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Style
                    _buildFilterSection(
                      'Style',
                      [
                        'Basic',
                        'Classic',
                        'Streetwear',
                        'Formal',
                        'Traditional',
                      ],
                      isDark,
                      accent,
                    ),
                    const SizedBox(height: 24),
                    // Event
                    _buildFilterSection(
                      'Event',
                      ['Daily', 'University', 'Work', 'Party'],
                      isDark,
                      accent,
                    ),
                    const SizedBox(height: 24),
                    // Season
                    _buildFilterSection(
                      'Season',
                      ['Summer', 'Rainy', 'Winter'],
                      isDark,
                      accent,
                    ),
                    const SizedBox(height: 24),
                    // Weather
                    _buildFilterSection(
                      'Weather',
                      ['Sunny', 'Cloudy', 'Rainy'],
                      isDark,
                      accent,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Apply Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    bool isDark,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.inkGrey.withOpacity(0.2),
                ),
              ),
              child: Text(
                option,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarberCard(
    BuildContext context,
    String name,
    String rating,
    String reviewCount,
    String location,
    List<String> services,
    bool isDark,
  ) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: accent.withOpacity(0.15),
                    child: Icon(Icons.content_cut, color: accent, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.rufina(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.inkBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.gold,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$rating ($reviewCount reviews)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey,
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Services',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                  ),
                ),
                const SizedBox(height: 12),
                ...services.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.split('—')[0].trim(),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.paleText
                                : AppColors.inkGrey,
                          ),
                        ),
                        Text(
                          s.split('—').length > 1 ? s.split('—')[1].trim() : '',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark
                          ? AppColors.charcoal
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Book Appointment',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
