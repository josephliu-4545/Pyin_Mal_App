import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/pose_detection_service.dart';
import '../services/tps.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WarpedClothingOverlay
//
// The TPS upgrade over ClothingOverlay. Instead of stretching the garment PNG
// into a rigid rectangle, it lays a fine grid over the image and warps every
// grid point through a thin-plate-spline so the garment's anchor pixels land on
// the live body landmarks. The warped grid is drawn as a textured mesh via
// Canvas.drawVertices, so the garment bends at the shoulders and sleeves and
// follows the body as it turns.
//
// Pipeline each frame:
//   1. Build destination control points from the pose (screen space).
//   2. Smooth them (EMA) to damp detection jitter.
//   3. Build source control points from the garment anchors (image space).
//   4. Solve a TPS from source → destination.
//   5. Sample an N×N grid over the image, warp each point, drawVertices.
//
// Only anchors present in BOTH the garment map and the current pose are used,
// so it degrades gracefully when arms aren't detected (falls back to a
// shoulders+hips warp).
// ─────────────────────────────────────────────────────────────────────────────
class WarpedClothingOverlay extends StatefulWidget {
  /// Latest detected pose. Null / invalid = render nothing.
  final PoseResult? pose;

  /// Transparent garment PNG, e.g. 'assets/clothes/black_tshirt.png'.
  final String assetPath;

  /// Garment anchor points in normalized image space (see ClothingItem.anchors).
  final Map<String, Offset> anchors;

  /// Tint applied to the garment for color variants (transparent = no tint).
  final Color tintColor;

  /// Grid resolution per side. Higher = smoother warp, slightly more cost.
  final int gridResolution;

  const WarpedClothingOverlay({
    super.key,
    required this.pose,
    required this.assetPath,
    required this.anchors,
    this.tintColor = Colors.transparent,
    this.gridResolution = 16,
  });

  @override
  State<WarpedClothingOverlay> createState() => _WarpedClothingOverlayState();
}

class _WarpedClothingOverlayState extends State<WarpedClothingOverlay> {
  // Decoded garment images are cached across instances — decoding is expensive
  // and the same few garments are reused constantly.
  static final Map<String, ui.Image> _imageCache = {};

  ui.Image? _image;

  // Smoothed destination control points (EMA), keyed by anchor name.
  final Map<String, Offset> _smoothed = {};
  static const double _alpha = 0.30; // new frame weight; lower = steadier

  @override
  void initState() {
    super.initState();
    _loadImage(widget.assetPath);
  }

