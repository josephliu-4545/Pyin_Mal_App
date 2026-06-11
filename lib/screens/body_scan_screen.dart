import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/services/bodygram_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';

/// Bodygram body scan: front + right-side photo plus height/weight/age/gender
/// → precise body measurements, saved to the user profile for sizing.
class BodyScanScreen extends StatefulWidget {
  const BodyScanScreen({super.key});

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  final _db = DatabaseService();
  final _picker = ImagePicker();

  String _gender = 'female'; // Bodygram accepts only male / female
  final _ageCtrl = TextEditingController(text: '22');
  final _heightCtrl = TextEditingController(text: '165');
  final _weightCtrl = TextEditingController(text: '58');

  Uint8List? _frontPhoto;
  Uint8List? _rightPhoto;

  bool _busy = false;
  BodyMeasurements? _result;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillFromProfile() async {
    try {
      final data = await _db.getUserData();
      if (data == null || !mounted) return;
      setState(() {
        if (data['gender'] == 'Male') _gender = 'male';
        if (data['age'] != null) _ageCtrl.text = '${data['age']}';
        if (data['heightCm'] != null) _heightCtrl.text = '${data['heightCm']}';
        if (data['weightKg'] != null) _weightCtrl.text = '${data['weightKg']}';
        final saved = data['bodyMeasurements'];
        if (saved is Map) {
          _result = BodyMeasurements.fromMap(Map<String, dynamic>.from(saved));
        }
      });
    } catch (_) {} // prefill is best-effort
  }

  Future<void> _pickPhoto(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('bodygram.take_photo'.tr(), style: GoogleFonts.outfit()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('bodygram.from_gallery'.tr(), style: GoogleFonts.outfit()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // imageQuality forces JPEG re-encode — Bodygram requires JPEG.
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (isFront) {
          _frontPhoto = bytes;
        } else {
          _rightPhoto = bytes;
        }
      });
    } catch (e) {
      _showError('bodygram.photo_error'.tr());
    }
  }

  Future<void> _scan() async {
    final age = int.tryParse(_ageCtrl.text.trim());
    final height = int.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (age == null || height == null || weight == null ||
        age < 5 || age > 110 || height < 80 || height > 250 ||
        weight < 20 || weight > 300) {
      _showError('bodygram.invalid_stats'.tr());
      return;
    }

    final hasPhotos = _frontPhoto != null && _rightPhoto != null;
    setState(() => _busy = true);
    try {
      final result = hasPhotos
          ? await BodygramService.photoScan(
              age: age,
              gender: _gender,
              heightCm: height,
              weightKg: weight,
              frontPhotoJpeg: _frontPhoto!,
              rightPhotoJpeg: _rightPhoto!,
            )
          : await BodygramService.statsEstimation(
              age: age,
              gender: _gender,
              heightCm: height,
              weightKg: weight,
            );

      await _db.saveBodyMeasurements(result.toMap());
      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('bodygram.saved'.tr())),
      );
    } on BodygramException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('bodygram.generic_error'.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final card = isDark ? AppColors.darkWarm : AppColors.creamCard;
    final border = isDark ? AppColors.darkBorder : AppColors.creamAlt;
    final hasPhotos = _frontPhoto != null && _rightPhoto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('bodygram.title'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('bodygram.subtitle'.tr(),
              style: GoogleFonts.outfit(fontSize: 14, color: muted, height: 1.4)),
          const SizedBox(height: 20),

          // ── Stats ─────────────────────────────────────────────────────
          _sectionLabel('bodygram.about_you'.tr(), muted),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _genderChip('female', 'bodygram.female'.tr(), ink),
                    const SizedBox(width: 10),
                    _genderChip('male', 'bodygram.male'.tr(), ink),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statField(_ageCtrl, 'profile.age'.tr(), 'profile.yrs'.tr(), ink, muted, border),
                    const SizedBox(width: 10),
                    _statField(_heightCtrl, 'profile.height'.tr(), 'profile.cm'.tr(), ink, muted, border),
                    const SizedBox(width: 10),
                    _statField(_weightCtrl, 'profile.weight'.tr(), 'profile.kg'.tr(), ink, muted, border),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Photos ────────────────────────────────────────────────────
          _sectionLabel('bodygram.photos'.tr(), muted),
          Row(
            children: [
              _photoCard(
                isFront: true,
                bytes: _frontPhoto,
                label: 'bodygram.front_photo'.tr(),
                icon: Icons.accessibility_new_rounded,
                card: card, border: border, muted: muted,
              ),
              const SizedBox(width: 12),
              _photoCard(
                isFront: false,
                bytes: _rightPhoto,
                label: 'bodygram.right_photo'.tr(),
                icon: Icons.directions_walk_rounded,
                card: card, border: border, muted: muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(isDark ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    size: 18, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('bodygram.tips'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 12.5, color: muted, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Action ────────────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _busy ? null : _scan,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      hasPhotos
                          ? 'bodygram.scan_btn'.tr()
                          : 'bodygram.estimate_btn'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
          if (!hasPhotos)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('bodygram.estimate_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 12, color: muted)),
            ),

          // ── Results ───────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 28),
            _sectionLabel('bodygram.results'.tr(), muted),
            Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  for (final name in BodyMeasurements.keyMeasurements)
                    if (_result!.cm(name) != null)
                      _measureRow(name, _result!.cm(name)!, ink, muted, border),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color muted) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: muted, letterSpacing: 1.2)),
      );

  Widget _genderChip(String value, String label, Color ink) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.burgundy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected
                    ? AppColors.burgundy
                    : AppColors.gold.withOpacity(0.5)),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : ink)),
        ),
      ),
    );
  }

  Widget _statField(TextEditingController ctrl, String label, String unit,
      Color ink, Color muted, Color border) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
            fontSize: 16, fontWeight: FontWeight.w600, color: ink),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          labelStyle: GoogleFonts.outfit(fontSize: 12, color: muted),
          suffixStyle: GoogleFonts.outfit(fontSize: 11, color: muted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold),
          ),
        ),
      ),
    );
  }

  Widget _photoCard({
    required bool isFront,
    required Uint8List? bytes,
    required String label,
    required IconData icon,
    required Color card,
    required Color border,
    required Color muted,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _busy ? null : () => _pickPhoto(isFront),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: bytes != null ? AppColors.gold : border,
                width: bytes != null ? 1.5 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: AppColors.gold, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 14,
                            color: Colors.white),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 38, color: AppColors.gold),
                    const SizedBox(height: 10),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: muted)),
                    const SizedBox(height: 4),
                    Icon(Icons.add_circle_outline, size: 18, color: muted),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _measureRow(
      String name, double cm, Color ink, Color muted, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('bodygram.m.$name'.tr(),
                style: GoogleFonts.outfit(fontSize: 14, color: ink)),
          ),
          Text('${cm.toStringAsFixed(1)} cm',
              style: GoogleFonts.outfit(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.burgundy)),
        ],
      ),
    );
  }
}
