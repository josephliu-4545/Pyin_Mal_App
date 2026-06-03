import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/model_3d_service.dart';
import '../main.dart';

/// Widget to display 3D product model with rotation and zoom
class Product3DViewer extends StatefulWidget {
  final double height;
  final bool isDark;

  const Product3DViewer({
    super.key,
    this.height = 400,
    required this.isDark,
  });

  @override
  State<Product3DViewer> createState() => _Product3DViewerState();
}

class _Product3DViewerState extends State<Product3DViewer> {
  String? modelPath;
  bool isLoading = true;
  String? errorMessage;
  double rotation = 0;
  double zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      print('🎨 Initializing 3D model...');
      final path = await Model3DService.generateHoodie3DModel();

      if (mounted) {
        setState(() {
          modelPath = path;
          isLoading = false;
          errorMessage = null;
        });
        print('✅ 3D model ready: $path');
      }
    } catch (e) {
      print('❌ Error initializing model: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    // Show 3D viewer if model loaded successfully
    if (modelPath != null && modelPath!.isNotEmpty) {
      return _build3DViewer();
    }

    // Show fallback/placeholder (not an error)
    return _buildPlaceholder();
  }

  Widget _buildLoadingState() {
    return Container(
      color: widget.isDark ? AppColors.darkWarm : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                widget.isDark ? AppColors.gold : AppColors.burgundy,
              ),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Generating 3D Model...',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: widget.isDark ? AppColors.darkWarm : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.view_in_ar_outlined,
              color: widget.isDark ? Colors.white54 : Colors.grey.withOpacity(0.6),
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading 3D Model...',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your 3D product viewer is being prepared',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: widget.isDark ? Colors.white60 : Colors.grey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                widget.isDark ? AppColors.gold : AppColors.burgundy,
              ),
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DViewer() {
    if (modelPath == null || modelPath!.isEmpty) {
      return _buildPlaceholder();
    }

    return Stack(
      children: [
        // 3D Model Viewer using ModelViewerPlus
        Container(
          color: widget.isDark ? AppColors.darkWarm : Colors.white,
          child: ModelViewer(
            src: modelPath!,
            alt: '3D Product Model',
            autoRotate: false,
            cameraControls: true,
            backgroundColor: Color.lerp(
              widget.isDark ? AppColors.darkWarm : Colors.white,
              Colors.transparent,
              0.1,
            )!,
          ),
        ),

        // Rotation handle — circle + curved arcs with arrowheads
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: const Center(
            child: _RotationHandle(),
          ),
        ),
      ],
    );
  }
}

// ── Rotation handle: circle with ↔ icon + curved arcs + arrowheads ──────────
class _RotationHandle extends StatelessWidget {
  const _RotationHandle();

  @override
  Widget build(BuildContext context) {
    // Total canvas: arcs spread 80px each side of the 36px circle
    return SizedBox(
      width: 160,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Curved arcs painted behind the circle
          CustomPaint(
            size: const Size(160, 44),
            painter: _ArcsPainter(),
          ),
          // White circle with shadow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;   // 80
    final cy = size.height / 2;  // 22

    const circleR = 19.0; // half of circle widget + small gap
    const arcW    = 50.0; // horizontal reach from circle edge to arrow tip
    const arcH    = 14.0; // how high the arc bows UPWARD above cy

    // Quadratic bezier: single control point pulled straight UP at midpoint
    // → creates a clean symmetric arch bowing upward

    // ── Left arc ─────────────────────────────────────────────────────────────
    final leftStart = Offset(cx - circleR, cy);
    final leftEnd   = Offset(cx - circleR - arcW, cy);
    final leftCtrl  = Offset((leftStart.dx + leftEnd.dx) / 2, cy - arcH);

    final leftPath = Path()
      ..moveTo(leftStart.dx, leftStart.dy)
      ..quadraticBezierTo(leftCtrl.dx, leftCtrl.dy, leftEnd.dx, leftEnd.dy);
    canvas.drawPath(leftPath, paint);

    // Arrowhead at the left tip — pointing left, angled to match arc arrival
    _drawHead(canvas, paint, tip: leftEnd, towardX: leftCtrl.dx, towardY: leftCtrl.dy);

    // ── Right arc ────────────────────────────────────────────────────────────
    final rightStart = Offset(cx + circleR, cy);
    final rightEnd   = Offset(cx + circleR + arcW, cy);
    final rightCtrl  = Offset((rightStart.dx + rightEnd.dx) / 2, cy - arcH);

    final rightPath = Path()
      ..moveTo(rightStart.dx, rightStart.dy)
      ..quadraticBezierTo(rightCtrl.dx, rightCtrl.dy, rightEnd.dx, rightEnd.dy);
    canvas.drawPath(rightPath, paint);

    // Arrowhead at the right tip
    _drawHead(canvas, paint, tip: rightEnd, towardX: rightCtrl.dx, towardY: rightCtrl.dy);
  }

  /// Draws a V-shaped arrowhead at [tip], with the opening facing [toward].
  void _drawHead(Canvas canvas, Paint paint,
      {required Offset tip, required double towardX, required double towardY}) {
    // Direction vector from tip back toward the arc (so we know arrival angle)
    final dx = towardX - tip.dx;
    final dy = towardY - tip.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final ux = dx / len; // unit vector
    final uy = dy / len;

    const headLen = 7.0;
    const spread  = 0.38; // radians for half-angle of arrowhead

    // Two arms of the V
    final arm1 = Offset(
      tip.dx + headLen * (ux * math.cos(spread) - uy * math.sin(spread)),
      tip.dy + headLen * (ux * math.sin(spread) + uy * math.cos(spread)),
    );
    final arm2 = Offset(
      tip.dx + headLen * (ux * math.cos(spread) + uy * math.sin(spread)),
      tip.dy + headLen * (-ux * math.sin(spread) + uy * math.cos(spread)),
    );

    final path = Path()
      ..moveTo(arm1.dx, arm1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(arm2.dx, arm2.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
