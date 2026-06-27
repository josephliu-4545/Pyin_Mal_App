import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class _Service {
  final String name;
  final String desc;
  final String category; // Haircut / Coloring / Styling / Treatment
  final int price;
  const _Service(this.name, this.desc, this.category, this.price);
}

class _Salon {
  final String name;
  final String location;
  final double rating;
  final int reviews;
  final List<String> tags;
  final IconData icon;
  final List<_Service> services;
  const _Salon({
    required this.name,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.tags,
    required this.icon,
    required this.services,
  });
}

const _salons = <_Salon>[
  _Salon(
    name: 'Yangon Classic Barber',
    location: 'Bogyoke Market, Yangon',
    rating: 4.8,
    reviews: 95,
    tags: ['Premium', 'Online booking'],
    icon: Icons.content_cut_rounded,
    services: [
      _Service('Classic Haircut', 'Precision cut with scissor work', 'Haircut', 8000),
      _Service('Beard Trim & Shape', 'Professional beard sculpt', 'Haircut', 5000),
      _Service('Kids Cut', 'Gentle cut for kids', 'Haircut', 6000),
      _Service('Full Color', 'Complete coloring session', 'Coloring', 15000),
      _Service('Root Touch Up', 'Regrowth coverage', 'Coloring', 12000),
      _Service('Blowout', 'Professional blow dry', 'Styling', 5000),
      _Service('Deep Conditioning', 'Nourishing treatment', 'Treatment', 6000),
      _Service('Hair Spa', 'Relaxing hair treatment', 'Treatment', 25000),
    ],
  ),
  _Salon(
    name: 'Mandalay Heritage Salon',
    location: '84th Street, Mandalay',
    rating: 4.9,
    reviews: 112,
    tags: ['Modern', 'Luxury'],
    icon: Icons.storefront_rounded,
    services: [
      _Service('Executive Fade', 'Premium skin fade with detail', 'Haircut', 12000),
      _Service('Designer Undercut', 'Precision undercut with design', 'Haircut', 15000),
      _Service('Platinum Blonde', 'Full platinum transformation', 'Coloring', 25000),
      _Service('Luxury Styling', 'Premium products + finish', 'Styling', 10000),
      _Service('Keratin Treatment', 'Smoothing & repair', 'Treatment', 20000),
      _Service('Scalp Therapy', 'Deep scalp care', 'Treatment', 14000),
    ],
  ),
];

class HaircutBookingScreen extends StatefulWidget {
  /// Optional hairstyle chosen from "Try a hairstyle".
  final String? preselectedStyle;
  const HaircutBookingScreen({super.key, this.preselectedStyle});

  @override
  State<HaircutBookingScreen> createState() => _HaircutBookingScreenState();
}

class _HaircutBookingScreenState extends State<HaircutBookingScreen> {
  // Selected services keyed by "salonIndex:serviceName".
  // Only one salon can be active per booking.
  int? _activeSalon;
  final Set<String> _selected = {};
  // Per-salon active category filter.
  final Map<int, String> _category = {};

  static const _categories = ['All', 'Haircut', 'Coloring', 'Styling', 'Treatment'];

  int get _total {
    int sum = 0;
    if (_activeSalon == null) return 0;
    for (final s in _salons[_activeSalon!].services) {
      if (_selected.contains('$_activeSalon:${s.name}')) sum += s.price;
    }
    return sum;
  }

  String _fmt(int v) =>
      v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  void _toggle(int salon, _Service s) {
    setState(() {
      // Switching salon resets selection (one shop per booking).
      if (_activeSalon != salon) {
        _activeSalon = salon;
        _selected.clear();
      }
      final key = '$salon:${s.name}';
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
      if (_selected.isEmpty) _activeSalon = null;
    });
  }

  void _confirm() {
    final count = _selected.length;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accent = isDark ? AppColors.gold : AppColors.burgundy;
        final ink = isDark ? Colors.white : AppColors.inkBlack;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkWarm : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: accent, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Booking confirmed!',
                  style: GoogleFonts.rufina(
                      fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
              const SizedBox(height: 6),
              Text(
                '$count service${count == 1 ? '' : 's'} at ${_salons[_activeSalon!].name}\nTotal ${_fmt(_total)} MMK',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? AppColors.paleText : AppColors.inkGrey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Done',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
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
      bottomNavigationBar: _bottomBar(isDark, accent, ink),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Top bar
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
                                color:
                                    Colors.black.withOpacity(isDark ? 0.2 : 0.07),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_rounded,
                            size: 18, color: ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Book a haircut',
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                  ],
                ),
              ),
            ),

            // Preselected hairstyle banner
            if (widget.preselectedStyle != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chosen hairstyle',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, color: muted)),
                              Text(widget.preselectedStyle!,
                                  style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('Choose a salon & services',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink)),
              ),
            ),

            // Salons
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _salonCard(i, isDark, accent, cardBg, ink, muted),
                childCount: _salons.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _salonCard(int idx, bool isDark, Color accent, Color cardBg, Color ink,
      Color muted) {
    final salon = _salons[idx];
    final cat = _category[idx] ?? 'All';
    final services =
        cat == 'All' ? salon.services : salon.services.where((s) => s.category == cat).toList();
    final dimmed = _activeSalon != null && _activeSalon != idx;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _activeSalon == idx
                ? accent
                : (isDark ? AppColors.darkBorder : AppColors.creamAlt),
            width: _activeSalon == idx ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salon header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(salon.icon, color: accent, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salon.name,
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              size: 13, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text('${salon.rating} (${salon.reviews})',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: muted)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('· ${salon.location}',
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
            const SizedBox(height: 10),
            // Tags
            Wrap(
              spacing: 6,
              children: salon.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
            // Category filter
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, ci) {
                  final c = _categories[ci];
                  final sel = cat == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category[idx] = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? accent
                            : (isDark
                                ? AppColors.charcoal
                                : const Color(0xFFF2F2F2)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? (isDark ? AppColors.charcoal : Colors.white)
                                  : ink)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Services
            ...services.map((s) {
              final checked = _selected.contains('$idx:${s.name}');
              return GestureDetector(
                onTap: () => _toggle(idx, s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.charcoal : const Color(0xFFF7F5F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: checked ? accent : Colors.transparent,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            const SizedBox(height: 2),
                            Text(s.desc,
                                style: GoogleFonts.outfit(
                                    fontSize: 11, color: muted)),
                          ],
                        ),
                      ),
                      Text('${_fmt(s.price)} MMK',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                      const SizedBox(width: 10),
                      // Checkbox
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: checked ? accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: checked ? accent : muted, width: 1.6),
                        ),
                        child: checked
                            ? Icon(Icons.check_rounded,
                                size: 15,
                                color: isDark
                                    ? AppColors.charcoal
                                    : Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(bool isDark, Color accent, Color ink) {
    final hasSelection = _selected.isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? AppColors.paleText : AppColors.inkGrey)),
                Text('${_fmt(_total)} MMK',
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: accent)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hasSelection ? _confirm : null,
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: Text(
                    hasSelection
                        ? 'Confirm booking (${_selected.length})'
                        : 'Select services',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor:
                      isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
