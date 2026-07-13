import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/services/bodygram_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/pose_guide_validator.dart';
import 'package:pyin_mal_app/screens/pose_guide_camera_screen.dart';

/// Bodygram body scan: front + right-side photo plus height/weight/age/gender
/// → precise body measurements, saved to the user profile for sizing.
class BodyScanScreen extends StatefulWidget {
  const BodyScanScreen({super.key});

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  final _picker = ImagePicker();

  late final TabController _tabs;

  String _gender = 'female'; // Bodygram accepts only male / female
  final _ageCtrl = TextEditingController(text: '22');
  final _heightCtrl = TextEditingController(text: '165');
  final _weightCtrl = TextEditingController(text: '58');

  Uint8List? _frontPhoto;
  Uint8List? _rightPhoto;

  bool _busy = false;
  BodyMeasurements? _result;

  /// Measurements a user can realistically take themselves with a tape,
  /// keyed by Bodygram's names so manual entries feed sizing the same way.
  static const _manualKeys = [
    'neckGirth',
    'acrossBackShoulderWidth',
    'bustGirth',
    'waistGirth',
    'hipGirth',
    'backNeckPointToWristLengthR',
    'thighGirthR',
    'insideLegLengthR',
  ];
  final Map<String, TextEditingController> _manualCtrls = {
    for (final k in _manualKeys) k: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    for (final c in _manualCtrls.values) {
      c.dispose();
    }
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
          _fillManualFromResult();
        }
      });
    } catch (_) {} // prefill is best-effort
  }

  /// Prefill the manual-entry fields from whatever measurements are on file
  /// (whether they came from a scan or a previous manual entry).
  void _fillManualFromResult() {
    if (_result == null) return;
    for (final k in _manualKeys) {
      final cm = _result!.cm(k);
      if (cm != null) _manualCtrls[k]!.text = cm.toStringAsFixed(1);
    }
  }

  /// Save the hand-entered measurements to the profile, same store as a scan.
  Future<void> _saveManual() async {
    final valuesMm = <String, double>{};
    for (final k in _manualKeys) {
      final cm = double.tryParse(_manualCtrls[k]!.text.trim());
      if (cm != null && cm > 0) valuesMm[k] = cm * 10.0; // cm → mm
    }
    if (valuesMm.isEmpty) {
      _showError('measure.empty_error'.tr());
      return;
    }

    setState(() => _busy = true);
    try {
      final result = BodyMeasurements(
        scanId: 'manual-${DateTime.now().millisecondsSinceEpoch}',
        source: 'manual',
        valuesMm: valuesMm,
        measuredAt: DateTime.now(),
      );
      await _db.saveBodyMeasurements(result.toMap());
      if (!mounted) return;
      setState(() => _result = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('measure.saved'.tr())),
      );
    } catch (e) {
      _showError('bodygram.generic_error'.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto(bool isFront) async {
    final choice = await showModalBottomSheet<String>(
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
              leading: const Icon(Icons.center_focus_strong_outlined),
              title: Text('capture.guided_camera'.tr(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              subtitle: Text('capture.guided_camera_sub'.tr(),
                  style: GoogleFonts.outfit(fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'guided'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('bodygram.from_gallery'.tr(), style: GoogleFonts.outfit()),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;

    if (choice == 'guided') {
      if (!mounted) return;
      final bytes = await Navigator.push<Uint8List?>(
        context,
        MaterialPageRoute(
          builder: (_) => PoseGuideCameraScreen(
            shot: isFront ? BodyShot.front : BodyShot.side,
          ),
        ),
      );
      if (bytes == null || !mounted) return;
      setState(() {
        if (isFront) {
          _frontPhoto = bytes;
        } else {
          _rightPhoto = bytes;
        }
      });
      return;
    }

    try {
      // imageQuality forces JPEG re-encode — Bodygram requires JPEG.
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 92,
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

    return Scaffold(
      appBar: AppBar(
        title: Text('bodygram.title'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.burgundy,
          labelColor: ink,
          unselectedLabelColor: muted,
          labelStyle:
              GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'measure.tab_scan'.tr()),
            Tab(text: 'measure.tab_manual'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildScanTab(isDark, ink, muted, card, border),
          _buildManualTab(isDark, ink, muted, card, border),
        ],
      ),
    );
  }

  // ── Tab 1: AI body scan (Bodygram) ──────────────────────────────────────────
  Widget _buildScanTab(
      bool isDark, Color ink, Color muted, Color card, Color border) {
    final hasPhotos = _frontPhoto != null && _rightPhoto != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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

        ..._resultsSection(ink, muted, card, border),
      ],
    );
  }

  // ── Tab 2: Measure yourself (manual, no AI / no photos) ─────────────────────
  Widget _buildManualTab(
      bool isDark, Color ink, Color muted, Color card, Color border) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Privacy-first intro
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(isDark ? 0.12 : 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('measure.intro_title'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text('measure.intro'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 12.5, color: muted, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _sectionLabel('measure.how_to'.tr(), muted),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.straighten_rounded, size: 16, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text('measure.tip'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 12.5, color: muted, height: 1.5)),
              ),
            ],
          ),
        ),

        for (int i = 0; i < _manualKeys.length; i++)
          _manualRow(i + 1, _manualKeys[i], ink, muted, card, border),

        const SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _busy ? null : _saveManual,
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
                : Text('measure.save_btn'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),

        ..._resultsSection(ink, muted, card, border),
      ],
    );
  }

  /// A single "how to measure X" row with a cm input. Shared shape with the
  /// scan results so both tabs feel like one feature.
  Widget _manualRow(int num, String key, Color ink, Color muted, Color card,
      Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.burgundy, shape: BoxShape.circle),
            child: Text('$num',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('bodygram.m.$key'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ink)),
                const SizedBox(height: 3),
                Text('measure.how.$key'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: muted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _manualCtrls[key],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w600, color: ink),
              decoration: InputDecoration(
                suffixText: 'cm',
                isDense: true,
                suffixStyle: GoogleFonts.outfit(fontSize: 11, color: muted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.gold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Saved-measurements block, shared by both tabs (updates when either a scan
  /// or a manual save sets [_result]).
  List<Widget> _resultsSection(
      Color ink, Color muted, Color card, Color border) {
    if (_result == null) return const [];
    return [
      const SizedBox(height: 28),
      _sectionLabel('bodygram.results'.tr(), muted),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(_resultSourceIcon(), size: 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(_scanInfoLabel(),
                style: GoogleFonts.outfit(fontSize: 12, color: muted)),
          ],
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            for (final name in _orderedMeasurementNames())
              _measureRow(name, _result!.cm(name)!, ink, muted, border),
          ],
        ),
      ),
    ];
  }

  IconData _resultSourceIcon() {
    switch (_result!.source) {
      case 'statsEstimation':
        return Icons.calculate_outlined;
      case 'manual':
        return Icons.straighten_rounded;
      default:
        return Icons.photo_camera_outlined;
    }
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

  /// e.g. "Photo scan · 11.06.2026"
  String _scanInfoLabel() {
    final String src;
    switch (_result!.source) {
      case 'statsEstimation':
        src = 'bodygram.source_stats'.tr();
        break;
      case 'manual':
        src = 'measure.source_manual'.tr();
        break;
      default:
        src = 'bodygram.source_photo'.tr();
    }
    final d = _result!.measuredAt;
    if (d == null) return src;
    final date = '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
    return '$src · $date';
  }

  /// Fit-relevant measurements first, everything else Bodygram returned after.
  List<String> _orderedMeasurementNames() {
    final all = _result!.valuesMm.keys.toSet();
    final key = BodyMeasurements.keyMeasurements
        .where(all.contains)
        .toList();
    final rest = (all.difference(key.toSet()).toList())..sort();
    return [...key, ...rest];
  }

  /// Translated label, falling back to a humanized camelCase name
  /// (e.g. outerAnkleHeightR → "Outer ankle height").
  String _measureLabel(String name) {
    final key = 'bodygram.m.$name';
    final t = key.tr();
    if (t != key) return t;
    var s = name
        .replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}')
        .trim();
    if (s.endsWith(' r')) s = s.substring(0, s.length - 2);
    return s[0].toUpperCase() + s.substring(1);
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
            child: Text(_measureLabel(name),
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
