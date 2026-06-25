import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

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

const _kBurgundy = Color(0xFF8B1A2F);
const _kGold     = Color(0xFFC9A96E);
const _kDark     = Color(0xFF1C1A1A);
const _kCard     = Color(0xFF2A2320);

class OverlayApp extends StatelessWidget {
  const OverlayApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(),
          textTheme: Typography.material2021().white.apply(
            decoration: TextDecoration.none,
          ),
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
        _resize(90, 90);
        setState(() => _state = _OverlayState.scanning);
        break;

      case 'showResults':
        final raw = msg['products'] as List? ?? [];
        setState(() {
          _products = raw.map((e) => e as Map<String, dynamic>).toList();
          _state    = _OverlayState.results;
        });
        _resize(-1, 520);
        break;

      case 'noResults':
        _resize(90, 90);
        setState(() {
          _state    = _OverlayState.error;
          _errorMsg = 'No matching items found.';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _state = _OverlayState.fab);
        });
        break;

      case 'scanError':
        _resize(90, 90);
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

  Future<void> _resize(int w, int h) async {
    await FlutterOverlayWindow.resizeOverlay(w, h, w == 90 && h == 90);
  }

  // ── FAB tap ───────────────────────────────────────────────────────────────

  Future<void> _onFabTap() async {
    debugPrint('overlayMain: FAB tapped');
    if (!_projectionReady) {
      if (_waitingForProjection) return;
      _waitingForProjection = true;
      debugPrint('overlayMain: sending requestProjection');
      FlutterOverlayWindow.shareData(
          jsonEncode({'action': 'requestProjection'}));
      debugPrint('overlayMain: shareData sent (fire-and-forget)');
      setState(() {});
      return;
    }
    await _resize(-1, -1);
    setState(() => _state = _OverlayState.crop);
  }

  // ── Crop confirmed ────────────────────────────────────────────────────────

  Future<void> _onCropConfirmed(Rect rect, double dpr) async {
    final x = (rect.left   * dpr).round();
    final y = (rect.top    * dpr).round();
    final w = (rect.width  * dpr).round();
    final h = (rect.height * dpr).round();

    await _resize(90, 90);
    setState(() => _state = _OverlayState.scanning);

    FlutterOverlayWindow.shareData(jsonEncode({
      'action': 'captureRegion',
      'x': x, 'y': y, 'w': w, 'h': h,
    }));
  }

  void _onCropCancelled() {
    _resize(90, 90);
    setState(() => _state = _OverlayState.fab);
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Future<void> _onProductTap(Map<String, dynamic> product) async {
    FlutterOverlayWindow.shareData(
        jsonEncode({'action': 'openProduct', ...product}));
    _closeResults();
  }

  void _closeResults() {
    _resize(90, 90);
    setState(() { _state = _OverlayState.fab; _products = []; });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: switch (_state) {
      _OverlayState.fab      => _FabWidget(
                                    onTap:   _onFabTap,
                                    waiting: _waitingForProjection),
      _OverlayState.scanning => const _ScanningWidget(),
      _OverlayState.error    => _ErrorWidget(
                                    message: _errorMsg,
                                    onTap: () => setState(() => _state = _OverlayState.fab)),
      _OverlayState.crop     => _CropWidget(
                                    onConfirm: _onCropConfirmed,
                                    onCancel:  _onCropCancelled),
      _OverlayState.results  => _ResultsWidget(
                                    products:     _products,
                                    onProductTap: _onProductTap,
                                    onClose:      _closeResults,
                                    onRescan: () {
                                      _closeResults();
                                      Future.delayed(
                                        const Duration(milliseconds: 300),
                                        _onFabTap);
                                    }),
    });
  }
}

// ── FAB widget ────────────────────────────────────────────────────────────────
class _FabWidget extends StatefulWidget {
  final VoidCallback onTap;
  final bool waiting;
  const _FabWidget({required this.onTap, this.waiting = false});
  @override
  State<_FabWidget> createState() => _FabWidgetState();
}

class _FabWidgetState extends State<_FabWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseScale;
  late final Animation<double>   _pulseOpacity;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseScale   = Tween<double>(begin: 1.0, end: 1.30)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(begin: 0.45, end: 0.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:  (_) => setState(() => _pressed = true),
      onTapUp:    (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 90, height: 90,
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ring
                if (!widget.waiting)
                  Transform.scale(
                    scale: _pulseScale.value,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kGold.withOpacity(_pulseOpacity.value),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                // Button body
                AnimatedScale(
                  scale: _pressed ? 0.90 : 1.0,
                  duration: const Duration(milliseconds: 80),
                  child: Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AC72), _kGold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kGold.withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: widget.waiting
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: Color(0xFF3D2810), strokeWidth: 2.5),
                          )
                        : const Icon(Icons.document_scanner_rounded,
                            color: Color(0xFF3D2810), size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scanning spinner ──────────────────────────────────────────────────────────
class _ScanningWidget extends StatefulWidget {
  const _ScanningWidget();
  @override
  State<_ScanningWidget> createState() => _ScanningWidgetState();
}

class _ScanningWidgetState extends State<_ScanningWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 90, height: 90,
    child: Center(
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kDark.withOpacity(0.88),
          boxShadow: [
            BoxShadow(color: _kBurgundy.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            painter: _ArcSpinPainter(progress: _ctrl.value),
          ),
        ),
      ),
    ),
  );
}

