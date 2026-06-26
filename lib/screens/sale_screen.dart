import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/widgets/cart_bar.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';

// ── Shared sale helpers (single source of truth for home + sale page) ─────────
const saleDiscountPool = [30, 25, 40, 20, 35, 15, 50, 45];

/// Deterministic discount for the product at [index] in the master list.
int saleDiscountFor(int index) => saleDiscountPool[index % saleDiscountPool.length];

/// The price string with thousands separators preserved, recomputed.
String _formatPrice(int value, String label) {
  final withSep = value
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$withSep ${label.trim()}'.trim();
}

/// Reverse-computes the "original" (pre-discount) price from a sale price.
/// e.g. sale 50,000 at 30% off -> original 71,429.
String saleOriginalPrice(String salePrice, int discount) {
  final match = RegExp(r'[\d,]+').firstMatch(salePrice);
  if (match == null) return '';
  final sale = int.tryParse(match.group(0)!.replaceAll(',', ''));
  if (sale == null || discount <= 0) return '';
  final original = (sale / (1 - discount / 100)).round();
  final label = salePrice.replaceFirst(RegExp(r'[\d,]+'), '').trim();
  return _formatPrice(original, label);
}

/// Full page listing sale items across all shops.
/// Linked from the home "On Sale" section.
class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  // Countdown
  Duration _remaining = const Duration(hours: 2, minutes: 45, seconds: 30);
  Timer? _timer;

  String _shopFilter = 'All';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    return '${two(h)}:${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const red = Color(0xFFE53935);
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final all = ProductRepository.allProducts;
    // Index in the master list -> stable discount.
    final indexed = List.generate(all.length, (i) => (i, all[i]));
    final shops = <String>{
      'All',
      ...all.map((p) => p.shopName ?? p.brand),
    }.toList();

    final visible = _shopFilter == 'All'
        ? indexed
        : indexed
            .where((e) => (e.$2.shopName ?? e.$2.brand) == _shopFilter)
            .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        screenWidth >= 1024 ? 4 : (screenWidth >= 640 ? 3 : 2);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const SafeArea(top: false, child: CartBar()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Hero header with countdown ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    // Top bar
                    Row(
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
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.2 : 0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Icon(Icons.arrow_back_ios_rounded,
                                size: 18, color: ink),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Sale banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB0293F), Color(0xFFE53935)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: red.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.white,
                                        size: 22),
                                    const SizedBox(width: 6),
                                    Text('Flash Sale',
                                        style: GoogleFonts.rufina(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Deals from shops across Pyin Mal',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.9))),
                              ],
                            ),
                          ),
                          // Countdown box
                          Column(
                            children: [
                              Text('Ends in',
                                  style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.85))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_countdown,
                                    style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ])),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Shop filter chips ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: shops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final s = shops[i];
                      final sel = _shopFilter == s;
                      return GestureDetector(
                        onTap: () => setState(() => _shopFilter = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? red : cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: sel
                                    ? red
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.creamAlt)),
                          ),
                          child: Center(
                            child: Text(s,
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : ink)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Count ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  '${visible.length} items on sale',
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w500, color: muted),
                ),
              ),
            ),

            // ── Sale grid ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = visible[i];
                    return _SaleCard(
                      product: entry.$2,
                      discount: saleDiscountFor(entry.$1),
                      isDark: isDark,
                      cardBg: cardBg,
                      ink: ink,
                      muted: muted,
                    );
                  },
                  childCount: visible.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Product product;
  final int discount;
  final bool isDark;
  final Color cardBg;
  final Color ink;
  final Color muted;

  const _SaleCard({
    required this.product,
    required this.discount,
    required this.isDark,
    required this.cardBg,
    required this.ink,
    required this.muted,
  });

  // Compute an original price from the sale price + discount, for the
  // struck-through "was" line. Parses the leading number out of the price.
  String _originalPrice() {
    final match = RegExp(r'[\d,]+').firstMatch(product.price);
    if (match == null) return '';
    final sale = int.tryParse(match.group(0)!.replaceAll(',', ''));
    if (sale == null) return '';
    final original = (sale / (1 - discount / 100)).round();
    // Re-add thousands separators + the trailing label (e.g. "MMK").
    final label = product.price.replaceFirst(RegExp(r'[\d,]+'), '').trim();
    final withSep = original.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$withSep $label'.trim();
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen.fromProduct(product, discount: discount),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: CdnImage(product.image,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('-$discount%',
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ink)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 10, color: muted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(product.shopName ?? product.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 10, color: muted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.price,
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: red)),
                        Text(_originalPrice(),
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: muted,
                                decoration: TextDecoration.lineThrough)),
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
