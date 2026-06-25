import 'dart:async';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    show InputImageRotation;
import 'package:permission_handler/permission_handler.dart';

import '../models/clothing_item.dart';
import '../services/cart_service.dart';
import '../services/pose_detection_service.dart';
import '../services/screenshot_service.dart';
import '../widgets/clothing_overlay.dart';
import '../widgets/clothing_selector.dart';
import '../widgets/try_on_controls.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ARFittingRoomScreen
//
// Full-screen live AR try-on using the device camera + MLKit Pose Detection.
//
// Flow:
//  1. Request camera permission
//  2. Initialize CameraController (front camera for selfie try-on)
//  3. Start image stream → PoseDetectionService.detect() per frame
//  4. setState() with latest PoseResult → ClothingOverlay re-renders
//  5. Clothing is positioned over shoulders/hips via Positioned widget
//  6. Bottom panel: ClothingSelector + TryOnControls
//
// Mock mode:
//  Set _useMockPose = true to skip real pose detection and use animated
//  simulated landmarks. Useful when testing on an emulator.
// ─────────────────────────────────────────────────────────────────────────────

/// Set to true to use simulated pose data (no camera/MLKit required).
const bool _useMockPose = false;

class ARFittingRoomScreen extends StatefulWidget {
  /// The product to show in the AR view by default (optional).
  final ClothingItem? initialItem;

  /// Product details passed from ProductDetailScreen for the cart action.
  final String? productId;
  final String? productName;
  final String? productPrice;
  final String? productImage;
  final String? productBrand;

  const ARFittingRoomScreen({
    super.key,
    this.initialItem,
    this.productId,
    this.productName,
    this.productPrice,
    this.productImage,
    this.productBrand,
  });

  @override
  State<ARFittingRoomScreen> createState() => _ARFittingRoomScreenState();
}

