import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:google_fonts/google_fonts.dart';

import '../main.dart' show AppColors;
import 'generating_silhouettes.dart';

/// Full-screen "please wait" takeover for long-running AI jobs.
///
/// The silhouette is drawn as a few thousand twinkling dots that scatter away
/// from the user's finger and spring back when it lifts — the wait stays a wait,
/// but there is something to fiddle with while it passes.
///
/// Drop it as the last child of a [Stack] and drive it with the screen's
/// existing loading flag:
///
/// ```dart
/// Stack(children: [
///   ...,
///   GeneratingOverlay(
///     visible: _isLoading,
///     silhouette: GeneratingSilhouette.shirt,
///   ),
/// ])
/// ```
class GeneratingOverlay extends StatelessWidget {
  const GeneratingOverlay({
    super.key,
    required this.visible,
    required this.silhouette,
    this.label,
    this.tips,
  });

  /// Whether the job is running. Fades in and out.
  final bool visible;

  /// Shape the particles form.
  final GeneratingSilhouette silhouette;

  /// Defaults to the localized "Generating…".
  final String? label;

  /// Rotating hints under the progress bar. Defaults to the localized set.
  final List<String>? tips;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 260),
        child: visible
            ? _GeneratingBody(
                silhouette: silhouette,
                label: label ?? 'generating.label'.tr(),
                tips: tips ?? defaultTips(),
              )
            : const SizedBox.expand(),
      ),
    );
  }

  /// The localized rotating hints, in order.
  static List<String> defaultTips() => <String>[
        for (var i = 1; i <= 6; i++) 'generating.tip_$i'.tr(),
      ];
}

class _GeneratingBody extends StatefulWidget {
  const _GeneratingBody({
    required this.silhouette,
    required this.label,
    required this.tips,
  });

  final GeneratingSilhouette silhouette;
  final String label;
  final List<String> tips;

  @override
  State<_GeneratingBody> createState() => _GeneratingBodyState();
}

class _GeneratingBodyState extends State<_GeneratingBody> {
  static const _tipInterval = Duration(seconds: 4);

