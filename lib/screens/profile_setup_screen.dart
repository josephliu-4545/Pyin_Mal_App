import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/screens/onboarding_screen.dart';
import 'package:easy_localization/easy_localization.dart';

/// Collected after sign-up: body info + style preferences.
/// On finish, saves to Firestore (best-effort) and continues to onboarding.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _db = DatabaseService();
  int _step = 0;
  static const _totalSteps = 5;
  bool _saving = false;

  // ── Step 1: basics ──────────────────────────────────────────────────────
  String _gender = 'Female';
  int _age = 22;
  int _height = 165; // cm
  int _weight = 58; // kg

  // ── Step 2: skin tone ───────────────────────────────────────────────────
  int _skinTone = 2; // index into _skinTones

  // ── Step 3: outfit types ────────────────────────────────────────────────
  final Set<String> _outfitTypes = {};
  // ── Step 4: colors — palette builder ────────────────────────────────────
  final List<Color> _palette = [];
  double _hue = 28; // current builder color (HSV)
  double _sat = 0.75;
  double _val = 0.85;
  Color get _currentColor =>
      HSVColor.fromAHSV(1, _hue, _sat, _val).toColor();
  // ── Step 5: style + fit ─────────────────────────────────────────────────
  final Set<String> _styles = {};
  String _fit = 'Regular';

  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const _skinTones = [
    Color(0xFFF6E0C8),
    Color(0xFFEFC9A4),
    Color(0xFFD9A878),
    Color(0xFFB87A4F),
    Color(0xFF8D5524),
    Color(0xFF5C3A21),
  ];
  static const _skinToneLabels = [
    'Fair', 'Light', 'Medium', 'Tan', 'Brown', 'Deep'
  ];
  static const _outfitOptions = [
    ('Casual', Icons.checkroom_rounded),
    ('Streetwear', Icons.skateboarding_rounded),
    ('Formal', Icons.business_center_rounded),
    ('Sporty', Icons.sports_basketball_rounded),
    ('Traditional', Icons.temple_buddhist_rounded),
    ('Minimal', Icons.crop_square_rounded),
    ('Vintage', Icons.camera_roll_rounded),
    ('Party', Icons.celebration_rounded),
  ];
  static const _styleOptions = [
    'Trendy', 'Classic', 'Bold', 'Comfy', 'Elegant', 'Edgy', 'Romantic', 'Cozy'
  ];
  static const _fitOptions = ['Slim', 'Regular', 'Oversized', 'Relaxed'];

  bool get _canContinue {
    switch (_step) {
      case 2:
        return _outfitTypes.isNotEmpty;
      case 3:
        return _palette.isNotEmpty;
      case 4:
        return _styles.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await _db.saveProfileSetup({
        'gender': _gender,
        'age': _age,
        'heightCm': _height,
        'weightKg': _weight,
        'skinTone': _skinToneLabels[_skinTone],
        'outfitTypes': _outfitTypes.toList(),
        'preferredColors': _palette
            .map((c) =>
                '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}')
            .toList(),
        'styles': _styles.toList(),
        'fit': _fit,
        // Merge into the existing free-text preference list used by AI context.
        'preferences': [
          ..._outfitTypes,
          ..._styles,
          'prefers $_fit fit',
        ],
      });
    } catch (_) {
      // Best effort — never block the user from entering the app.
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header: back + progress + skip ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  if (_step > 0)
                    GestureDetector(
                      onTap: _back,
                      child: Icon(Icons.arrow_back_ios_rounded,
                          size: 20, color: ink),
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  // Progress segments
                  Expanded(
                    child: Row(
                      children: List.generate(_totalSteps, (i) {
                        final done = i <= _step;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 5,
                            decoration: BoxDecoration(
                              color: done
                                  ? accent
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.inkGrey.withOpacity(0.25)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _finish,
                    child: Text('profile.skip'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.paleText
                                : AppColors.inkGrey)),
                  ),
                ],
              ),
            ),

            // ── Animated step body ───────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _buildStep(isDark, accent, ink),
                ),
              ),
            ),

            // ── Continue button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_canContinue && !_saving) ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accent.withOpacity(0.4),
                    foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _step == _totalSteps - 1 ? 'profile.finish'.tr() : 'profile.continue_btn'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark, Color accent, Color ink) {
    switch (_step) {
      case 0:
        return _basicsStep(isDark, accent, ink);
      case 1:
        return _skinToneStep(isDark, accent, ink);
      case 2:
        return _multiStep(
          isDark, accent, ink,
          title: 'profile.what_to_wear'.tr(),
          subtitle: 'profile.what_to_wear_desc'.tr(),
          options: _outfitOptions.map((o) => o.$1).toList(),
          icons: _outfitOptions.map((o) => o.$2).toList(),
          selected: _outfitTypes,
        );
      case 3:
        return _colorStep(isDark, accent, ink);
      case 4:
        return _styleStep(isDark, accent, ink);
      default:
        return const SizedBox();
    }
  }

  // ── Section heading helper ───────────────────────────────────────────────
  Widget _heading(String title, String subtitle, Color ink, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.rufina(
                fontSize: 26, fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.paleText : AppColors.inkGrey)),
        const SizedBox(height: 26),
      ],
    );
  }

  // ── Step 1: basics (gender, age, height, weight) ─────────────────────────
  Widget _basicsStep(bool isDark, Color accent, Color ink) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('profile.about_you'.tr(), 'profile.about_desc'.tr(),
            ink, isDark),
        // Gender
        Text('profile.gender'.tr(),
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _genders.map((g) {
            final sel = _gender == g;
            return GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? accent : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel
                          ? accent
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt)),
                ),
                child: Text('profile.genders.$g'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? (isDark ? AppColors.charcoal : Colors.white)
                            : ink)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _slider('profile.age'.tr(), _age, 14, 70, 'profile.yrs'.tr(), accent, isDark, ink,
            (v) => setState(() => _age = v)),
        const SizedBox(height: 20),
        _slider('profile.height'.tr(), _height, 130, 210, 'profile.cm'.tr(), accent, isDark, ink,
            (v) => setState(() => _height = v)),
        const SizedBox(height: 20),
        _slider('profile.weight'.tr(), _weight, 35, 150, 'profile.kg'.tr(), accent, isDark, ink,
            (v) => setState(() => _weight = v)),
      ],
    );
  }

  Widget _slider(String label, int value, int min, int max, String unit,
      Color accent, bool isDark, Color ink, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
            Text('$value $unit',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accent)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accent,
            inactiveTrackColor: accent.withOpacity(0.2),
            thumbColor: accent,
            overlayColor: accent.withOpacity(0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  // ── Step 2: skin tone ─────────────────────────────────────────────────────
  Widget _skinToneStep(bool isDark, Color accent, Color ink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('profile.skin_tone'.tr(),
            'profile.skin_desc'.tr(), ink, isDark),
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: List.generate(_skinTones.length, (i) {
              final sel = _skinTone == i;
              return GestureDetector(
                onTap: () => setState(() => _skinTone = i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: sel ? 64 : 56,
                      height: sel ? 64 : 56,
                      decoration: BoxDecoration(
                        color: _skinTones[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? accent : Colors.transparent,
                            width: 3),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('profile.skin_tones.${_skinToneLabels[i]}'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel
                                ? accent
                                : (isDark
                                    ? AppColors.paleText
                                    : AppColors.inkGrey))),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Generic multi-select chips step (outfit types) ───────────────────────
  Widget _multiStep(
    bool isDark,
    Color accent,
    Color ink, {
    required String title,
    required String subtitle,
    required List<String> options,
    required List<IconData> icons,
    required Set<String> selected,
  }) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(title, subtitle, ink, isDark),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(options.length, (i) {
            final label = options[i];
            final sel = selected.contains(label);
            return GestureDetector(
              onTap: () => setState(() {
                sel ? selected.remove(label) : selected.add(label);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: sel ? accent.withOpacity(0.12) : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: sel
                          ? accent
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt),
                      width: sel ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(icons[i],
                        size: 20,
                        color: sel
                            ? accent
                            : (isDark ? AppColors.paleText : AppColors.inkGrey)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('profile.outfits.$label'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? accent : ink)),
                    ),
                    if (sel)
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: accent),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Step 4: colors — palette builder ──────────────────────────────────────
  Widget _colorStep(bool isDark, Color accent, Color ink) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final current = _currentColor;
    // Readable check colour on top of the current swatch.
    final onCurrent =
        current.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('profile.palette'.tr(),
            'profile.palette_desc'.tr(), ink, isDark),

        // ── Live preview + Add button ────────────────────────────────────
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: current,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: current.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${(current.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _palette.length >= 8
                          ? null
                          : () => setState(() {
                                if (!_palette.any((c) => c.value == current.value)) {
                                  _palette.add(current);
                                }
                              }),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _palette.length >= 8 ? 'profile.palette_full'.tr() : 'profile.add_palette'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        disabledBackgroundColor: accent.withOpacity(0.4),
                        foregroundColor:
                            isDark ? AppColors.charcoal : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Quick check overlay icon on swatch (decorative)
            Icon(Icons.palette_rounded, color: onCurrent.withOpacity(0), size: 0),
          ],
        ),
        const SizedBox(height: 22),

        // ── Hue / Saturation / Brightness sliders ────────────────────────
        _colorSlider(
          label: 'profile.hue'.tr(),
          value: _hue,
          min: 0,
          max: 360,
          gradient: const [
            Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
            Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
          thumb: HSVColor.fromAHSV(1, _hue, 1, 1).toColor(),
          onChanged: (v) => setState(() => _hue = v),
          ink: ink,
          muted: muted,
        ),
        const SizedBox(height: 16),
        _colorSlider(
          label: 'profile.saturation'.tr(),
          value: _sat,
          min: 0,
          max: 1,
          gradient: [
            HSVColor.fromAHSV(1, _hue, 0, _val).toColor(),
            HSVColor.fromAHSV(1, _hue, 1, _val).toColor(),
          ],
          thumb: current,
          onChanged: (v) => setState(() => _sat = v),
          ink: ink,
          muted: muted,
        ),
        const SizedBox(height: 16),
        _colorSlider(
          label: 'profile.brightness'.tr(),
          value: _val,
          min: 0,
          max: 1,
          gradient: [
            Colors.black,
            HSVColor.fromAHSV(1, _hue, _sat, 1).toColor(),
          ],
          thumb: current,
          onChanged: (v) => setState(() => _val = v),
          ink: ink,
          muted: muted,
        ),
        const SizedBox(height: 26),

        // ── Your palette ─────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('profile.your_palette'.tr(),
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
            Text('${_palette.length}/8',
                style: GoogleFonts.outfit(fontSize: 12, color: muted)),
          ],
        ),
        const SizedBox(height: 12),
        if (_palette.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
            ),
            child: Center(
              child: Text('profile.no_colors'.tr(),
                  style: GoogleFonts.outfit(fontSize: 12, color: muted)),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette.map((c) {
              final onC =
                  c.computeLuminance() > 0.55 ? Colors.black54 : Colors.white;
              return GestureDetector(
                onTap: () => setState(() => _palette.remove(c)),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.creamAlt),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(Icons.close_rounded, size: 14, color: onC),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _colorSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required List<Color> gradient,
    required Color thumb,
    required ValueChanged<double> onChanged,
    required Color ink,
    required Color muted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600, color: muted)),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.center,
          children: [
            // Gradient track
            Container(
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 0,
                activeTrackColor: Colors.transparent,
                inactiveTrackColor: Colors.transparent,
                thumbColor: thumb,
                overlayColor: thumb.withOpacity(0.15),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 11),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: style + fit ───────────────────────────────────────────────────
  Widget _styleStep(bool isDark, Color accent, Color ink) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('profile.style_vibe'.tr(),
            'profile.style_vibe_desc'.tr(), ink, isDark),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _styleOptions.map((s) {
            final sel = _styles.contains(s);
            return GestureDetector(
              onTap: () => setState(() {
                sel ? _styles.remove(s) : _styles.add(s);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? accent : cardBg,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: sel
                          ? accent
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt)),
                ),
                child: Text('profile.vibes.$s'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? (isDark ? AppColors.charcoal : Colors.white)
                            : ink)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        Text('Preferred fit',
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
        const SizedBox(height: 10),
        Row(
          children: _fitOptions.map((f) {
            final sel = _fit == f;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _fit = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? accent.withOpacity(0.12) : cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: sel
                            ? accent
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.creamAlt),
                        width: sel ? 2 : 1),
                  ),
                  child: Text('profile.fits.$f'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? accent : ink)),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
