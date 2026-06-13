import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Overlay widgets — rendered inside the system overlay window by a separate
// Flutter engine.  overlayMain() is defined in main.dart (required convention).
//
// Communication via FlutterOverlayWindow.shareData / overlayListener:
//
//  Overlay → Main:
//    {'action': 'requestProjection'}
//    {'action': 'captureRegion', x, y, w, h}
//    {'action': 'openProduct', ...product fields...}
//
//  Main → Overlay:
//    {'action': 'projectionResult', 'granted': bool}
//    {'action': 'scanning'}
//    {'action': 'showResults', 'products': [...]}
//    {'action': 'noResults'}
//    {'action': 'scanError', 'message': '...'}
// ─────────────────────────────────────────────────────────────────────────────

class OverlayApp extends StatelessWidget {
  const OverlayApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(),
        ),
        home: const _OverlayRoot(),
      );
}

// ── State machine ─────────────────────────────────────────────────────────────
enum _OverlayState { fab, crop, scanning, results, error }

class _OverlayRoot extends StatefulWidget {
  const _OverlayRoot();
  @override
  State<_OverlayRoot> createState() => _OverlayRootState();
}

class _OverlayRootState extends State<_OverlayRoot> {
  _OverlayState _state = _OverlayState.fab;
  List<Map<String, dynamic>> _products = [];
  String _errorMsg = '';
  bool _projectionReady      = false;
  bool _waitingForProjection = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen(_handleMessage);
  }

  void _handleMessage(dynamic raw) {
    if (raw == null) return;
    final msg = raw is String
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : raw as Map<String, dynamic>;

    switch (msg['action'] as String?) {
      case 'projectionResult':
        final granted = msg['granted'] == true;
        setState(() { _projectionReady = granted; });
        if (granted && _waitingForProjection) {
          // Auto-proceed to crop now that we have permission
          _waitingForProjection = false;
          _resize(-1, -1);
          setState(() => _state = _OverlayState.crop);
        } else if (!granted) {
          _waitingForProjection = false;
          setState(() {
            _state    = _OverlayState.error;
            _errorMsg = 'Screen capture denied. Tap to retry.';
          });
        }
        break;

      case 'scanning':
        _resize(80, 80);
        setState(() => _state = _OverlayState.scanning);
        break;

      case 'showResults':
        final raw = msg['products'] as List? ?? [];
        setState(() {
          _products = raw.map((e) => e as Map<String, dynamic>).toList();
          _state    = _OverlayState.results;
        });
        _resize(-1, 500);
        break;

      case 'noResults':
        _resize(80, 80);
        setState(() {
          _state    = _OverlayState.error;
          _errorMsg = 'No matching items found.';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _state = _OverlayState.fab);
        });
        break;

      case 'scanError':
        _resize(80, 80);
        setState(() {
          _state    = _OverlayState.error;
          _errorMsg = msg['message'] as String? ?? 'Scan error.';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _state = _OverlayState.fab);
        });
        break;
    }
  }

  // Expand/shrink the overlay window
  Future<void> _resize(int w, int h) async {
    await FlutterOverlayWindow.resizeOverlay(w, h, w == 80);
  }

  // ── FAB tap ───────────────────────────────────────────────────────────────

  Future<void> _onFabTap() async {
    if (!_projectionReady) {
      // Ask main app to show the MediaProjection consent dialog.
      // After the user approves, _handleMessage will auto-proceed to crop.
      _waitingForProjection = true;
      await FlutterOverlayWindow.shareData(
          jsonEncode({'action': 'requestProjection'}));
      return;
    }
    // Expand to full screen for crop selection
    await _resize(-1, -1);
    setState(() => _state = _OverlayState.crop);
  }

  // ── Crop confirmed ────────────────────────────────────────────────────────

  Future<void> _onCropConfirmed(Rect rect, double dpr) async {
    // Convert logical pixels → physical pixels for native capture
    final x = (rect.left   * dpr).round();
    final y = (rect.top    * dpr).round();
    final w = (rect.width  * dpr).round();
    final h = (rect.height * dpr).round();

    await _resize(80, 80);
    setState(() => _state = _OverlayState.scanning);

    await FlutterOverlayWindow.shareData(jsonEncode({
      'action': 'captureRegion',
      'x': x, 'y': y, 'w': w, 'h': h,
    }));
  }

  void _onCropCancelled() {
    _resize(80, 80);
    setState(() => _state = _OverlayState.fab);
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Future<void> _onProductTap(Map<String, dynamic> product) async {
    await FlutterOverlayWindow.shareData(
        jsonEncode({'action': 'openProduct', ...product}));
    _closeResults();
  }

  void _closeResults() {
    _resize(80, 80);
    setState(() { _state = _OverlayState.fab; _products = []; });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _OverlayState.fab      => _FabWidget(onTap: _onFabTap),
      _OverlayState.scanning => const _ScanningWidget(),
      _OverlayState.error    => _ErrorWidget(message: _errorMsg,
                                    onTap: () => setState(() => _state = _OverlayState.fab)),
      _OverlayState.crop     => _CropWidget(
                                    onConfirm: _onCropConfirmed,
                                    onCancel:  _onCropCancelled),
      _OverlayState.results  => _ResultsWidget(
                                    products:      _products,
                                    onProductTap:  _onProductTap,
                                    onClose:       _closeResults,
                                    onRescan: () {
                                      _closeResults();
                                      Future.delayed(
                                        const Duration(milliseconds: 300),
                                        _onFabTap);
                                    }),
    };
  }
}

