import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  int _tab = 0; // 0 = Active, 1 = History

  // step index 0..3 (Placed, Packed, On the way, Delivered)
  static const _orders = <(String, String, String, int, String)>[
    ('PM2048', 'NRF Deathwish Hoodie', '45,000 MMK', 2, 'Est. today, 2:30 PM'),
    ('PM2051', 'Luna Set 2',           '55,000 MMK', 1, 'Est. tomorrow'),
  ];
  static const _history = <(String, String, String, int, String)>[
    ('PM1990', 'ABCD Tee',         '15,000 MMK', 3, 'Delivered · 12 Jun'),
    ('PM1974', 'AJOHN V2 Hoodie',  '38,000 MMK', 3, 'Delivered · 5 Jun'),
  ];

  static const _steps = ['Placed', 'Packed', 'On the way', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final list = _tab == 0 ? _orders : _history;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery',
                        style: GoogleFonts.rufina(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text('Track your orders in real time',
                        style: GoogleFonts.outfit(fontSize: 13, color: muted)),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            // Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkWarm : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _tabBtn('Active', 0, isDark, accent, ink),
                      _tabBtn('History', 1, isDark, accent, ink),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // Orders
            if (list.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No orders here yet',
                        style: GoogleFonts.outfit(fontSize: 13, color: muted)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _orderCard(
                        list[i], isDark, accent, ink, muted),
                    childCount: list.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int i, bool isDark, Color accent, Color ink) {
    final sel = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sel
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : ink)),
        ),
      ),
    );
  }

  Widget _orderCard((String, String, String, int, String) o, bool isDark,
      Color accent, Color ink, Color muted) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final step = o.$4;
    final delivered = step >= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                    delivered
                        ? Icons.inventory_2_rounded
                        : Icons.local_shipping_rounded,
                    color: accent,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 2),
                    Text('Order #${o.$1} · ${o.$3}',
                        style:
                            GoogleFonts.outfit(fontSize: 12, color: muted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (delivered ? Colors.green : accent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(delivered ? 'Done' : 'Live',
                    style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: delivered ? Colors.green.shade600 : accent)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tracker
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final done = (i ~/ 2) < step;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: done
                        ? accent
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.inkGrey.withOpacity(0.25)),
                  ),
                );
              }
              final idx = i ~/ 2;
              final done = idx <= step;
              return Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done
                          ? accent
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt),
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? Icon(Icons.check_rounded,
                            size: 13,
                            color: isDark ? AppColors.charcoal : Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 52,
                    child: Text(_steps[idx],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight:
                                done ? FontWeight.w600 : FontWeight.w400,
                            color: done ? accent : muted)),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),

          // Footer (ETA + action)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: muted),
                  const SizedBox(width: 5),
                  Text(o.$5,
                      style:
                          GoogleFonts.outfit(fontSize: 12, color: muted)),
                ],
              ),
              if (!delivered)
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Tracking order #${o.$1}'),
                      duration: const Duration(seconds: 2),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: accent, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Track',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Reordering ${o.$2}'),
                      duration: const Duration(seconds: 2),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Reorder',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
