// One-time asset cleaner: masks logo_head.png to a clean circle with true
// transparency, removing the baked-in opaque checkerboard background.
//
// Run:  dart run tool/clean_head.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const srcPath = 'assets/images/logo_head.png';
  const backup = 'assets/images/logo_head_original.png';

  final bytes = File(srcPath).readAsBytesSync();
  final src = img.decodePng(bytes);
  if (src == null) {
    stderr.writeln('Could not decode $srcPath');
    exit(1);
  }

  // Keep a one-time backup of the original.
  if (!File(backup).existsSync()) {
    File(backup).writeAsBytesSync(bytes);
  }

  final w = src.width;
  final h = src.height;
  final cx = w / 2.0;
  final cy = h / 2.0;
  // Radius covering the logo circle + its dark border, but inside the
  // square corners where the checkerboard lives. 0.49 of the shorter side.
  final r = (w < h ? w : h) * 0.49;
  final rSq = r * r;
  // Soft edge width (px) for anti-aliasing the mask.
  const feather = 2.0;

  final out = img.Image(width: w, height: h, numChannels: 4);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final dist = (dx * dx + dy * dy);
      final p = src.getPixel(x, y);

      if (dist <= rSq) {
        // Inside circle: keep pixel, but feather the very edge.
        final d = dist.toDouble();
        final edge = r - (d <= 0 ? 0 : _sqrt(d));
        double a = (p.a).toDouble();
        if (edge < feather) {
          a = a * (edge / feather).clamp(0.0, 1.0);
        }
        out.setPixelRgba(x, y, p.r, p.g, p.b, a.round());
      } else {
        // Outside circle: fully transparent.
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  File(srcPath).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Cleaned $srcPath (${w}x$h), backup at $backup');
}

double _sqrt(double v) {
  // Newton's method to avoid importing dart:math just for sqrt.
  if (v <= 0) return 0;
  double x = v;
  for (int i = 0; i < 20; i++) {
    x = 0.5 * (x + v / x);
  }
  return x;
}
