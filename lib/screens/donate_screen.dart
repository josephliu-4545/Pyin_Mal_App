import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';

class Shelter {
  final String name;
  final String address;
  final String city; // 'Yangon' or 'Mandalay'
  final IconData icon;
  final List<String> needs;
  final String hours;
  final bool pickup;
  final double urgency; // 0..1 — how urgently they need donations
  final String about;

  const Shelter({
    required this.name,
    required this.address,
    required this.city,
    required this.icon,
    required this.needs,
    required this.hours,
    required this.pickup,
    required this.urgency,
    required this.about,
  });

  /// Search string Google Maps can resolve to the real place.
  String get mapsQuery => '$name, $address, $city, Myanmar';
}

// ── Open Google Maps directions to a shelter ──────────────────────────────────
Future<void> _launchDirections(BuildContext context, Shelter s) async {
  final q = Uri.encodeComponent(s.mapsQuery);
  final dir =
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q');
  final search =
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
  try {
    final ok = await launchUrl(dir, mode: LaunchMode.externalApplication);
    if (!ok) await launchUrl(search, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }
}

// ── Shelter "About" detail sheet ──────────────────────────────────────────────
void _showShelterDetails(
    BuildContext context, Shelter s, bool isDark, Color accent) {
  final ink = isDark ? Colors.white : AppColors.inkBlack;
  final muted = isDark ? Colors.white60 : const Color(0xFF888888);
  final sheetBg = isDark ? AppColors.charcoal : Colors.white;
  final urgent = s.urgency >= 0.7;

  Widget infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.outfit(
                      fontSize: 13, height: 1.4, color: ink)),
            ),
          ],
        ),
      );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: muted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(s.icon, color: accent, size: 27),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: GoogleFonts.rufina(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ink)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on_rounded,
                                      size: 12, color: accent),
                                  const SizedBox(width: 3),
                                  Text(s.city,
                                      style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: accent)),
                                ],
                              ),
                            ),
                            if (urgent) ...[
                              const SizedBox(width: 8),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // About
              Text('About',
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 6),
              Text(s.about,
                  style: GoogleFonts.outfit(
                      fontSize: 13, height: 1.5, color: muted)),
              const SizedBox(height: 18),
              // Info
              infoRow(Icons.place_outlined, '${s.address}, ${s.city}'),
              infoRow(Icons.schedule_rounded, s.hours),
              infoRow(
                  s.pickup
                      ? Icons.local_shipping_outlined
                      : Icons.volunteer_activism_outlined,
                  s.pickup
                      ? 'Pickup available for donations'
                      : 'Drop-off donations welcome'),
              const SizedBox(height: 6),
              // Needs
              Text('donate.currently_needs'.tr(),
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: s.needs
                    .map((n) => Container(
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
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              Text(
                'Hours and current needs are indicative — please contact the centre to confirm before visiting.',
                style: GoogleFonts.outfit(
                    fontSize: 11, fontStyle: FontStyle.italic, color: muted),
              ),
              const SizedBox(height: 20),
              // Directions button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _launchDirections(sheetCtx, s),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text('donate.directions'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor:
                        isDark ? AppColors.charcoal : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen>
    with TickerProviderStateMixin {
  // Real, well-known charitable organisations in Yangon and Mandalay.
  // The Directions button resolves each place by name via Google Maps.
  static const _shelters = <Shelter>[
    Shelter(
      name: 'Hninzigon Home for the Aged',
      address: 'Kabar Aye Pagoda Rd, Bahan Tsp',
      city: 'Yangon',
      icon: Icons.elderly_rounded,
      needs: ['Warm clothes', 'Blankets', 'Longyi'],
      hours: 'Open daily · 9:00 AM – 5:00 PM',
      pickup: false,
      urgency: 0.7,
      about:
          'One of Myanmar\'s oldest and largest charitable homes for the elderly, '
          'caring for hundreds of residents in Bahan Township. Donations of '
          'clothing, blankets and daily essentials are always welcome.',
    ),
    Shelter(
      name: 'Free Funeral Service Society',
      address: 'Thaketa Township',
      city: 'Yangon',
      icon: Icons.volunteer_activism_rounded,
      needs: ['Any clean clothes', 'Footwear'],
      hours: 'Open daily · 9:00 AM – 4:00 PM',
      pickup: false,
      urgency: 0.5,
      about:
          'Founded by actor Kyaw Thu, the FFSS provides free funeral services and '
          'also runs a free clinic, library and education programs for people in need.',
    ),
    Shelter(
      name: 'Thabarwa Centre',
      address: 'Thanlyin',
      city: 'Yangon',
      icon: Icons.spa_rounded,
      needs: ['Clothes', 'Blankets', 'Medical supplies'],
      hours: 'Open 24 hours',
      pickup: true,
      urgency: 0.85,
      about:
          'A large community centre founded by Sayadaw U Ottamasara that shelters '
          'thousands of sick, elderly and homeless people. It relies entirely on '
          'donations and volunteers.',
    ),
    Shelter(
      name: 'Phaung Daw Oo Monastic Education School',
      address: 'Pyigyitagon Township',
      city: 'Mandalay',
      icon: Icons.school_rounded,
      needs: ['Children\'s wear', 'Shoes', 'Stationery'],
      hours: 'Mon – Fri · 8:00 AM – 4:00 PM',
      pickup: false,
      urgency: 0.6,
      about:
          'A renowned monastic school providing free education to thousands of '
          'underprivileged children in Mandalay. It welcomes donations of clothing, '
          'school supplies and food.',
    ),
    Shelter(
      name: 'Aung Myae Oo Monastic Free Education School',
      address: 'Sagaing (near Mandalay)',
      city: 'Mandalay',
      icon: Icons.menu_book_rounded,
      needs: ['Uniforms', 'Warm clothes', 'Books'],
      hours: 'Mon – Fri · 8:00 AM – 4:00 PM',
      pickup: false,
      urgency: 0.55,
      about:
          'A large free monastic school near Mandalay educating thousands of '
          'children from poor families, supported entirely by public donations.',
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
                            Text('Yangon · Mandalay',
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
                      key: index == 0 ? GuideKeys.donateDirections : null,
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
    super.key,
    required this.shelter,
    required this.isDark,
    required this.accent,
  });

  @override
  State<_ShelterCard> createState() => _ShelterCardState();
}

class _ShelterCardState extends State<_ShelterCard> {
  bool _pressed = false;

  // Pickup form — for donors who can't travel, a rider collects the
  // donation from their address and delivers it to the shelter.
  void _openPickupForm() {
    final isDark = widget.isDark;
    final accent = widget.accent;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? Colors.white54 : const Color(0xFF888888);
    final fieldBg = isDark ? Colors.white10 : const Color(0xFFF4F4F4);

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final selectedItems = <String>{'Clothes'};
    String timeSlot = '9–12 AM';
    DateTime? date;

    InputDecoration deco(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 13, color: muted),
          prefixIcon: Icon(icon, size: 18, color: accent),
          filled: true,
          fillColor: fieldBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 1.4),
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text('Donation pickup',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text(
                        'Can\'t make it there? A rider will collect your donation and deliver it to ${widget.shelter.name} for free.',
                        style: GoogleFonts.outfit(
                            fontSize: 12, height: 1.4, color: muted)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.outfit(fontSize: 13, color: ink),
                      decoration:
                          deco('Your name', Icons.person_outline_rounded),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(fontSize: 13, color: ink),
                      decoration: deco(
                          'Phone number (09xxxxxxxxx)', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressCtrl,
                      style: GoogleFonts.outfit(fontSize: 13, color: ink),
                      decoration:
                          deco('Pickup address', Icons.place_outlined),
                    ),
                    const SizedBox(height: 14),
                    Text('What are you donating?',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in [
                          'Clothes',
                          'Blankets',
                          'Footwear',
                          'Longyi',
                          'Other'
                        ])
                          GestureDetector(
                            onTap: () => setSheet(() {
                              selectedItems.contains(item)
                                  ? selectedItems.remove(item)
                                  : selectedItems.add(item);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 13, vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedItems.contains(item)
                                    ? accent.withOpacity(0.14)
                                    : fieldBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selectedItems.contains(item)
                                        ? accent
                                        : Colors.transparent,
                                    width: 1.4),
                              ),
                              child: Text(item,
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selectedItems.contains(item)
                                          ? accent
                                          : ink)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Date + time slot
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: sheetCtx,
                                initialDate:
                                    now.add(const Duration(days: 1)),
                                firstDate: now,
                                lastDate:
                                    now.add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setSheet(() => date = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 13),
                              decoration: BoxDecoration(
                                color: fieldBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 16, color: accent),
                                  const SizedBox(width: 8),
                                  Text(
                                      date == null
                                          ? 'Pickup date'
                                          : '${date!.day}/${date!.month}/${date!.year}',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: date != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color:
                                              date != null ? ink : muted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final t in ['9–12 AM', '12–4 PM', '4–7 PM'])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setSheet(() => timeSlot = t),
                              child: Container(
                                margin: EdgeInsets.only(
                                    right: t == '4–7 PM' ? 0 : 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      timeSlot == t ? accent : fieldBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(t,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: timeSlot == t
                                            ? (isDark
                                                ? AppColors.charcoal
                                                : Colors.white)
                                            : ink)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: GoogleFonts.outfit(fontSize: 13, color: ink),
                      decoration: deco('Notes for the rider (optional)',
                          Icons.edit_note_rounded),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty ||
                              addressCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill in your name, phone and address')),
                            );
                            return;
                          }
                          if (date == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Please pick a pickup date')),
                            );
                            return;
                          }
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                              content: Text(
                                  'Pickup booked! A rider will collect your donation on ${date!.day}/${date!.month} ($timeSlot) and deliver it to ${widget.shelter.name}. +200 pts'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_shipping_rounded,
                            size: 17),
                        label: Text('Confirm pickup',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor:
                              isDark ? AppColors.charcoal : Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
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
        onTap: () => _showShelterDetails(context, s, isDark, accent),
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
                            Text(s.city,
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
                      onPressed: () => _launchDirections(context, s),
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
                      onPressed: _openPickupForm,
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
