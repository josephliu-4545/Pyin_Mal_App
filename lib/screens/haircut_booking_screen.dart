import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final List<String> branches; // branch locations across Yangon & Mandalay
  final double rating;
  final int reviews;
  final List<String> tags;
  final IconData icon;
  final List<_Service> services;
  const _Salon({
    required this.name,
    required this.branches,
    required this.rating,
    required this.reviews,
    required this.tags,
    required this.icon,
    required this.services,
  });
}

const _salons = <_Salon>[
  _Salon(
    name: 'V47',
    branches: [
      'Hledan Center, Yangon',
      'Junction City, Yangon',
      'Myanmar Plaza, Yangon',
      '78th Street, Mandalay',
    ],
    rating: 4.8,
    reviews: 312,
    tags: ['Premium', 'Online booking', '4 branches'],
    icon: Icons.content_cut_rounded,
    services: [
      _Service('Signature Haircut', 'Precision cut with scissor work', 'Haircut', 18000),
      _Service('Skin Fade', 'Sharp clean skin fade', 'Haircut', 20000),
      _Service('Beard Trim & Shape', 'Professional beard sculpt', 'Haircut', 12000),
      _Service('Kids Cut', 'Gentle cut for kids', 'Haircut', 12000),
      _Service('Full Color', 'Complete coloring session', 'Coloring', 45000),
      _Service('Highlights', 'Dimensional highlights', 'Coloring', 65000),
      _Service('Pomade Styling', 'Slick pomade finish', 'Styling', 10000),
      _Service('Blowout', 'Professional blow dry', 'Styling', 12000),
      _Service('Hot Towel Treatment', 'Warm towel care', 'Treatment', 15000),
      _Service('Scalp Massage', 'Relaxing scalp massage', 'Treatment', 18000),
    ],
  ),
  _Salon(
    name: 'VIP Salon',
    branches: [
      'Dagon Center 2, Yangon',
      'Sule Square, Yangon',
      'Ocean North Point, Yangon',
      '84th Street, Mandalay',
    ],
    rating: 4.7,
    reviews: 268,
    tags: ['Luxury', 'Online booking', '4 branches'],
    icon: Icons.diamond_rounded,
    services: [
      _Service('VIP Haircut', 'Premium tailored cut', 'Haircut', 22000),
      _Service('Executive Fade', 'Detailed skin fade', 'Haircut', 25000),
      _Service('Precision Beard', 'Sharp beard sculpt', 'Haircut', 15000),
      _Service('Full Color', 'Complete coloring session', 'Coloring', 55000),
      _Service('Root Touch Up', 'Regrowth coverage', 'Coloring', 40000),
      _Service('Ombré', 'Graduated colour blend', 'Coloring', 85000),
      _Service('Luxury Styling', 'Premium products + finish', 'Styling', 18000),
      _Service('Royal Shave', 'Luxury straight shave', 'Styling', 20000),
      _Service('Keratin Treatment', 'Smoothing & repair', 'Treatment', 120000),
      _Service('Gold Hair Treatment', 'Gold-infused care', 'Treatment', 90000),
    ],
  ),
  _Salon(
    name: 'T8',
    branches: [
      'Kamayut, Yangon',
      'Times City, Yangon',
      'Junction Square, Yangon',
      'Diamond Plaza, Mandalay',
    ],
    rating: 4.8,
    reviews: 401,
    tags: ['Trendy', 'Fast', '4 branches'],
    icon: Icons.brush_rounded,
    services: [
      _Service('Trend Cut', 'On-trend modern cut', 'Haircut', 16000),
      _Service('Two Block', 'Korean two-block style', 'Haircut', 18000),
      _Service('Taper Fade', 'Clean taper fade', 'Haircut', 17000),
      _Service('Perm', 'Soft texture perm', 'Styling', 60000),
      _Service('Down Perm', 'Side volume control perm', 'Styling', 35000),
      _Service('Color & Style', 'Colour with finish', 'Coloring', 70000),
      _Service('Highlights', 'Dimensional highlights', 'Coloring', 75000),
      _Service('Blowout', 'Professional blow dry', 'Styling', 12000),
      _Service('Hair Spa', 'Relaxing hair treatment', 'Treatment', 30000),
      _Service('Scalp Treatment', 'Targeted scalp care', 'Treatment', 35000),
    ],
  ),
  _Salon(
    name: 'Tony Tun Tun',
    branches: [
      'Myanmar Plaza, Yangon',
      'Junction Square, Yangon',
      'Gamone Pwint, Yangon',
      'Mingalar Mandalay, Mandalay',
      '78th Street, Mandalay',
    ],
    rating: 4.9,
    reviews: 540,
    tags: ['Celebrity stylist', 'Luxury', '5 branches'],
    icon: Icons.workspace_premium_rounded,
    services: [
      _Service('Designer Haircut', 'Signature designer cut', 'Haircut', 30000),
      _Service('Creative Cut', 'Custom creative cut', 'Haircut', 35000),
      _Service('Beard Sculpt', 'Sharp beard sculpt', 'Haircut', 18000),
      _Service('Creative Color', 'Artistic colour work', 'Coloring', 120000),
      _Service('Color Correction', 'Fix & rebalance colour', 'Coloring', 160000),
      _Service('Balayage', 'Hand-painted highlights', 'Coloring', 150000),
      _Service('Bridal Styling', 'Bridal hair styling', 'Styling', 130000),
      _Service('Red Carpet Style', 'Glam event styling', 'Styling', 60000),
      _Service('Keratin Smoothing', 'Smoothing treatment', 'Treatment', 180000),
      _Service('Luxury Hair Spa', 'Premium hair spa', 'Treatment', 80000),
    ],
  ),
  _Salon(
    name: 'Neighborhood',
    branches: [
      'Sanchaung, Yangon',
      'Golden Valley, Yangon',
      'Hledan, Yangon',
      '35th Street, Mandalay',
    ],
    rating: 4.7,
    reviews: 223,
    tags: ['Barbershop', 'Walk-in', '4 branches'],
    icon: Icons.storefront_rounded,
    services: [
      _Service('Classic Haircut', 'Precision cut with scissor work', 'Haircut', 12000),
      _Service('Buzz Cut', 'Clean all-over buzz', 'Haircut', 10000),
      _Service('Crop Cut', 'Textured french crop', 'Haircut', 14000),
      _Service('Beard Trim & Line Up', 'Trim with line-up', 'Haircut', 8000),
      _Service('Hair & Beard Combo', 'Cut + beard combo', 'Haircut', 18000),
      _Service('Hot Towel Shave', 'Warm towel shave', 'Styling', 12000),
      _Service('Pomade Style', 'Slick pomade finish', 'Styling', 8000),
      _Service('Kids Cut', 'Gentle cut for kids', 'Haircut', 8000),
      _Service('Beard Treatment', 'Beard conditioning', 'Treatment', 10000),
      _Service('Scalp Massage', 'Relaxing scalp massage', 'Treatment', 12000),
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // Booking form fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

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

  // Step 1 — collect customer details before confirming.
  void _openBookingForm() {
    final salon = _salons[_activeSalon!];
    String? branch = salon.branches.first;
    DateTime? date;
    TimeOfDay? time;
    final formKey = GlobalKey<FormState>();

    final selectedServices = salon.services
        .where((s) => _selected.contains('$_activeSalon:${s.name}'))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accent = isDark ? AppColors.gold : AppColors.burgundy;
        final cardBg = isDark ? AppColors.darkWarm : Colors.white;
        final ink = isDark ? Colors.white : AppColors.inkBlack;
        final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
        final fieldBg = isDark ? AppColors.charcoal : const Color(0xFFF7F5F2);

        InputDecoration deco(String hint, IconData icon) => InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 13, color: muted),
              prefixIcon: Icon(icon, size: 18, color: accent),
              filled: true,
              fillColor: fieldBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            );

        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scroll) => Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 14),
                  Text('booking.details'.tr(),
                      style: GoogleFonts.rufina(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink)),
                  const SizedBox(height: 2),
                  Text(salon.name,
                      style: GoogleFonts.outfit(fontSize: 13, color: muted)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Form(
                      key: formKey,
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          _formLabel('booking.full_name'.tr(), ink),
                          TextFormField(
                            controller: _nameCtrl,
                            style: GoogleFonts.outfit(fontSize: 14, color: ink),
                            decoration: deco('booking.your_name'.tr(),
                                Icons.person_outline_rounded),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'booking.err_name'.tr()
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _formLabel('booking.phone'.tr(), ink),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.outfit(fontSize: 14, color: ink),
                            decoration: deco(
                                'booking.phone_hint'.tr(), Icons.phone_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'booking.err_phone'.tr();
                              }
                              if (v.trim().length < 7) {
                                return 'booking.err_phone_valid'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _formLabel('booking.branch'.tr(), ink),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: salon.branches.map((b) {
                              final sel = branch == b;
                              return GestureDetector(
                                onTap: () => setSheet(() => branch = b),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: sel ? accent : fieldBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(b,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: sel
                                              ? (isDark
                                                  ? AppColors.charcoal
                                                  : Colors.white)
                                              : ink)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          // Date + time pickers
                          Row(
                            children: [
                              Expanded(
                                child: _pickerTile(
                                  label: date == null
                                      ? 'booking.select_date'.tr()
                                      : '${date!.day}/${date!.month}/${date!.year}',
                                  icon: Icons.calendar_today_rounded,
                                  filled: date != null,
                                  accent: accent,
                                  fieldBg: fieldBg,
                                  ink: ink,
                                  muted: muted,
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: sheetCtx,
                                      initialDate: now,
                                      firstDate: now,
                                      lastDate:
                                          now.add(const Duration(days: 60)),
                                    );
                                    if (picked != null) {
                                      setSheet(() => date = picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _pickerTile(
                                  label: time == null
                                      ? 'booking.select_time'.tr()
                                      : time!.format(sheetCtx),
                                  icon: Icons.access_time_rounded,
                                  filled: time != null,
                                  accent: accent,
                                  fieldBg: fieldBg,
                                  ink: ink,
                                  muted: muted,
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: sheetCtx,
                                      initialTime: const TimeOfDay(
                                          hour: 10, minute: 0),
                                    );
                                    if (picked != null) {
                                      setSheet(() => time = picked);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _formLabel('booking.notes'.tr(), ink),
                          TextFormField(
                            controller: _noteCtrl,
                            maxLines: 2,
                            style: GoogleFonts.outfit(fontSize: 14, color: ink),
                            decoration: deco('booking.notes_hint'.tr(),
                                Icons.edit_note_rounded),
                          ),
                          const SizedBox(height: 18),
                          // Summary
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'booking.services_selected'.tr(args: [
                                      selectedServices.length.toString()
                                    ]),
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ink)),
                                const SizedBox(height: 6),
                                ...selectedServices.map((s) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 3),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text('· ${s.name}',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 12,
                                                    color: muted)),
                                          ),
                                          Text('${_fmt(s.price)} MMK',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: ink)),
                                        ],
                                      ),
                                    )),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('booking.total'.tr(),
                                        style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: ink)),
                                    Text('${_fmt(_total)} MMK',
                                        style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: accent)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                if (date == null || time == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'booking.pick_datetime'.tr())),
                                  );
                                  return;
                                }
                                Navigator.pop(sheetCtx);
                                _confirm(
                                  branch: branch!,
                                  date: date!,
                                  time: time!,
                                );
                              },
                              icon: const Icon(
                                  Icons.event_available_rounded, size: 18),
                              label: Text('booking.confirm'.tr(),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor:
                                    isDark ? AppColors.charcoal : Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
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
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _formLabel(String text, Color ink) => Padding(
        padding: const EdgeInsets.only(bottom: 7, left: 2),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
      );

  Widget _pickerTile({
    required String label,
    required IconData icon,
    required bool filled,
    required Color accent,
    required Color fieldBg,
    required Color ink,
    required Color muted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                      color: filled ? ink : muted)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm({
    required String branch,
    required DateTime date,
    required TimeOfDay time,
  }) {
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
              Text('booking.confirmed'.tr(),
                  style: GoogleFonts.rufina(
                      fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
              const SizedBox(height: 6),
              Text(
                '${'booking.services_selected'.tr(args: [count.toString()])} · ${_salons[_activeSalon!].name}\n$branch\n${date.day}/${date.month}/${date.year} · ${time.format(context)}\n${'booking.total'.tr()} ${_fmt(_total)} MMK',
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
                  child: Text('booking.done'.tr(),
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
                    Text('booking.title'.tr(),
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
                              Text('booking.chosen_style'.tr(),
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
                child: Text('booking.choose_salon'.tr(),
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
                            child: Text(
                                '· ${'booking.branch_count'.tr(args: [salon.branches.length.toString()])}',
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
            const SizedBox(height: 12),
            // Branches
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : const Color(0xFFF7F5F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place_rounded, size: 13, color: accent),
                      const SizedBox(width: 5),
                      Text('booking.branches'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: salon.branches
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkWarm
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.creamAlt),
                              ),
                              child: Text(b,
                                  style: GoogleFonts.outfit(
                                      fontSize: 10.5, color: muted)),
                            ))
                        .toList(),
                  ),
                ],
              ),
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
                      child: Text('booking.cat.$c'.tr(),
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
                Text('booking.total'.tr(),
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
                onPressed: hasSelection ? _openBookingForm : null,
                icon: const Icon(Icons.event_available_rounded, size: 18),
                label: Text(
                    hasSelection
                        ? 'booking.confirm_count'
                            .tr(args: [_selected.length.toString()])
                        : 'booking.select_services'.tr(),
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
