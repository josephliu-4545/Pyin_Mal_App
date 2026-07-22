import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/widgets/cart_bar.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';

/// "New In" — a richer discovery layout: a big "just dropped" hero, a
/// horizontal fresh-arrivals strip, then the rest in a grid.
class NewInScreen extends StatefulWidget {
  const NewInScreen({super.key});

  @override
  State<NewInScreen> createState() => _NewInScreenState();
}

class _NewInScreenState extends State<NewInScreen> {
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

    final all = ProductRepository.allProducts;
    final hero = all.isNotEmpty ? all.first : null;
    final strip = all.length > 1 ? all.sublist(1, math.min(8, all.length)) : <Product>[];
    final grid = all.length > 8 ? all.sublist(8) : <Product>[];

    final width = MediaQuery.of(context).size.width;
    final cols = width >= 1024 ? 4 : (width >= 640 ? 3 : 2);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const SafeArea(top: false, child: CartBar()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _topBar(isDark, accent, ink, cardBg,
                title: 'New In', count: all.length,
                icon: Icons.fiber_new_rounded),

            if (hero != null)
              SliverToBoxAdapter(
                child: _heroCard(hero, isDark, accent, ink, 'JUST DROPPED'),
              ),

            if (strip.isNotEmpty) ...[
              _sectionLabel('Fresh arrivals', ink, muted),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 214,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: strip.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        _stripCard(strip[i], isDark, accent, ink, cardBg),
                  ),
                ),
              ),
            ],

            if (grid.isNotEmpty) ...[
              _sectionLabel('More new styles', ink, muted),
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
                    (_, i) => _gridCard(grid[i], isDark, accent, ink, cardBg,
                        badge: 'NEW'),
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

  // ── Shared building blocks (also used by TrendingScreen visually) ──────────

  Widget _topBar(bool isDark, Color accent, Color ink, Color cardBg,
      {required String title, required int count, required IconData icon}) {
    final muted = isDark ? Colors.white54 : const Color(0xFF888888);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: ink),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.rufina(
                        fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
                Text('$count product${count == 1 ? '' : 's'}',
                    style: GoogleFonts.outfit(fontSize: 11, color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color ink, Color muted) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
      ),
    );
  }

  Widget _heroCard(
      Product p, bool isDark, Color accent, Color ink, String badge) {
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
                // bottom scrim
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
                // badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: isDark ? AppColors.charcoal : Colors.white)),
                  ),
                ),
                // info
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

  Widget _stripCard(
      Product p, bool isDark, Color accent, Color ink, Color cardBg) {
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
                        size: 26, color: isDark ? Colors.white24 : Colors.grey),
                  ),
                ),
              ),
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

  Widget _gridCard(
      Product p, bool isDark, Color accent, Color ink, Color cardBg,
      {String? badge}) {
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
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
                  if (badge != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(badge,
                            style: GoogleFonts.outfit(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color:
                                    isDark ? AppColors.charcoal : Colors.white)),
                      ),
                    ),
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
