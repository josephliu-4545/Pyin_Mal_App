import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/ar_fitting_room_screen.dart';
import 'package:pyin_mal_app/screens/ar_hair_filter_screen.dart';

/// "Future Plan" — a roadmap of features coming to Ta Chat Nhate. The AR
/// try-on experiences (clothing + hair) live here as previews while they are
/// still being polished for release.
class FuturePlanScreen extends StatelessWidget {
  const FuturePlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('futureplan.title'.tr(),
            style: GoogleFonts.rufina(
                color: ink, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'futureplan.subtitle'.tr(),
            style: GoogleFonts.outfit(fontSize: 13, height: 1.5, color: muted),
          ),
          const SizedBox(height: 20),

          // ── AR Try-On (clothing / shop) ──
          _futureCard(
            isDark: isDark,
            accent: accent,
            ink: ink,
            muted: muted,
            icon: Icons.view_in_ar_rounded,
            title: 'futureplan.ar_clothing_title'.tr(),
            description: 'futureplan.ar_clothing_desc'.tr(),
            highlights: [
              'futureplan.ar_clothing_h1'.tr(),
              'futureplan.ar_clothing_h2'.tr(),
              'futureplan.ar_clothing_h3'.tr(),
            ],
            buttonLabel: 'futureplan.try_ar'.tr(),
            onTry: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ARFittingRoomScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // ── AR Hair Try-On ──
          _futureCard(
            isDark: isDark,
            accent: accent,
            ink: ink,
            muted: muted,
            icon: Icons.face_retouching_natural_rounded,
            title: 'futureplan.ar_hair_title'.tr(),
            description: 'futureplan.ar_hair_desc'.tr(),
            highlights: [
              'futureplan.ar_hair_h1'.tr(),
              'futureplan.ar_hair_h2'.tr(),
              'futureplan.ar_hair_h3'.tr(),
            ],
            buttonLabel: 'futureplan.try_ar'.tr(),
            onTry: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ARHairFilterScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _futureCard({
    required bool isDark,
    required Color accent,
    required Color ink,
    required Color muted,
    required IconData icon,
    required String title,
    required String description,
    required List<String> highlights,
    required String buttonLabel,
    required VoidCallback onTry,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.rufina(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ink)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: accent),
                          const SizedBox(width: 5),
                          Text('futureplan.coming_soon'.tr(),
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(description,
              style: GoogleFonts.outfit(
                  fontSize: 13, height: 1.5, color: muted)),
          const SizedBox(height: 14),
          ...highlights.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(h,
                          style: GoogleFonts.outfit(
                              fontSize: 12.5, height: 1.4, color: ink)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTry,
              icon: const Icon(Icons.view_in_ar_rounded, size: 18),
              label: Text(buttonLabel,
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
