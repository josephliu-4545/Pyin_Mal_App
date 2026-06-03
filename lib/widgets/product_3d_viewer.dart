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

    final cx = size.width / 2;  // 80
    final cy = size.height / 2; // 22

    const circleR   = 19.0; // half of center circle widget
    const arcW      = 50.0; // horizontal reach of each arc
    const arcH      = 13.0; // vertical height of the upward bow
    const headLen   = 7.0;
    const headSpread = 0.45; // radians — half-angle of arrowhead V

    // ── LEFT ARC ──────────────────────────────────────────────────────────────
    // Rect whose right edge = circle edge, left edge = arrow tip.
    // drawArc at angle=0 starts at the RIGHTMOST point = circle edge.
    // sweepAngle = -π  → counterclockwise 180° on screen = right→UP→left ✓
    final leftRect = Rect.fromLTRB(
      cx - circleR - arcW, // left  (arrow tip side)
      cy - arcH,           // top   (peak of upward bow)
      cx - circleR,        // right (circle edge)
      cy + arcH,           // bottom
    );
    canvas.drawArc(leftRect, 0, -math.pi, false, paint);

    // Arrowhead at the left tip — V pointing LEFT
    final lt = Offset(leftRect.left, cy);
    canvas.drawPath(
      Path()
        ..moveTo(lt.dx + headLen * math.cos(headSpread),
                 lt.dy - headLen * math.sin(headSpread))
        ..lineTo(lt.dx, lt.dy)
        ..lineTo(lt.dx + headLen * math.cos(headSpread),
                 lt.dy + headLen * math.sin(headSpread)),
      paint,
    );

    // ── RIGHT ARC ─────────────────────────────────────────────────────────────
    // Rect whose left edge = circle edge, right edge = arrow tip.
    // drawArc at angle=π starts at the LEFTMOST point = circle edge.
    // sweepAngle = +π  → clockwise 180° on screen = left→UP→right ✓
    final rightRect = Rect.fromLTRB(
      cx + circleR,         // left  (circle edge)
      cy - arcH,            // top   (peak of upward bow)
      cx + circleR + arcW,  // right (arrow tip side)
      cy + arcH,            // bottom
    );
    canvas.drawArc(rightRect, math.pi, math.pi, false, paint);

    // Arrowhead at the right tip — V pointing RIGHT
    final rt = Offset(rightRect.right, cy);
    canvas.drawPath(
      Path()
        ..moveTo(rt.dx - headLen * math.cos(headSpread),
                 rt.dy - headLen * math.sin(headSpread))
        ..lineTo(rt.dx, rt.dy)
        ..lineTo(rt.dx - headLen * math.cos(headSpread),
                 rt.dy + headLen * math.sin(headSpread)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
