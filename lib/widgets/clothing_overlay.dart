import 'package:flutter/material.dart';
import '../services/pose_detection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ClothingOverlay
//
// Renders a transparent PNG clothing item overlaid on the camera preview,
// positioned and sized using pose landmarks.
//
// Landmark coordinate math:
//   All landmark x/y values are normalized [0.0, 1.0] relative to the
//   preview widget's Width × Height.
//
//   clothCenterX   = average(leftShoulder.x, rightShoulder.x) * previewWidth
//   clothTopY      = average(leftShoulder.y, rightShoulder.y) * previewHeight
//                    - neckOffset     ← shifts up so collar aligns with shoulders
//   shoulderPx     = |rightShoulder.x - leftShoulder.x| * previewWidth
//   clothWidth     = shoulderPx * widthMultiplier   (default 1.8)
//   hipCenterY     = average(leftHip.y, rightHip.y) * previewHeight
//   clothHeight    = (hipCenterY - clothTopY) * heightMultiplier  (default 1.4)
//   clothLeft      = clothCenterX - clothWidth / 2
//
// Smoothing (exponential moving average):
//   smoothed = previous * 0.75 + detected * 0.25
//   This damps jitter from frame-to-frame detection noise.
// ─────────────────────────────────────────────────────────────────────────────
class ClothingOverlay extends StatefulWidget {
  /// The detected pose from the current frame. Null = no person detected.
  final PoseResult? pose;

  /// Asset path of the clothing PNG (e.g. 'assets/clothes/black_tshirt.png').
  final String assetPath;

  /// Tint color applied to the clothing image (for color variants).
  final Color tintColor;

  /// Scale factor for width relative to shoulder distance (default 1.8).
  final double widthMultiplier;

  /// Scale factor for height relative to shoulder-to-hip distance (default 1.4).
  final double heightMultiplier;

  /// Upward offset in pixels to raise the top of the garment above the
  /// shoulder line so the collar sits at the right place.
  final double neckOffsetFraction; // fraction of clothHeight to shift up

  const ClothingOverlay({
    super.key,
    required this.pose,
    required this.assetPath,
    this.tintColor = Colors.transparent,
    this.widthMultiplier = 1.8,
    this.heightMultiplier = 1.4,
    this.neckOffsetFraction = 0.12,
  });

  @override
  State<ClothingOverlay> createState() => _ClothingOverlayState();
}

class _ClothingOverlayState extends State<ClothingOverlay> {
  // ── Smoothed layout values (exponential moving average) ─────────────────

  double? _smoothLeft;
  double? _smoothTop;
  double? _smoothWidth;
  double? _smoothHeight;

  // Smoothing factor α: 0 = never update, 1 = no smoothing
  // 0.25 means new detection contributes 25%, old value 75% → stable overlay.
  static const double _alpha = 0.25;

  /// Apply exponential moving average.
  /// Returns [detected] if no previous value exists.
  double _smooth(double? previous, double detected) {
    if (previous == null) return detected;
    return previous * (1.0 - _alpha) + detected * _alpha;
  }

  // ── Layout computation ───────────────────────────────────────────────────