class _ArcSpinPainter extends CustomPainter {
  final double progress;
  const _ArcSpinPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width / 2) - 8;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Faint track
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Spinning gold arc
    final arcPaint = Paint()
      ..color = _kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      progress * 2 * math.pi - math.pi / 2,
      math.pi * 1.2,
      false,
      arcPaint,
    );

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy), 3.5,
      Paint()..color = _kGold,
    );
  }

  @override
  bool shouldRepaint(_ArcSpinPainter old) => old.progress != progress;
}

// ── Error widget ──────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  const _ErrorWidget({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 90, height: 90,
      child: Center(
        child: Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kDark.withOpacity(0.92),
            border: Border.all(color: Colors.redAccent.withOpacity(0.7), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
            ],
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 26),
        ),
      ),
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
      onPanStart:  (d) => setState(() {
        _start = d.localPosition; _end = d.localPosition;
      }),
      onPanUpdate: (d) => setState(() => _end = d.localPosition),
      onPanEnd:    (_) {},
      child: SizedBox.expand(
        child: Stack(children: [
          // Dim + crop cutout
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _CropPainter(rect: rect),
          ),

          // Instructions (before selection)
          if (rect == null)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.touch_app_rounded,
                        color: _kGold.withOpacity(0.9), size: 36),
                    const SizedBox(height: 10),
                    const Text('Drag to select clothing',
                        style: TextStyle(color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Draw a box around the item to scan',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                ),
              ]),
            ),

          // Confirm / Cancel
          if (rect != null && !_confirmed)
            Positioned(
              bottom: 56,
              left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _CropButton(
                  icon: Icons.close_rounded, label: 'Cancel',
                  color: Colors.black.withOpacity(0.6),
                  borderColor: Colors.white24,
                  onTap: widget.onCancel,
                ),
                const SizedBox(width: 16),
                _CropButton(
                  icon: Icons.document_scanner_rounded, label: 'Scan',
                  color: _kBurgundy,
                  borderColor: _kGold.withOpacity(0.5),
                  onTap: () {
                    setState(() => _confirmed = true);
                    widget.onConfirm(rect, dpr);
                  },
                ),
              ]),
            ),

          // Back button
          Positioned(
            top: 52, left: 16,
            child: GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect? rect;
  _CropPainter({this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withOpacity(0.58);
    final r = rect;
    if (r == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }

    // Dim with cutout
    canvas.drawPath(
      Path()
        ..addRect(Offset.zero & size)
        ..addRect(r)
        ..fillType = PathFillType.evenOdd,
      dim,
    );

    // Thin white border
    canvas.drawRect(r,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);

    // Gold corner brackets
    const cLen = 22.0;
    final cp = Paint()
      ..color = _kGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(cLen, 0), cp);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, cLen), cp);
    // Top-right
    canvas.drawLine(r.topRight, r.topRight + const Offset(-cLen, 0), cp);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, cLen), cp);
    // Bottom-left
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(cLen, 0), cp);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -cLen), cp);
    // Bottom-right
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(-cLen, 0), cp);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -cLen), cp);
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.rect != rect;
}

class _CropButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;
  const _CropButton({
    required this.icon, required this.label,
    required this.color, required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    ),
  );
}

// ── Product image ─────────────────────────────────────────────────────────────
class _ProductImage extends StatelessWidget {
  final String image;
  const _ProductImage({required this.image});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFF3D3330),
      child: const Icon(Icons.image_outlined, color: Colors.white24, size: 36),
    );
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
          color: _kDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 32)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Drag handle
          Container(
            width: 32, height: 3,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: _kGold, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Similar Items Found',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              // Rescan
              GestureDetector(
                onTap: onRescan,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: _kGold, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Close
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                ),
              ),
              const SizedBox(width: 8),
            ]),
          ),

          // Divider
          Container(height: 0.5, color: Colors.white12,
              margin: const EdgeInsets.only(bottom: 14)),

          // Cards
          SizedBox(
            height: 220,
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
    final name  = product['name']  as String? ?? '';
    final price = product['price'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(image: image),
                    // Subtle gradient at bottom for text legibility
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent,
                                     Colors.black.withOpacity(0.35)],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Text
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 11),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(children: [
                  Expanded(
                    child: Text(price,
                        style: const TextStyle(color: _kGold,
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kBurgundy.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('View',
                        style: TextStyle(color: Colors.white,
                            fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
