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
    return SizedBox(
      width: 170,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Curved arcs painted behind the circle
          CustomPaint(
            size: const Size(170, 52),
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
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width  / 2; // 85
    final cy = size.height / 2; // 26

    const circleR = 19.0; // half of center circle widget
    const arcW    = 48.0; // horizontal reach from circle edge to arrow tip
    const arcH    = 20.0; // how far the arc bows UPWARD (larger = more bow)

    // In Flutter's canvas: y increases downward.
    // drawArc Rect top = cy - arcH  (ABOVE center = visually UP)
    //                bottom = cy + arcH  (below center)
    //
    // LEFT arc: startAngle=π (leftmost point = arrow tip side),
    //           sweepAngle=+π (clockwise) → tip → TOP → circle edge
    //           Drawn right-to-left so the arc bows UPWARD.
    final leftRect = Rect.fromLTRB(
      cx - circleR - arcW,  // left  = arrow-tip side
      cy - arcH,            // top   = upward peak
      cx - circleR,         // right = circle-edge side
      cy + arcH,            // bottom
    );
    // Start at leftmost (π), sweep +π clockwise → left→UP→right direction
    // i.e., tip → peak → circle edge  (bows upward toward viewer)
    canvas.drawArc(leftRect, math.pi, math.pi, false, paint);

    // Arrowhead at LEFT tip (pointing left)
    final lt = Offset(leftRect.left, cy);
    canvas.drawPath(
      Path()
        ..moveTo(lt.dx + 8, lt.dy - 5)
        ..lineTo(lt.dx, lt.dy)
        ..lineTo(lt.dx + 8, lt.dy + 5),
      paint,
    );

    // RIGHT arc: startAngle=0 (rightmost = arrow tip side),
    //            sweepAngle=−π (counter-clockwise) → tip → TOP → circle edge
    final rightRect = Rect.fromLTRB(
      cx + circleR,         // left  = circle-edge side
      cy - arcH,            // top   = upward peak
      cx + circleR + arcW,  // right = arrow-tip side
      cy + arcH,            // bottom
    );
    canvas.drawArc(rightRect, 0, -math.pi, false, paint);

    // Arrowhead at RIGHT tip (pointing right)
    final rt = Offset(rightRect.right, cy);
    canvas.drawPath(
      Path()
        ..moveTo(rt.dx - 8, rt.dy - 5)
        ..lineTo(rt.dx, rt.dy)
        ..lineTo(rt.dx - 8, rt.dy + 5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
