import 'dart:io';
import 'dart:typed_data';
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
  bool _isLoading = false;

  XFile? _userPhoto;
  Uint8List? _userPhotoBytes;

  XFile? _shirtPhoto;
  Uint8List? _shirtPhotoBytes;

  XFile? _pantsPhoto;
  Uint8List? _pantsPhotoBytes;

  XFile? _shoesPhoto;
  Uint8List? _shoesPhotoBytes;

  String? _resultImageUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(
    void Function(XFile file, Uint8List bytes) onPicked,
  ) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        onPicked(image, bytes);
      });
    }
  }

  Future<void> _processTryOn() async {
    if (_userPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo of the person!')),
      );
      return;
    }

    if (_shirtPhoto == null && _pantsPhoto == null && _shoesPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one clothing item!'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Call API
      final resultUrl = await NanoBananaApiService.generateTryOnImage(
        userPhoto: _userPhoto!,
        shirtPhoto: _shirtPhoto,
        pantsPhoto: _pantsPhoto,
        shoesPhoto: _shoesPhoto,
      );

      // Update UI
      if (mounted) {
        setState(() {
          _resultImageUrl = resultUrl;
          _isLoading = false;
        });

        if (resultUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to generate try-on image. Please check API settings.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _reset() {
    setState(() {
      _userPhoto = null;
      _userPhotoBytes = null;
      _shirtPhoto = null;
      _shirtPhotoBytes = null;
      _pantsPhoto = null;
      _pantsPhotoBytes = null;
      _shoesPhoto = null;
      _shoesPhotoBytes = null;
      _resultImageUrl = null;
    });
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
    // If result exists, show the result
    if (_resultImageUrl != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your AI Fit',
                style: GoogleFonts.rufina(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  _resultImageUrl!,
                  height: 400,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Try Another Outfit',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise show the upload UI
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mix & Match',
                style: GoogleFonts.rufina(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your photo and build your outfit to see the magic.',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Upload Grid
              Row(
                children: [
                  Expanded(
                    child: _buildUploadBox(
                      title: 'Person',
                      icon: Icons.person_add_alt_1_rounded,
                      imageBytes: _userPhotoBytes,
                      onTap: () => _pickImage((f, b) {
                        _userPhoto = f;
                        _userPhotoBytes = b;
                      }),
                      isAccent: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUploadBox(
                      title: 'Shirt / Top',
                      icon: Icons.checkroom_rounded,
                      imageBytes: _shirtPhotoBytes,
                      onTap: () => _pickImage((f, b) {
                        _shirtPhoto = f;
                        _shirtPhotoBytes = b;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildUploadBox(
                      title: 'Pants / Bottom',
                      icon: Icons.dry_cleaning_rounded,
                      imageBytes: _pantsPhotoBytes,
                      onTap: () => _pickImage((f, b) {
                        _pantsPhoto = f;
                        _pantsPhotoBytes = b;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUploadBox(
                      title: 'Sneakers',
                      icon: Icons.snowshoeing_rounded,
                      imageBytes: _shoesPhotoBytes,
                      onTap: () => _pickImage((f, b) {
                        _shoesPhoto = f;
                        _shoesPhotoBytes = b;
                      }),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Process Button
              ElevatedButton(
                onPressed: _isLoading ? null : _processTryOn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3064E3), // NanoBanana blue
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Generate Try-On',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String title,
    required IconData icon,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    bool isAccent = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: imageBytes != null
                ? Colors.green.shade400
                : (isAccent
                      ? Colors.blue.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2)),
            width: 2,
          ),
        ),
        child: imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isAccent ? Colors.blue.shade200 : Colors.white70,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: isAccent ? Colors.blue.shade100 : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
