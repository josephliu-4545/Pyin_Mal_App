import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/nanobanana_api_service.dart';

class HairTryOnScreen extends StatefulWidget {
  final String? initialPrompt;

  const HairTryOnScreen({super.key, this.initialPrompt});

  @override
  State<HairTryOnScreen> createState() => _HairTryOnScreenState();
}

class _HairTryOnScreenState extends State<HairTryOnScreen> {
  bool _isLoading = false;

  XFile? _userPhoto;
  Uint8List? _userPhotoBytes;

  XFile? _hairPhoto;
  Uint8List? _hairPhotoBytes;

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
        SnackBar(content: Text('hair_try_on.err_person'.tr())),
      );
      return;
    }

    if (_hairPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('hair_try_on.err_hair'.tr()),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Call API
      final resultUrl = await NanoBananaApiService.generateHairStyleImage(
        userPhoto: _userPhoto!,
        referenceHairPhoto: _hairPhoto,
        promptOverride: widget.initialPrompt ??
            'Virtual hair try-on, replace the person\'s hairstyle with the reference hairstyle, realistic, high quality.',
      );

      // Update UI
      if (mounted) {
        setState(() {
          _resultImageUrl = resultUrl;
          _isLoading = false;
        });

        if (resultUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('hair_try_on.err_api'.tr()),
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
        ).showSnackBar(SnackBar(content: Text('hair_try_on.error'.tr(args: [e.toString()]))));
      }
    }
  }

  void _reset() {
    setState(() {
      _userPhoto = null;
      _userPhotoBytes = null;
      _hairPhoto = null;
      _hairPhotoBytes = null;
      _resultImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark mode background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'hair_try_on.title'.tr(),
          style: GoogleFonts.rufina(
            color: const Color(0xFFD4AF37), // Gold accent
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
                'hair_try_on.new_look'.tr(),
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
                  backgroundColor: const Color(0xFFD4AF37), // Gold
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
                  'hair_try_on.try_another'.tr(),
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
                'hair_try_on.studio'.tr(),
                style: GoogleFonts.rufina(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'hair_try_on.desc'.tr(),
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Upload Grid
              Row(
                children: [
                  Expanded(
                    child: _buildUploadBox(
                      title: 'hair_try_on.photo'.tr(),
                      icon: Icons.face,
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
                      title: 'hair_try_on.reference'.tr(),
                      icon: Icons.content_cut,
                      imageBytes: _hairPhotoBytes,
                      onTap: () => _pickImage((f, b) {
                        _hairPhoto = f;
                        _hairPhotoBytes = b;
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
                  backgroundColor: const Color(0xFFD4AF37), // Gold accent
                  foregroundColor: Colors.black,
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
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'hair_try_on.generate'.tr(),
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
      child: AspectRatio(
        aspectRatio: 3 / 4, // More natural aspect ratio for portrait photos
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: imageBytes != null
                  ? Colors.green.shade400
                  : (isAccent
                      ? const Color(0xFFD4AF37).withOpacity(0.5)
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
                      color:
                          isAccent ? const Color(0xFFD4AF37) : Colors.white70,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color:
                            isAccent ? const Color(0xFFD4AF37) : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
