import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as imgLib;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/screens/product_detail_screen.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

// ── Isolate-safe YUV→JPEG conversion ─────────────────────────────────────────
Uint8List? _convertYuvIsolate(Map<String, dynamic> data) {
  try {
    final int width  = data['width']  as int;
    final int height = data['height'] as int;
    final int fmt    = data['format'] as int;
    imgLib.Image img;

    if (fmt == ImageFormatGroup.bgra8888.index) {
      final Uint8List bytes = data['plane0'] as Uint8List;
      img = imgLib.Image.fromBytes(
        width: width, height: height,
        bytes: bytes.buffer, order: imgLib.ChannelOrder.bgra,
      );
    } else {
      // YUV420
      final Uint8List yBytes = data['plane0'] as Uint8List;
      final Uint8List uBytes = data['plane1'] as Uint8List;
      final Uint8List vBytes = data['plane2'] as Uint8List;
      final int yStride  = data['yRowStride']   as int;
      final int uvStride = data['uvRowStride']  as int;
      final int uvPixel  = data['uvPixelStride'] as int;
      img = imgLib.Image(width: width, height: height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yv = yBytes[y * yStride + x];
          final int uv = uBytes[(y ~/ 2) * uvStride + (x ~/ 2) * uvPixel] - 128;
          final int vv = vBytes[(y ~/ 2) * uvStride + (x ~/ 2) * uvPixel] - 128;
          img.setPixelRgb(x, y,
            (yv + 1.402 * vv).round().clamp(0, 255),
            (yv - 0.344136 * uv - 0.714136 * vv).round().clamp(0, 255),
            (yv + 1.772 * uv).round().clamp(0, 255),
          );
        }
      }
    }
    return Uint8List.fromList(imgLib.encodeJpg(img, quality: 65));
  } catch (_) { return null; }
}

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

  // Pre-copied frame data for compute() isolate, throttled to ~2fps
  Map<String, dynamic>? _latestFrameData;
  int _frameCount = 0;

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
    try { _controller?.stopImageStream(); } catch (_) {}
    _controller?.dispose();
    _controller = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoScanTimer?.cancel();
      _isAnalyzing = false;
      _latestFrameData = null;
      _disposeCamera();
      if (mounted) setState(() { _cameraReady = false; });
    } else if (state == AppLifecycleState.resumed &&
        !_cameraReady && !_isInitializing) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _isAnalyzing = false;
    _latestFrameData = null;
    _frameCount = 0;

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

      final ctrl = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await ctrl.initialize();

      // Give Xiaomi's camera extension time to settle after init
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) { ctrl.dispose(); return; }

      // Throttle: copy frame data every ~15 frames (~2fps) to limit GC pressure
      await ctrl.startImageStream((img) {
        _frameCount++;
        if (_frameCount % 15 != 0) return;
        if (_isAnalyzing) return;
        _frameCount = 0;
        try {
          final data = <String, dynamic>{
            'width': img.width, 'height': img.height,
            'format': img.format.group.index,
            'plane0': Uint8List.fromList(img.planes[0].bytes),
            'yRowStride': img.planes[0].bytesPerRow,
          };
          if (img.planes.length >= 3) {
            data['plane1']        = Uint8List.fromList(img.planes[1].bytes);
            data['plane2']        = Uint8List.fromList(img.planes[2].bytes);
            data['uvRowStride']   = img.planes[1].bytesPerRow;
            data['uvPixelStride'] = img.planes[1].bytesPerPixel ?? 1;
          }
          _latestFrameData = data;
        } catch (_) {}
      });

      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _controller = ctrl; _cameraReady = true; });
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
    final frameData = _latestFrameData;
    if (frameData == null) return;

    setState(() => _isAnalyzing = true);

    Uint8List? bytes;
    List<Product> results = [];
    try {
      bytes = await compute(_convertYuvIsolate, frameData);
      if (bytes == null || bytes.isEmpty) return;

      results = await _identifyProducts(bytes)
          .timeout(const Duration(seconds: 25), onTimeout: () => []);
    } catch (_) {
      // finally handles cleanup
    } finally {
      _isAnalyzing = false;
      if (mounted) setState(() {});
    }

    if (!mounted) return;
    if (bytes != null && results.isNotEmpty) {
      setState(() => _resultShown = true);
      _autoScanTimer?.cancel();
      _showResultsSheet(bytes, results);
    }
  }

  // Returns up to 4 ranked similar products
  Future<List<Product>> _identifyProducts(Uint8List imageBytes) async {
    final productsContext = ProductRepository.allProducts.map((p) =>
      '- ID: "${p.id}" | Name: "${p.name}" | Category: ${p.category} | Brand: ${p.brand}'
    ).join('\n');

    final prompt = '''
You are a fashion AI for the Pyin Mal app. Analyze the clothing item in this image.

Available products:
$productsContext

Instructions:
1. Identify the clothing type, color, style, and graphic details in the image.
2. Return the top 1-4 most visually similar products from the list, ranked best match first.
3. Return ONLY valid JSON, no markdown:
{"matched_product_ids": ["id1", "id2", "id3"], "item_type": "<what you see, e.g. black graphic hoodie>"}

Only include IDs that are genuinely similar. Return an empty list if nothing matches.
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
    if (raw == null || raw.isEmpty) return [];

    final cleaned = raw
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
                Text('Smart Scan', style: GoogleFonts.rufina(
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
                            label: 'Identifying... keep phone steady',
                            icon: Icons.auto_awesome_rounded,
                            color: accent, textColor: Colors.white)
                        : _StatusChip(key: const ValueKey('i'),
                            label: 'Auto-scanning every 5s',
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
                  Text('Tap to scan now', style: GoogleFonts.outfit(
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

          // Header row: scanned thumbnail + title + scan again
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(children: [

              // Scanned image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(scannedBytes,
                    width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),

              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Similar Items Found',
                      style: GoogleFonts.rufina(
                          fontSize: 18, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.inkBlack)),
                  Text('${products.length} match${products.length == 1 ? "" : "es"} from catalog',
                      style: GoogleFonts.outfit(fontSize: 12,
                          color: isDark ? AppColors.paleText : AppColors.inkGrey)),
                ],
              )),

              // Scan again button
              GestureDetector(
                onTap: onScanAgain,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 14, color: accent),
                    const SizedBox(width: 5),
                    Text('Rescan', style: GoogleFonts.outfit(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: accent)),
                  ]),
                ),
              ),
            ]),
          ),

          const Divider(height: 1),

          // Results grid
          Expanded(
            child: GridView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => _ProductCard(
                product: products[i],
                accent: accent,
                isDark: isDark,
                onTap: () => onSelectProduct(products[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Product card in results grid ──────────────────────────────────────────────
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

          // Product image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18)),
              child: CdnImage(product.image, fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                      color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                      child: const Icon(Icons.image,
                          color: Colors.grey, size: 40))),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Shop name
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

              // Name
              Text(product.name,
                  style: GoogleFonts.outfit(fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),

              // Price
              Text(product.price, style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold, color: accent)),
            ]),
          ),
        ]),
      ),
    );
  }
}
