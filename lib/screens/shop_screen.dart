import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/screens/category_products_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/screens/cart_screen.dart';
import 'package:pyin_mal_app/screens/checkout_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};

  // Categories matching reference design
  final List<Map<String, dynamic>> _categories = [
    {'label': 'New in',      'icon': Icons.auto_awesome_rounded},
    {'label': 'Women',       'icon': Icons.female_rounded},
    {'label': 'Men',         'icon': Icons.male_rounded},
    {'label': 'T-Shirts',    'icon': Icons.checkroom_rounded},
    {'label': 'Hoodies',     'icon': Icons.dry_cleaning_rounded},
    {'label': 'Pants',       'icon': Icons.straighten_rounded},
    {'label': 'Shoes',       'icon': Icons.directions_walk_rounded},
    {'label': 'Bags',        'icon': Icons.shopping_bag_outlined},
    {'label': 'Hats',        'icon': Icons.theater_comedy_outlined},
    {'label': 'Accessories', 'icon': Icons.watch_outlined},
    {'label': 'Sports',      'icon': Icons.sports_basketball_outlined},
    {'label': 'Sets',        'icon': Icons.style_outlined},
  ];
  String _selectedCategory = 'New in';
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    await ProductRepository.loadFromOpenCart();
    if (mounted) setState(() => _loadingProducts = false);
  }

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
    if (_selectedCategory == 'New in') return ProductRepository.allProducts;
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

            // SECTION 2: Category Tabs with icons
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: _categories.map((cat) {
                    final label = cat['label'] as String;
                    final icon  = cat['icon']  as IconData;
                    final isSelected = _selectedCategory == label;

                    // Selected: dark filled pill with white icon+text
                    // Unselected: light pill with circular icon bg + label
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          if (label == 'New in') {
                            setState(() => _selectedCategory = label);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryProductsScreen(
                                  category: label,
                                  icon: icon,
                                ),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                                : (isDark ? const Color(0xFF2A2521) : const Color(0xFFF4F4F4)),
                            borderRadius: BorderRadius.circular(50),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFE0E0E0),
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon circle
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.white)
                                      : (isDark
                                          ? Colors.white12
                                          : Colors.white),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  size: 16,
                                  color: isSelected
                                      ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                                      : (isDark ? Colors.white60 : const Color(0xFF555555)),
                                ),
                              ),
                              const SizedBox(width: 7),
                              // Label
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                                        : (isDark ? Colors.white70 : const Color(0xFF333333)),
                                  ),
                                ),
                              ),
                            ],
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
            if (_loadingProducts)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
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
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    final isFavorited = _favorites.contains(product.id);
                    return _ProductCard(
                      product: product,
                      isFavorited: isFavorited,
                      isDark: isDark,
                      accent: accent,
                      onFavTap: () => setState(() {
                        isFavorited
                            ? _favorites.remove(product.id)
                            : _favorites.add(product.id);
                      }),
                      onTap: () => Navigator.push(
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

// ── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorited;
  final bool isDark;
  final Color accent;
  final VoidCallback onFavTap;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isFavorited,
    required this.isDark,
    required this.accent,
    required this.onFavTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final mutedColor = isDark ? Colors.white38 : const Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ─────────────────────────────────────────────────
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: CdnImage(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark
                            ? const Color(0xFF2A2421)
                            : const Color(0xFFF2F2F2),
                        child: Center(
                          child: Icon(Icons.image_outlined,
                              size: 36, color: mutedColor),
                        ),
                      ),
                    ),
                  ),

                  // Subtle bottom fade so text doesn't fight the photo
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.28),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Category chip — bottom-left
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Wishlist — top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavTap,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isFavorited
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavorited
                                ? const Color(0xFFE53935)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info area ──────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand + name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),

                    // Stars + price row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stars
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (_) => Icon(Icons.star_rounded,
                                  size: 11, color: AppColors.gold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Price row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                product.price,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
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
  }
}
