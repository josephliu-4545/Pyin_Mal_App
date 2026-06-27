import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/cdn_image.dart';

class ARHairFilterScreen extends StatefulWidget {
  final String? initialHairstylePath;
  const ARHairFilterScreen({super.key, this.initialHairstylePath});

  @override
  State<ARHairFilterScreen> createState() => _ARHairFilterScreenState();
}

class _ARHairFilterScreenState extends State<ARHairFilterScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isCameraInitialized = false;
  bool _isDetectingFaces = false;
  List<Face> _faces = [];
  String? _currentHairstyle;
  Size? _cameraImageSize;
  InputImageRotation? _cameraRotation;

  @override
  void initState() {
    super.initState();
    _currentHairstyle = widget.initialHairstylePath ?? 'pyin-mal-assets/assets/images/HairStyle/Female/Oval Face/Oval - Bixie Cut.jpg';
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      // Determine camera rotation based on sensor orientation
      final sensorOrientation = frontCamera.sensorOrientation;
      _cameraRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: false,
        enableLandmarks: true,
        enableTracking: true,
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetectingFaces) return;
    _isDetectingFaces = true;

    if (_cameraImageSize == null) {
      setState(() {
         _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }

    final inputImage = _getInputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetectingFaces = false;
      return;
    }

    try {
      final faces = await _faceDetector!.processImage(inputImage);
      if (mounted) {
        setState(() {
          _faces = faces;
        });
      }
    } catch (e) {
      debugPrint('Error detecting faces: $e');
    }

    _isDetectingFaces = false;
  }

  InputImage? _getInputImageFromCameraImage(CameraImage image) {
    if (_cameraRotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _cameraRotation!,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  double _translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * size.width / (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
      case InputImageRotation.rotation270deg:
        return size.width - x * size.width / (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double _translateY(double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }

  Widget _buildHairOverlay(BuildContext context, BoxConstraints constraints) {
    if (_faces.isEmpty || _cameraImageSize == null || _cameraRotation == null) {
      return const SizedBox.shrink();
    }

    final face = _faces.first;
    final boundingBox = face.boundingBox;
    final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
    
    // Calculate translated face bounding box coordinates
    final left = _translateX(boundingBox.left, _cameraRotation!, screenSize, _cameraImageSize!);
    final right = _translateX(boundingBox.right, _cameraRotation!, screenSize, _cameraImageSize!);
    final top = _translateY(boundingBox.top, _cameraRotation!, screenSize, _cameraImageSize!);
    final bottom = _translateY(boundingBox.bottom, _cameraRotation!, screenSize, _cameraImageSize!);
    
    // Width and height of the face on screen
    final faceWidth = (right - left).abs();
    
    // Scale hair based on face width
    final hairWidth = faceWidth * 1.65; // Make hair wider than face
    final hairHeight = hairWidth * 1.1; // Maintain a reasonable aspect ratio
    
    // Position hair relative to the translated face coordinates
    // Center it horizontally
    final hairLeft = math.min(left, right) - (hairWidth - faceWidth) / 2;
    
    // Position it slightly above the face
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    double hairTop = top - (hairHeight * 0.45);
    
    // Use nose for better anchoring if available
    if (noseBase != null) {
       final translatedNoseY = _translateY(noseBase.position.y.toDouble(), _cameraRotation!, screenSize, _cameraImageSize!);
       hairTop = translatedNoseY - (hairHeight * 0.65);
    }

    // Head rotation
    double rotationAngle = 0.0;
    if (face.headEulerAngleZ != null) {
      rotationAngle = -face.headEulerAngleZ! * math.pi / 180.0;
    }

    return Positioned(
      left: hairLeft,
      top: hairTop,
      child: Transform.rotate(
        angle: rotationAngle,
        alignment: Alignment.center,
        child: SizedBox(
          width: hairWidth,
          height: hairHeight,
          child: _currentHairstyle != null
            ? CdnImage(
                _currentHairstyle!,
                fit: BoxFit.contain,
              )
            : const SizedBox.shrink(),
        ),
      ),
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
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return _buildUnsupportedScreen();
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
              fit: StackFit.expand,
              children: [
                // Camera preview
                CameraPreview(_cameraController!),
                
                // Hair overlay
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildHairOverlay(context, constraints);
                  },
                ),
                
                // Instructions
                Positioned(
                  bottom: 40,
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

  Widget _buildUnsupportedScreen() {
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
}