  @override
  void didUpdateWidget(covariant WarpedClothingOverlay old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath) {
      _image = null;
      _smoothed.clear();
      _loadImage(widget.assetPath);
    }
  }

  Future<void> _loadImage(String path) async {
    final cached = _imageCache[path];
    if (cached != null) {
      if (mounted) setState(() => _image = cached);
      return;
    }
    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _imageCache[path] = frame.image;
      if (mounted && widget.assetPath == path) {
        setState(() => _image = frame.image);
      }
    } catch (e) {
      debugPrint('[WarpedClothing] could not load $path: $e');
      // Leave _image null → overlay renders nothing (no crash).
    }
  }

  /// Destination control points in widget/screen space, or null if the pose
  /// can't support a warp. Garment "left" is matched to whichever landmark is
  /// on the left of the screen, so it works for both front and rear cameras.
  Map<String, Offset>? _destPoints(BoxConstraints c) {
    final pose = widget.pose;
    if (pose == null || !pose.isValid) return null;

    final w = c.maxWidth;
    final h = c.maxHeight;
    Offset px(ARLandmark l) => Offset(l.x * w, l.y * h);

    final s1 = px(pose.leftShoulder!);
    final s2 = px(pose.rightShoulder!);
    final h1 = px(pose.leftHip!);
    final h2 = px(pose.rightHip!);

    final shoulderL = s1.dx <= s2.dx ? s1 : s2;
    final shoulderR = s1.dx <= s2.dx ? s2 : s1;
    final hipL = h1.dx <= h2.dx ? h1 : h2;
    final hipR = h1.dx <= h2.dx ? h2 : h1;

    final midShoulder = (shoulderL + shoulderR) / 2;
    // Neck sits above the shoulder line, biased toward the nose when we have it.
    final Offset neck;
    if (pose.nose != null && pose.nose!.likelihood > 0.5) {
      neck = midShoulder + (px(pose.nose!) - midShoulder) * 0.40;
    } else {
      final shoulderSpan = (shoulderR - shoulderL).distance;
      neck = midShoulder - Offset(0, shoulderSpan * 0.25);
    }

    final pts = <String, Offset>{
      'neck': neck,
      'lShoulder': shoulderL,
      'rShoulder': shoulderR,
      'lHip': hipL,
      'rHip': hipR,
    };

    // Elbows are optional — only add them when confidently detected, so a
    // lowered/occluded arm doesn't yank the sleeve to a bad guess.
    final le = pose.leftElbow;
    final re = pose.rightElbow;
    if (le != null && re != null && le.likelihood > 0.5 && re.likelihood > 0.5) {
      final e1 = px(le);
      final e2 = px(re);
      pts['lElbow'] = e1.dx <= e2.dx ? e1 : e2;
      pts['rElbow'] = e1.dx <= e2.dx ? e2 : e1;
    }
    return pts;
  }

  /// EMA-smooths [raw] into [_smoothed] in place and returns the smoothed map.
  Map<String, Offset> _applySmoothing(Map<String, Offset> raw) {
    // Drop any keys no longer present (e.g. elbows just lost) so they don't
    // linger and distort the warp.
    _smoothed.removeWhere((k, _) => !raw.containsKey(k));
    raw.forEach((k, v) {
      final prev = _smoothed[k];
      _smoothed[k] = prev == null ? v : prev * (1 - _alpha) + v * _alpha;
    });
    return _smoothed;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        final dest = _destPoints(constraints);
        if (dest == null) {
          _smoothed.clear();
          return const SizedBox.expand();
        }

        final smoothed = _applySmoothing(dest);

        // Pair each shared anchor: source (image px) → destination (screen px).
        final src = <Offset>[];
        final dst = <Offset>[];
        widget.anchors.forEach((key, normalized) {
          final target = smoothed[key];
          if (target == null) return;
          src.add(Offset(
            normalized.dx * image.width,
            normalized.dy * image.height,
          ));
          dst.add(target);
        });

        // Need at least 3 non-collinear control points for a stable warp.
        if (src.length < 3) return const SizedBox.expand();

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _WarpPainter(
            image: image,
            src: src,
            dst: dst,
            tint: widget.tintColor,
            grid: widget.gridResolution,
          ),
        );
      },
    );
  }
}

class _WarpPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> src;
  final List<Offset> dst;
  final Color tint;
  final int grid;

  _WarpPainter({
    required this.image,
    required this.src,
    required this.dst,
    required this.tint,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tps = ThinPlateSpline(src, dst);

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final n = grid;

    // Build the mesh: texture coords sample the image on a regular grid,
    // positions are those same points pushed through the spline.
    final positions = <Offset>[];
    final texCoords = <Offset>[];
    for (int j = 0; j <= n; j++) {
      for (int i = 0; i <= n; i++) {
        final uv = Offset(imgW * i / n, imgH * j / n);
        texCoords.add(uv);
        positions.add(tps.transform(uv));
      }
    }

    // Two triangles per grid cell.
    final indices = <int>[];
    int idx(int i, int j) => j * (n + 1) + i;
    for (int j = 0; j < n; j++) {
      for (int i = 0; i < n; i++) {
        final a = idx(i, j);
        final b = idx(i + 1, j);
        final c = idx(i, j + 1);
        final d = idx(i + 1, j + 1);
        indices..addAll([a, b, c])..addAll([b, d, c]);
      }
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texCoords,
      indices: indices,
    );

    // Identity ImageShader → texture coordinates are read as raw image pixels.
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );

    if (tint != Colors.transparent) {
      paint.colorFilter =
          ColorFilter.mode(tint.withOpacity(0.55), BlendMode.srcATop);
    }

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  @override
  bool shouldRepaint(_WarpPainter old) =>
      old.image != image ||
      old.tint != tint ||
      old.grid != grid ||
      !_listEq(old.dst, dst);

  static bool _listEq(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
