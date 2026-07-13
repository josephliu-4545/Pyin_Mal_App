import 'package:flutter/material.dart';
import 'package:pyin_mal_app/services/pose_guide_validator.dart';

/// Draws a translucent body-outline guide over the camera preview so the user
/// can just match the shape instead of reading instructions.
///
/// [BodyShot.front] → A-pose figure (arms angled out and down).
/// [BodyShot.side]  → profile figure facing right (arms at the side).
///
/// Turns green once [ok] is true so the user gets instant "you've got it"
/// feedback even from across the room.
class PoseGuidePainter extends CustomPainter {
  final BodyShot shot;
  final bool ok;

  const PoseGuidePainter({required this.shot, required this.ok});

  @override
  void paint(Canvas canvas, Size size) {
    final color = ok ? const Color(0xFF4ADE80) : Colors.white.withOpacity(0.85);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = color;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = color.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Work in a centered 9:16 box; the figure spans ~82% of its height.
    final boxH = size.height * 0.9;
    final boxW = boxH * 9 / 16;
    final cx = size.width / 2;
    final top = (size.height - boxH) / 2;
    final unit = boxH; // vertical reference

    double y(double f) => top + f * unit; // fraction of figure height → dy

    final path =
        shot == BodyShot.front ? _frontPath(cx, y, boxW) : _sidePath(cx, y, boxW);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);

    // Feet line + head circle emphasis.
    final headR = boxW * 0.11;
    final headC = Offset(shot == BodyShot.front ? cx : cx - boxW * 0.04, y(0.09));
    canvas.drawCircle(headC, headR, glow);
    canvas.drawCircle(headC, headR, stroke);
  }

  Path _frontPath(double cx, double Function(double) y, double boxW) {
    final p = Path();
    final shW = boxW * 0.30; // half shoulder width
    final hipW = boxW * 0.22; // half hip width
    final footW = boxW * 0.16;

    // Neck → shoulders
    p.moveTo(cx, y(0.17));
    // Left side down: shoulder → A-pose hand → back up handled as outline.
    p.lineTo(cx - shW, y(0.24)); // left shoulder
    p.lineTo(cx - shW - boxW * 0.14, y(0.52)); // left hand (arm out & down)
    p.moveTo(cx - shW, y(0.24));
    p.lineTo(cx - hipW, y(0.55)); // left waist/hip
    p.lineTo(cx - footW, y(0.97)); // left foot
    // Right side (mirror)
    p.moveTo(cx, y(0.17));
    p.lineTo(cx + shW, y(0.24));
    p.lineTo(cx + shW + boxW * 0.14, y(0.52));
    p.moveTo(cx + shW, y(0.24));
    p.lineTo(cx + hipW, y(0.55));
    p.lineTo(cx + footW, y(0.97));
    // Hip line + inseam hint
    p.moveTo(cx - hipW, y(0.55));
    p.lineTo(cx + hipW, y(0.55));
    p.moveTo(cx, y(0.55));
    p.lineTo(cx, y(0.97));
    return p;
  }

  Path _sidePath(double cx, double Function(double) y, double boxW) {
    // Profile facing right. Slight offsets sketch a side body.
    final p = Path();
    final backX = cx - boxW * 0.12;
    final frontX = cx + boxW * 0.14;
    // Back line: neck → back → hip → leg
    p.moveTo(cx - boxW * 0.02, y(0.17));
    p.lineTo(backX, y(0.30));
    p.lineTo(backX + boxW * 0.02, y(0.55)); // lower back
    p.lineTo(cx - boxW * 0.10, y(0.97)); // heel
    // Front line: chest → belly → front leg
    p.moveTo(cx + boxW * 0.04, y(0.17));
    p.lineTo(frontX, y(0.34)); // chest
    p.lineTo(frontX - boxW * 0.02, y(0.55)); // belly
    p.lineTo(cx + boxW * 0.02, y(0.97)); // toes
    // Arm hanging at the side
    p.moveTo(cx + boxW * 0.02, y(0.28));
    p.lineTo(cx + boxW * 0.06, y(0.55)); // hand at hip level
    return p;
  }

  @override
  bool shouldRepaint(covariant PoseGuidePainter old) =>
      old.ok != ok || old.shot != shot;
}