  int _tipIndex = 0;
  late final Stopwatch _elapsed = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _scheduleTip();
  }

  void _scheduleTip() {
    Future<void>.delayed(_tipInterval, () {
      if (!mounted || widget.tips.isEmpty) return;
      setState(() => _tipIndex = (_tipIndex + 1) % widget.tips.length);
      _scheduleTip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tips.isEmpty ? '' : widget.tips[_tipIndex];

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [Color(0xFF2A2725), Color(0xFF121010)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ParticleField(silhouette: widget.silhouette),
            // Chrome sits above the dots but must not eat their touches.
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CreepingBar(elapsed: _elapsed),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          tip,
                          key: ValueKey<int>(_tipIndex),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indeterminate bar that eases toward — but never reaches — full.
///
/// None of the AI providers we call report real progress, so a bar that
/// asymptotes is honest about that: it always advances, never claims to finish.
class _CreepingBar extends StatefulWidget {
  const _CreepingBar({required this.elapsed});

  final Stopwatch elapsed;

  @override
  State<_CreepingBar> createState() => _CreepingBarState();
}

class _CreepingBarState extends State<_CreepingBar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}))..start();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.elapsed.elapsedMilliseconds / 1000;
    final progress = 0.94 * (1 - math.exp(-t / 11));

    return SizedBox(
      width: 170,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.13),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

// ── Particle field ───────────────────────────────────────────────────────────

class _Particle {
  _Particle({
    required this.homeX,
    required this.homeY,
    required this.brightness,
    required this.edge,
    required this.phase,
    required this.twinkleSpeed,
    required this.weight,
  })  : x = homeX,
        y = homeY;

  /// Slot in the silhouette. Particles always spring back to this.
  final double homeX;
  final double homeY;

  /// Base opacity before twinkling. Rim dots sit brighter so the outline reads.
  final double brightness;
  final bool edge;
  final double phase;
  final double twinkleSpeed;

  /// How strongly this dot answers to a finger, 0.3–1.0. Uniform repulsion
  /// punches a clean hole; varying it leaves heavier dots behind inside the
  /// pocket, so the cloud separates without ever fully clearing.
  final double weight;

  double x;
  double y;
  double vx = 0;
  double vy = 0;
}

class _ParticleField extends StatefulWidget {
  const _ParticleField({required this.silhouette});

  final GeneratingSilhouette silhouette;

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  // Physics, tuned so a held finger opens a visible pocket that never empties.
  static const _repelRadius = 110.0;
  static const _repelAccel = 7.0;
  static const _spring = 0.055;
  static const _damping = 0.86;

  static const _targetCount = 3200;

  late final Ticker _ticker;
  final _rnd = math.Random(7);

  List<_Particle> _particles = const [];
  Size _builtFor = Size.zero;

  Offset? _touch;
  Offset? _releaseAt;
  double _releaseAge = 0;

  double _time = 0;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration now) {
    final rawDt = (now - _lastTick).inMicroseconds / 1e6;
    _lastTick = now;
    // First frame and any post-jank catch-up must not blow the integration up.
    final dt = rawDt.isFinite ? rawDt.clamp(0.0, 0.05) : 0.0;
    final step = (dt * 60).clamp(0.0, 2.0);

    _time += dt;
    if (_releaseAt != null) {
      _releaseAge += dt;
      if (_releaseAge > 0.6) _releaseAt = null;
    }

    final touch = _touch;
    // Constant for the frame — hoisted out of the per-particle loop.
    final damp = math.pow(_damping, step).toDouble();

    for (final p in _particles) {
      if (touch != null) {
        final dx = p.x - touch.dx;
        final dy = p.y - touch.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < _repelRadius * _repelRadius && d2 > 0.01) {
          final d = math.sqrt(d2);
          // Squared falloff: dots under the fingertip scatter widest, dots at
          // the edge of reach barely stir.
          final fall = 1 - d / _repelRadius;
          final f = _repelAccel * p.weight * fall * fall * step;
          p.vx += dx / d * f;
          p.vy += dy / d * f;
        }
      }

      // Spring home. Balanced against the push above, this settles at a partial
      // displacement — the cloud opens up without ever evacuating.
      p.vx += (p.homeX - p.x) * _spring * step;
      p.vy += (p.homeY - p.y) * _spring * step;

      p.vx *= damp;
      p.vy *= damp;

      p.x += p.vx * step;
      p.y += p.vy * step;
    }

    setState(() {});
  }

  void _rebuild(Size size) {
    if (size == _builtFor || size.isEmpty) return;
    _builtFor = size;

    final path = GeneratingSilhouettes.build(widget.silhouette, size);
    final bounds = path.getBounds();
    if (bounds.isEmpty) return;

    const probe = 3.0;
    final out = <_Particle>[];
    var guard = 0;
    final maxTries = _targetCount * 60;

    while (out.length < _targetCount && guard < maxTries) {
      guard++;
      final x = bounds.left + _rnd.nextDouble() * bounds.width;
      final y = bounds.top + _rnd.nextDouble() * bounds.height;
      if (!path.contains(Offset(x, y))) continue;

      final edge = !path.contains(Offset(x - probe, y)) ||
          !path.contains(Offset(x + probe, y)) ||
          !path.contains(Offset(x, y - probe)) ||
          !path.contains(Offset(x, y + probe));

      // Thin the interior slightly so the rim reads denser and the shape stays
      // legible, without hollowing the fill out.
      if (!edge && _rnd.nextDouble() > 0.80) continue;

      out.add(_Particle(
        homeX: x,
        homeY: y,
        brightness: edge
            ? 0.88 + _rnd.nextDouble() * 0.12
            : 0.48 + _rnd.nextDouble() * 0.45,
        edge: edge,
        phase: _rnd.nextDouble() * math.pi * 2,
        twinkleSpeed: 1.4 + _rnd.nextDouble() * 2.6,
        weight: 0.30 + _rnd.nextDouble() * 0.70,
      ));
    }

    _particles = out;
  }

  void _setTouch(Offset? p) {
    if (p == null && _touch != null) {
      _releaseAt = _touch;
      _releaseAge = 0;
    }
    _touch = p;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _rebuild(size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _setTouch(d.localPosition),
          onTapUp: (_) => _setTouch(null),
          onTapCancel: () => _setTouch(null),
          onPanDown: (d) => _setTouch(d.localPosition),
          onPanUpdate: (d) => _setTouch(d.localPosition),
          onPanEnd: (_) => _setTouch(null),
          onPanCancel: () => _setTouch(null),
          child: CustomPaint(
            size: size,
            painter: _FieldPainter(
              particles: _particles,
              time: _time,
              releaseAt: _releaseAt,
              releaseAge: _releaseAge,
            ),
          ),
        );
      },
    );
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter({
    required this.particles,
    required this.time,
    required this.releaseAt,
    required this.releaseAge,
  });

  final List<_Particle> particles;
  final double time;
  final Offset? releaseAt;
  final double releaseAge;

  /// Dots are batched into opacity tiers so the whole field costs a handful of
  /// [Canvas.drawRawPoints] calls instead of thousands of [Canvas.drawCircle]s.
  static const _tiers = 6;
  static const _releaseRadius = 130.0;

  // Faintly warm rather than pure white, to sit with the app's gold accent.
  static final Color _dotColor = Color.lerp(
    Colors.white,
    AppColors.gold,
    0.15,
  )!;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    // [tier][edge ? 1 : 0]
    final buckets = List.generate(
      _tiers,
      (_) => <List<double>>[<double>[], <double>[]],
      growable: false,
    );

    final release = releaseAt;
    final bloom = release == null
        ? 0.0
        // Brief bloom where the finger lifted, decaying over ~0.6s.
        : 0.5 * math.exp(-releaseAge / 0.22);

    for (final p in particles) {
      var alpha = p.brightness *
          (0.45 +
              0.55 * (0.5 + 0.5 * math.sin(p.phase + time * p.twinkleSpeed)));

      if (bloom > 0) {
        final d = (Offset(p.x, p.y) - release!).distance;
        if (d < _releaseRadius) {
          alpha += bloom * (1 - d / _releaseRadius);
        }
      }

      alpha = alpha.clamp(0.0, 1.0);
      final tier = (alpha * (_tiers - 1)).round().clamp(0, _tiers - 1);
      buckets[tier][p.edge ? 1 : 0]
        ..add(p.x)
        ..add(p.y);
    }

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    for (var tier = 0; tier < _tiers; tier++) {
      final alpha = (tier + 1) / _tiers;
      for (var kind = 0; kind < 2; kind++) {
        final coords = buckets[tier][kind];
        if (coords.isEmpty) continue;
        paint
          ..color = _dotColor.withValues(alpha: alpha)
          ..strokeWidth = kind == 1 ? 2.2 : 1.6;
        canvas.drawRawPoints(
          ui.PointMode.points,
          Float32List.fromList(coords),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) => true;
}
