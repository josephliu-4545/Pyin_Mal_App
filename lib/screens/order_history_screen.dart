import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Make sure the catalog is loaded so purchases resolve to product
    // names/images even when this screen is opened right after app start.
    ProductRepository.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _fmtPrice(double v) {
    final s = v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$s MMK';
  }

  String _fmtDate(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        title: Text('order_history.title'.tr(),
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService().streamPurchases(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accent));
          }
          final purchases = snap.data ?? const [];

          if (purchases.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: muted),
                    const SizedBox(height: 16),
                    Text('order_history.empty_title'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 6),
                    Text('order_history.empty_desc'.tr(),
                        textAlign: TextAlign.center,
                        style:
                            GoogleFonts.outfit(fontSize: 13, color: muted)),
                  ],
                ),
              ),
            );
          }

          // Summary totals
          double totalSpent = 0;
          int totalPoints = 0;
          for (final p in purchases) {
            totalSpent += (p['price'] as num?)?.toDouble() ?? 0;
            totalPoints += (p['pointsEarned'] as num?)?.toInt() ?? 0;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              // ── Summary card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'order_history.orders_count'
                                  .tr(args: [purchases.length.toString()]),
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: muted)),
                          const SizedBox(height: 4),
                          Text(_fmtPrice(totalSpent),
                              style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: ink)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded,
                              size: 16,
                              color:
                                  isDark ? AppColors.charcoal : Colors.white),
                          const SizedBox(width: 5),
                          Text(
                              'order_history.points_earned'
                                  .tr(args: [totalPoints.toString()]),
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.charcoal
                                      : Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Purchase list ──
              ...purchases.map((p) {
                final productId = p['productId'] as String? ?? '';
                final product = ProductRepository.getProductById(productId);
                final price = (p['price'] as num?)?.toDouble() ?? 0;
                final points = (p['pointsEarned'] as num?)?.toInt() ?? 0;
                final date = _fmtDate(p['timestamp']);

                return GestureDetector(
                  onTap: product == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen.fromProduct(product)),
                          ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: product != null
                                ? CdnImage(
                                    product.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: isDark
                                          ? AppColors.charcoal
                                          : AppColors.creamAlt,
                                      child: Icon(Icons.checkroom_rounded,
                                          size: 24, color: muted),
                                    ),
                                  )
                                : Container(
                                    color: isDark
                                        ? AppColors.charcoal
                                        : AppColors.creamAlt,
                                    child: Icon(Icons.checkroom_rounded,
                                        size: 24, color: muted),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  product?.name ??
                                      'order_history.unknown_item'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ink)),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 12, color: muted),
                                  const SizedBox(width: 4),
                                  Text(date,
                                      style: GoogleFonts.outfit(
                                          fontSize: 11, color: muted)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.stars_rounded,
                                      size: 12, color: accent),
                                  const SizedBox(width: 3),
                                  Text('+$points',
                                      style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(_fmtPrice(price),
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: accent)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
