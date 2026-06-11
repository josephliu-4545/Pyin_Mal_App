import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Strategy: base Camera2 plugin preview + takePicture() for frame capture.
//
// camera_android_camerax is intentionally NOT used. CameraX always creates
// an ImageAnalysis use case (YUV_420_888 ImageReader) even with no stream,
// and its onCameraAccessPrioritiesChanged handler tears down the entire session
// — both are fatal on Xiaomi Redmi Note 9S.
//
// Base Camera2 plugin with takePicture():
//   • Preview + ImageCapture only — no ImageAnalysis/YUV ImageReader
//   • No onCameraAccessPrioritiesChanged handler → session stays alive
//   • FocusMode.locked + ExposureMode.locked → skip AE precapture,
//     takePicture() completes immediately without STATE_WAITING_FOCUS hang
// ─────────────────────────────────────────────────────────────────────────────

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool  _cameraReady    = false;
  bool  _isAnalyzing    = false;
  bool  _resultShown    = false;
  bool  _isInitializing = false;
  Timer? _autoScanTimer;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScanTimer?.cancel();
    _disposeCamera();
    super.dispose();
  }

  void _disposeCamera() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoScanTimer?.cancel();
      _isAnalyzing = false;
      if (_cameraReady) {
        _disposeCamera();
        if (mounted) setState(() { _cameraReady = false; });
      }
    } else if (state == AppLifecycleState.resumed &&
        !_cameraReady && !_isInitializing) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _isAnalyzing = false;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'scan.no_camera'.tr());
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // No imageFormatGroup needed — we use takePicture(), not startImageStream
      final ctrl = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }

      // FlashMode.off is the key: it causes camera_android to skip the entire
      // AE precapture sequence (runPrecaptureSequence) before each takePicture().
      // With FlashMode.auto the precapture runs ~14 frames (~0.5s) per capture.
      // FocusMode.locked + ExposureMode.locked still trigger refreshPreviewCaptureSession
      // which can interfere — just disabling flash is sufficient and cleaner.
      try {
        await ctrl.setFlashMode(FlashMode.off);
      } catch (_) {} // non-fatal

      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _controller = ctrl; _cameraReady = true; });
      _startAutoScan();

    } catch (e) {
      if (mounted) setState(() => _cameraError = 'scan.err_start'.tr());
    } finally {
      _isInitializing = false;
    }
  }

  void _startAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_isAnalyzing && !_resultShown) _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_isAnalyzing || _resultShown) return;
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    setState(() => _isAnalyzing = true);

    Uint8List bytes = Uint8List(0);
    List<Product> results = [];
    bool cameraFailed = false;
    String? scanError;

    try {
      final XFile file = await ctrl.takePicture()
          .timeout(const Duration(seconds: 10));
      bytes = await file.readAsBytes();

      if (bytes.isNotEmpty) {
        results = await _identifyProducts(bytes)
            .timeout(const Duration(seconds: 30), onTimeout: () => []);
      }
    } on CameraException catch (e) {
      cameraFailed = true;
      debugPrint('ScanScreen: CameraException → ${e.code}: ${e.description}');
    } on TimeoutException {
      scanError = 'scan.err_timeout'.tr();
      debugPrint('ScanScreen: takePicture or AI proxy timed out');
    } catch (e) {
      scanError = 'scan.err_scan'.tr();
      debugPrint('ScanScreen: _analyzeCurrentFrame error → $e');
    } finally {
      _isAnalyzing = false;
      if (mounted) setState(() {});
    }

    if (!mounted) return;

    // Camera hardware died → reinitialize so preview recovers
    if (cameraFailed) {
      _autoScanTimer?.cancel();
      _disposeCamera();
      setState(() { _cameraReady = false; });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _initCamera();
      return;
    }

    // Show any scan-level errors as a brief snackbar
    if (scanError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scanError), duration: const Duration(seconds: 2)));
      return;
    }

    if (bytes.isNotEmpty && results.isNotEmpty) {
      setState(() => _resultShown = true);
      _autoScanTimer?.cancel();
      _showResultsSheet(bytes, results);
    } else if (bytes.isNotEmpty && results.isEmpty) {
      // AI returned no matches — give brief feedback so user knows scan ran
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('scan.no_match'.tr()),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // Returns up to 4 ranked similar products using Groq LLaMA vision.
  // Groq API is called directly — free tier, global coverage.
  // (api.groq.com was temporarily unreachable on a prior test; it is accessible
  //  from Myanmar. If DNS fails again, check mobile data vs Wi-Fi.)
  Future<List<Product>> _identifyProducts(Uint8List imageBytes) async {
    // Build rich catalog context: ID + visual description + tags
    final productsContext = ProductRepository.allProducts.map((p) {
      final desc   = p.description ?? p.name;
      final tagStr = p.tags.isNotEmpty ? p.tags.join(', ') : p.category;
      return '- ID: "${p.id}" | ${p.category} | ${p.brand} | Visual: $desc | Tags: $tagStr';
    }).join('\n');

    const groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

    // Burmese-aware prompt — understands Myanmar fashion context
    const promptHeader =
        'You are a fashion AI assistant for Pyin Mal, a Myanmar clothing app.\n'
        'Analyze the clothing item visible in this image. The photo may be taken in Myanmar.\n'
        'You understand both English and Burmese (မြန်မာဘာသာ) clothing terms.\n\n'
        'Step 1 — Describe what you see:\n'
        '  • Clothing type (hoodie, t-shirt, set, dress, jacket, etc.)\n'
        '  • Color(s) — be specific (black, oatmeal/cream, navy, etc.)\n'
        '  • Style (graphic print, plain/minimal, sporty, feminine, streetwear, etc.)\n'
        '  • Key visual details (zipper, skull graphic, logo, embroidery, wide-leg, wrap, etc.)\n'
        '  • Gender presentation (male/menswear, female/womenswear, unisex)\n\n'
        'Step 2 — Match against the catalog below using the visual description and tags.\n'
        'Focus on: clothing TYPE first → COLOR second → STYLE/DETAILS third.\n'
        'A match is valid even if not identical — similar style counts.\n\n'
        'Available products:\n';

    const promptFooter =
        '\n\nStep 3 — Return ONLY valid JSON (no markdown, no extra text):\n'
        '{"matched_product_ids": ["id1", "id2", "id3"], "item_type": "brief description of what you see"}\n\n'
        'Rules:\n'
        '- Include 1 to 4 IDs ranked best match first.\n'
        '- Only include a product if it genuinely resembles the scanned item.\n'
        '- Return matched_product_ids as empty array [] if nothing is similar.\n'
        '- Do NOT invent IDs — only use IDs from the list above.';

    final body = jsonEncode({
      'model': groqModel,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
              },
            },
            {
              'type': 'text',
              'text': '$promptHeader$productsContext$promptFooter',
            },
          ],
        },
      ],
    });

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      debugPrint('ScanScreen: Groq ${response.statusCode} → ${response.body}');
      throw Exception('Groq API returned ${response.statusCode}');
    }

    final data    = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['choices'] as List).first['message']['content'] as String;

    final cleaned = content
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final ids  = (json['matched_product_ids'] as List?)?.cast<String>() ?? [];

    return ids
        .map((id) => ProductRepository.getProductById(id))
        .whereType<Product>()
        .toList();
  }

  void _showResultsSheet(Uint8List scannedBytes, List<Product> products) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ResultsSheet(
        scannedBytes: scannedBytes,
        products: products,
        accent: accent,
        isDark: isDark,
        onScanAgain: () {
          Navigator.pop(context);
          setState(() => _resultShown = false);
          _startAutoScan();
        },
        onSelectProduct: (product) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId:   product.id,
              name:        product.name,
              price:       product.price,
              image:       product.image,
              brand:       product.brand,
              category:    product.category,
              description: product.description,
              shopName:    product.shopName,
            ),
          ));
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [

          // Camera preview
          if (_cameraReady && _controller != null)
            Positioned.fill(child: CameraPreview(_controller!))
          else if (_cameraError != null)
            Center(child: Padding(padding: const EdgeInsets.all(32),
              child: Text(_cameraError!, textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14))))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Scan frame overlay
          if (_cameraReady)
            Positioned.fill(child: _ScanFrameOverlay(
                isAnalyzing: _isAnalyzing, accent: accent)),

          // Top bar
          Positioned(top: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20)),
                ),
                const SizedBox(width: 14),
                Text('scan.title'.tr(), style: GoogleFonts.rufina(
                    fontSize: 22, fontWeight: FontWeight.bold,
                    color: Colors.white)),
              ]),
            ),
          ),

          // Bottom controls
          if (_cameraReady)
            Positioned(bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [

                  // Status chip
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isAnalyzing
                        ? _StatusChip(key: const ValueKey('a'),
                            label: 'scan.identifying'.tr(),
                            icon: Icons.auto_awesome_rounded,
                            color: accent, textColor: Colors.white)
                        : _StatusChip(key: const ValueKey('i'),
                            label: 'scan.auto_scan'.tr(),
                            icon: Icons.radar_rounded,
                            color: Colors.white.withOpacity(0.15),
                            textColor: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Shutter button
                  GestureDetector(
                    onTap: _isAnalyzing ? null : _analyzeCurrentFrame,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isAnalyzing
                            ? Colors.white.withOpacity(0.3) : Colors.white,
                        border: Border.all(
                            color: accent.withOpacity(0.6), width: 3),
                        boxShadow: [BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: _isAnalyzing
                          ? Padding(padding: const EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: accent, strokeWidth: 2.5))
                          : Icon(Icons.document_scanner_rounded,
                              color: accent, size: 30),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('scan.tap_to_scan'.tr(), style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Scan frame overlay ────────────────────────────────────────────────────────
class _ScanFrameOverlay extends StatefulWidget {
  final bool isAnalyzing;
  final Color accent;
  const _ScanFrameOverlay({required this.isAnalyzing, required this.accent});
  @override State<_ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<_ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  @override void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.72;
    final centerY   = size.height * 0.42;
    return Stack(children: [
      CustomPaint(size: Size(size.width, size.height),
          painter: _VignettePainter(frameSize: frameSize,
              center: Offset(size.width / 2, centerY))),
      Positioned(
        left: (size.width - frameSize) / 2,
        top:  centerY - frameSize / 2,
        child: AnimatedBuilder(animation: _pulse, builder: (_, __) {
          final color = widget.isAnalyzing
              ? Color.lerp(widget.accent, Colors.white, _pulse.value)!
              : Colors.white;
          return SizedBox(width: frameSize, height: frameSize,
              child: CustomPaint(painter: _CornerPainter(color: color)));
        }),
      ),
    ]);
  }
}

class _VignettePainter extends CustomPainter {
  final double frameSize; final Offset center;
  _VignettePainter({required this.frameSize, required this.center});
  @override void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: center,
                width: frameSize, height: frameSize),
            const Radius.circular(12)))
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(0.5),
    );
  }
  @override bool shouldRepaint(_VignettePainter o) =>
      o.frameSize != frameSize || o.center != center;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    const len = 28.0; const r = 10.0;
    void corner(double x, double y, double dx, double dy) {
      canvas.drawPath(Path()
        ..moveTo(x + dx * len, y)..lineTo(x + dx * r, y)
        ..arcToPoint(Offset(x, y + dy * r),
            radius: const Radius.circular(r),
            clockwise: dx * dy < 0 ? false : true)
        ..lineTo(x, y + dy * len), p);
    }
    corner(0, 0, 1, 1); corner(size.width, 0, -1, 1);
    corner(0, size.height, 1, -1); corner(size.width, size.height, -1, -1);
  }
  @override bool shouldRepaint(_CornerPainter o) => o.color != color;
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label; final IconData icon;
  final Color color, textColor;
  const _StatusChip({super.key, required this.label, required this.icon,
      required this.color, required this.textColor});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(color: color,
        borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: textColor), const SizedBox(width: 7),
      Text(label, style: GoogleFonts.outfit(
          fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
    ]),
  );
}

