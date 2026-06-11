import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class ARHairFilterScreen extends StatefulWidget {
  const ARHairFilterScreen({super.key});

  @override
  State<ARHairFilterScreen> createState() => _ARHairFilterScreenState();
}

class _ARHairFilterScreenState extends State<ARHairFilterScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isCameraInitialized = false;
  bool _isDetectingFaces = false;
  List<Face> _faces = [];
  double? _headRotation;
  Offset? _faceCenter;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
      _cameraController!.startImageStream(_processCameraImage);
    }
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetectingFaces) return;
    _isDetectingFaces = true;

    final inputImage = _getInputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetectingFaces = false;
      return;
    }

    final faces = await _faceDetector!.processImage(inputImage);

    if (mounted) {
      setState(() {
        _faces = faces;
        if (faces.isNotEmpty) {
          _calculateFaceMetrics(faces.first);
        }
      });
    }

    _isDetectingFaces = false;
  }

  InputImage? _getInputImageFromCameraImage(CameraImage image) {
    final rotation = InputImageRotation.rotation0deg;
    final format = InputImageFormat.nv21;

    if (image.planes.isEmpty) return null;

    final plane = image.planes[0];
    final bytes = plane.bytes;

    // Convert camera image to InputImage
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _calculateFaceMetrics(Face face) {
    // Calculate head rotation using eye landmarks
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye != null && rightEye != null) {
      final dx = rightEye.position.x - leftEye.position.x;
      final dy = rightEye.position.y - leftEye.position.y;
      _headRotation = (dy / dx) * (180 / 3.14159);
    }

    // Calculate face center
    _faceCenter = Offset(
      face.boundingBox.left + face.boundingBox.width / 2,
      face.boundingBox.top + face.boundingBox.height / 2,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on web
    if (kIsWeb || !Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'ar_hair.title'.tr(),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Colors.white54,
                ),
                const SizedBox(height: 24),
                Text(
                  'ar_hair.not_supported_title'.tr(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'ar_hair.not_supported_desc'.tr(),
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ar_hair.title'.tr(),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ar_hair.toast_position'.tr())),
              );
            },
          ),
        ],
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                // Camera preview
                Center(
                  child: CameraPreview(_cameraController!),
                ),
                // Hair overlay
                if (_faces.isNotEmpty && _faceCenter != null && _headRotation != null)
                  Positioned(
                    left: _faceCenter!.dx - 100,
                    top: _faceCenter!.dy - 150,
                    child: Transform.rotate(
                      angle: _headRotation! * 3.14159 / 180,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.face,
                            size: 100,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Instructions
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _faces.isEmpty 
                            ? 'ar_hair.status_position'.tr() 
                            : 'ar_hair.status_detected'.tr(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
