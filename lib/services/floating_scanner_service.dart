import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:pyin_mal_app/services/ai_scan_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FloatingScannerService — runs in the main Flutter isolate.
//
// Responsibilities:
//   • Start / stop the foreground service (keeps process alive on MIUI)
//   • Show / hide the overlay FAB
//   • Listen for messages from the overlay engine
//   • Handle requestProjection and captureRegion on behalf of the overlay
//     (the overlay engine cannot call platform channels directly, so all
//      native calls go through the main engine via this service)
//   • Send results back to the overlay engine
//
// Usage:
//   await FloatingScannerService.initialize();   ← call once in main()
//   await FloatingScannerService.enable();       ← user enables the FAB
//   await FloatingScannerService.disable();      ← user disables the FAB
// ─────────────────────────────────────────────────────────────────────────────

// Notifier that the app UI listens to for "open product" deep-links from overlay.
final pendingOverlayProduct = ValueNotifier<Map<String, dynamic>?>(null);

@pragma('vm:entry-point')
void _foregroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_ScannerTaskHandler());
}

class _ScannerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {}
  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

class FloatingScannerService {
  static const _captureChannel = MethodChannel('pyin_mal/screen_capture');
  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  // ── Init ──────────────────────────────────────────────────────────────────

  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId:          'pyin_mal_scanner',
        channelName:        'ta chat nhate Scanner',
        channelDescription: 'ta chat nhate Scanner is active — tap to scan',
        onlyAlertOnce:      true,
        playSound:          false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction:   ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
      ),
    );

    // Listen for messages from the overlay engine (subscription kept alive by stream)
    FlutterOverlayWindow.overlayListener.listen(_handleOverlayMessage);
  }

  // ── Enable / disable ──────────────────────────────────────────────────────

  static Future<bool> enable() async {
    // Check overlay permission
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (granted != true) {
      debugPrint('FloatingScannerService: overlay permission not granted');
      return false;
    }

    // Start foreground service (ignore if already running)
    try {
      final result = await FlutterForegroundTask.startService(
        serviceId:         1,
        notificationTitle: 'ta chat nhate Scanner',
        notificationText:  'ta chat nhate Scanner is active — tap to scan',
        callback:          _foregroundTaskCallback,
      );
      debugPrint('FloatingScannerService: startService result = $result');
    } catch (e) {
      // ServiceAlreadyStartedException is fine — service is running
      debugPrint('FloatingScannerService: startService error (may be already running): $e');
    }

    // Show the overlay FAB (80×80 dp, right edge, draggable)
    try {
      await FlutterOverlayWindow.showOverlay(
        height:          80,
        width:           80,
        alignment:       OverlayAlignment.center,
        flag:            OverlayFlag.focusPointer,
        overlayTitle:    'ta chat nhate Scanner',
        overlayContent:  'ta chat nhate Scanner is active — tap to scan',
        enableDrag:      true,
        positionGravity: PositionGravity.auto,
      );
      debugPrint('FloatingScannerService: showOverlay called');
    } catch (e) {
      debugPrint('FloatingScannerService: showOverlay error: $e');
      return false;
    }

    _enabled = true;
    return true;
  }

  static Future<void> disable() async {
    _enabled = false;

    // Close overlay
    if (await FlutterOverlayWindow.isActive() == true) {
      await FlutterOverlayWindow.closeOverlay();
    }

    // Release MediaProjection
    try {
      await _captureChannel.invokeMethod('releaseProjection');
    } catch (_) {}

    // Stop foreground service
    await FlutterForegroundTask.stopService();
  }

  // ── Overlay message handler ───────────────────────────────────────────────

  static Future<void> _handleOverlayMessage(dynamic raw) async {
    if (raw == null) return;
    final msg = raw is String
        ? (jsonDecode(raw) as Map<String, dynamic>)
        : raw as Map<String, dynamic>;

    switch (msg['action'] as String?) {

      case 'requestProjection':
        bool granted = false;
        try {
          final result = await _captureChannel
              .invokeMethod<bool>('requestProjection')
              .timeout(const Duration(seconds: 60));
          granted = result ?? false;
        } catch (e) {
          debugPrint('FloatingScannerService: requestProjection error: $e');
        }
        await FlutterOverlayWindow.shareData(
            jsonEncode({'action': 'projectionResult', 'granted': granted}));
        break;

      case 'captureRegion':
        await _captureAndIdentify(
          x: (msg['x'] as num).toInt(),
          y: (msg['y'] as num).toInt(),
          w: (msg['w'] as num).toInt(),
          h: (msg['h'] as num).toInt(),
        );
        break;

      case 'openProduct':
        // Store for the main app to navigate to when it comes to foreground
        pendingOverlayProduct.value = Map<String, dynamic>.from(msg);
        // Bring main app to foreground via native channel
        try { await _captureChannel.invokeMethod('launchApp'); } catch (_) {}
        break;
    }
  }

  // ── Capture + identify ────────────────────────────────────────────────────

  static Future<void> _captureAndIdentify({
    required int x, required int y, required int w, required int h,
  }) async {
    // Notify overlay that capture + AI call is in progress
    await FlutterOverlayWindow.shareData(jsonEncode({'action': 'scanning'}));

    try {
      // 1 — capture region via native
      final bytes = await _captureChannel
          .invokeMethod<Uint8List>('captureRegion',
              {'x': x, 'y': y, 'w': w, 'h': h})
          .timeout(const Duration(seconds: 15));

      if (bytes == null || bytes.isEmpty) {
        await _sendError('Screen capture failed.');
        return;
      }

      // 2 — identify products (Groq direct → proxy fallback)
      final products = await AiScanService.identifyProducts(bytes)
          .timeout(const Duration(seconds: 35), onTimeout: () => []);

      if (products.isEmpty) {
        await FlutterOverlayWindow.shareData(
            jsonEncode({'action': 'noResults'}));
      } else {
        await FlutterOverlayWindow.shareData(jsonEncode({
          'action': 'showResults',
          'products': products.map((p) => {
            'id':          p.id,
            'name':        p.name,
            'price':       p.price,
            'image':       p.image,
            'brand':       p.brand,
            'category':    p.category,
            'description': p.description,
            'shopName':    p.shopName,
          }).toList(),
        }));
      }
    } catch (e) {
      debugPrint('FloatingScannerService: captureAndIdentify error: $e');
      await _sendError('Scan error. Please try again.');
    }
  }

  static Future<void> _sendError(String msg) async {
    await FlutterOverlayWindow.shareData(
        jsonEncode({'action': 'scanError', 'message': msg}));
  }
}
