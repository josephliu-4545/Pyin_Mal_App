import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';

/// One step of the guided tour. It points at a real on-screen control ([key])
/// and knows how to reach the screen that control lives on.
class GuideStepTarget {
  final GlobalKey? key; // the real widget to spotlight (null → centered card)
  final String title;
  final String body;
  final String where;
  final String? tip;
  final Color color;

  /// Scene grouping so we only navigate when the screen actually changes.
  final String sceneId;

  /// If set, switch the bottom-nav to this tab before showing the step.
  final int? tabIndex;

  /// If set, push this screen before showing the step (popped when leaving).
  final WidgetBuilder? pushBuilder;

  /// If true, open the Home tab's custom menu overlay before locating [key]
  /// — needed for targets (like the language switcher) that only exist in
  /// the DOM while that overlay is open.
  final bool openMenu;

  const GuideStepTarget({
    required this.title,
    required this.body,
    required this.where,
    required this.color,
    required this.sceneId,
    this.tip,
    this.key,
    this.tabIndex,
    this.pushBuilder,
    this.openMenu = false,
  });
}

/// Drives the tour: handles scene navigation and the spotlight overlay.
class GuideController {
  static OverlayEntry? _entry;
  static NavigatorState? _navigator;
  static List<GuideStepTarget> _steps = const [];
  static int _i = 0;
  static String? _scene;
  static Route<dynamic>? _pushed;
  static VoidCallback? _onDone;
  static bool _running = false;
  static bool _menuOpen = false;

  static bool get isRunning => _running;

  static Future<void> start(
    BuildContext context,
    List<GuideStepTarget> steps, {
    VoidCallback? onDone,
  }) =>
      startNav(Navigator.of(context, rootNavigator: true), steps,
          onDone: onDone);

  /// Start using a captured NavigatorState — safe to call after popping the
  /// screen the tour was launched from.
  static Future<void> startNav(
    NavigatorState navigator,
    List<GuideStepTarget> steps, {
    VoidCallback? onDone,
  }) async {
    if (_running || steps.isEmpty) return;
    _running = true;
    _steps = steps;
    _i = 0;
    _scene = null;
    _pushed = null;
    _menuOpen = false;
    _onDone = onDone;
    _navigator = navigator;
    // Let any pop settle before the first step navigates.
    await Future.delayed(const Duration(milliseconds: 220));
    await _show();
  }

  static Future<void> _enterScene(GuideStepTarget step) async {
    // Close the custom menu overlay before moving on, unless this step also
    // wants it open (avoids a pointless close-then-reopen flicker).
    if (_menuOpen && !step.openMenu) {
      GuideNav.closeMenu?.call();
      GuideNav.closeMenu = null;
      _menuOpen = false;
    }

    if (step.sceneId == _scene) {
      if (step.openMenu && !_menuOpen) {
        GuideNav.openMenu?.call();
        _menuOpen = true;
        await Future.delayed(const Duration(milliseconds: 380));
      }
      return;
    }
    // Leave any pushed scene first.
    if (_pushed != null) {
      _navigator!.removeRoute(_pushed!);
      _pushed = null;
    }
    if (step.tabIndex != null) {
      GuideNav.switchTab?.call(step.tabIndex!);
      await Future.delayed(const Duration(milliseconds: 280));
    }
    if (step.pushBuilder != null) {
      _pushed = MaterialPageRoute(builder: step.pushBuilder!);
      _navigator!.push(_pushed!);
      await Future.delayed(const Duration(milliseconds: 420));
    }
    if (step.openMenu) {
      GuideNav.openMenu?.call();
      _menuOpen = true;
      await Future.delayed(const Duration(milliseconds: 380));
    }
    _scene = step.sceneId;
  }

  static Future<Rect?> _locate(GlobalKey? key) async {
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    try {
      await Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), alignment: 0.3);
    } catch (_) {}
    await WidgetsBinding.instance.endOfFrame;
    final obj = key.currentContext?.findRenderObject();
    if (obj is! RenderBox || !obj.attached) return null;
    final pos = obj.localToGlobal(Offset.zero);
    return pos & obj.size;
  }

  static Future<void> _show() async {
    final step = _steps[_i];
    await _enterScene(step);
    await Future.delayed(const Duration(milliseconds: 120));
    final rect = await _locate(step.key);

    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => _CoachLayer(
        step: step,
        rect: rect,
        index: _i,
        total: _steps.length,
        onNext: _next,
        onBack: _i > 0 ? _back : null,
        onSkip: _finish,
      ),
    );
    // Re-inserting after any push keeps the overlay on top.
    _navigator!.overlay!.insert(_entry!);
  }

  static Future<void> _next() async {
    if (_i < _steps.length - 1) {
      _i++;
      await _show();
    } else {
      _finish();
    }
  }

  static Future<void> _back() async {
    if (_i > 0) {
      _i--;
      await _show();
    }
  }

  static void _finish() {
    _entry?.remove();
    _entry = null;
    if (_pushed != null) {
      _navigator!.removeRoute(_pushed!);
      _pushed = null;
    }
    if (_menuOpen) {
      GuideNav.closeMenu?.call();
      GuideNav.closeMenu = null;
      _menuOpen = false;
    }
    _running = false;
    final cb = _onDone;
    _onDone = null;
    cb?.call();
  }
}

