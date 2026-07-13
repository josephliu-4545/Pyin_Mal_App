import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    show InputImageRotation;
import 'package:permission_handler/permission_handler.dart';

import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/services/pose_detection_service.dart';
import 'package:pyin_mal_app/services/pose_guide_validator.dart';
import 'package:pyin_mal_app/widgets/pose_guide_painter.dart';

/// Guided self-camera for Bodygram photos: shows a body-outline guide, watches
/// the user's live pose, and only fires the countdown once they're posed
/// correctly (full body in frame, A-pose for front / profile for side).
///
/// Pops with a `Uint8List` (captured JPEG) on success, or null if cancelled.
class PoseGuideCameraScreen extends StatefulWidget {
  final BodyShot shot;
  const PoseGuideCameraScreen({super.key, required this.shot});

  @override
  State<PoseGuideCameraScreen> createState() => _PoseGuideCameraScreenState();
}

enum _Phase { starting, positioning, countdown, captured }

class _PoseGuideCameraScreenState extends State<PoseGuideCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cam;
  late final PoseDetectionService _pose;

  _Phase _phase = _Phase.starting;
  bool _permissionDenied = false;
  CameraLensDirection _lens = CameraLensDirection.back;

  PoseCheck _check = const PoseCheck(false, 'capture.hint_no_body');
  int _goodStreak = 0; // consecutive valid detections before locking in

  int _timerSeconds = 10; // user-selectable: 3 / 5 / 10
  int _countdown = 0;
  Timer? _countdownTimer;

  Uint8List? _captured;

  // Require a couple of consecutive good frames so a momentary blip doesn't
  // trigger the countdown.
  static const _streakToLock = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pose = PoseDetectionService();
    _init();
  }

  Future<void> _init() async {
    await _pose.initialize();
    await _startCamera();
  }

  Future<void> _startCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == _lens,
      orElse: () => cameras.first,
    );
    final isFront = camera.lensDirection == CameraLensDirection.front;

    // high (720p) → capture meets Bodygram's 720x1280 minimum in portrait.
    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    try {
      await ctrl.initialize();
      await ctrl.setFlashMode(FlashMode.off); // avoid AE precapture stalls
    } catch (e) {
      debugPrint('[PoseGuide] camera init failed: $e');
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    if (!mounted) {
      ctrl.dispose();
      return;
    }

    final rotation = rotationFromCamera(camera);
    await ctrl.startImageStream((image) => _onFrame(image, rotation, isFront));

    setState(() {
      _cam = ctrl;
      _phase = _Phase.positioning;
    });
  }

  void _onFrame(CameraImage image, InputImageRotation rotation, bool isFront) {
    if (_phase != _Phase.positioning) return;
    _pose
        .detect(
          image: image,
          rotation: rotation,
          isFrontCamera: isFront,
          previewSize: Size.zero,
        )
        .then((result) {
      if (!mounted || _phase != _Phase.positioning) return;
      final check = PoseGuideValidator.check(result, widget.shot);
      _goodStreak = check.ok ? _goodStreak + 1 : 0;
      setState(() => _check = check);
      if (_goodStreak >= _streakToLock) _beginCountdown();
    });
  }

  // ── Countdown → capture ────────────────────────────────────────────────────

  void _beginCountdown() {
    if (_phase == _Phase.countdown) return;
    _countdownTimer?.cancel();
    setState(() {
      _phase = _Phase.countdown;
      _countdown = _timerSeconds;
    });
    SystemSound.play(SystemSoundType.click);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown <= 1) {
        t.cancel();
        _capture();
      } else {
        setState(() => _countdown--);
        SystemSound.play(SystemSoundType.click);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _goodStreak = 0;
    setState(() => _phase = _Phase.positioning);
  }

  Future<void> _capture() async {
    final ctrl = _cam;
    if (ctrl == null) return;
    try {
      // Stop the stream before grabbing the still to avoid buffer contention.
      await ctrl.stopImageStream().catchError((_) {});
      final file = await ctrl
          .takePicture()
          .timeout(const Duration(seconds: 10));
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _captured = bytes;
        _phase = _Phase.captured;
      });
    } catch (e) {
      debugPrint('[PoseGuide] capture failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('bodygram.photo_error'.tr())),
      );
      _retake();
    }
  }

  Future<void> _retake() async {
    setState(() {
      _captured = null;
      _phase = _Phase.starting;
      _check = const PoseCheck(false, 'capture.hint_no_body');
      _goodStreak = 0;
    });
    await _cam?.dispose();
    _cam = null;
    await _startCamera();
  }

  Future<void> _flip() async {
    if (_cam == null) return;
    _countdownTimer?.cancel();
    setState(() {
      _phase = _Phase.starting;
      _goodStreak = 0;
      _lens = _lens == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
    });
    await _cam?.stopImageStream().catchError((_) {});
    await _cam?.dispose();
    _cam = null;
    await _startCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cam == null || !_cam!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cam?.stopImageStream().catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _cam?.stopImageStream().catchError((_) {});
    _cam?.dispose();
    _pose.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return Scaffold(
      backgroundColor: Colors.black,
      body: _permissionDenied
          ? _buildPermissionDenied()
          : _phase == _Phase.captured
              ? _buildReview()
              : _buildCamera(),
    );
  }

  Widget _buildCamera() {
    final cam = _cam;
    if (cam == null || !cam.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final counting = _phase == _Phase.countdown;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1 / cam.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(cam),
                // Body outline guide over camera preview
                CustomPaint(
                  painter: PoseGuidePainter(shot: widget.shot, ok: _check.ok),
                ),
              ],
            ),
          ),
        ),

        // Bottom UI (Hint Pill + Controls)
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomUI(counting),
        ),

        // Countdown number
        if (counting)
          Center(
            child: Text(
              '$_countdown',
              style: GoogleFonts.outfit(
                fontSize: 140,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [
                  Shadow(blurRadius: 24, color: Colors.black87),
                ],
              ),
            ),
          ),

        _buildTopBar(),
      ],
    );
  }

  Widget _buildBottomUI(bool counting) {
    return SafeArea(
      top: false,
      child: Container(
        // Add a subtle gradient at the bottom so UI elements are always legible
        // even if the background is complex.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.4),
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.only(top: 20, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live hint pill
            _hintPill(counting),
            
            const SizedBox(height: 16),
            
            if (!counting) ...[
              // Timer selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final s in [3, 5, 10]) _timerChip(s),
                ],
              ),
              const SizedBox(height: 16),
              // Manual shutter (fallback if someone else is holding the phone)
              GestureDetector(
                onTap: _beginCountdown,
                child: Container(
                  width: 66, height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Container(
                      width: 54, height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.timer_rounded,
                          color: Colors.black87, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('capture.shutter_hint'.tr(),
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontSize: 12)),
            ] else ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: _cancelCountdown,
                child: Text('capture.cancel'.tr(),
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hintPill(bool counting) {
    final ok = _check.ok;
    final text = counting ? 'capture.hold_still'.tr() : _check.hintKey.tr();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: (ok ? const Color(0xFF16803D) : const Color(0xFF111111)).withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: ok
                      ? const Color(0xFF4ADE80).withOpacity(0.6)
                      : Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.accessibility_new_rounded,
                    size: 18, color: ok ? const Color(0xFF4ADE80) : Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleBtn(Icons.close_rounded, () => Navigator.pop(context)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.shot == BodyShot.front
                      ? 'bodygram.front_photo'.tr()
                      : 'bodygram.right_photo'.tr(),
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
              _circleBtn(Icons.flip_camera_ios_rounded, _flip),
            ],
          ),
        ),
      ),
    );
  }

  // _buildBottomControls was replaced by _buildBottomUI

  Widget _timerChip(int s) {
    final sel = _timerSeconds == s;
    return GestureDetector(
      onTap: () => setState(() => _timerSeconds = s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.burgundy : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: sel ? AppColors.burgundy : Colors.white.withOpacity(0.2),
              width: 1.5),
          boxShadow: sel
              ? [
                  BoxShadow(
                      color: AppColors.burgundy.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text('${s}s',
            style: GoogleFonts.outfit(
                color: sel ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: sel ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── Review captured photo ───────────────────────────────────────────────────

  Widget _buildReview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_captured!, fit: BoxFit.contain),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retake,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      label: Text('capture.retake'.tr(),
                          style: GoogleFonts.outfit(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _captured),
                      icon: const Icon(Icons.check_rounded),
                      label: Text('capture.use_photo'.tr(),
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.burgundy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            Text('capture.permission'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 16)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => openAppSettings(),
              child: Text('capture.open_settings'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('capture.go_back'.tr(),
                  style: GoogleFonts.outfit(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}