  /// Computes the Rect for the clothing overlay in widget-local coordinates.
  /// Returns null if the pose is invalid or missing key landmarks.
  Rect? _computeRect(BoxConstraints constraints) {
    final pose = widget.pose;
    if (pose == null || !pose.isValid) {
      // Gradually fade smoothed values to zero so clothing disappears cleanly
      if (_smoothLeft != null) {
        setState(() {
          _smoothLeft = null;
          _smoothTop = null;
          _smoothWidth = null;
          _smoothHeight = null;
        });
      }
      return null;
    }

    final ls = pose.leftShoulder!;
    final rs = pose.rightShoulder!;
    final lh = pose.leftHip!;
    final rh = pose.rightHip!;

    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    // ── Raw pixel positions ─────────────────────────────────────────────
    final lsX = ls.x * w;
    final rsX = rs.x * w;
    final lsY = ls.y * h;
    final rsY = rs.y * h;
    final lhY = lh.y * h;
    final rhY = rh.y * h;

    // Shoulder center and hip center
    final shoulderCenterX = (lsX + rsX) / 2.0;
    final shoulderCenterY = (lsY + rsY) / 2.0;
    final hipCenterY = (lhY + rhY) / 2.0;

    // Shoulder pixel distance → clothing width
    final shoulderDist = (rsX - lsX).abs();
    final rawWidth = shoulderDist * widget.widthMultiplier;

    // Shoulder-to-hip distance → clothing height
    final rawHeight =
        (hipCenterY - shoulderCenterY).abs() * widget.heightMultiplier;

    // Top-left corner: center X minus half-width, Y minus neck offset
    final neckOffset = rawHeight * widget.neckOffsetFraction;
    final rawLeft = shoulderCenterX - rawWidth / 2.0;
    final rawTop = shoulderCenterY - neckOffset;

    // ── Apply exponential moving average ────────────────────────────────
    _smoothLeft = _smooth(_smoothLeft, rawLeft);
    _smoothTop = _smooth(_smoothTop, rawTop);
    _smoothWidth = _smooth(_smoothWidth, rawWidth);
    _smoothHeight = _smooth(_smoothHeight, rawHeight);

    return Rect.fromLTWH(
      _smoothLeft!,
      _smoothTop!,
      _smoothWidth!,
      _smoothHeight!,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rect = _computeRect(constraints);

        // No valid pose → render nothing (invisible placeholder)
        if (rect == null) return const SizedBox.expand();

        return Stack(
          children: [
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: _buildClothingImage(rect),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClothingImage(Rect rect) {
    // Attempt to load the PNG asset. Falls back to a CustomPaint silhouette
    // when the PNG file is not yet in the assets folder (during development).
    return ColorFiltered(
      // Apply tint only if a real color (not transparent) is requested
      colorFilter: widget.tintColor != Colors.transparent
          ? ColorFilter.mode(
              widget.tintColor.withOpacity(0.55), BlendMode.srcATop)
          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
      child: Image.asset(
        widget.assetPath,
        fit: BoxFit.fill, // stretch to exactly match computed rect
        errorBuilder: (_, __, ___) =>
            // ── Fallback: drawn silhouette when PNG is missing ──────────
            CustomPaint(
              painter: _ClothingSilhouettePainter(assetPath: widget.assetPath),
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClothingSilhouettePainter
//
// Draws a minimal flat clothing silhouette when the PNG asset is not yet
// available. This lets you develop the AR layout without real images.
//
// It differentiates between a t-shirt, hoodie, and jacket by checking
// the assetPath string.
// ─────────────────────────────────────────────────────────────────────────────
class _ClothingSilhouettePainter extends CustomPainter {
  final String assetPath;
  const _ClothingSilhouettePainter({required this.assetPath});

  @override
  void paint(Canvas canvas, Size size) {
    final Color fill;
    final Color stroke;

    if (assetPath.contains('black')) {
      fill = Colors.black.withOpacity(0.75);
      stroke = Colors.white.withOpacity(0.3);
    } else if (assetPath.contains('white')) {
      fill = Colors.white.withOpacity(0.80);
      stroke = Colors.grey.withOpacity(0.4);
    } else {
      // Blue jacket
      fill = const Color(0xFF1565C0).withOpacity(0.80);
      stroke = Colors.white.withOpacity(0.3);
    }

    final paint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Simple T-shirt / top silhouette path
    // Collar notch at top-center, shoulder slopes, side seams, hem
    final path = Path()
      ..moveTo(w * 0.30, 0) // left collar point
      ..lineTo(w * 0.10, h * 0.15) // left armhole top
      ..lineTo(0, h * 0.20) // left sleeve-hem
      ..lineTo(w * 0.10, h * 0.40) // left underarm
      ..lineTo(w * 0.12, h) // left hem
      ..lineTo(w * 0.88, h) // right hem
      ..lineTo(w * 0.90, h * 0.40) // right underarm
      ..lineTo(w, h * 0.20) // right sleeve-hem
      ..lineTo(w * 0.90, h * 0.15) // right armhole top
      ..lineTo(w * 0.70, 0) // right collar point
      // Collar U-curve
      ..quadraticBezierTo(w * 0.50, h * 0.10, w * 0.30, 0)
      ..close();

    // For hoodie — add hood
    if (assetPath.contains('hoodie')) {
      final hoodPath = Path()
        ..addOval(Rect.fromCenter(
            center: Offset(w * 0.50, -h * 0.08),
            width: w * 0.55,
            height: h * 0.28));
      canvas.drawPath(hoodPath, paint..color = fill.withOpacity(0.65));
    }

    // Draw body
    canvas.drawPath(path, paint..color = fill);
    canvas.drawPath(path, borderPaint);

    // Label so developer knows it's a placeholder
    final tp = TextPainter(
      text: TextSpan(
        text: '[ PNG missing ]',
        style: TextStyle(
          color: stroke,
          fontSize: w * 0.07,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w);
    tp.paint(canvas, Offset((w - tp.width) / 2, h * 0.50));
  }

  @override
  bool shouldRepaint(_ClothingSilhouettePainter old) =>
      old.assetPath != assetPath;
}