// ── Overlay UI ────────────────────────────────────────────────────────────────
class _CoachLayer extends StatelessWidget {
  final GuideStepTarget step;
  final Rect? rect;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _CoachLayer({
    required this.step,
    required this.rect,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safe = MediaQuery.of(context).padding;
    final r = rect;
    const gap = 26.0; // space for the arrow between button and tooltip

    // Decide tooltip placement (below the target, unless it's in the lower half).
    bool below = true;
    if (r != null) below = r.center.dy < size.height * 0.55;

    // Tooltip vertical anchoring.
    double? top;
    double? bottom;
    if (r == null) {
      top = size.height * 0.40;
    } else if (below) {
      top = (r.bottom + gap).clamp(0.0, size.height - 160);
    } else {
      bottom = (size.height - (r.top - gap)).clamp(0.0, size.height - 160);
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Dim everything except a hole around the real button + arrow.
          // Absorbs taps so the screen behind isn't pressed during the tour.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: r,
                  color: step.color,
                  below: below,
                  gap: gap,
                ),
              ),
            ),
          ),
          // Tooltip
          Positioned(
            left: 16,
            right: 16,
            top: top != null ? top + (below ? 0 : 0) : null,
            bottom: bottom,
            child: _Tooltip(
              step: step,
              index: index,
              total: total,
              onNext: onNext,
              onBack: onBack,
              onSkip: onSkip,
            ),
          ),
          // If no target was found, show a hint that it's a general tip.
          if (r == null)
            Positioned(
              top: safe.top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text('Tip',
                    style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  final GuideStepTarget step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  const _Tooltip({
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final last = index == total - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: step.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${index + 1} / $total',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: step.color)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                child: Text('Skip',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF888888))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(step.title,
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1210))),
          const SizedBox(height: 5),
          Text(step.body,
              style: GoogleFonts.outfit(
                  fontSize: 13, height: 1.45, color: const Color(0xFF6B5F5A))),
          if (step.tip != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 15, color: step.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(step.tip!,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF1A1210))),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_rounded, size: 14, color: step.color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('Find it: ${step.where}',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: step.color)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (onBack != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      foregroundColor: const Color(0xFF1A1210),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back',
                        style:
                            GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: step.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(last ? 'Got it' : 'Next',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Dims the screen with a rounded hole around the target + a connecting arrow.
class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Color color;
  final bool below;
  final double gap;
  _SpotlightPainter({
    required this.hole,
    required this.color,
    required this.below,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withOpacity(0.80);
    if (hole == null) {
      canvas.drawRect(Offset.zero & size, scrim);
      return;
    }
    final cut = hole!.inflate(8);
    final rrect = RRect.fromRectAndRadius(cut, const Radius.circular(14));
    final full = Path()..addRect(Offset.zero & size);
    final cutPath = Path()..addRRect(rrect);
    canvas.drawPath(
        Path.combine(PathOperation.difference, full, cutPath), scrim);

    // Glow ring around the real button.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Arrow connecting the button to the tooltip.
    final midX = cut.center.dx.clamp(20.0, size.width - 20);
    final arrow = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (below) {
      final y0 = cut.bottom + 4;
      final y1 = cut.bottom + gap - 2;
      canvas.drawLine(Offset(midX, y1), Offset(midX, y0 + 6), arrow);
      _head(canvas, Offset(midX, y0), color, up: true);
    } else {
      final y0 = cut.top - 4;
      final y1 = cut.top - gap + 2;
      canvas.drawLine(Offset(midX, y1), Offset(midX, y0 - 6), arrow);
      _head(canvas, Offset(midX, y0), color, up: false);
    }
  }

  void _head(Canvas canvas, Offset tip, Color c, {required bool up}) {
    final p = Paint()..color = c;
    final dir = up ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 7, tip.dy + 11 * dir)
      ..lineTo(tip.dx + 7, tip.dy + 11 * dir)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.hole != hole || old.color != color || old.below != below;
}
