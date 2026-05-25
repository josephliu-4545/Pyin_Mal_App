import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/nanobanana_api_service.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  
  File? _userPhoto;
  File? _clothesPhoto;
  String? _resultImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    }
  }

  Future<void> _pickClothesPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _clothesPhoto = File(image.path);
      });
    }
  }

  Future<void> _captureAndProcess() async {
    if (_clothesPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a clothing image first!')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Capture User Photo
      final XFile photo = await _cameraController!.takePicture();
      _userPhoto = File(photo.path);

      // 2. Call API
      final resultUrl = await NanoBananaApiService.generateTryOnImage(
        userPhoto: _userPhoto!,
        clothesPhoto: _clothesPhoto!,
      );

      // 3. Update UI
      if (mounted) {
        setState(() {
          _resultImageUrl = resultUrl;
          _isLoading = false;
        });

        if (resultUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate try-on image.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _userPhoto = null;
      _resultImageUrl = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Virtual Try-On',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_resultImageUrl != null) {
      // Show Result
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(_resultImageUrl!, height: 400),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Try Another',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      children: [
        // Camera Preview
        Center(child: CameraPreview(_cameraController!)),
        
        // Clothes Selector
        Positioned(
          top: 20,
          right: 20,
          child: GestureDetector(
            onTap: _pickClothesPhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: _clothesPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_clothesPhoto!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checkroom, color: Colors.white),
                        Text(
                          'Upload',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        // Capture Button / Loading state
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: _isLoading
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'AI is fitting your clothes...',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: _captureAndProcess,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
