import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/screens/cart_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Set<String> _favorites = {};

  // Categories matching reference design
  final List<String> _categories = [
    'All',
    'Women',
    'Men',
    'Hoodies',
    'T-Shirts',
    'Shoes',
    'Bags',
    'Hats',
    'Accessories',
    'Sports',
    'Sets',
  ];

  // Shops with logo colors and icons
  final List<Map<String, dynamic>> _shops = [
    {'name': 'Pyin Mal\nOfficial', 'icon': Icons.store_rounded, 'color': Color(0xFF6B2737), 'bg': Color(0xFFF5E6E8)},
    {'name': 'Luna\nBoutique',     'icon': Icons.diamond_rounded, 'color': Color(0xFF7B5EA7), 'bg': Color(0xFFF0EAF8)},
    {'name': 'NRF\nStore',         'icon': Icons.bolt_rounded,    'color': Color(0xFF1A1A2E), 'bg': Color(0xFFE8E8F0)},
    {'name': 'ABCD\nFashion',      'icon': Icons.auto_awesome_rounded, 'color': Color(0xFFB5541B), 'bg': Color(0xFFFAEDE6)},
    {'name': 'AJOHN\nOfficial',    'icon': Icons.workspace_premium_rounded, 'color': Color(0xFF2E7D32), 'bg': Color(0xFFE8F5E9)},
    {'name': 'LAPSES\nShop',       'icon': Icons.style_rounded,   'color': Color(0xFF1565C0), 'bg': Color(0xFFE3F2FD)},
    {'name': 'Fartech\nBrand',     'icon': Icons.flash_on_rounded, 'color': Color(0xFFE65100), 'bg': Color(0xFFFFF3E0)},
  ];


  List<Product> get _filteredProducts {
    if (_selectedCategory == 'All') return ProductRepository.allProducts;
    return ProductRepository.allProducts
        .where((p) => p.category == _selectedCategory || p.gender == _selectedCategory)
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
    final crossAxisCount = screenWidth >= 1024 ? 4 : (screenWidth >= 640 ? 3 : 2);
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : Color(0xFFFAF8F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // SECTION 1: Search Bar with Camera Icon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkWarm : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Camera/Scan Icon Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.camera_alt_rounded, color: accent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Camera/Scan feature coming soon')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Cart Icon
                    ListenableBuilder(
                      listenable: CartService.instance,
                      builder: (context, _) {
                        final count = CartService.instance.itemCount;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkWarm : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: accent,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CartScreen()),
                                  );
                                },
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // SECTION 2: Category Tabs (Horizontal Scroll)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accent
                                : (isDark ? AppColors.darkWarm : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: !isSelected
                                ? Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
                                  )
                                : null,
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? AppColors.charcoal : Colors.white)
                                  : (isDark ? Colors.white70 : AppColors.inkBlack),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // SECTION 3: Shops Row (auto-sliding)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shops',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                        Text(
                          'See all',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _shops.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final shop = _shops[index];
                          final bg = isDark
                              ? (shop['color'] as Color).withOpacity(0.2)
                              : shop['bg'] as Color;
                          final iconColor = shop['color'] as Color;
                          return Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: bg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: iconColor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: iconColor.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  shop['icon'] as IconData,
                                  color: iconColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  shop['name'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : AppColors.inkBlack,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),


            // SECTION 5: Products Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'All Products',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    final isFavorited = _favorites.contains(product.id);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productId: product.id,
                              name: product.name,
                              price: product.price,
                              image: product.image,
                              brand: product.brand,
                              category: product.category,
                              description: product.description,
                              shopName: product.shopName,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkWarm : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image with Wishlist
                            Stack(
                              children: [
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: CdnImage(
                                      product.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: isDark ? Colors.white30 : Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Wishlist Button (Top Right)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isFavorited) {
                                          _favorites.remove(product.id);
                                        } else {
                                          _favorites.add(product.id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isFavorited ? Icons.favorite : Icons.favorite_outline,
                                          color: isFavorited ? Colors.red : Colors.grey,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Product Details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Brand Label
                                        Text(
                                          product.brand,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            color: isDark ? Colors.white60 : Colors.grey,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Product Name
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.inkBlack,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Rating
                                        Row(
                                          children: [
                                            ...List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star_rounded,
                                                size: 12,
                                                color: AppColors.gold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '4.8 (128)',
                                              style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: isDark ? Colors.white60 : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Price
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product.price,
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: accent,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'View',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: accent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // SECTION 6: Flash Sale Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Flash Sale',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.inkBlack,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, color: Colors.red, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '02:45:30',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Flash Sale Products (First 2)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filteredProducts.take(2).map((product) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkWarm : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.1),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          child: CdnImage(
                                            product.image,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '-30%',
                                            style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : AppColors.inkBlack,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.price,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
