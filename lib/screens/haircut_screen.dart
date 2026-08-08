import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/hair_360_screen.dart';
import 'package:pyin_mal_app/screens/hair_try_on_screen.dart';
import 'package:pyin_mal_app/screens/haircut_booking_screen.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/core/hairstyle_favorites_notifier.dart';
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
  // Which section the selection came from: 'gallery' | 'recommended'.
  // Controls where the Preview / Try On / Book buttons appear.
  String _selectionSource = 'gallery';

  static const _womenCategories = [
    'Hot', 'Bangs', 'Curls', 'Straight', 'Short', 'Wavy', 'Updo'
  ];
  static const _menCategories = [
    'Hot', 'Fade', 'Crop', 'Quiff', 'Curly', 'Long', 'Buzz'
  ];

  List<String> get _hairCategories =>
      _hairGender == 'Women' ? _womenCategories : _menCategories;

  // Which style keywords flatter each face shape. Women's assets are already
  // sorted into per-face-shape folders, so this drives the MEN'S list (organised
  // by cut type, not face shape) — matched against the style name in the file.
  // An empty list means "everything suits" (oval is the balanced all-rounder).
  static const Map<String, List<String>> _faceShapeStyles = {
    'Oval Face': [],
    'Round Face': [
      'fade', 'taper', 'quiff', 'pompadour', 'undercut', 'crop', 'wolf',
      'french', 'textured', 'spiky',
    ],
    'Square Face': [
      'buzz', 'crop', 'quiff', 'fade', 'wavy', 'caesar', 'textured', 'french',
      'side',
    ],
    'Diamond Face': [
      'crop', 'curly', 'wavy', 'mullet', 'wolf', 'fringe', 'shag', 'layered',
      'textured', 'french',
    ],
    'Triangle Face': [
      'pixie', 'short', 'crop', 'bang', 'fringe', 'layer', 'wav', 'curl',
      'quiff', 'fade', 'side', 'updo', 'pomp',
    ],
    'Heart Face': [
      'bob', 'bang', 'fringe', 'side', 'wav', 'curl', 'layer', 'shag', 'crop',
      'curtain', 'medium', 'long', 'mullet',
    ],
  };

  // Face shapes that have their own curated women's asset folders. Others
  // (Triangle, Heart) fall back to filtering the whole set by suitability.
  static const _womenFolderShapes = {
    'Oval Face', 'Round Face', 'Square Face', 'Diamond Face'
  };

  /// True when [path]'s style suits [faceShape]. Empty keyword list → suits all.
  bool _suitsFaceShape(String path, String faceShape) {
    final keys = _faceShapeStyles[faceShape] ?? const <String>[];
    if (keys.isEmpty) return true;
    final name = path.toLowerCase();
    return keys.any(name.contains);
  }

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
    // Women's assets live in per-face-shape folders for the four original
    // shapes (already curated). For Men, and for the newer women's shapes with
    // no dedicated folder (Triangle, Heart), we take the whole gender set and
    // filter by which styles flatter the selected face shape.
    final usesFolder =
        _hairGender == 'Women' && _womenFolderShapes.contains(_selectedFaceShape);
    final targetFolder = usesFolder
        ? 'pyin-mal-assets/assets/images/Hair/$genderPath/$_selectedFaceShape/'
        : 'pyin-mal-assets/assets/images/Hair/$genderPath/';

    bool suitsShape(String p) =>
        usesFolder || _suitsFaceShape(p, _selectedFaceShape);

    _visibleHairstyles = _allAssetPaths.where((p) {
      if (!p.startsWith(targetFolder)) return false;
      if (!suitsShape(p)) return false;
      return _matchesCategory(p, _hairCategory, _hairGender);
    }).toList();

    // If nothing matches this category for the shape, show all suitable styles.
    if (_visibleHairstyles.isEmpty && _hairCategory != 'Hot') {
      _visibleHairstyles = _allAssetPaths
          .where((p) => p.startsWith(targetFolder) && suitsShape(p))
          .toList();
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

            // 2. Face Shape Selector (both Women and Men)
            _buildFaceShapeSelector(isDark, accent),

            // 2b. Hairstyle Try-On Gallery (category tabs + selectable cards)
            _buildHairstyleGallery(isDark, accent),

            // 3. Recommended Hairstyles
            _buildHairstyleSection(context, isMobile, isDark, accent),

            // 4. Hair care products (order from partner salons)
            _buildHairCareProducts(isDark, accent),

            // Clear the floating glass nav bar (+ the device's bottom inset).
            SizedBox(height: 120 + MediaQuery.of(context).padding.bottom),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Hair360Screen()),
                      );
                    },
                    icon: const Icon(Icons.threed_rotation_rounded),
                    label: const Text('360 Studio'),
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
              const SizedBox(height: 16),
              // General "Book now" — for anyone who just wants to book a salon
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HaircutBookingScreen(),
                  ),
                ),
                icon: const Icon(Icons.event_available_rounded),
                label: Text('haircut.book_now'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : AppColors.inkBlack,
                  foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
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
      {'name': 'Triangle Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/T.jpg'},
      {'name': 'Heart Face', 'img': 'pyin-mal-assets/assets/images/HairStyle/H.jpg'},
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
              Text('haircut.${label.toLowerCase()}'.tr(),
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
              Text('haircut.try_hairstyle'.tr(),
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
          child: Text(
            'hairx.suits_intro'.tr(args: [_selectedFaceShape]),
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: accent),
          ),
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
              final fav = hairstyleFavoritesNotifier.value.contains(path);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedHairstyle = path;
                  _selectionSource = 'gallery';
                }),
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
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => hairstyleFavoritesNotifier.toggle(path)),
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

        // Action buttons appear here only when the pick came from this gallery
        if (_selectedHairstyle != null && _selectionSource == 'gallery')
          _selectedStyleActions(isDark, accent),
      ],
    );
  }

  // Preview on me / Try On / Book — shown under whichever section the
  // selected hairstyle was picked from.
  Widget _selectedStyleActions(bool isDark, Color accent) {
    final outlined = OutlinedButton.styleFrom(
      foregroundColor: accent,
      side: BorderSide(color: accent, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        children: [
          // Two preview actions side by side.
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HairTryOnScreen(
                        initialHairstylePath: _selectedHairstyle,
                      ),
                    ),
                  ),
                  icon: const Icon(
                      Icons.face_retouching_natural_rounded, size: 17),
                  label: Text('product.try_on'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w700)),
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
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Hair360Screen(
                        initialStylePath: _selectedHairstyle,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.threed_rotation_rounded, size: 17),
                  label: Text('studio.view_360'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  style: outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Primary conversion action — full width.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HaircutBookingScreen(
                    preselectedStyle:
                        _extractHairstyleName(_selectedHairstyle!),
                  ),
                ),
              ),
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: Text('haircut.book_with_style'.tr(),
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: outlined,
            ),
          ),
        ],
      ),
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
    // Recommendations come from the styles that suit the selected face shape
    // (women: the face-shape folder; men: filtered by flattering keywords),
    // spread across cut categories so the picks feel varied.
    final genderPath = _hairGender == 'Women' ? 'Female' : 'Male';
    final usesFolder =
        _hairGender == 'Women' && _womenFolderShapes.contains(_selectedFaceShape);
    final folder = usesFolder
        ? 'pyin-mal-assets/assets/images/Hair/$genderPath/$_selectedFaceShape/'
        : 'pyin-mal-assets/assets/images/Hair/$genderPath/';
    final pool = _allAssetPaths
        .where((p) =>
            p.startsWith(folder) &&
            (usesFolder || _suitsFaceShape(p, _selectedFaceShape)))
        .toList();
    final recommended = <String>[];
    if (pool.isNotEmpty) {
      final step = (pool.length / 6).ceil().clamp(1, pool.length);
      for (var i = 0; i < pool.length && recommended.length < 6; i += step) {
        recommended.add(pool[i]);
      }
    }

    if (recommended.isEmpty) return const SizedBox.shrink();

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
          height: 300,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            itemBuilder: (_, i) =>
                _buildRecommendedCard(recommended[i], isDark, accent),
          ),
        ),
        // Action buttons appear here only when the pick came from this section
        if (_selectedHairstyle != null && _selectionSource == 'recommended')
          _selectedStyleActions(isDark, accent),
      ],
    );
  }

  Widget _buildRecommendedCard(String path, bool isDark, Color accent) {
    final name = _extractHairstyleName(path);
    final fav = hairstyleFavoritesNotifier.value.contains(path);
    final sel = _selectedHairstyle == path;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedHairstyle = path;
        _selectionSource = 'recommended';
      }),
      child: Container(
        width: 210,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: sel ? accent : Colors.transparent, width: 2),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    child: CdnImage(
                      path,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Trending',
                        style: GoogleFonts.outfit(
                          color: isDark ? AppColors.charcoal : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favourite heart — same list as the gallery hearts
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(
                          () => hairstyleFavoritesNotifier.toggle(path)),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          fav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: fav
                              ? const Color(0xFFE53935)
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  if (sel)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 16,
                            color:
                                isDark ? AppColors.charcoal : Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text('Best Match',
                          style: GoogleFonts.outfit(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const Spacer(),
                      Text('Tap to select',
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: isDark
                                  ? AppColors.paleText
                                  : AppColors.inkGrey)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ── Hair care products (order from the 5 partner salons) ────────────────────
  Widget _buildHairCareProducts(bool isDark, Color accent) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.spa_rounded, color: AppColors.gold, size: 22),
                  const SizedBox(width: 10),
                  Text('haircare.title'.tr(),
                      style: GoogleFonts.rufina(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  'haircare.subtitle'.tr(),
                  style: GoogleFonts.outfit(fontSize: 13, color: muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // First horizontal scrolling row of product cards.
        SizedBox(
          height: 246,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _hairCareProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) =>
                _hairCareCard(_hairCareProducts[i], isDark, accent, ink, muted),
          ),
        ),
        const SizedBox(height: 14),
        // Second horizontal scrolling row of product cards.
        SizedBox(
          height: 246,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _hairCareProducts2.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _hairCareCard(
                _hairCareProducts2[i], isDark, accent, ink, muted),
          ),
        ),
      ],
    );
  }

  Widget _hairCareCard(_HairCareProduct p, bool isDark, Color accent,
      Color ink, Color muted) {
    return GestureDetector(
      onTap: () => _showHairCareDetails(p, isDark, accent, ink, muted),
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with a "From {salon}" badge.
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(19)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: accent.withOpacity(0.10),
                    child: Image.asset(
                      p.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.spa_rounded,
                            color: accent, size: 36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(p.salon,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: ink)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.storefront_rounded, size: 12, color: accent),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text('haircare.from'.tr(args: [p.salon]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: muted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(p.price,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Details popup: Good for / How to use + Order button.
  void _showHairCareDetails(_HairCareProduct p, bool isDark, Color accent,
      Color ink, Color muted) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.25)),
                      ),
                      child: Image.asset(
                        p.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.spa_rounded, color: accent, size: 28),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: GoogleFonts.rufina(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: ink)),
                          const SizedBox(height: 4),
                          Text('haircare.from'.tr(args: [p.salon]),
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: accent)),
                          const SizedBox(height: 2),
                          Text(p.price,
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: ink)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _careMeta(Icons.favorite_border_rounded, 'haircare.good_for'.tr(),
                    p.goodFor, accent, ink, muted),
                const SizedBox(height: 12),
                _careMeta(Icons.info_outline_rounded, 'haircare.how_to_use'.tr(),
                    p.howToUse, accent, ink, muted),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _orderHairCareProduct(p);
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text('haircare.order_now'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor:
                          isDark ? AppColors.charcoal : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
      },
    );
  }

  Widget _careMeta(IconData icon, String label, String value, Color accent,
      Color ink, Color muted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: ink),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.outfit(
                      fontSize: 12.5, height: 1.4, color: muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _orderHairCareProduct(_HairCareProduct p) {
    CartService().addToCart(CartItem(
      productId: 'haircare_${p.name}',
      name: p.name,
      price: p.price,
      image: p.image,
      brand: p.salon,
      size: 'One size',
      color: '-',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('haircare.added'.tr(namedArgs: {'name': p.name, 'salon': p.salon})),
      ),
    );
  }
}

