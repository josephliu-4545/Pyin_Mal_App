import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/services/fitting_session.dart';

/// Inline, non-blocking size-mismatch notice. Purely presentational — pass it
/// the message from SizeAdvisor/SizeFitService. Deliberately plain so the UI
/// team can restyle it in one place.
class SizeFitBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  const SizeFitBanner({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Amber "heads-up" treatment — advisory, not an error.
    const amber = Color(0xFFB26A00);
    final bg = isDark ? const Color(0x33B26A00) : const Color(0xFFFFF4E0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: amber.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.straighten_rounded, size: 18, color: amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF3D9A6) : const Color(0xFF7A4A00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "Fitting for: You / [name]" chip. Tapping opens a sheet to
/// switch between the account holder and a guest (with the guest's sizes).
/// Rebuilds whenever [FittingSession] changes. [onChanged] lets the host
/// re-run its size checks after the wearer flips.
class WhoIsThisForSelector extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onChanged;

  const WhoIsThisForSelector({super.key, required this.isDark, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return AnimatedBuilder(
      animation: FittingSession.instance,
      builder: (context, _) {
        final session = FittingSession.instance;
        final label = session.isSelf
            ? 'You'
            : (session.guestName?.trim().isNotEmpty == true
                ? session.guestName!.trim()
                : 'Someone else');
        return GestureDetector(
          onTap: () async {
            await showWhoIsThisForSheet(context, isDark: isDark);
            onChanged?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(session.isSelf ? Icons.person_rounded : Icons.group_rounded,
                    size: 15, color: accent),
                const SizedBox(width: 6),
                Text('Fitting for: $label',
                    style: GoogleFonts.outfit(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: accent)),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: accent),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet to choose who a try-on / purchase is being sized for. Picking
/// "Someone else" reveals key measurement fields (cm) that seed a guest body on
/// [FittingSession] for the rest of the session. Returns when dismissed.
Future<void> showWhoIsThisForSheet(BuildContext context,
    {required bool isDark}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WhoIsThisForSheet(isDark: isDark),
  );
}

class _WhoIsThisForSheet extends StatefulWidget {
  final bool isDark;
  const _WhoIsThisForSheet({required this.isDark});

  @override
  State<_WhoIsThisForSheet> createState() => _WhoIsThisForSheetState();
}

class _WhoIsThisForSheetState extends State<_WhoIsThisForSheet> {
  late bool _someoneElse = !FittingSession.instance.isSelf;
  final _nameCtrl = TextEditingController();

  // Key fit measurements, in cm, keyed by Bodygram names so they feed the size
  // engine exactly like the account holder's own measurements.
  static const _fields = <({String key, String label})>[
    (key: 'bustGirth', label: 'Chest / Bust'),
    (key: 'waistGirth', label: 'Waist'),
    (key: 'hipGirth', label: 'Hip'),
  ];
  final Map<String, TextEditingController> _ctrls = {
    for (final f in _fields) f.key: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    final s = FittingSession.instance;
    if (!s.isSelf) {
      _nameCtrl.text = s.guestName ?? '';
      final g = s.guestMeasurements;
      if (g != null) {
        for (final f in _fields) {
          final cm = g.cm(f.key);
          if (cm != null) _ctrls[f.key]!.text = cm.toStringAsFixed(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_someoneElse) {
      FittingSession.instance.useSelf();
      Navigator.pop(context);
      return;
    }
    final values = <String, double>{};
    _ctrls.forEach((key, ctrl) {
      final cm = double.tryParse(ctrl.text.trim());
      if (cm != null && cm > 0) values[key] = cm * 10.0; // cm → mm
    });
    final guest = BodyMeasurements(
      scanId: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      source: 'manual',
      valuesMm: values,
      measuredAt: DateTime.now(),
    );
    FittingSession.instance.useSomeoneElse(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      measurements: guest,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final sheetBg = isDark ? AppColors.charcoal : Colors.white;
    final fill = isDark ? AppColors.darkWarm : const Color(0xFFF3F1F0);

    Widget option(String label, String sub, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.12) : fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? accent : Colors.transparent, width: 1.6),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20, color: selected ? accent : muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: GoogleFonts.outfit(
                            fontSize: 14.5, fontWeight: FontWeight.w700, color: ink)),
                    Text(sub, style: GoogleFonts.outfit(fontSize: 11.5, color: muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: muted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Who's this for?",
                    style: GoogleFonts.rufina(
                        fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 4),
                Text('Size tips are based on this person\'s measurements.',
                    style: GoogleFonts.outfit(fontSize: 12.5, color: muted)),
                const SizedBox(height: 18),
                option('Me', 'Use my saved sizes', !_someoneElse,
                    () => setState(() => _someoneElse = false)),
                const SizedBox(height: 10),
                option('Someone else', 'Enter their sizes', _someoneElse,
                    () => setState(() => _someoneElse = true)),
                if (_someoneElse) ...[
                  const SizedBox(height: 18),
                  _sheetField(_nameCtrl, 'Their name (optional)', ink, muted, fill),
                  const SizedBox(height: 12),
                  Text('Measurements (cm)',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.w700, color: muted)),
                  const SizedBox(height: 8),
                  for (final f in _fields) ...[
                    _sheetField(_ctrls[f.key]!, f.label, ink, muted, fill,
                        number: true),
                    const SizedBox(height: 10),
                  ],
                  Text('Leave blank if unknown — checks use whatever you provide.',
                      style: GoogleFonts.outfit(fontSize: 11, color: muted)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Done',
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, Color ink,
      Color muted, Color fill,
      {bool number = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: GoogleFonts.outfit(color: ink, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: muted, fontSize: 13),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixText: number ? 'cm' : null,
        suffixStyle: GoogleFonts.outfit(color: muted, fontSize: 12),
      ),
    );
  }
}
