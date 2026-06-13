import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/ar_hair_filter_screen.dart';
import 'package:pyin_mal_app/screens/hair_try_on_screen.dart';
import '../widgets/cdn_image.dart';

class HaircutScreen extends StatefulWidget {
  const HaircutScreen({super.key});

  @override
  State<HaircutScreen> createState() => _HaircutScreenState();
}

class _HaircutScreenState extends State<HaircutScreen> {
  String _selectedFaceShape = 'Oval Face';

  // ── Hairstyle try-on gallery ──────────────────────────────────────────────
  String _hairGender = 'Women'; // 'Women' | 'Men'
  String _hairCategory = 'Hot';
  String? _selectedHairstyle;
  final Set<String> _favHairstyles = {};

  // Category tabs per gender
  static const _womenCategories = [
    'Hot', 'Bangs', 'Curls', 'Straight', 'Short', 'Wavy', 'Updo'
  ];
  static const _menCategories = [
    'Hot', 'Fade', 'Crop', 'Quiff', 'Curly', 'Long', 'Buzz'
  ];

  List<String> get _hairCategories =>
      _hairGender == 'Women' ? _womenCategories : _menCategories;

  // label, gender, category, gradient seed colors
  static const _hairstyles = <(String, String, String, Color, Color)>[
    // ── Women ──────────────────────────────────────────────────────────────
    ('Feather',        'Women', 'Hot',      Color(0xFFB5838D), Color(0xFF6D4C5A)),
    ('Clarity',        'Women', 'Hot',      Color(0xFFC9A96E), Color(0xFF8A6A3A)),
    ('Half-Up',        'Women', 'Hot',      Color(0xFFA68A64), Color(0xFF5E4B33)),
    ('Wispy Side',     'Women', 'Bangs',    Color(0xFF8E9AAF), Color(0xFF4A5468)),
    ('Thick Side Part','Women', 'Bangs',    Color(0xFF6D6875), Color(0xFF3A3543)),
    ('Curtain Bangs',  'Women', 'Bangs',    Color(0xFFB08968), Color(0xFF6F543C)),
    ('Soft Waves',     'Women', 'Curls',    Color(0xFFCB997E), Color(0xFF8A5E45)),
    ('Spiral Curls',   'Women', 'Curls',    Color(0xFFA5668B), Color(0xFF5E3354)),
    ('Sleek',          'Women', 'Straight', Color(0xFF6B705C), Color(0xFF3B3E32)),
    ('Long Straight',  'Women', 'Straight', Color(0xFF7F7065), Color(0xFF463C35)),
    ('Pixie',          'Women', 'Short',    Color(0xFF936639), Color(0xFF5A3E22)),
    ('Bob',            'Women', 'Short',    Color(0xFFB98B73), Color(0xFF6E4F3E)),
    ('Beach Wave',     'Women', 'Wavy',     Color(0xFFDDA15E), Color(0xFF9A6B36)),
    ('Loose Wave',     'Women', 'Wavy',     Color(0xFFBC9B6A), Color(0xFF7A6240)),
    ('Top Knot',       'Women', 'Updo',     Color(0xFF8C7A6B), Color(0xFF534639)),
    ('Braided Bun',    'Women', 'Updo',     Color(0xFFA47551), Color(0xFF634530)),
    // ── Men ────────────────────────────────────────────────────────────────
    ('Textured Crop',  'Men',   'Hot',      Color(0xFF4A6670), Color(0xFF2A3B42)),
    ('Side Part',      'Men',   'Hot',      Color(0xFF5C6B73), Color(0xFF353E44)),
    ('Slick Back',     'Men',   'Hot',      Color(0xFF6B5D4F), Color(0xFF3E352C)),
    ('Low Fade',       'Men',   'Fade',     Color(0xFF52616B), Color(0xFF2F383E)),
    ('High Fade',      'Men',   'Fade',     Color(0xFF5E5548), Color(0xFF35302A)),
    ('Skin Fade',      'Men',   'Fade',     Color(0xFF646E78), Color(0xFF383F45)),
    ('French Crop',    'Men',   'Crop',     Color(0xFF6E5C4B), Color(0xFF3F342A)),
    ('Caesar Cut',     'Men',   'Crop',     Color(0xFF7A6A55), Color(0xFF463C30)),
    ('Classic Quiff',  'Men',   'Quiff',    Color(0xFF566573), Color(0xFF313943)),
    ('Modern Quiff',   'Men',   'Quiff',    Color(0xFF625B4E), Color(0xFF38332C)),
    ('Curly Top',      'Men',   'Curly',    Color(0xFF6B5848), Color(0xFF3D3229)),
    ('Afro',           'Men',   'Curly',    Color(0xFF4F4639), Color(0xFF2E2820)),
    ('Man Bun',        'Men',   'Long',     Color(0xFF5A5043), Color(0xFF332E26)),
    ('Shoulder Length','Men',   'Long',     Color(0xFF6E5F4E), Color(0xFF3F362C)),
    ('Buzz Cut',       'Men',   'Buzz',     Color(0xFF5C5C5C), Color(0xFF343434)),
    ('Crew Cut',       'Men',   'Buzz',     Color(0xFF676052), Color(0xFF3B362E)),
  ];

