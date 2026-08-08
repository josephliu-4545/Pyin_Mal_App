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
  // Null means "no shape filter" — the gallery then shows every style for the
  // selected gender. Tapping the active shape again clears it, like a chip.
  String? _selectedFaceShape = 'Oval Face';

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

  // The six shapes, in the order they appear in the selector.
  static const _faceShapes = [
    'Oval Face', 'Round Face', 'Square Face',
    'Diamond Face', 'Triangle Face', 'Heart Face',
  ];

  static const _styleRoot = 'pyin-mal-assets/assets/images/Hair/';

  // Which style keywords flatter each face shape. Women's assets are sorted
  // into per-face-shape folders, so this drives the MEN'S list (organised by
  // cut type, not face shape) — matched against the style name in the file.
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

  /// Reference portrait for [shape] in the currently selected gender.
  String _faceShapeImage(String shape) =>
      'pyin-mal-assets/assets/images/FaceShape/$_genderPath/$shape.jpg';

  String get _genderPath => _hairGender == 'Women' ? 'Female' : 'Male';

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

    // Only the gendered style folders — Hair/ also holds Product/, which is
    // salon stock, not hairstyles.
    final hairstyles = allAssets.where((p) =>
      (p.startsWith('${_styleRoot}Female/') ||
       p.startsWith('${_styleRoot}Male/')) &&
      (p.endsWith('.jpg') || p.endsWith('.png') || p.endsWith('.webp'))
    ).toList();
    
    if (mounted) {
      setState(() {
        _allAssetPaths = hairstyles;
        _updateVisibleHairstyles();
      });
    }
  }

  /// Every style for the current gender, narrowed to the face shape when one
  /// is selected. With no shape selected this is the whole gender catalogue.
  ///
  /// Women's styles live in per-face-shape folders for the four curated shapes,
  /// so those are a direct folder lookup. Men's styles are filed by cut type,
  /// and women's Triangle/Heart have no folder yet — both fall back to taking
  /// the whole gender set and keeping the cuts that flatter the shape.
  List<String> get _shapePool {
    final shape = _selectedFaceShape;
    final genderRoot = '$_styleRoot$_genderPath/';
    if (shape == null) {
      return _allAssetPaths.where((p) => p.startsWith(genderRoot)).toList();
    }

    final usesFolder = _hairGender == 'Women' && _womenFolderShapes.contains(shape);
    if (usesFolder) {
      return _allAssetPaths
          .where((p) => p.startsWith('$genderRoot$shape/'))
          .toList();
    }
    return _allAssetPaths
        .where((p) => p.startsWith(genderRoot) && _suitsFaceShape(p, shape))
        .toList();
  }

  void _updateVisibleHairstyles() {
    final pool = _shapePool;
    _visibleHairstyles = pool
        .where((p) => _matchesCategory(p, _hairCategory, _hairGender))
        .toList();

    // If nothing matches this category for the shape, fall back to the shape's
    // full set rather than showing an empty row.
    if (_visibleHairstyles.isEmpty && _hairCategory != 'Hot') {
      _visibleHairstyles = pool;
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
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final count = _shapePool.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 4),
          child: Text(
            'haircut.select_face_shape'.tr(),
            style: GoogleFonts.rufina(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: Text(
            _selectedFaceShape == null
                ? 'haircut.shape_hint'.tr()
                : 'haircut.shape_active'.tr(args: ['$count']),
            style: GoogleFonts.outfit(fontSize: 13, color: muted),
          ),
        ),

        // Gender first — it decides which set of face portraits you see below.
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

        SizedBox(
          height: 186,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _faceShapes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _faceShapeTile(_faceShapes[i], isDark, accent),
          ),
        ),
      ],
    );
  }

  /// One face-shape tile. Acts like a filter chip: tap to filter the gallery,
  /// tap the active one again to clear the filter and see every style.
  Widget _faceShapeTile(String shape, bool isDark, Color accent) {
    final isSelected = _selectedFaceShape == shape;
    final label = 'haircut.face_shapes.$shape'.tr();

    return GestureDetector(
      onTap: () => setState(() {
        _selectedFaceShape = isSelected ? null : shape;
        _updateVisibleHairstyles();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 124,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : AppColors.creamCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withOpacity(0.28)
                  : AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17.5)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Sources vary in aspect ratio, so cover + top alignment
                    // keeps every face framed the same way across the row.
                    CdnImage(
                      _faceShapeImage(shape),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (c, e, s) => Container(
                        color: isDark
                            ? AppColors.charcoal
                            : AppColors.creamAlt,
                        child: Icon(Icons.face_retouching_natural,
                            color: isSelected ? accent : Colors.grey,
                            size: 34),
                      ),
                    ),
                    // Dim the unselected tiles so the active one reads first.
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _selectedFaceShape == null || isSelected
                          ? 0.0
                          : 0.45,
                      child: Container(
                        color: isDark ? AppColors.charcoal : Colors.white,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.charcoal
                                  : Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(17.5)),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : (isDark ? AppColors.paleText : AppColors.inkGrey),
                ),
              ),
            ),
          ],
        ),
      ),
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
            _selectedFaceShape == null
                ? 'haircut.showing_all'.tr()
                : 'hairx.suits_intro'.tr(
                    args: ['haircut.face_shapes.$_selectedFaceShape'.tr()]),
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: accent),
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
    // Recommendations come from the selected face shape's curated folder (or
    // the whole gender catalogue when no shape is picked), sampled evenly so
    // the picks feel varied rather than clustered at the top of the folder.
    final pool = _shapePool;
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
        SizedBox(
          // Tall enough for the fullest card — 2-line name + salon + price —
          // so nothing overflows once those fields are filled in.
          height: 252,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _hairCareProducts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) =>
                _hairCareCard(_hairCareProducts[i], isDark, accent, ink, muted),
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
                    height: 150,
                    width: double.infinity,
                    color: accent.withOpacity(0.10),
                    padding: const EdgeInsets.all(6),
                    // Product shots are tall bottles on a plain background —
                    // contain keeps the whole item visible instead of cropping
                    // it to a band across the middle.
                    child: Image.asset(
                      p.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.spa_rounded,
                            color: accent, size: 36),
                      ),
                    ),
                  ),
                ),
                if (p.salon.isNotEmpty)
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
                  if (p.salon.isNotEmpty) ...[
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
                  ],
                  if (p.price.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(p.price,
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                  ],
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
                          if (p.salon.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('haircare.from'.tr(args: [p.salon]),
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: accent)),
                          ],
                          if (p.price.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(p.price,
                                style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: ink)),
                          ],
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
                  // Without a confirmed price there is nothing to charge, so
                  // ordering stays closed until one is filled in.
                  child: ElevatedButton.icon(
                    onPressed: p.price.isEmpty
                        ? null
                        : () {
                            Navigator.pop(sheetCtx);
                            _orderHairCareProduct(p);
                          },
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: Text(
                        p.price.isEmpty
                            ? 'haircare.price_soon'.tr()
                            : 'haircare.order_now'.tr(),
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
        content: Text(p.salon.isEmpty
            ? 'haircare.added_simple'.tr(namedArgs: {'name': p.name})
            : 'haircare.added'
                .tr(namedArgs: {'name': p.name, 'salon': p.salon})),
      ),
    );
  }
}

