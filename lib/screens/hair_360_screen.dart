// lib/screens/hair_360_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart'; // AppColors
import '../services/nanobanana_api_service.dart';
import 'try_on_video_screen.dart';

/// Standalone "Hair 360": take/upload a photo, pick a hairstyle from the
/// catalogue, and get a short video of yourself turning your head so the new
/// cut can be judged from the front, sides and back.
///
/// The hairstyle try-on image (NanoBanana) is an internal step — the user
/// only ever sees photo → style → video.
class Hair360Screen extends StatefulWidget {
  /// Asset path of a hairstyle to preselect (e.g. when arriving from the
  /// haircut gallery with a style already chosen).
  final String? initialStylePath;

  const Hair360Screen({super.key, this.initialStylePath});

  @override
  State<Hair360Screen> createState() => _Hair360ScreenState();
}

class _Hair360ScreenState extends State<Hair360Screen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _userPhoto;
  Uint8List? _userPhotoBytes;

  String? _stylePath;
  XFile? _stylePhoto;
  Uint8List? _styleBytes;

  // Catalogue browsing state.
  List<String> _allStyles = [];
  String _gender = 'Men';
  bool _working = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStylePath;
    if (initial != null && initial.isNotEmpty) {
      // Show the gallery the style actually came from.
      _gender = initial.contains('/Female/') ? 'Women' : 'Men';
      _selectStyle(initial);
    }
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    const prefix = 'pyin-mal-assets/assets/images/Hair/';
    final styles = manifest
        .listAssets()
        .where((p) =>
            p.startsWith(prefix) &&
            (p.endsWith('.jpg') || p.endsWith('.png') || p.endsWith('.webp')))
        .toList()
      ..sort();
    if (mounted) setState(() => _allStyles = styles);
  }

  List<String> get _visibleStyles {
    final folder =
        'pyin-mal-assets/assets/images/Hair/${_gender == 'Women' ? 'Female' : 'Male'}/';
    return _allStyles.where((p) => p.startsWith(folder)).toList();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _accent => _isDark ? AppColors.gold : AppColors.burgundy;
  Color get _bg => _isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
  Color get _surface => _isDark ? AppColors.darkWarm : Colors.white;
  Color get _ink => _isDark ? Colors.white : AppColors.inkBlack;
  Color get _muted => _isDark ? AppColors.paleText : AppColors.inkGrey;

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'A clear photo of your face and shoulders works best — '
                'facing the camera, hair fully visible.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12.5, color: _muted),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera_rounded, color: _accent),
              title: Text('Take a photo',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, color: _ink)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: _accent),
              title: Text('Choose from gallery',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, color: _ink)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final img = await _picker.pickImage(source: choice);
    if (img == null || !mounted) return;
    final bytes = await img.readAsBytes();
    setState(() {
      _userPhoto = img;
      _userPhotoBytes = bytes;
    });
  }

  Future<void> _selectStyle(String path) async {
    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      if (!mounted) return;
      setState(() {
        _stylePath = path;
        _styleBytes = bytes;
        _stylePhoto = XFile.fromData(bytes, name: path.split('/').last);
      });
    } catch (e) {
      debugPrint('Failed to load hairstyle asset: $e');
    }
  }

  Future<void> _generate() async {
    if (_userPhoto == null || _stylePhoto == null) return;
    setState(() => _working = true);

    final imageUrl = await NanoBananaApiService.generateHairStyleImage(
      userPhoto: _userPhoto!,
      referenceHairPhoto: _stylePhoto,
    );
    if (!mounted) return;
    setState(() => _working = false);

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not apply the hairstyle — please try again.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TryOnVideoScreen(tryOnImageUrl: imageUrl, headTurn: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _userPhotoBytes != null && _styleBytes != null;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hair 360',
                        style: GoogleFonts.rufina(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _ink)),
                    const SizedBox(height: 6),
                    Text(
                        'Try a new cut and watch it from every angle before you '
                        'sit in the chair.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, height: 1.4, color: _muted)),
                    const SizedBox(height: 24),
                    _stepLabel('1', 'Your photo'),
                    const SizedBox(height: 12),
                    _photoCard(),
                    const SizedBox(height: 24),
                    _stepLabel('2', 'Pick a hairstyle'),
                    const SizedBox(height: 12),
                    _genderToggle(),
                    const SizedBox(height: 12),
                    _styleGrid(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (ready && !_working) ? _generate : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          disabledBackgroundColor: _isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade300,
                          foregroundColor:
                              _isDark ? AppColors.charcoal : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _working
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('Cutting your hair…',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.face_retouching_natural_rounded,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text('Generate Hair Video',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        ready
                            ? 'Takes 2-4 minutes in total'
                            : 'Add your photo and choose a style',
                        style: GoogleFonts.outfit(fontSize: 12, color: _muted),
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
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDark ? 0.2 : 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: _ink),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.face_retouching_natural_rounded,
                    size: 13, color: _accent),
                const SizedBox(width: 4),
                Text('AI Hair',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLabel(String num, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          child: Center(
            child: Text(num,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? AppColors.charcoal : Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
      ],
    );
  }

  Widget _photoCard() {
    final has = _userPhotoBytes != null;
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: has ? _accent : _accent.withOpacity(0.35),
            width: has ? 2.5 : 1.5,
          ),
        ),
        child: has
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_userPhotoBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo_rounded,
                        color: _accent, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text('Add your photo',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 4),
                  Text('Face and shoulders, looking at the camera',
                      style: GoogleFonts.outfit(fontSize: 12, color: _muted)),
                ],
              ),
      ),
    );
  }

  Widget _genderToggle() {
    return Row(
      children: [
        for (final g in ['Men', 'Women'])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _gender = g;
                _stylePath = null;
                _styleBytes = null;
                _stylePhoto = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: _gender == g ? _accent : _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _gender == g
                          ? _accent
                          : (_isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt)),
                ),
                child: Text(g,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _gender == g
                            ? (_isDark ? AppColors.charcoal : Colors.white)
                            : _muted)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _styleGrid() {
    final styles = _visibleStyles;
    if (styles.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text('Loading hairstyles…',
              style: GoogleFonts.outfit(fontSize: 12, color: _muted)),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final path = styles[i];
          final selected = path == _stylePath;
          // "Hair/Male/Fade/BURST_FADE.jpg" → "Burst Fade"
          final name = path
              .split('/')
              .last
              .replaceAll(RegExp(r'\.(jpg|png|webp)$'), '')
              .replaceAll('_', ' ');
          return GestureDetector(
            onTap: () => _selectStyle(path),
            child: SizedBox(
              width: 124,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? _accent
                              : (_isDark
                                  ? AppColors.darkBorder
                                  : AppColors.creamAlt),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(path, fit: BoxFit.cover),
                            if (selected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                      color: _accent, shape: BoxShape.circle),
                                  child: Icon(Icons.check_rounded,
                                      size: 13,
                                      color: _isDark
                                          ? AppColors.charcoal
                                          : Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _accent : _ink)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
