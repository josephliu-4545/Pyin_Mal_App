import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../main.dart';
import 'cdn_image.dart';

/// Widget to display 3D product model with rotation and zoom
class Product3DViewer extends StatefulWidget {
  final double height;
  final bool isDark;

  /// Asset path of a real GLB model to display (e.g.
  /// 'assets/models/w_star_wear_p1.glb'). When null, a placeholder is shown.
  final String? modelAsset;

  /// Product photo shown while the model is still being parsed, so the user
  /// sees the product instead of a blank WebView. Optional.
  final String? posterImage;

  const Product3DViewer({
    super.key,
    this.height = 400,
    required this.isDark,
    this.modelAsset,
    this.posterImage,
  });

  @override
  State<Product3DViewer> createState() => _Product3DViewerState();
}

class _Product3DViewerState extends State<Product3DViewer> {
  /// True once `<model-viewer>` reports the GLB is decoded and on screen.
  bool _modelReady = false;

  /// JS injected into the viewer page: tells Flutter when the model is up.
  static const _readyScript = '''
const mv = document.querySelector('model-viewer');
mv.addEventListener('load', () => ModelReady.postMessage('load'));
mv.addEventListener('error', () => ModelReady.postMessage('error'));
''';

  Timer? _coverTimeout;

  bool get _hasModel =>
      widget.modelAsset != null && widget.modelAsset!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _armCover();
  }

  @override
  void didUpdateWidget(covariant Product3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when the model asset changes (e.g. user switches color variant).
    if (oldWidget.modelAsset != widget.modelAsset) {
      setState(() => _modelReady = false);
      _armCover();
    }
  }

  @override
  void dispose() {
    _coverTimeout?.cancel();
    super.dispose();
  }

  /// JS channels only exist on mobile, so on web the model is treated as ready
  /// straight away. Everywhere else the cover lifts on the `load` event, with a
  /// timeout so a silent failure can never leave the spinner up forever.
  void _armCover() {
    _coverTimeout?.cancel();
    if (kIsWeb) {
      _modelReady = true;
      return;
    }
    _coverTimeout = Timer(const Duration(seconds: 12), () {
      if (mounted && !_modelReady) setState(() => _modelReady = true);
    });
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
    if (!_hasModel) return _buildPlaceholder();
    return _build3DViewer();
  }

  /// Shown for products that simply do not ship a model — this is a final
  /// state, so no spinner.
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
            'No 3D view for this item',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse the photos instead',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: widget.isDark ? Colors.white60 : Colors.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Covers the WebView until `<model-viewer>` fires `load`. Without it the
  /// user stares at a blank white page for the whole parse.
  Widget _buildLoadingCover() {
    final accent = widget.isDark ? AppColors.gold : AppColors.burgundy;
    return Container(
      color: widget.isDark ? AppColors.darkWarm : Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.posterImage != null)
            Opacity(
              opacity: 0.45,
              child: CdnImage(widget.posterImage!, fit: BoxFit.contain),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(accent),
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Preparing 360° view…',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white70 : AppColors.inkGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DViewer() {
    return Stack(
      children: [
        // 3D Model Viewer using ModelViewerPlus
        Container(
          color: widget.isDark ? AppColors.darkWarm : Colors.white,
          child: ModelViewer(
            key: ValueKey(widget.modelAsset),
            src: widget.modelAsset!,
            alt: '3D Product Model',
            autoRotate: false,
            cameraControls: true,
            relatedJs: _readyScript,
            javascriptChannels: {
              JavascriptChannel(
                'ModelReady',
                onMessageReceived: (_) {
                  _coverTimeout?.cancel();
                  if (mounted && !_modelReady) {
                    setState(() => _modelReady = true);
                  }
                },
              ),
            },
            backgroundColor: Color.lerp(
              widget.isDark ? AppColors.darkWarm : Colors.white,
              Colors.transparent,
              0.1,
            )!,
          ),
        ),

        // Poster + spinner over the WebView until the model is actually up.
        if (!_modelReady) Positioned.fill(child: _buildLoadingCover()),

        // Rotation handle — circle + curved arcs with arrowheads
        if (_modelReady)
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

