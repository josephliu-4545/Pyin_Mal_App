import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanning = false;
  String? _errorMessage;
  File? _capturedImage;

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _capturedImage = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) {
        setState(() => _isScanning = false);
        return;
      }

      final imageFile = File(picked.path);
      setState(() => _capturedImage = imageFile);

      final imageBytes = await imageFile.readAsBytes();

      final product = await _identifyProduct(imageBytes);

      if (!mounted) return;

      if (product == null) {
        setState(() {
          _isScanning = false;
          _errorMessage = 'No matching item found in our catalog. Try a clearer photo of a clothing item.';
        });
        return;
      }

      setState(() => _isScanning = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: product.id,
            name: product.name,
            price: product.price,
            image: product.image,
            brand: product.brand,
            category: product.category,
            description: product.description,
            shopName: product.shopName,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<Product?> _identifyProduct(Uint8List imageBytes) async {
    final productsContext = ProductRepository.allProducts.map((p) {
      return '- ID: "${p.id}" | Name: "${p.name}" | Category: ${p.category} | Brand: ${p.brand} | Gender: ${p.gender}';
    }).join('\n');

    final prompt = '''
You are a fashion AI for the Pyin Mal app. Analyze the clothing item in this image and find the best match from our product catalog.

Available products:
$productsContext

Instructions:
1. Identify the type of clothing, color, and style in the image.
2. Find the closest matching product from the list above.
3. Return ONLY valid JSON in this exact format (no markdown, no extra text):
{"matched_product_id": "<product id or null if no match>", "confidence": "<high|medium|low>"}

If no product is a reasonable match, set matched_product_id to null.
''';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ]),
    ]);

    final text = response.text;
    if (text == null) return null;

    final json = jsonDecode(text) as Map<String, dynamic>;
    final id = json['matched_product_id'];
    if (id == null || id == 'null') return null;

    return ProductRepository.getProductById(id.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkWarm : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Smart Scan',
                    style: GoogleFonts.rufina(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isScanning
                  ? _buildScanningState(isDark, accent)
                  : _buildIdleState(isDark, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState(bool isDark, Color accent) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Preview image or placeholder
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _capturedImage != null
                ? ClipRRect(
                    key: const ValueKey('preview'),
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(
                      _capturedImage!,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    key: const ValueKey('placeholder'),
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkWarm : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accent.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 40,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Point at a clothing item',
                          style: GoogleFonts.rufina(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI will identify it and find\nthe best match in our catalog',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? AppColors.paleText : AppColors.inkGrey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Camera button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _scan(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                'Take a Photo',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Gallery button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _scan(ImageSource.gallery),
              icon: Icon(Icons.photo_library_rounded, color: accent),
              label: Text(
                'Choose from Gallery',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: accent.withOpacity(0.4), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 14,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey),
              const SizedBox(width: 6),
              Text(
                'Works best with clear, well-lit photos',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState(bool isDark, Color accent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_capturedImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(
                _capturedImage!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 40),
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            color: accent,
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Analyzing item...',
          style: GoogleFonts.rufina(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.inkBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI is identifying your clothing item',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? AppColors.paleText : AppColors.inkGrey,
          ),
        ),
      ],
    );
  }
}