// Hair care products sold by the 5 partner salons (from the booking screen).
class _HairCareProduct {
  final String name;
  final String salon;
  final String price;
  final String goodFor;
  final String howToUse;
  final String image; // salon logo asset

  const _HairCareProduct({
    required this.name,
    required this.salon,
    required this.price,
    required this.goodFor,
    required this.howToUse,
    required this.image,
  });
}

const _hairShopsDir = 'pyin-mal-assets/assets/images/shops';

const _hairCareProducts = <_HairCareProduct>[
  _HairCareProduct(
    name: 'Signature Styling Pomade',
    salon: 'V47',
    price: '14,000 MMK',
    goodFor: 'Straight and wavy hair needing all-day medium hold.',
    howToUse:
        'Rub a pea-sized amount between palms and work through dry hair, then shape as you like.',
    image: '$_hairShopsDir/V47/logo.png',
  ),
  _HairCareProduct(
    name: 'Keratin Repair Serum',
    salon: 'VIP Salon',
    price: '28,000 MMK',
    goodFor: 'Dry, damaged and colour-treated hair.',
    howToUse:
        'Apply a few drops to towel-dried hair, focus on the ends, do not rinse, then blow-dry.',
    image: '$_hairShopsDir/VIP salon/logo.png',
  ),
  _HairCareProduct(
    name: 'Volumizing Sea Salt Spray',
    salon: 'T8',
    price: '16,000 MMK',
    goodFor: 'Fine and flat hair that needs texture and volume.',
    howToUse:
        'Spray onto damp hair, scrunch with your hands, then air-dry or blow-dry for a beachy finish.',
    image: '$_hairShopsDir/T8/logo.png',
  ),
  _HairCareProduct(
    name: 'Argan Oil Hair Treatment',
    salon: 'Tony Tun Tun',
    price: '32,000 MMK',
    goodFor: 'Frizzy, curly and very dry hair.',
    howToUse:
        'Warm a small amount, massage into mid-lengths and ends, leave 10 minutes (or overnight), then rinse.',
    image: '$_hairShopsDir/Tony Tun Tun/logo.png',
  ),
  _HairCareProduct(
    name: 'Nourishing Beard and Scalp Oil',
    salon: 'Neighborhood',
    price: '12,000 MMK',
    goodFor: 'Dry scalp and beard grooming.',
    howToUse:
        'Massage a few drops into the scalp or beard once a day after washing. No need to rinse.',
    image: '$_hairShopsDir/the neighbour hood project/logo.png',
  ),
];

