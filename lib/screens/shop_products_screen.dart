import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/widgets/cart_bar.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class ShopProductsScreen extends StatelessWidget {
  final String shopName;
  const ShopProductsScreen({super.key, required this.shopName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : const Color(0xFFF5F5F5);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;

    final products = ProductRepository.allProducts
        .where((p) => p.shopName == shopName)
        .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        screenWidth >= 1024 ? 4 : (screenWidth >= 640 ? 3 : 2);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const SafeArea(top: false, child: CartBar()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ────────────────────────────────────────────────────
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
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_rounded,
                            size: 18,
                            color: isDark ? Colors.white : AppColors.inkBlack),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('shop_products.title'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.inkBlack,
                        )),
                  ],
                ),
              ),
            ),

            // ── Shop header banner ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.store_rounded, color: accent, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shopName,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? Colors.white : AppColors.inkBlack,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 14, color: AppColors.gold),
                                const SizedBox(width: 3),
                                Text('4.9',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.inkBlack)),
                                const SizedBox(width: 8),
                                Text('shop_products.stats'.tr(args: [products.length.toString()]),
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF999999))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section label ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text('shop_products.products'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    )),
              ),
            ),

            // ── Product grid ───────────────────────────────────────────────
            if (products.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('shop_products.no_products'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF888888))),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = products[index];
                      return _ShopProductCard(
                        product: p,
                        isDark: isDark,
                        accent: accent,
                        cardBg: cardBg,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productId: p.id,
                              name: p.name,
                              price: p.price,
                              image: p.image,
                              brand: p.brand,
                              category: p.category,
                              description: p.description,
                              shopName: p.shopName,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShopProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final Color accent;
  final Color cardBg;
  final VoidCallback onTap;

  const _ShopProductCard({
    required this.product,
    required this.isDark,
    required this.accent,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
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
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CdnImage(
                  product.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark
                        ? const Color(0xFF2A2421)
                        : const Color(0xFFF2F2F2),
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          size: 32,
                          color: isDark ? Colors.white24 : Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.brand.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 1.0,
                            )),
                        const SizedBox(height: 3),
                        Text(product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A),
                            )),
                      ],
                    ),
                    Text(product.price,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        )),
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
