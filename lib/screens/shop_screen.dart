import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/screens/category_products_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/widgets/cart_bar.dart';
import 'package:pyin_mal_app/widgets/product_search_sheet.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/screens/cart_screen.dart';
import 'package:pyin_mal_app/screens/sale_screen.dart';
import 'package:pyin_mal_app/screens/scan_screen.dart';
import 'package:pyin_mal_app/core/constants/shop_constants.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';

class ShopScreen extends StatefulWidget {
  /// When false, the screen does not render its own cart bar — used when the
  /// shell provides a shared one (avoids showing two bars on the shop tab).
  final bool showCartBar;
  const ShopScreen({super.key, this.showCartBar = true});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};

  // Categories matching reference design
  // Fixed icon map — covers all categories from the asset file structure
  static const _categoryIcons = {
    'New in':   Icons.auto_awesome_rounded,
    'Women':    Icons.female_rounded,
    'Men':      Icons.male_rounded,
    'T-Shirt':  Icons.checkroom_rounded,
    'Hoodie':   Icons.dry_cleaning_rounded,
    'Shirt':    Icons.checkroom_rounded,
    'Jacket':   Icons.downhill_skiing_rounded,
    'Sweater':  Icons.ac_unit_rounded,
    'Coat':     Icons.umbrella_rounded,
    'Pants':    Icons.straighten_rounded,
    'Jersey':   Icons.sports_rounded,
    'Set':      Icons.style_outlined,
    'Top':      Icons.female_rounded,
    'Dress':    Icons.female_rounded,
    'Skirt':    Icons.female_rounded,
    'Other':    Icons.category_outlined,
  };

  List<Map<String, dynamic>> _categories = [
    {'label': 'New in', 'icon': Icons.auto_awesome_rounded},
    {'label': 'Women',  'icon': Icons.female_rounded},
    {'label': 'Men',    'icon': Icons.male_rounded},
  ];

  void _buildCategories() {
    final seen = <String>{};
    final dynamicCats = <Map<String, dynamic>>[];
    for (final p in ProductRepository.allProducts) {
      final cat = p.category;
      if (cat.isEmpty || cat == 'Other' || seen.contains(cat)) continue;
      seen.add(cat);
      dynamicCats.add({
        'label': cat,
        'icon': _categoryIcons[cat] ?? Icons.category_outlined,
      });
    }
    dynamicCats.sort((a, b) => (a['label'] as String).compareTo(b['label'] as String));
    _categories = [
      {'label': 'New in', 'icon': Icons.auto_awesome_rounded},
      {'label': 'Women',  'icon': Icons.female_rounded},
      {'label': 'Men',    'icon': Icons.male_rounded},
      ...dynamicCats,
    ];
  }
  String _selectedCategory = 'New in';
  String? _selectedShop; // null = all shops
  List<ShopInfo> _shopsWithLogos = [];
  bool _loadingProducts = false;

  // ── Flash-sale countdown ──────────────────────────────────────────────────
  Timer? _saleTimer;
  late DateTime _saleEndsAt;
  Duration _saleRemaining = const Duration(hours: 2, minutes: 45, seconds: 30);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadShopsWithLogos();

    // Live flash-sale countdown that ticks every second and loops when it ends.
    _saleEndsAt = DateTime.now().add(_saleRemaining);
    _saleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      var remaining = _saleEndsAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _saleEndsAt = DateTime.now().add(const Duration(hours: 3));
        remaining = _saleEndsAt.difference(DateTime.now());
      }
      setState(() => _saleRemaining = remaining);
    });
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    await ProductRepository.loadFromOpenCart();
    if (mounted) setState(() {
      _loadingProducts = false;
      _buildCategories();
    });
  }

  Future<void> _loadShopsWithLogos() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final withLogos = ShopConstants.shops
        .where((s) => assets.contains(s.logoAsset))
        .toList();
    if (mounted) setState(() => _shopsWithLogos = withLogos);
  }


  List<Product> get _filteredProducts {
    var products = ProductRepository.allProducts;
    if (_selectedShop != null) {
      products = products
          .where((p) => (p.brand == _selectedShop) || (p.shopName == _selectedShop))
          .toList();
    }
    if (_selectedCategory == 'New in') return products;
    if (_selectedCategory == 'Women') {
      return products.where((p) => p.gender == 'Female').toList();
    }
    if (_selectedCategory == 'Men') {
      return products.where((p) => p.gender == 'Male').toList();
    }
    return products.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _saleTimer?.cancel();
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
      bottomNavigationBar: widget.showCartBar ? const CartBar() : null,
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
                        key: GuideKeys.shopSearch,
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
                          readOnly: true,
                          onTap: () => showProductSearch(context, isDark),
                          decoration: InputDecoration(
                            hintText: 'shop.search_hint'.tr(),
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
                    // Scan Icon Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.document_scanner_rounded, color: accent),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ScanScreen()),
                        ),
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
                          setState(() {
                            // If they tap the already selected category, maybe reset to 'New in'?
                            // Let's just set the selected category
                            _selectedCategory = label;
                          });
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
                          'shop.shops_title'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                        Text(
                          'shop.see_all'.tr(),
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
                    child: _shopsWithLogos.isEmpty
                        ? const SizedBox()
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _shopsWithLogos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final shop = _shopsWithLogos[index];
                              final isSelected = _selectedShop == shop.name;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _selectedShop = isSelected ? null : shop.name;
                                }),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? const Color(0xFF2A2421)
                                            : const Color(0xFFF2EDE8),
                                        border: Border.all(
                                          color: isSelected
                                              ? accent
                                              : (isDark ? Colors.white24 : Colors.black12),
                                          width: isSelected ? 2.5 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          shop.logoAsset,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.store_rounded,
                                            size: 28,
                                            color: isDark ? Colors.white54 : Colors.black38,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 64,
                                      child: Text(
                                        shop.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? accent
                                              : (isDark ? Colors.white70 : AppColors.inkBlack),
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // SECTION 4: Flash Sale Banner (links to SaleScreen)
            if (_selectedCategory == 'New in')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _buildShopSaleSection(context, isDark),
                ),
              ),
            if (_selectedCategory == 'New in')
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

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
                  _selectedCategory == 'New in'
                      ? 'shop.all_products'.tr()
                      : '$_selectedCategory Products',
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
                          builder: (_) => ProductDetailScreen.fromProduct(product),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Shop-screen sale section ──────────────────────────────────────────────
  Widget _buildShopSaleSection(BuildContext context, bool isDark) {
    const red = Color(0xFFE53935);
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;

    final all = ProductRepository.allProducts;
    final saleItems = all.length > 6 ? all.sublist(0, 6) : all;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(isDark ? 0.25 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: red.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: red, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SaleScreen())),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text('Flash Sale',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.rufina(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: ink)),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 20, color: muted),
                        ],
                      ),
                      Text('Deals from shops across Pyin Mal',
                          style: GoogleFonts.outfit(fontSize: 11, color: muted)),
                    ],
                  ),
                ),
              ),
              // Countdown pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: red, size: 13),
                    const SizedBox(width: 4),
                    Text(_fmtDuration(_saleRemaining),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: red,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal sale product cards
          SizedBox(
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: saleItems.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                // Trailing "See all" card
                if (i == saleItems.length) {
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SaleScreen())),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: red.withOpacity(0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: red, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text('See all',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: red)),
                        ],
                      ),
                    ),
                  );
                }

                final p = saleItems[i];
                final off = saleDiscountFor(i);

                // Compute original price
                String originalPrice = '';
                final match = RegExp(r'[\d,]+').firstMatch(p.price);
                if (match != null) {
                  final sale = int.tryParse(match.group(0)!.replaceAll(',', ''));
                  if (sale != null) {
                    final orig = (sale / (1 - off / 100)).round();
                    final label = p.price.replaceFirst(RegExp(r'[\d,]+'), '').trim();
                    final sep = orig.toString().replaceAllMapped(
                        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
                    originalPrice = '$sep $label'.trim();
                  }
                }

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen.fromProduct(p, discount: off),
                    ),
                  ),
                  child: Container(
                    width: 134,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image + discount badge
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                              child: SizedBox(
                                height: 110,
                                width: double.infinity,
                                child: CdnImage(p.image,
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('-$off%',
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.storefront_rounded, size: 10, color: muted),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(p.shopName ?? p.brand,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: 10, color: muted)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Sale price
                              Text(p.price,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: red)),
                              // Original strikethrough price
                              if (originalPrice.isNotEmpty)
                                Text(originalPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: muted,
                                        decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