// ── FAB widget ────────────────────────────────────────────────────────────────
class _FabWidget extends StatelessWidget {
  final VoidCallback onTap;
  const _FabWidget({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1A2F), Color(0xFFC9A96E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.45),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: const Icon(Icons.document_scanner_rounded,
          color: Colors.white, size: 28),
    ),
  );
}

// ── Scanning spinner ──────────────────────────────────────────────────────────
class _ScanningWidget extends StatelessWidget {
  const _ScanningWidget();
  @override
  Widget build(BuildContext context) => Container(
    width: 60, height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF8B1A2F).withOpacity(0.9),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45),
          blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
    ),
  );
}

// ── Error widget ──────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _ErrorWidget({required this.message, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: Colors.redAccent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4),
            blurRadius: 8)],
      ),
      child: const Icon(Icons.error_outline_rounded,
          color: Colors.redAccent, size: 26),
    ),
  );
}

// ── Crop selection ────────────────────────────────────────────────────────────
class _CropWidget extends StatefulWidget {
  final void Function(Rect rect, double dpr) onConfirm;
  final VoidCallback onCancel;
  const _CropWidget({required this.onConfirm, required this.onCancel});
  @override
  State<_CropWidget> createState() => _CropWidgetState();
}

class _CropWidgetState extends State<_CropWidget> {
  Offset? _start;
  Offset? _end;
  bool    _confirmed = false;

  Rect? get _rect {
    if (_start == null || _end == null) return null;
    return Rect.fromPoints(_start!, _end!);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dpr  = MediaQuery.of(context).devicePixelRatio;
    final rect = _rect;

    return GestureDetector(
      onPanStart:  (d) => setState(() { _start = d.localPosition; _end = d.localPosition; }),
      onPanUpdate: (d) => setState(() => _end = d.localPosition),
      onPanEnd:    (_) { /* user lifted finger – show confirm */ },
      child: SizedBox.expand(
        child: Stack(children: [
          // Dim overlay with cutout
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _DimPainter(rect: rect),
          ),

          // Instructions
          if (rect == null)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.touch_app_rounded, color: Colors.white70, size: 48),
                const SizedBox(height: 12),
                Text('Drag to select clothing item',
                    style: GoogleFonts.outfit(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),

          // Confirm / Cancel buttons
          if (rect != null && !_confirmed)
            Positioned(
              bottom: 60,
              left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _CropButton(
                  icon: Icons.close_rounded, label: 'Cancel',
                  color: Colors.white24,
                  onTap: widget.onCancel,
                ),
                const SizedBox(width: 24),
                _CropButton(
                  icon: Icons.check_circle_outline_rounded, label: 'Scan',
                  color: const Color(0xFF8B1A2F),
                  onTap: () {
                    setState(() => _confirmed = true);
                    widget.onConfirm(rect, dpr);
                  },
                ),
              ]),
            ),

          // Top-left cancel
          Positioned(
            top: 48, left: 16,
            child: GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DimPainter extends CustomPainter {
  final Rect? rect;
  _DimPainter({this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withOpacity(0.6);
    final r = rect;
    if (r == null) {
      canvas.drawRect(Offset.zero & size, dim);
    } else {
      canvas.drawPath(
        Path()
          ..addRect(Offset.zero & size)
          ..addRect(r)
          ..fillType = PathFillType.evenOdd,
        dim,
      );
      // Selection border
      canvas.drawRect(r, Paint()
        ..color = const Color(0xFFC9A96E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(_DimPainter old) => old.rect != rect;
}

class _CropButton extends StatelessWidget {
  final IconData icon; final String label;
  final Color color; final VoidCallback onTap;
  const _CropButton({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.outfit(color: Colors.white,
            fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    ),
  );
}

// ── Smart image widget ────────────────────────────────────────────────────────
// Local products use asset paths; OpenCart products use HTTPS URLs.
class _ProductImage extends StatelessWidget {
  final String image;
  const _ProductImage({required this.image});
  @override
  Widget build(BuildContext context) {
    final fallback = Container(color: const Color(0xFF3D3330),
        child: const Icon(Icons.image, color: Colors.grey, size: 36));
    if (image.isEmpty) return fallback;
    if (image.startsWith('http')) {
      return Image.network(image, fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (_, __, ___) => fallback);
    }
    return Image.asset(image, fit: BoxFit.cover, width: double.infinity,
        errorBuilder: (_, __, ___) => fallback);
  }
}

// ── Results panel ─────────────────────────────────────────────────────────────
class _ResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final void Function(Map<String, dynamic>) onProductTap;
  final VoidCallback onClose;
  final VoidCallback onRescan;
  const _ResultsWidget({
    required this.products, required this.onProductTap,
    required this.onClose, required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 24)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2))),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(child: Text('Similar Items Found',
                  style: GoogleFonts.rufina(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 16))),
              GestureDetector(
                onTap: onRescan,
                child: const Icon(Icons.refresh_rounded, color: Color(0xFFC9A96E), size: 22),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
              ),
            ]),
          ),

          // Product cards
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _ResultCard(
                product: products[i],
                onTap: () => onProductTap(products[i]),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _ResultCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = product['image'] as String? ?? '';
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2320),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: _ProductImage(image: image),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product['name'] as String? ?? '',
                    style: GoogleFonts.outfit(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product['price'] as String? ?? '',
                    style: GoogleFonts.outfit(color: const Color(0xFFC9A96E),
                        fontWeight: FontWeight.bold, fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
