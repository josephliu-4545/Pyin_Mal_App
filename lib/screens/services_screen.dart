import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/resell_screen.dart';
import 'package:pyin_mal_app/screens/donate_screen.dart';

/// Footer "Services" tab — hosts the two community services (Resell & Donate)
/// under a simple two-tab switcher. The child screens run in `embedded` mode so
/// they don't render their own back button / header here.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _tab = 0; // 0 = Resell, 1 = Donate

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.handshake_rounded, color: accent, size: 22),
                  const SizedBox(width: 10),
                  Text('Services',
                      style: GoogleFonts.rufina(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ink)),
                ],
              ),
            ),
            // ── Tab switcher ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkWarm : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                ),
                child: Row(
                  children: [
                    _tabButton(
                        0, 'Resell', Icons.sell_rounded, accent, ink, muted, isDark),
                    _tabButton(1, 'Donate', Icons.volunteer_activism_rounded,
                        accent, ink, muted, isDark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Selected service ──
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  ResellScreen(embedded: true),
                  DonateScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int idx, String label, IconData icon, Color accent,
      Color ink, Color muted, bool isDark) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: sel
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : muted),
              const SizedBox(width: 7),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: sel
                          ? (isDark ? AppColors.charcoal : Colors.white)
                          : ink)),
            ],
          ),
        ),
      ),
    );
  }
}
