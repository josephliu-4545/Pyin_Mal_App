import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';

class Shelter {
  final String name;
  final String address;
  final String distance;
  final IconData icon;
  final List<String> needs;
  final String hours;
  final bool pickup;
  final double urgency; // 0..1 — how urgently they need donations

  const Shelter({
    required this.name,
    required this.address,
    required this.distance,
    required this.icon,
    required this.needs,
    required this.hours,
    required this.pickup,
    required this.urgency,
  });
}

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen>
    with TickerProviderStateMixin {
  static const _shelters = <Shelter>[
    Shelter(
      name: 'Hope Shelter',
      address: 'No. 24, Pyay Road, Sanchaung',
      distance: '1.2 km',
      icon: Icons.home_rounded,
      needs: ['Jackets', 'Hoodies', 'Blankets'],
      hours: 'Open today · 9:00 AM – 6:00 PM',
      pickup: true,
      urgency: 0.9,
    ),
    Shelter(
      name: 'New Life Center',
      address: 'Bo Aung Kyaw St, Kyauktada',
      distance: '2.8 km',
      icon: Icons.apartment_rounded,
      needs: ['Children\'s wear', 'Shoes', 'T-Shirts'],
      hours: 'Open today · 8:00 AM – 5:00 PM',
      pickup: false,
      urgency: 0.6,
    ),
    Shelter(
      name: 'Sunrise Home',
      address: 'Insein Road, Hlaing Township',
      distance: '4.1 km',
      icon: Icons.wb_sunny_rounded,
      needs: ['Warm clothes', 'Sweaters'],
      hours: 'Open today · 10:00 AM – 7:00 PM',
      pickup: true,
      urgency: 0.45,
    ),
    Shelter(
      name: 'Safe Haven',
      address: 'Kabar Aye Pagoda Rd, Yankin',
      distance: '5.6 km',
      icon: Icons.shield_rounded,
      needs: ['Any clean clothes', 'Footwear'],
      hours: 'Closes 8:00 PM',
      pickup: false,
      urgency: 0.75,
    ),
    Shelter(
      name: 'Metta Care Center',
      address: 'University Ave, Bahan',
      distance: '6.3 km',
      icon: Icons.favorite_rounded,
      needs: ['Men\'s wear', 'Jackets', 'Bags'],
      hours: 'Open 24 hours',
      pickup: true,
      urgency: 0.55,
    ),
  ];

  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// A reveal animation for the item at [index], staggered down the list.
  Animation<double> _stagger(int index, {int total = 8}) {
    final start = (index / total).clamp(0.0, 0.9);
    final end = (start + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _reveal(int index, Widget child) {
    final anim = _stagger(index);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Top bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _reveal(
                0,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.arrow_back_ios_rounded,
                        isDark: isDark,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Text('donate.title'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          )),
                    ],
                  ),
                ),
              ),
            ),

            // ── Hero impact card ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _reveal(
                1,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: _HeroImpactCard(
                    accent: accent,
                    isDark: isDark,
                    progress: _intro,
                  ),
                ),
              ),
            ),

            // ── Section header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _reveal(
                2,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('donate.shelters_near_you'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 13, color: accent),
                            const SizedBox(width: 3),
                            Text('donate.yangon'.tr(),
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Shelter list ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _reveal(
                    index + 3,
                    _ShelterCard(
                      shelter: _shelters[index],
                      isDark: isDark,
                      accent: accent,
                    ),
                  ),
                  childCount: _shelters.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero impact card with animated counters + gentle pulse ────────────────────
class _HeroImpactCard extends StatefulWidget {
  final Color accent;
  final bool isDark;
  final Animation<double> progress;
  const _HeroImpactCard({
    required this.accent,
    required this.isDark,
    required this.progress,
  });

  @override
  State<_HeroImpactCard> createState() => _HeroImpactCardState();
}

class _HeroImpactCardState extends State<_HeroImpactCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final isDark = widget.isDark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [accent.withOpacity(0.30), AppColors.darkWarm]
              : [accent, accent.withOpacity(0.78)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(isDark ? 0.25 : 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pulsing badge
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final t = _pulse.value;
                  return Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.25 * (1 - t)),
                          blurRadius: 6 + 14 * t,
                          spreadRadius: 2 * t,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: const Center(
                  child: Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('donate.kindness_counts'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 3),
                    Text('donate.kindness_desc'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.85),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated stat row
          Row(
            children: [
              _Stat(
                  progress: widget.progress,
                  target: 1240,
                  label: 'donate.items_donated'.tr(),
                  suffix: '+'),
              _divider(),
              _Stat(
                  progress: widget.progress,
                  target: 38,
                  label: 'donate.families_helped'.tr(),
                  suffix: ''),
              _divider(),
              _Stat(
                  progress: widget.progress,
                  target: 5,
                  label: 'donate.shelters_count'.tr(),
                  suffix: ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.22),
      );
}

class _Stat extends StatelessWidget {
  final Animation<double> progress;
  final int target;
  final String label;
  final String suffix;
  const _Stat({
    required this.progress,
    required this.target,
    required this.label,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: progress,
        builder: (_, __) {
          final value = (target * progress.value).round();
          return Column(
            children: [
              Text('$value$suffix',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ── Shelter card with press scale + tap actions ──────────────────────────────
class _ShelterCard extends StatefulWidget {
  final Shelter shelter;
  final bool isDark;
  final Color accent;

  const _ShelterCard({
    required this.shelter,
    required this.isDark,
    required this.accent,
  });

  @override
  State<_ShelterCard> createState() => _ShelterCardState();
}

class _ShelterCardState extends State<_ShelterCard> {
  bool _pressed = false;

  void _confirm(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$action — ${widget.shelter.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.shelter;
    final isDark = widget.isDark;
    final accent = widget.accent;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final muted = isDark ? Colors.white54 : const Color(0xFF888888);
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    final urgent = s.urgency >= 0.7;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(s.icon, color: accent, size: 25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(s.name,
                                  style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: ink)),
                            ),
                            if (urgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('donate.urgent'.tr(),
                                    style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFE53935))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.place_outlined, size: 12, color: muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(s.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12, color: muted)),
                            ),
                            const SizedBox(width: 6),
                            Text(s.distance,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 12, color: muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(s.hours,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, color: muted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('donate.currently_needs'.tr(),
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: s.needs.map((n) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(n,
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accent)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirm('${'donate.directions_to'.tr()} '),
                      icon: const Icon(Icons.directions_rounded, size: 15),
                      label: Text('donate.directions'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFCCCCCC)),
                        foregroundColor: ink,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirm(s.pickup
                          ? 'donate.pickup_from'.tr()
                          : 'donate.drop_off_for'.tr()),
                      icon: Icon(
                          s.pickup
                              ? Icons.local_shipping_rounded
                              : Icons.volunteer_activism_rounded,
                          size: 15),
                      label: Text(s.pickup ? 'donate.request_pickup'.tr() : 'donate.donate_btn'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        backgroundColor:
                            isDark ? Colors.white : AppColors.inkBlack,
                        foregroundColor:
                            isDark ? AppColors.charcoal : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable circular icon button ────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 18, color: isDark ? Colors.white : AppColors.inkBlack),
      ),
    );
  }
}