  List<(String, String, String, Color, Color)> get _visibleHairstyles =>
      _hairstyles
          .where((h) => h.$2 == _hairGender && h.$3 == _hairCategory)
          .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 640;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('haircut.title'.tr(), style: GoogleFonts.rufina(
          fontWeight: FontWeight.bold,
          color: accent,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Hero Section
            _buildHero(context, isMobile, isDesktop, isDark, accent),

            // 2. Face Shape Selector
            _buildFaceShapeSelector(isDark, accent),

            // 2b. Hairstyle Try-On Gallery (category tabs + selectable cards)
            _buildHairstyleGallery(isDark, accent),

            // 3. Recommended Hairstyles
            _buildHairstyleSection(context, isMobile, isDark, accent),

            // 4. Smart Assistant Tips
            _buildSmartTips(isDark, accent),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile, bool isDesktop, bool isDark, Color accent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppColors.charcoal, AppColors.darkWarm] 
            : [AppColors.creamAlt, AppColors.cream],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'haircut.hero_subtitle'.tr(),
              style: GoogleFonts.outfit(
                color: AppColors.charcoal,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'haircut.hero_title'.tr(),
            style: GoogleFonts.rufina(
              fontSize: isMobile ? 36 : 52,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'haircut.hero_desc'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: isDark ? AppColors.paleText : AppColors.inkGrey,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ARHairFilterScreen()),
                  );
                },
                icon: const Icon(Icons.face_retouching_natural),
                label: Text('haircut.ar_filter'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkWarm : AppColors.creamCard,
                  foregroundColor: isDark ? Colors.white : AppColors.inkBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HairTryOnScreen()),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text('haircut.ai_try_on'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: accent.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaceShapeSelector(bool isDark, Color accent) {
    final shapes = [
      {'name': 'Oval Face', 'img': 'assets/images/HairStyle/O.jpg'},
      {'name': 'Round Face', 'img': 'assets/images/HairStyle/R.jpg'},
      {'name': 'Square Face', 'img': 'assets/images/HairStyle/S.jpg'},
      {'name': 'Diamond Face', 'img': 'assets/images/HairStyle/O.jpg'}, // Using O as placeholder
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Text(
            'haircut.select_face_shape'.tr(),
            style: GoogleFonts.rufina(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: shapes.length,
            itemBuilder: (context, i) {
              final shape = shapes[i];
              final isSelected = _selectedFaceShape == shape['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedFaceShape = shape['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamCard),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(
                      color: isSelected ? accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.charcoal : AppColors.creamAlt,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: CdnImage(
                          shape['img']!,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Icon(Icons.face, color: isSelected ? Colors.white : Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'haircut.face_shapes.${shape['name']}'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? AppColors.paleText : AppColors.inkGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _genderTab(
      String label, IconData icon, bool isDark, Color accent, Color ink) {
    final sel = _hairGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_hairGender == label) return;
          setState(() {
            _hairGender = label;
            _hairCategory = _hairCategories.first;
            _selectedHairstyle = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: sel
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : ink),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
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

  // ── Hairstyle Try-On Gallery ──────────────────────────────────────────────
  Widget _buildHairstyleGallery(bool isDark, Color accent) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Try a hairstyle',
                  style: GoogleFonts.rufina(
                      fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
              if (_selectedHairstyle != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_selectedHairstyle!,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Text('Pick a category, then tap a look to preview it.',
              style: GoogleFonts.outfit(fontSize: 13, color: muted)),
        ),

        // ── Women / Men toggle ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _genderTab('Women', Icons.female_rounded, isDark, accent, ink),
                _genderTab('Men', Icons.male_rounded, isDark, accent, ink),
              ],
            ),
          ),
        ),

        // Category tabs
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _hairCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cat = _hairCategories[i];
              final sel = _hairCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _hairCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? accent
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.inkGrey.withOpacity(0.3))),
                  ),
                  child: Center(
                    child: Text(cat,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? (isDark ? AppColors.charcoal : Colors.white)
                                : ink)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Hairstyle cards
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _visibleHairstyles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final h = _visibleHairstyles[i];
              final label = h.$1;
              final sel = _selectedHairstyle == label;
              final fav = _favHairstyles.contains(label);
              return GestureDetector(
                onTap: () => setState(() => _selectedHairstyle = label),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 120,
                      height: 148,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [h.$4, h.$5],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: sel ? accent : Colors.transparent,
                            width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Stylised "portrait" placeholder
                          Center(
                            child: Icon(
                                _hairGender == 'Women'
                                    ? Icons.face_3_rounded
                                    : Icons.face_6_rounded,
                                size: 64,
                                color: Colors.white.withOpacity(0.55)),
                          ),
                          // Favourite heart badge
                          Positioned(
                            top: 6,
                            left: 6,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                fav
                                    ? _favHairstyles.remove(label)
                                    : _favHairstyles.add(label);
                              }),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  fav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: 14,
                                  color: fav
                                      ? const Color(0xFFE53935)
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          // Selected check
                          if (sel)
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check_rounded,
                                    size: 15,
                                    color: isDark
                                        ? AppColors.charcoal
                                        : Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(label,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? accent : ink)),
                  ],
                ),
              );
            },
          ),
        ),

        // Apply button (only when a look is selected)
        if (_selectedHairstyle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Previewing "$_selectedHairstyle"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text('Preview on me',
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHairstyleSection(BuildContext context, bool isMobile, bool isDark, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'haircut.recommended'.tr(),
                style: GoogleFonts.rufina(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              Text(
                'haircut.trending'.tr(),
                style: GoogleFonts.outfit(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildHairstyleCard(
                'Classic Undercut',
                'Sharp sides with a textured top for a versatile modern look.',
                'assets/images/HairStyle/Male/Diamond Face/Diamond - Undercut.jpg',
                'Professional',
                isDark, accent,
              ),
              _buildHairstyleCard(
                'Textured Crop',
                'Low maintenance style that works perfectly with active lifestyles.',
                'assets/images/HairStyle/Male/Diamond Face/Diamond  - Textured Crop.jpg',
                'Casual',
                isDark, accent,
              ),
              _buildHairstyleCard(
                'Long Textured Top',
                'Flowing layers with a clean fade for a sophisticated vintage vibe.',
                'assets/images/HairStyle/Male/Round Face/Round - Longer Textured Top + Fade.jpg',
                'Elegant',
                isDark, accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHairstyleCard(String title, String desc, String img, String tag, bool isDark, Color accent) {
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CdnImage(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50)),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.charcoal : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_outline, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    color: isDark ? AppColors.paleText : AppColors.inkGrey,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.gold, size: 14),
                    const SizedBox(width: 4),
                    Text('Best Match', style: GoogleFonts.outfit(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmartTips(bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 24),
              const SizedBox(width: 12),
              Text(
                'haircut.styling_tips'.tr(),
                style: GoogleFonts.rufina(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipItem(Icons.check_circle_outline, 'Best for oval and round faces', isDark, accent),
          const SizedBox(height: 12),
          _buildTipItem(Icons.check_circle_outline, 'Works well with casual and formal outfits', isDark, accent),
          const SizedBox(height: 12),
          _buildTipItem(Icons.check_circle_outline, 'Low maintenance for daily styling', isDark, accent),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text, bool isDark, Color accent) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