// Hair care products stocked by the partner salons.
class _HairCareProduct {
  final String name;
  final String salon; // Empty until the stocking salon is confirmed.
  final String price; // Empty until the real price is confirmed.
  final String goodFor;
  final String howToUse;
  final String image; // product photo asset

  const _HairCareProduct({
    required this.name,
    required this.salon,
    required this.price,
    required this.goodFor,
    required this.howToUse,
    required this.image,
  });
}

const _hairProductsDir = 'pyin-mal-assets/assets/images/Hair/Product';

// The products the partner salons actually stock. Each name mirrors its asset
// filename.
//
// PRICES ARE ESTIMATES, NOT CONFIRMED FIGURES. They are benchmarked against the
// Myanmar retail market (mass-market shampoo runs ~8,000-27,000 MMK; imported
// salon styling lines like Reuzel run 54,000+), positioned mid-range for
// salon-stocked product. Replace each one with the real price before launch.
//
// `salon` is left blank on purpose — which partner salon carries which product
// is a business fact, and the badge names a real shop to the customer. The card
// and details sheet hide the field while it is empty, so filling it in here is
// all that is needed.
const _hairCareProducts = <_HairCareProduct>[
  _HairCareProduct(
    name: 'Shampoo',
    salon: '',
    price: '15,000 MMK',
    goodFor: 'Everyday cleansing for all hair types.',
    howToUse:
        'Massage into wet hair and scalp, lather, then rinse thoroughly. Repeat if needed.',
    image: '$_hairProductsDir/Shampoo.jpg',
  ),
  _HairCareProduct(
    name: 'Anti Dandruff Shampoo',
    salon: '',
    price: '18,000 MMK',
    goodFor: 'Flaky, itchy scalp and recurring dandruff.',
    howToUse:
        'Massage into a wet scalp and leave for 2-3 minutes so it can work, then rinse. Use 2-3 times a week.',
    image: '$_hairProductsDir/Anti Dandruff Shampoo.jpg',
  ),
  _HairCareProduct(
    name: 'Hair Mask',
    salon: '',
    price: '25,000 MMK',
    goodFor: 'Dry, damaged or over-processed hair that needs deep conditioning.',
    howToUse:
        'Apply to clean, damp hair from mid-lengths to ends, leave 5-10 minutes, then rinse well. Use weekly.',
    image: '$_hairProductsDir/Hair Mask.jpg',
  ),
  _HairCareProduct(
    name: 'One Minute Treatment',
    salon: '',
    price: '22,000 MMK',
    goodFor: 'A fast conditioning boost for dry or brittle hair.',
    howToUse:
        'After shampooing, work through damp hair, leave for one minute, then rinse thoroughly.',
    image: '$_hairProductsDir/One Minute Treatment.jpg',
  ),
  _HairCareProduct(
    name: 'Hair Coat',
    salon: '',
    price: '20,000 MMK',
    goodFor: 'Frizzy or damaged hair needing a smoothing, protective layer.',
    howToUse:
        'Work a small amount through damp mid-lengths and ends before drying. Leave in, do not rinse.',
    image: '$_hairProductsDir/Hair Coat.jpg',
  ),
  _HairCareProduct(
    name: 'Soft Spray',
    salon: '',
    price: '16,000 MMK',
    goodFor: 'Light, flexible hold that keeps hair moving.',
    howToUse:
        'Hold about 30 cm from dry, styled hair and mist evenly. Layer for extra hold.',
    image: '$_hairProductsDir/Soft Spray.jpg',
  ),
];
