import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // for compute()
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as imgLib;
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

// ── Top-level isolate function (must be outside class) ────────────────────────
Uint8List? _convertYuvIsolate(Map<String, dynamic> data) {
  try {
    final int width = data['width'] as int;
    final int height = data['height'] as int;
    final int formatIndex = data['format'] as int;

    imgLib.Image converted;

    if (formatIndex == ImageFormatGroup.bgra8888.index) {
      final Uint8List bytes = data['plane0'] as Uint8List;
      converted = imgLib.Image.fromBytes(
        width: width,
        height: height,
        bytes: bytes.buffer,
        order: imgLib.ChannelOrder.bgra,
      );
    } else {
      // YUV420
      final Uint8List yBytes = data['plane0'] as Uint8List;
      final Uint8List uBytes = data['plane1'] as Uint8List;
      final Uint8List vBytes = data['plane2'] as Uint8List;
      final int yRowStride = data['yRowStride'] as int;
      final int uvRowStride = data['uvRowStride'] as int;
      final int uvPixelStride = data['uvPixelStride'] as int;

      converted = imgLib.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIdx = y * yRowStride + x;
          final int uvIdx =
              (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          final int yv = yBytes[yIdx];
          final int uv = uBytes[uvIdx] - 128;
          final int vv = vBytes[uvIdx] - 128;

          final int r = (yv + 1.402 * vv).round().clamp(0, 255);
          final int g =
              (yv - 0.344136 * uv - 0.714136 * vv).round().clamp(0, 255);
          final int b = (yv + 1.772 * uv).round().clamp(0, 255);

          converted.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return Uint8List.fromList(imgLib.encodeJpg(converted, quality: 65));
  } catch (_) {
    return null;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _cameraReady = false;
  bool _isAnalyzing = false;
  bool _resultShown = false;
  bool _isInitializing = false;
  Timer? _autoScanTimer;
  String? _cameraError;

  CameraImage? _latestFrame;

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
    try {
      _controller?.stopImageStream();
    } catch (_) {}
    _controller?.dispose();
    _controller = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only react to paused — NOT inactive (inactive fires on every overlay/notification)
    if (state == AppLifecycleState.paused) {
      _autoScanTimer?.cancel();
      _disposeCamera();
      if (mounted) setState(() => _cameraReady = false);
    } else if (state == AppLifecycleState.resumed && !_cameraReady && !_isInitializing) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera found.');
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        ResolutionPreset.low, // low = ~352×288, fast conversion
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      // Start image stream — grab frames without takePicture()
      await controller.startImageStream((CameraImage img) {
        // Just store the latest frame; never block here
        _latestFrame = img;
      });

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _cameraReady = true;
      });

      _startAutoScan();
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Could not start camera.');
    } finally {
      _isInitializing = false;
    }
  }

  void _startAutoScan() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isAnalyzing && !_resultShown) _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_isAnalyzing || _resultShown) return;
    final frame = _latestFrame;
    if (frame == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // Build the data map to pass to the isolate (copy bytes off the camera object)
      final Map<String, dynamic> frameData = {
        'width': frame.width,
        'height': frame.height,
        'format': frame.format.group.index,
        'plane0': Uint8List.fromList(frame.planes[0].bytes),
        'yRowStride': frame.planes[0].bytesPerRow,
      };
      if (frame.planes.length >= 3) {
        frameData['plane1'] = Uint8List.fromList(frame.planes[1].bytes);
        frameData['plane2'] = Uint8List.fromList(frame.planes[2].bytes);
        frameData['uvRowStride'] = frame.planes[1].bytesPerRow;
        frameData['uvPixelStride'] = frame.planes[1].bytesPerPixel ?? 1;
      }

      // Run heavy YUV conversion in background isolate — never blocks UI
      final bytes = await compute(_convertYuvIsolate, frameData);

      if (bytes == null) {
        if (mounted) setState(() => _isAnalyzing = false);
        return;
      }

      final product = await _identifyProduct(bytes)
          .timeout(const Duration(seconds: 15), onTimeout: () => null);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      if (product != null) {
        setState(() => _resultShown = true);
        _autoScanTimer?.cancel();
        _showResultSheet(product);
      }
    } catch (_) {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<Product?> _identifyProduct(Uint8List imageBytes) async {
    final productsContext = ProductRepository.allProducts.map((p) {
      return '- ID: "${p.id}" | Name: "${p.name}" | Category: ${p.category} | Brand: ${p.brand}';
    }).join('\n');

    final prompt = '''
You are a fashion AI for the Pyin Mal app. Analyze the clothing item in this image and find the best match from our product catalog.

Available products:
$productsContext

Instructions:
1. Identify the type of clothing, color, and style in the image.
2. Find the closest matching product from the list above.
3. Return ONLY valid JSON, no markdown, no code blocks:
{"matched_product_id": "<product id or null>", "confidence": "<high|medium|low>"}

If no product matches, set matched_product_id to null.
''';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final response = await model.generateContent([
      Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
    ]);

    final raw = response.text;
    if (raw == null || raw.isEmpty) return null;

    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final id = json['matched_product_id'];
    if (id == null || id.toString() == 'null' || id.toString().isEmpty) {
      return null;
    }
    return ProductRepository.getProductById(id.toString());
  }

  void _showResultSheet(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ResultSheet(
        product: product,
        accent: accent,
        isDark: isDark,
        onViewProduct: () {
          Navigator.pop(context);
          Navigator.push(
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
        },
        onScanAgain: () {
          Navigator.pop(context);
          setState(() => _resultShown = false);
          _startAutoScan();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Camera preview ────────────────────────────────────────────
            if (_cameraReady && _controller != null)
              Positioned.fill(child: CameraPreview(_controller!))
            else if (_cameraError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(_cameraError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 14)),
                ),
              )
            else
              const Center(
                  child: CircularProgressIndicator(color: Colors.white)),

            // ── Scan frame overlay ────────────────────────────────────────
            if (_cameraReady)
              Positioned.fill(
                child: _ScanFrameOverlay(
                    isAnalyzing: _isAnalyzing, accent: accent),
              ),

            // ── Top bar ───────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('Smart Scan',
                        style: GoogleFonts.rufina(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            if (_cameraReady)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isAnalyzing
                            ? _StatusChip(
                                key: const ValueKey('analyzing'),
                                label: 'Analyzing...',
                                icon: Icons.auto_awesome_rounded,
                                color: accent,
                                textColor: Colors.white,
                              )
                            : _StatusChip(
                                key: const ValueKey('idle'),
                                label: 'Auto-scanning every 5s',
                                icon: Icons.radar_rounded,
                                color: Colors.white.withOpacity(0.15),
                                textColor: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Manual shutter button
                      GestureDetector(
                        onTap: _isAnalyzing ? null : _analyzeCurrentFrame,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAnalyzing
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white,
                            border: Border.all(
                                color: accent.withOpacity(0.6), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _isAnalyzing
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                      color: accent, strokeWidth: 2.5),
                                )
                              : Icon(Icons.document_scanner_rounded,
                                  color: accent, size: 30),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Tap to scan now',
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Scan frame corners ────────────────────────────────────────────────────────
class _ScanFrameOverlay extends StatefulWidget {
  final bool isAnalyzing;
  final Color accent;
  const _ScanFrameOverlay({required this.isAnalyzing, required this.accent});

  @override
  State<_ScanFrameOverlay> createState() => _ScanFrameOverlayState();
}

class _ScanFrameOverlayState extends State<_ScanFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.72;
    final centerY = size.height * 0.42;

    return Stack(
      children: [
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _VignettePainter(
            frameSize: frameSize,
            center: Offset(size.width / 2, centerY),
          ),
        ),
        Positioned(
          left: (size.width - frameSize) / 2,
          top: centerY - frameSize / 2,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) {
              final color = widget.isAnalyzing
                  ? Color.lerp(widget.accent, Colors.white, _pulse.value)!
                  : Colors.white;
              return SizedBox(
                width: frameSize,
                height: frameSize,
                child: CustomPaint(painter: _CornerPainter(color: color)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VignettePainter extends CustomPainter {
  final double frameSize;
  final Offset center;
  _VignettePainter({required this.frameSize, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: frameSize, height: frameSize),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(_VignettePainter old) =>
      old.frameSize != frameSize || old.center != center;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    const r = 10.0;

    void corner(double x, double y, double dx, double dy) {
      final path = Path();
      path.moveTo(x + dx * len, y);
      path.lineTo(x + dx * r, y);
      path.arcToPoint(Offset(x, y + dy * r),
          radius: const Radius.circular(r),
          clockwise: dx * dy < 0 ? false : true);
      path.lineTo(x, y + dy * len);
      canvas.drawPath(path, paint);
    }

    corner(0, 0, 1, 1);
    corner(size.width, 0, -1, 1);
    corner(0, size.height, 1, -1);
    corner(size.width, size.height, -1, -1);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 7),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ],
      ),
    );
  }
}

// ── Result bottom sheet ───────────────────────────────────────────────────────
class _ResultSheet extends StatelessWidget {
  final Product product;
  final Color accent;
  final bool isDark;
  final VoidCallback onViewProduct;
  final VoidCallback onScanAgain;

  const _ResultSheet({
    required this.product,
    required this.accent,
    required this.isDark,
    required this.onViewProduct,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: accent, size: 18),
                const SizedBox(width: 8),
                Text('Match Found!',
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 90, height: 90,
                    child: CdnImage(product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.creamAlt,
                              child: const Icon(Icons.image,
                                  color: Colors.grey),
                            )),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.shopName != null)
                        Row(children: [
                          Icon(Icons.storefront_rounded,
                              size: 13, color: accent),
                          const SizedBox(width: 5),
                          Text(product.shopName!,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: accent,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      const SizedBox(height: 4),
                      Text(product.name,
                          style: GoogleFonts.rufina(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.inkBlack),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(product.price,
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accent)),
                      if (product.description != null) ...[
                        const SizedBox(height: 4),
                        Text(product.description!,
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.paleText
                                    : AppColors.inkGrey,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onScanAgain,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: accent.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Scan Again',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.inkBlack)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('View Item',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
