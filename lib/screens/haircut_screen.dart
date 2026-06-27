import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/ar_hair_filter_screen.dart';
import 'package:pyin_mal_app/screens/hair_try_on_screen.dart';
import '../widgets/cdn_image.dart';
import 'package:flutter/services.dart';

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
  String? _selectedHairstyle; // Selected asset path
  final Set<String> _favHairstyles = {}; // Fav asset paths

  static const _womenCategories = [
    'Hot', 'Bangs', 'Curls', 'Straight', 'Short', 'Wavy', 'Updo'
  ];
  static const _menCategories = [
    'Hot', 'Fade', 'Crop', 'Quiff', 'Curly', 'Long', 'Buzz'
  ];

  List<String> get _hairCategories =>
      _hairGender == 'Women' ? _womenCategories : _menCategories;

  List<String> _allAssetPaths = [];
  List<String> _visibleHairstyles = [];

  @override
  void initState() {
    super.initState();
    _loadHairstyles();
  }

  Future<void> _loadHairstyles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();
    final prefix = 'pyin-mal-assets/assets/images/Hair/';
    
    final hairstyles = allAssets.where((p) => 
      p.startsWith(prefix) && 
      (p.endsWith('.jpg') || p.endsWith('.png') || p.endsWith('.webp'))
    ).toList();
    
    if (mounted) {
      setState(() {
        _allAssetPaths = hairstyles;
        _updateVisibleHairstyles();
      });
    }
  }

  void _updateVisibleHairstyles() {
    final genderPath = _hairGender == 'Women' ? 'Female' : 'Male';
    final targetFolder = _hairGender == 'Women'
        ? 'pyin-mal-assets/assets/images/Hair/$genderPath/$_selectedFaceShape/'
        : 'pyin-mal-assets/assets/images/Hair/$genderPath/';
    
    _visibleHairstyles = _allAssetPaths.where((p) {
      if (!p.startsWith(targetFolder)) return false;
      return _matchesCategory(p, _hairCategory, _hairGender);
    }).toList();
    
    // If no styles match the category, fallback to showing all for that face shape
    if (_visibleHairstyles.isEmpty && _hairCategory != 'Hot') {
        _visibleHairstyles = _allAssetPaths.where((p) => p.startsWith(targetFolder)).toList();
    }
    
    _selectedHairstyle = null;
  }

  bool _matchesCategory(String path, String category, String gender) {
    if (category == 'Hot') return true; // Show all for 'Hot'
    
    final name = path.toLowerCase();
    if (gender == 'Women') {
      switch (category) {
        case 'Bangs': return name.contains('bangs') || name.contains('fringe');
        case 'Curls': return name.contains('curl');
        case 'Wavy': return name.contains('wav') || name.contains('shag') || name.contains('layer');
        case 'Short': return name.contains('short') || name.contains('bob') || name.contains('pixie') || name.contains('bixie') || name.contains('crop');
        case 'Straight': return name.contains('straight') || name.contains('sleek') || name.contains('blunt') || name.contains('flat');
        case 'Updo': return name.contains('updo') || name.contains('bun') || name.contains('knot') || name.contains('half-up');
      }
    } else {
      switch (category) {
        case 'Fade': return name.contains('fade') || name.contains('taper');
        case 'Crop': return name.contains('crop') || name.contains('caesar') || name.contains('fringe');
        case 'Quiff': return name.contains('quiff') || name.contains('pomp');
        case 'Curly': return name.contains('curl') || name.contains('afro') || name.contains('wav');
        case 'Long': return name.contains('long') || name.contains('mullet') || name.contains('flow') || name.contains('shag');
        case 'Buzz': return name.contains('buzz') || name.contains('crew') || name.contains('bald');
      }
    }
    return false;
  }

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
            if (_hairGender == 'Women')
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
                    MaterialPageRoute(
                      builder: (_) => ARHairFilterScreen(
                        initialHairstylePath: _selectedHairstyle,
                      ),
                    ),
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
      {'name': 'Oval Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/O.jpg'},
      {'name': 'Round Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/R.jpg'},
      {'name': 'Square Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/S.jpg'},
      {'name': 'Diamond Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/D.jpg'},
      {'name': 'Heart Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/H.jpg'},
      {'name': 'Triangle Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/T.jpg'},
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
                onTap: () {
                  setState(() {
                    _selectedFaceShape = shape['name']!;
                    _updateVisibleHairstyles();
                  });
                },
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
                        shape['name']!,
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
            _updateVisibleHairstyles();
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
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_extractHairstyleName(_selectedHairstyle!),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent),
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Text('Discover styles that suit your face shape.',
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
                onTap: () {
                  setState(() {
                    _hairCategory = cat;
                    _updateVisibleHairstyles();
                  });
                },
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
              final path = _visibleHairstyles[i];
              final label = _extractHairstyleName(path);
              final sel = _selectedHairstyle == path;
              final fav = _favHairstyles.contains(path);
              return GestureDetector(
                onTap: () => setState(() => _selectedHairstyle = path),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 120,
                      height: 148,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13), // accounting for border
                            child: CdnImage(
                              path,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // Favourite heart badge
                          Positioned(
                            top: 6,
                            left: 6,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                fav
                                    ? _favHairstyles.remove(path)
                                    : _favHairstyles.add(path);
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
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? accent : ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ARHairFilterScreen(
                        initialHairstylePath: _selectedHairstyle,
                      ),
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

  String _extractHairstyleName(String path) {
    final filename = path.split('/').last;
    final nameWithoutExt = filename.split('.').first;
    
    if (path.contains('/Male/')) {
      final parts = nameWithoutExt.split('_');
      if (parts.length > 3) {
        return parts.sublist(3).join(' ').trim();
      }
    } else if (path.contains('/Female/')) {
      final parts = nameWithoutExt.split('_');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ').trim();
      }
    }
    
    if (nameWithoutExt.contains('- ')) {
      return nameWithoutExt.split('- ')[1].trim();
    }
    return nameWithoutExt;
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
