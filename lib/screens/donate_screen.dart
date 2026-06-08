import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class Shelter {
  final String name;
  final String address;
  final String distance;
  final IconData icon;
  final List<String> needs;
  final String hours;
  final bool pickup;

  const Shelter({
    required this.name,
    required this.address,
    required this.distance,
    required this.icon,
    required this.needs,
    required this.hours,
    required this.pickup,
  });
}

class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  static const _shelters = <Shelter>[
    Shelter(
      name: 'Hope Shelter',
      address: 'No. 24, Pyay Road, Sanchaung',
      distance: '1.2 km',
      icon: Icons.home_rounded,
      needs: ['Jackets', 'Hoodies', 'Blankets'],
      hours: 'Open today · 9:00 AM – 6:00 PM',
      pickup: true,
    ),
    Shelter(
      name: 'New Life Center',
      address: 'Bo Aung Kyaw St, Kyauktada',
      distance: '2.8 km',
      icon: Icons.apartment_rounded,
      needs: ['Children\'s wear', 'Shoes', 'T-Shirts'],
      hours: 'Open today · 8:00 AM – 5:00 PM',
      pickup: false,
    ),
    Shelter(
      name: 'Sunrise Home',
      address: 'Insein Road, Hlaing Township',
      distance: '4.1 km',
      icon: Icons.wb_sunny_rounded,
      needs: ['Warm clothes', 'Sweaters'],
      hours: 'Open today · 10:00 AM – 7:00 PM',
      pickup: true,
    ),
    Shelter(
      name: 'Safe Haven',
      address: 'Kabar Aye Pagoda Rd, Yankin',
      distance: '5.6 km',
      icon: Icons.shield_rounded,
      needs: ['Any clean clothes', 'Footwear'],
      hours: 'Closes 8:00 PM',
      pickup: false,
    ),
    Shelter(
      name: 'Metta Care Center',
      address: 'University Ave, Bahan',
      distance: '6.3 km',
      icon: Icons.favorite_rounded,
      needs: ['Men\'s wear', 'Jackets', 'Bags'],
      hours: 'Open 24 hours',
      pickup: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : const Color(0xFFF5F5F5);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ────────────────────────────────────────────────────
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
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back_ios_rounded,
                            size: 18,
                            color: isDark ? Colors.white : AppColors.inkBlack),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Donate Clothes',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.inkBlack,
                        )),
                  ],
                ),
              ),
            ),

            // ── Intro banner ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent.withOpacity(0.18), accent.withOpacity(0.06)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.volunteer_activism_rounded,
                            color: accent, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Give your clothes a second life',
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.inkBlack)),
                            const SizedBox(height: 4),
                            Text(
                                'Choose a nearby shelter and drop off or request a pickup.',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF777777))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section label ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shelters near you',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.inkBlack,
                        )),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: accent),
                        const SizedBox(width: 3),
                        Text('Yangon',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: accent)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Shelter list ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ShelterCard(
                    shelter: _shelters[index],
                    isDark: isDark,
                    accent: accent,
                    cardBg: cardBg,
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

class _ShelterCard extends StatelessWidget {
  final Shelter shelter;
  final bool isDark;
  final Color accent;
  final Color cardBg;

  const _ShelterCard({
    required this.shelter,
    required this.isDark,
    required this.accent,
    required this.cardBg,
  });

  void _confirm(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — ${shelter.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white54 : const Color(0xFF888888);
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(shelter.icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(shelter.name,
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ink)),
                        ),
                        Text(shelter.distance,
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: accent)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 12, color: muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(shelter.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 12, color: muted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: muted),
                        const SizedBox(width: 4),
                        Text(shelter.hours,
                            style:
                                GoogleFonts.outfit(fontSize: 11, color: muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Needs chips
          Text('Currently needs',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: shelter.needs.map((n) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirm(context, 'Directions to'),
                  icon: const Icon(Icons.directions_rounded, size: 15),
                  label: Text('Directions',
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
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirm(
                      context,
                      shelter.pickup
                          ? 'Pickup requested from'
                          : 'Drop-off saved for'),
                  icon: Icon(
                      shelter.pickup
                          ? Icons.local_shipping_rounded
                          : Icons.volunteer_activism_rounded,
                      size: 15),
                  label: Text(shelter.pickup ? 'Request pickup' : 'Donate',
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
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
