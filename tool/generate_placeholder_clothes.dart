// Run this script once to generate placeholder clothing PNGs.
// Usage: dart run tool/generate_placeholder_clothes.dart
//
// It uses the 'image' package (already in pubspec.yaml) to draw
// simple shirt-shaped images with transparent backgrounds.
// Replace these PNGs with real product cutout images later.

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final outputDir = Directory('assets/clothes');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  // Generate each clothing item
  _generateTShirt('assets/clothes/black_tshirt.png',
      fillR: 30, fillG: 30, fillB: 30);

  _generateHoodie('assets/clothes/white_hoodie.png',
      fillR: 240, fillG: 240, fillB: 240);

  _generateJacket('assets/clothes/blue_jacket.png',
      fillR: 21, fillG: 101, fillB: 192);

  print('✅ Placeholder clothing PNGs generated in assets/clothes/');
}

/// Draws a T-shirt silhouette on a 400×480 transparent canvas.
void _generateTShirt(String path,
    {required int fillR, required int fillG, required int fillB}) {
  const w = 400, h = 480;
  final image = img.Image(width: w, height: h);

  // Fill with transparent
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final color = img.ColorRgba8(fillR, fillG, fillB, 220);

  // T-shirt body polygon points
  final bodyPts = [
    // Left collar
    img.Point(120, 0),
    // Left shoulder → left sleeve
    img.Point(40, 60),
    img.Point(0, 80),
    // Left sleeve-hem
    img.Point(0, 160),
    // Left underarm
    img.Point(48, 160),
    // Left side seam down to hem
    img.Point(48, h),
    // Hem
    img.Point(w - 48, h),
    // Right side seam
    img.Point(w - 48, 160),
    // Right underarm
    img.Point(w, 160),
    // Right sleeve
    img.Point(w, 80),
    // Right shoulder
    img.Point(w - 40, 60),
    // Right collar
    img.Point(w - 120, 0),
  ];

  _fillPolygon(image, bodyPts, color);

  // Collar U curve (draw as filled arc)
  img.fillCircle(image,
      x: w ~/ 2,
      y: 0,
      radius: 44,
      color: img.ColorRgba8(0, 0, 0, 0)); // punch out

  File(path).writeAsBytesSync(img.encodePng(image));
  print('  → $path');
}

/// Draws a hoodie silhouette with a hood on a 400×520 canvas.
void _generateHoodie(String path,
    {required int fillR, required int fillG, required int fillB}) {
  const w = 400, h = 520;
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final color = img.ColorRgba8(fillR, fillG, fillB, 215);

  // Hood (ellipse at the top)
  img.fillCircle(image,
      x: w ~/ 2, y: 30, radius: 110, color: color);

  // Body (same as tshirt but taller)
  final bodyPts = [
    img.Point(110, 60),
    img.Point(36, 70),
    img.Point(0, 90),
    img.Point(0, 180),
    img.Point(50, 180),
    img.Point(50, h),
    img.Point(w - 50, h),
    img.Point(w - 50, 180),
    img.Point(w, 180),
    img.Point(w, 90),
    img.Point(w - 36, 70),
    img.Point(w - 110, 60),
  ];
  _fillPolygon(image, bodyPts, color);

  File(path).writeAsBytesSync(img.encodePng(image));
  print('  → $path');
}

/// Draws a jacket silhouette with lapels on a 400×500 canvas.
void _generateJacket(String path,
    {required int fillR, required int fillG, required int fillB}) {
  const w = 400, h = 500;
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));

  final color = img.ColorRgba8(fillR, fillG, fillB, 220);
  final darkColor = img.ColorRgba8(
      (fillR * 0.7).round(), (fillG * 0.7).round(), (fillB * 0.7).round(), 220);

  // Jacket body
  final bodyPts = [
    img.Point(130, 0),
    img.Point(20, 70),
    img.Point(0, 100),
    img.Point(0, 190),
    img.Point(44, 190),
    img.Point(44, h),
    img.Point(w - 44, h),
    img.Point(w - 44, 190),
    img.Point(w, 190),
    img.Point(w, 100),
    img.Point(w - 20, 70),
    img.Point(w - 130, 0),
  ];
  _fillPolygon(image, bodyPts, color);

  // Left lapel (darker)
  final leftLapel = [
    img.Point(130, 0),
    img.Point(w ~/ 2 - 10, 80),
    img.Point(w ~/ 2 - 10, 160),
    img.Point(90, 80),
  ];
  _fillPolygon(image, leftLapel, darkColor);

  // Right lapel
  final rightLapel = [
    img.Point(w - 130, 0),
    img.Point(w ~/ 2 + 10, 80),
    img.Point(w ~/ 2 + 10, 160),
    img.Point(w - 90, 80),
  ];
  _fillPolygon(image, rightLapel, darkColor);

  File(path).writeAsBytesSync(img.encodePng(image));
  print('  → $path');
}

/// Fills a polygon defined by a list of Point objects.
void _fillPolygon(img.Image image, List<img.Point> pts, img.Color color) {
  if (pts.length < 3) return;

  final minY = pts.map((p) => p.yi).reduce((a, b) => a < b ? a : b);
  final maxY = pts.map((p) => p.yi).reduce((a, b) => a > b ? a : b);

  for (int y = minY; y <= maxY; y++) {
    final intersections = <int>[];
    for (int i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      if ((a.yi <= y && b.yi > y) || (b.yi <= y && a.yi > y)) {
        final x = a.xi +
            ((y - a.yi) * (b.xi - a.xi) / (b.yi - a.yi)).round();
        intersections.add(x);
      }
    }
    intersections.sort();
    for (int i = 0; i + 1 < intersections.length; i += 2) {
      for (int x = intersections[i]; x <= intersections[i + 1]; x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}