class _ARFittingRoomScreenState extends State<ARFittingRoomScreen>
    with WidgetsBindingObserver {
  // ── Services ───────────────────────────────────────────────────────────────
  CameraController? _camCtrl;
  late final PoseDetectionService _poseService;
  final ScreenshotService _screenshotService = ScreenshotService();
  final GlobalKey _repaintKey = GlobalKey();

  // ── State ──────────────────────────────────────────────────────────────────
  bool _cameraReady = false;
  bool _permissionDenied = false;
  bool _isSaving = false;

  CameraLensDirection _currentLensDirection = CameraLensDirection.front;
  PoseResult? _poseResult;

  // Selected clothing
  late ClothingItem _selectedItem;
  late String _selectedSize;
  ClothingColor? _selectedColor;

  // Mock-mode ticker
  Timer? _mockTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Default item: use initialItem if provided, otherwise first mock item
    _selectedItem =
        widget.initialItem ?? mockClothingItems.first;
    _selectedSize = 'M';
    _selectedColor = _selectedItem.availableColors.isNotEmpty
        ? _selectedItem.availableColors.first
        : null;

    _poseService = PoseDetectionService(useMock: _useMockPose);

    _initAll();
  }

  Future<void> _initAll() async {
    await _poseService.initialize();

    if (_useMockPose) {
      // In mock mode: tick at ~15 fps to get animated landmark data
      _mockTimer = Timer.periodic(const Duration(milliseconds: 66), (_) {
        if (mounted) {
          setState(() => _poseResult = _poseService.mockResult());
        }
      });
      setState(() => _cameraReady = true);
      return;
    }

    await _startCamera();
  }

  Future<void> _startCamera() async {
    // ── 1. Camera permission ───────────────────────────────────────────────
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // ── 2. Get available cameras ───────────────────────────────────────────
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // Get the camera matching the current selected direction
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == _currentLensDirection,
      orElse: () => cameras.first,
    );
    final isFront = camera.lensDirection == CameraLensDirection.front;

    // ── 3. Initialize camera controller ───────────────────────────────────
    final ctrl = CameraController(
      camera,
      ResolutionPreset.medium, // 720p – good balance of speed vs quality
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Android-optimised for MLKit
    );

    try {
      await ctrl.initialize();
    } catch (e) {
      debugPrint('[ARFitting] Camera init error: $e');
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    // ── 4. Start image stream → pose detection ─────────────────────────────
    final rotation = rotationFromCamera(camera);

    await ctrl.startImageStream((CameraImage image) {
      // Detect in background; update state when done
      _poseService
          .detect(
            image: image,
            rotation: rotation,
            isFrontCamera: isFront,
            previewSize: Size.zero,
          )
          .then((result) {
        if (mounted && result != null) {
          setState(() => _poseResult = result);
        }
      });
    });

    if (mounted) {
      setState(() {
        _camCtrl = ctrl;
        _cameraReady = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause/resume camera when app goes to background
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camCtrl?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mockTimer?.cancel();
    _camCtrl?.stopImageStream().catchError((_) {});
    _camCtrl?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _flipCamera() async {
    if (_camCtrl == null || _useMockPose) return;

    setState(() {
      _cameraReady = false;
      _currentLensDirection = _currentLensDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
    });

    await _camCtrl?.stopImageStream().catchError((_) {});
    await _camCtrl?.dispose();
    _camCtrl = null;

    await _startCamera();
  }

  Future<void> _saveScreenshot() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final path = await _screenshotService.capture(_repaintKey);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              path != null ? Icons.check_circle_rounded : Icons.error_rounded,
              color: path != null ? Colors.greenAccent : Colors.redAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              path != null
                  ? 'Photo saved to device!'
                  : 'Could not save photo.',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCart() {
    CartService.instance.addToCart(CartItem(
      productId: widget.productId ?? _selectedItem.id,
      name: widget.productName ?? _selectedItem.name,
      price: widget.productPrice ?? _selectedItem.price,
      image: widget.productImage ?? _selectedItem.assetPath,
      brand: widget.productBrand ?? '',
      size: _selectedSize,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.shopping_bag_rounded,
                color: Colors.greenAccent, size: 18),
            const SizedBox(width: 10),
            Text(
              '${_selectedItem.name} ($_selectedSize) added to cart!',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Fullscreen — hide status bar for immersive camera experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) return _buildPermissionDenied();
    if (!_cameraReady) return _buildLoading();
    return _buildARView();
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 20),
          Text(
            'Starting camera…',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Permission denied state ────────────────────────────────────────────────

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 20),
            Text(
              'Camera Permission Required',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The AR Fitting Room needs camera access to overlay clothing on your body in real time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Open Settings',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back',
                  style:
                      GoogleFonts.outfit(color: Colors.white60, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main AR view ───────────────────────────────────────────────────────────

  Widget _buildARView() {
    return RepaintBoundary(
      key: _repaintKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Camera + Overlay (perfectly aligned aspect ratio) ───────
          Center(
            child: AspectRatio(
              aspectRatio: _useMockPose || _camCtrl == null
                  ? 9 / 16 // default fallback portrait ratio
                  : 1 / _camCtrl!.value.aspectRatio, // portrait camera ratio
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraPreview(),
                  ClothingOverlay(
                    pose: _poseResult,
                    assetPath: _selectedItem.assetPath,
                    tintColor: _selectedColor?.color ?? Colors.transparent,
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Body-not-detected instruction ──────────────────────────
          if (!(_poseResult?.isValid ?? false)) _buildInstruction(),

          // ── 4. Top bar: Back + Save ────────────────────────────────────
          _buildTopBar(),

          // ── 5. Bottom panel: selector + controls ──────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // ── Camera preview ─────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    if (_useMockPose || _camCtrl == null) {
      // Mock mode: show animated gradient background to simulate camera
      return _buildMockBackground();
    }
    // CameraPreview will automatically fill the AspectRatio we provided above.
    return CameraPreview(_camCtrl!);
  }

  Widget _buildMockBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D0D1A),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded,
                size: 120, color: Colors.white.withOpacity(0.08)),
            const SizedBox(height: 8),
            Text(
              'MOCK MODE',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.15),
                fontSize: 12,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Instruction overlay ────────────────────────────────────────────────────

  Widget _buildInstruction() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 200),
        child: AnimatedOpacity(
          opacity: _poseResult == null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.accessibility_new_rounded,
                    color: Colors.white70, size: 22),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Stand straight and show\nyour upper body',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              _TopBarButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () {
                  SystemChrome.setEnabledSystemUIMode(
                      SystemUiMode.edgeToEdge);
                  Navigator.pop(context);
                },
              ),

              // Screen label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'AR Fitting Room',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Flip camera & Save buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_useMockPose) ...[
                    _TopBarButton(
                      icon: Icons.flip_camera_ios_rounded,
                      onTap: _flipCamera,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _TopBarButton(
                    icon: _isSaving
                        ? Icons.hourglass_empty_rounded
                        : Icons.camera_alt_rounded,
                    onTap: _saveScreenshot,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom panel ───────────────────────────────────────────────────────────

  Widget _buildBottomPanel() {
    return ClipRRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.92),
              Colors.black.withOpacity(0.70),
              Colors.transparent,
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item name ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    _selectedItem.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                // ── Clothing carousel ─────────────────────────────────────
                ClothingSelector(
                  items: mockClothingItems,
                  selectedId: _selectedItem.id,
                  onSelected: (item) {
                    setState(() {
                      _selectedItem = item;
                      _selectedColor = item.availableColors.isNotEmpty
                          ? item.availableColors.first
                          : null;
                    });
                  },
                ),

                const SizedBox(height: 14),

                // ── Size + Color + Cart ───────────────────────────────────
                TryOnControls(
                  item: _selectedItem,
                  selectedSize: _selectedSize,
                  selectedColor: _selectedColor,
                  onSizeChanged: (s) => setState(() => _selectedSize = s),
                  onColorChanged: (c) => setState(() => _selectedColor = c),
                  onAddToCart: _addToCart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable top bar icon button ─────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _TopBarButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}
