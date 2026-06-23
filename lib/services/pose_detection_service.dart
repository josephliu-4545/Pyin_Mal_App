// ignore_for_file: depend_on_referenced_packages
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PoseLandmark — a single landmark point in screen-normalized coordinates.
// x and y are in [0.0, 1.0] relative to the preview widget dimensions.
// likelihood is the confidence value from the detector (0.0–1.0).
// ─────────────────────────────────────────────────────────────────────────────
class ARLandmark {
  final double x; // normalized 0..1 (left → right)
  final double y; // normalized 0..1 (top → bottom)
  final double likelihood; // confidence

  const ARLandmark({
    required this.x,
    required this.y,
    required this.likelihood,
  });

  @override
  String toString() =>
      'ARLandmark(x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, '
      'likelihood: ${likelihood.toStringAsFixed(2)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// PoseResult — output from one detection cycle.
// Contains all upper-body landmarks we care about, or null if not detected.
// ─────────────────────────────────────────────────────────────────────────────
class PoseResult {
  final ARLandmark? leftShoulder; // MLKit index 11
  final ARLandmark? rightShoulder; // MLKit index 12
  final ARLandmark? leftHip; // MLKit index 23
  final ARLandmark? rightHip; // MLKit index 24
  final ARLandmark? nose; // MLKit index 0 (for framing)

  const PoseResult({
    this.leftShoulder,
    this.rightShoulder,
    this.leftHip,
    this.rightHip,
    this.nose,
  });

  /// True if we have the four corner landmarks above confidence threshold.
  bool get isValid {
    const threshold = 0.5;
    return (leftShoulder?.likelihood ?? 0) > threshold &&
        (rightShoulder?.likelihood ?? 0) > threshold &&
        (leftHip?.likelihood ?? 0) > threshold &&
        (rightHip?.likelihood ?? 0) > threshold;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PoseDetectionService
//
// Wraps google_mlkit_pose_detection with a clean interface.
// Pass useMock: true to get simulated landmarks for UI testing without a device.
//
// Usage:
//   final svc = PoseDetectionService(useMock: false);
//   await svc.initialize();
//   // In camera stream callback:
//   final result = await svc.detect(cameraImage, imageRotation);
//   // When done:
//   await svc.dispose();
// ─────────────────────────────────────────────────────────────────────────────
class PoseDetectionService {
  final bool useMock;

  PoseDetector? _detector;
  bool _isBusy = false; // prevents frame-drop race conditions

  // Mock mode animation state
  double _mockTime = 0;

  PoseDetectionService({this.useMock = false});

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (useMock) return; // Nothing to initialize in mock mode

    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream, // Optimised for live camera
      model: PoseDetectionModel.base, // base = faster, accurate enough
    );
    _detector = PoseDetector(options: options);
  }

  // ── Detection ─────────────────────────────────────────────────────────────

  /// Detect pose landmarks from a live camera frame.
  /// [image] – raw camera frame from camera.imageStream
  /// [rotation] – how much the image needs rotating to be upright
  /// [isFrontCamera] – true for selfie camera (we flip X coordinates)
  /// [previewSize] – the rendered size of CameraPreview on screen
  Future<PoseResult?> detect({
    required CameraImage image,
    required InputImageRotation rotation,
    required bool isFrontCamera,
    required Size previewSize,
  }) async {
    if (useMock) return _mockDetect();

    // Skip this frame if we're still processing the previous one
    if (_isBusy || _detector == null) return null;
    _isBusy = true;

    try {
      final inputImage = _toInputImage(image, rotation);
      if (inputImage == null) return null;

      final poses = await _detector!.processImage(inputImage);
      if (poses.isEmpty) return null;

      final pose = poses.first;

      // Helper: convert one MLKit landmark to our ARLandmark in normalized coords
      ARLandmark? toLandmark(PoseLandmarkType type) {
        final lm = pose.landmarks[type];
        if (lm == null) return null;

        // MLKit gives pixel coordinates within the input image
        double nx = lm.x / image.width;
        double ny = lm.y / image.height;

        // Mirror X for front-facing camera
        if (isFrontCamera) nx = 1.0 - nx;

        return ARLandmark(x: nx, y: ny, likelihood: lm.likelihood);
      }

      return PoseResult(
        leftShoulder: toLandmark(PoseLandmarkType.leftShoulder),
        rightShoulder: toLandmark(PoseLandmarkType.rightShoulder),
        leftHip: toLandmark(PoseLandmarkType.leftHip),
        rightHip: toLandmark(PoseLandmarkType.rightHip),
        nose: toLandmark(PoseLandmarkType.nose),
      );
    } catch (e) {
      debugPrint('[PoseDetection] Error: $e');
      return null;
    } finally {
      _isBusy = false;
    }
  }

  // ── Mock mode ─────────────────────────────────────────────────────────────

  /// Returns simulated landmark positions that sway gently to simulate a
  /// standing person. Useful for UI layout testing without a real device.
  /// This is PUBLIC so the AR screen can call it directly on a timer tick.
  PoseResult mockResult() => _mockDetect();

  PoseResult _mockDetect() {
    _mockTime += 0.03;
    final sway = math.sin(_mockTime) * 0.02; // gentle left-right sway
    final bob = math.sin(_mockTime * 1.3) * 0.01; // slight up-down

    return PoseResult(
      // Shoulders sit at ~35% from top, spread ~30% either side of center
      leftShoulder: ARLandmark(
          x: 0.35 + sway, y: 0.35 + bob, likelihood: 0.95),
      rightShoulder: ARLandmark(
          x: 0.65 + sway, y: 0.35 + bob, likelihood: 0.95),
      // Hips sit at ~60% from top
      leftHip:
          ARLandmark(x: 0.38 + sway, y: 0.60 + bob, likelihood: 0.92),
      rightHip:
          ARLandmark(x: 0.62 + sway, y: 0.60 + bob, likelihood: 0.92),
      nose: ARLandmark(x: 0.50 + sway, y: 0.22 + bob, likelihood: 0.98),
    );
  }

  // ── InputImage conversion ─────────────────────────────────────────────────

  /// Converts a [CameraImage] from the camera stream into an [InputImage]
  /// that MLKit can process.
  InputImage? _toInputImage(CameraImage image, InputImageRotation rotation) {
    try {
      // camera package yields NV21 on Android, BGRA8888 on iOS
      final format = (defaultTargetPlatform == TargetPlatform.android)
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      // NV21 = YUV420 semi-planar; first plane is Y, second is VU interleaved.
      // For MLKit we concatenate all planes into one byte buffer.
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      debugPrint('[PoseDetection] InputImage conversion error: $e');
      return null;
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility: get InputImageRotation from a CameraDescription + device orientation
// ─────────────────────────────────────────────────────────────────────────────
InputImageRotation rotationFromCamera(CameraDescription camera) {
  final sensorAngle = camera.sensorOrientation;
  switch (sensorAngle) {
    case 90:
      return InputImageRotation.rotation90deg;
    case 180:
      return InputImageRotation.rotation180deg;
    case 270:
      return InputImageRotation.rotation270deg;
    default:
      return InputImageRotation.rotation0deg;
  }
}