// ── Results bottom sheet ──────────────────────────────────────────────────────
class _ResultsSheet extends StatelessWidget {
  final Uint8List scannedBytes;
  final List<Product> products;
  final Color accent;
  final bool isDark;
  final VoidCallback onScanAgain;
  final ValueChanged<Product> onSelectProduct;

  const _ResultsSheet({
    required this.scannedBytes, required this.products,
    required this.accent, required this.isDark,
    required this.onScanAgain, required this.onSelectProduct,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25),
              blurRadius: 30)],
        ),
        child: Column(children: [

          // Handle
          Container(width: 40, height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 16),
              decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2))),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(scannedBytes,
                    width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('scan.similar_items'.tr(),
                      style: GoogleFonts.rufina(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.inkBlack)),
                  Text('scan.matches'.tr(args: [products.length.toString()]),
                      style: GoogleFonts.outfit(fontSize: 12,
                          color: isDark ? AppColors.paleText : AppColors.inkGrey)),
                ],
              )),
              GestureDetector(
                onTap: onScanAgain,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 14, color: accent),
                    const SizedBox(width: 5),
                    Text('scan.rescan'.tr(), style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                  ]),
                ),
              ),
            ]),
          ),

          const Divider(height: 1),

          Expanded(
            child: GridView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => _ProductCard(
                product: products[i], accent: accent, isDark: isDark,
                onTap: () => onSelectProduct(products[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.accent,
      required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2320) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: CdnImage(product.image, fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                    color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                    child: const Icon(Icons.image, color: Colors.grey, size: 40))),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (product.shopName != null)
                Row(children: [
                  Icon(Icons.storefront_rounded, size: 10, color: accent),
                  const SizedBox(width: 3),
                  Expanded(child: Text(product.shopName!,
                      style: GoogleFonts.outfit(fontSize: 10,
                          color: accent, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              const SizedBox(height: 2),
              Text(product.name,
                  style: GoogleFonts.outfit(fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(product.price, style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
            ]),
          ),
        ]),
      ),
    );
  }
}
