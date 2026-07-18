// lib/screens/ar_studio_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart'; // AppColors
import '../services/nanobanana_api_service.dart';
import '../services/pose_guide_validator.dart';
import 'pose_guide_camera_screen.dart';
import 'try_on_video_screen.dart';

/// Standalone "360° Studio": guided pose capture → outfit selection → AI 360°
/// video, as one flow. The try-on image (NanoBanana) is an internal step the
/// user never has to run separately — this screen generates it and hands the
/// URL to [TryOnVideoScreen], which creates and plays the video.
class ARStudioScreen extends StatefulWidget {
  const ARStudioScreen({super.key});

  @override
  State<ARStudioScreen> createState() => _ARStudioScreenState();
}

class _ARStudioScreenState extends State<ARStudioScreen> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _personBytes;
  XFile? _shirt;
  Uint8List? _shirtBytes;
  XFile? _pants;
  Uint8List? _pantsBytes;

  bool _working = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _accent => _isDark ? AppColors.gold : AppColors.burgundy;
  Color get _bg => _isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
  Color get _surface => _isDark ? AppColors.darkWarm : Colors.white;
  Color get _ink => _isDark ? Colors.white : AppColors.inkBlack;
  Color get _muted => _isDark ? AppColors.paleText : AppColors.inkGrey;

  Future<void> _capture() async {
    final bytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
          builder: (_) => const PoseGuideCameraScreen(shot: BodyShot.front)),
    );
    if (bytes != null && mounted) setState(() => _personBytes = bytes);
  }

  Future<void> _pickGarment(bool isShirt) async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img == null || !mounted) return;
    final bytes = await img.readAsBytes();
    setState(() {
      if (isShirt) {
        _shirt = img;
        _shirtBytes = bytes;
      } else {
        _pants = img;
        _pantsBytes = bytes;
      }
    });
  }

  Future<void> _generate() async {
    if (_personBytes == null || (_shirt == null && _pants == null)) return;
    setState(() => _working = true);

    // Internal step: dress the person (NanoBanana). Its result URL is public,
    // which is exactly what the video model needs as input.
    final imageUrl = await NanoBananaApiService.generateTryOnImage(
      userPhoto: XFile.fromData(_personBytes!, name: 'studio_capture.jpg'),
      shirtPhoto: _shirt,
      pantsPhoto: _pants,
    );
    if (!mounted) return;
    setState(() => _working = false);

    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not fit the outfit — please try again.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => TryOnVideoScreen(tryOnImageUrl: imageUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _personBytes != null && (_shirtBytes != null || _pantsBytes != null);
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
                    Text('360° Studio',
                        style: GoogleFonts.rufina(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _ink)),
                    const SizedBox(height: 6),
                    Text(
                        'Capture yourself with the guided camera, pick an outfit, '
                        'and watch yourself wearing it from every angle.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, height: 1.4, color: _muted)),
                    const SizedBox(height: 24),
                    _stepLabel('1', 'Capture yourself'),
                    const SizedBox(height: 12),
                    _captureCard(),
                    const SizedBox(height: 24),
                    _stepLabel('2', 'Pick the outfit'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _garmentCard('Top', Icons.checkroom_rounded,
                                _shirtBytes, () => _pickGarment(true), () {
                          setState(() {
                            _shirt = null;
                            _shirtBytes = null;
                          });
                        })),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _garmentCard(
                                'Bottom',
                                Icons.dry_cleaning_rounded,
                                _pantsBytes,
                                () => _pickGarment(false), () {
                          setState(() {
                            _pants = null;
                            _pantsBytes = null;
                          });
                        })),
                      ],
                    ),
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
                                  Text('Fitting your outfit…',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.threed_rotation_rounded,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text('Generate 360° Video',
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
                            : 'Capture yourself and add at least one piece',
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
                Icon(Icons.threed_rotation_rounded, size: 13, color: _accent),
                const SizedBox(width: 4),
                Text('AI 360°',
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

  Widget _captureCard() {
    final has = _personBytes != null;
    return GestureDetector(
      onTap: _capture,
      child: Container(
        height: 220,
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
                    Image.memory(_personBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _capture,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text('Recapture',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
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
                    child: Icon(Icons.accessibility_new_rounded,
                        color: _accent, size: 30),
                  ),
                  const SizedBox(height: 14),
                  Text('Open guided camera',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 4),
                  Text('We track your pose live so the shot comes out right',
                      style: GoogleFonts.outfit(fontSize: 12, color: _muted)),
                ],
              ),
      ),
    );
  }

  Widget _garmentCard(String title, IconData icon, Uint8List? bytes,
      VoidCallback onTap, VoidCallback onRemove) {
    final has = bytes != null;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: has
                  ? _accent
                  : (_isDark ? AppColors.darkBorder : AppColors.creamAlt),
              width: has ? 2 : 1,
            ),
          ),
          child: has
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(bytes, fit: BoxFit.cover),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: _muted, size: 28),
                    const SizedBox(height: 8),
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                    const SizedBox(height: 2),
                    Icon(Icons.add_rounded, size: 14, color: _accent),
                  ],
                ),
        ),
      ),
    );
  }
}