// Second row of products (one more per salon).
const _hairCareProducts2 = <_HairCareProduct>[
  _HairCareProduct(
    name: 'Hydrating Shampoo',
    salon: 'V47',
    price: '15,000 MMK',
    goodFor: 'All hair types, gentle daily cleansing.',
    howToUse:
        'Massage into wet hair and scalp, lather, then rinse thoroughly. Repeat if needed.',
    image: '$_hairShopsDir/V47/logo.png',
  ),
  _HairCareProduct(
    name: 'Colour-Protect Conditioner',
    salon: 'VIP Salon',
    price: '22,000 MMK',
    goodFor: 'Colour-treated hair that fades quickly.',
    howToUse:
        'After shampooing, apply from mid-lengths to ends, leave 2–3 minutes, then rinse.',
    image: '$_hairShopsDir/VIP salon/logo.png',
  ),
  _HairCareProduct(
    name: 'Matte Clay Wax',
    salon: 'T8',
    price: '18,000 MMK',
    goodFor: 'Short and medium hair needing a strong matte finish.',
    howToUse:
        'Warm a small amount in your palms and style dry hair for a natural, matte look.',
    image: '$_hairShopsDir/T8/logo.png',
  ),
  _HairCareProduct(
    name: 'Deep Repair Hair Mask',
    salon: 'Tony Tun Tun',
    price: '38,000 MMK',
    goodFor: 'Very dry, over-processed and brittle hair.',
    howToUse:
        'Apply to clean, damp hair, leave 5–10 minutes, then rinse well. Use once a week.',
    image: '$_hairShopsDir/Tony Tun Tun/logo.png',
  ),
  _HairCareProduct(
    name: 'Anti-Dandruff Tonic',
    salon: 'Neighborhood',
    price: '13,000 MMK',
    goodFor: 'Flaky, itchy scalp.',
    howToUse:
        'Part the hair and apply to the scalp, massage gently, and leave in. Use 3 times a week.',
    image: '$_hairShopsDir/the neighbour hood project/logo.png',
  ),
];
