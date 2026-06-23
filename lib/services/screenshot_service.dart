import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Handles capturing a screenshot of the AR camera view and saving it.
///
/// Usage:
///   final key = GlobalKey();          // Attach to RepaintBoundary
///   final svc = ScreenshotService();
///   final path = await svc.capture(key);
class ScreenshotService {
  /// Captures the widget tree wrapped in [boundaryKey]'s RepaintBoundary
  /// and saves the PNG to the app's Documents directory.
  ///
  /// Returns the saved file path on success, or null on failure.
  Future<String?> capture(GlobalKey boundaryKey, {double pixelRatio = 2.0}) async {
    try {
      // Find the render object attached to the RepaintBoundary
      final RenderRepaintBoundary? boundary = boundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('[Screenshot] RepaintBoundary not found');
        return null;
      }

      // Render to image at the given pixel ratio (2x = retina quality)
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/ar_tryon_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      debugPrint('[Screenshot] Saved to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[Screenshot] Error: $e');
      return null;
    }
  }
}
