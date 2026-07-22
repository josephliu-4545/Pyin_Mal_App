import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/widgets/cart_bar.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';

/// "Trend" — a featured #1 hero, a Top-picks carousel, then a ranked grid.
class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  @override
  void initState() {
    super.initState();
    ProductRepository.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _open(Product p) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen.fromProduct(p)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F5F5);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? Colors.white54 : const Color(0xFF888888);

    // No live popularity data yet, so "trending" = a curated slice.
    final products = ProductRepository.allProducts.take(20).toList();
    final hero = products.isNotEmpty ? products.first : null;
    final strip = products.length > 1
        ? products.sublist(1, math.min(7, products.length))
        : <Product>[];
    final grid = products.length > 7 ? products.sublist(7) : <Product>[];

    final width = MediaQuery.of(context).size.width;
    final cols = width >= 1024 ? 4 : (width >= 640 ? 3 : 2);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const SafeArea(top: false, child: CartBar()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                    const SizedBox(width: 12),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          shape: BoxShape.circle),
                      child: Icon(Icons.local_fire_department_rounded,
                          size: 18, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trending Now',
                            style: GoogleFonts.rufina(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ink)),
                        Text('Loved by shoppers this week',
                            style:
                                GoogleFonts.outfit(fontSize: 11, color: muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── #1 hero ──
            if (hero != null)
              SliverToBoxAdapter(
                child: _heroCard(hero, isDark, accent),
              ),

            // ── Top picks carousel ──
            if (strip.isNotEmpty) ...[
              _sectionLabel('Top picks', ink),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 214,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: strip.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _stripCard(
                        strip[i], i + 2, isDark, accent, ink, cardBg),
                  ),
                ),
              ),
            ],

            // ── More trending grid ──
            if (grid.isNotEmpty) ...[
              _sectionLabel('More trending', ink),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _gridCard(
                        grid[i], i + 8, isDark, accent, ink, cardBg),
                    childCount: grid.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color ink) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
      ),
    );
  }

  Widget _rankBadge(int rank, {bool big = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: big ? 10 : 8, vertical: big ? 5 : 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded,
              size: big ? 13 : 11, color: const Color(0xFFFF7043)),
          const SizedBox(width: 3),
          Text('#$rank',
              style: GoogleFonts.outfit(
                  fontSize: big ? 12 : 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _heroCard(Product p, bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => _open(p),
        child: Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CdnImage(
                  p.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark
                        ? const Color(0xFF2A2421)
                        : const Color(0xFFEDEDED),
                    child: Icon(Icons.image_outlined,
                        size: 40, color: isDark ? Colors.white24 : Colors.grey),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(top: 14, left: 14, child: _rankBadge(1, big: true)),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.brand.toUpperCase(),
                                style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: Colors.white70)),
                            const SizedBox(height: 3),
                            Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.rufina(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(p.price,
                                style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: accent)),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded,
                                size: 13, color: accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stripCard(Product p, int rank, bool isDark, Color accent, Color ink,
      Color cardBg) {
    return GestureDetector(
      onTap: () => _open(p),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: CdnImage(
                      p.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: isDark
                            ? const Color(0xFF2A2421)
                            : const Color(0xFFF2F2F2),
                        child: Icon(Icons.image_outlined,
                            size: 26,
                            color: isDark ? Colors.white24 : Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(top: 8, left: 8, child: _rankBadge(rank)),
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
                  Text(p.price,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCard(Product p, int rank, bool isDark, Color accent, Color ink,
      Color cardBg) {
    return GestureDetector(
      onTap: () => _open(p),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: SizedBox.expand(
                      child: CdnImage(
                        p.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF2A2421)
                              : const Color(0xFFF2F2F2),
                          child: Icon(Icons.image_outlined,
                              size: 32,
                              color: isDark ? Colors.white24 : Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Positioned(top: 8, left: 8, child: _rankBadge(rank)),
                ],
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
                        Text(p.brand.toUpperCase(),
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 3),
                        Text(p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                color: ink)),
                      ],
                    ),
                    Text(p.price,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accent)),
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
