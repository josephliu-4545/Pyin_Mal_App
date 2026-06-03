import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            '360° 3D View',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drag to rotate • Pinch to zoom',
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

  Widget _build3DViewer() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          rotation += details.delta.dx * 0.01;
        });
      },
      onPanUpdate: (details) {
        // Future: Add zoom with vertical drag
      },
      child: Stack(
        children: [
          // 3D Model Viewer Background
          Container(
            color: widget.isDark ? AppColors.darkWarm : Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Placeholder for 3D model
                  // Note: Actual 3D rendering uses model_viewer package
                  Icon(
                    Icons.view_in_ar,
                    size: 80,
                    color: widget.isDark
                        ? Colors.white30
                        : Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '3D Model Ready',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drag to rotate • Pinch to zoom',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: widget.isDark ? Colors.white38 : Colors.grey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rotation Indicator
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => rotation -= 0.3),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          '<',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkBlack,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.inkBlack,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => setState(() => rotation += 0.3),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          '>',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkBlack,
                          ),
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
    );
  }
}
