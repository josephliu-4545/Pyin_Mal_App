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

  /// Asset path of a real GLB model to display (e.g.
  /// 'assets/models/w_star_wear_p1.glb'). When provided, this model is loaded
  /// directly. When null, the procedural placeholder model is generated.
  final String? modelAsset;

  const Product3DViewer({
    super.key,
    this.height = 400,
    required this.isDark,
    this.modelAsset,
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

      // A real GLB asset was supplied — load it directly (ModelViewer reads
      // Flutter asset paths), skipping the procedural placeholder generator.
      if (widget.modelAsset != null && widget.modelAsset!.isNotEmpty) {
        if (mounted) {
          setState(() {
            modelPath = widget.modelAsset;
            isLoading = false;
            errorMessage = null;
          });
          print('✅ 3D model ready (asset): ${widget.modelAsset}');
        }
        return;
      }

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

// ── Rotation handle: white circle with ↔ icon + thin bent side lines ─────────
class _RotationHandle extends StatelessWidget {
  const _RotationHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Turntable plate rim — wide shallow ellipse arc
          CustomPaint(
            size: const Size(240, 70),
            painter: _SideLinesPainter(),
          ),
          // White circle with ↔ icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.swap_horiz_rounded,
                size: 24,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cy = size.height / 2;

    // Wide shallow ellipse = the turntable plate. We draw only the FRONT
    // (bottom) rim: a gentle valley, lowest in the middle where the rotate
    // button sits, rising toward both sides.
    final rect = Rect.fromLTWH(
      6,                 // left inset
      cy - 30,           // top of the ellipse (sides sit here, higher up)
      size.width - 12,   // wide
      44,                // ellipse height → bottom passes just below circle
    );

    // Bottom arc: from left (π) sweeping -π counter-clockwise through the
    // bottom point (π/2) to the right (0). Gives a shallow ∪ rim.
    canvas.drawArc(rect, math.pi, -math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

