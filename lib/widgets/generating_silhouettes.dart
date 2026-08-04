import 'package:flutter/material.dart';

/// Which silhouette the particle cloud forms while an AI job runs.
enum GeneratingSilhouette {
  /// Long-sleeve top — outfit try-on.
  shirt,

  /// Full body — body scan / measurement.
  person,

  /// Head, hair volume and shoulders — hair try-on and Hair 360.
  head,
}

/// Vector outlines for [GeneratingSilhouette], authored in a 0..100 box and
/// scaled to fit whatever area the overlay gets.
///
/// These are deliberately hand-drawn paths rather than masks derived from the
/// real product photo: catalog images are photographs with a background, so
/// thresholding one yields a rounded blob instead of a garment. A clean vector
/// always reads as clothing, at any size, with no decode step.
abstract final class GeneratingSilhouettes {
  /// Returns the outline for [kind], scaled to fill [size] while keeping its
  /// aspect ratio and staying centred.
  static Path build(GeneratingSilhouette kind, Size size) {
    final path = switch (kind) {
      GeneratingSilhouette.shirt => _shirt(),
      GeneratingSilhouette.person => _person(),
      GeneratingSilhouette.head => _head(),
    };

    final scale = size.shortestSide / 100;
    final dx = (size.width - 100 * scale) / 2;
    final dy = (size.height - 100 * scale) / 2;

    // Column-major affine: uniform scale, then translate into place.
    final m = Matrix4(
      scale, 0, 0, 0, //
      0, scale, 0, 0, //
      0, 0, 1, 0, //
      dx, dy, 0, 1, //
    );
    return path.transform(m.storage);
  }

  /// Long-sleeve top: dipped collar, sloped shoulders, straight hem.
  static Path _shirt() {
    return Path()
      ..moveTo(38, 9)
      // collar dip
      ..quadraticBezierTo(50, 18, 62, 9)
      // right shoulder + sleeve
      ..lineTo(78, 14)
      ..quadraticBezierTo(90, 22, 95, 41)
      ..lineTo(95, 63)
      ..lineTo(78, 63)
      ..lineTo(72, 39)
      // right body seam down to hem
      ..lineTo(74, 92)
      ..lineTo(26, 92)
      // left body seam back up
      ..lineTo(28, 39)
      ..lineTo(22, 63)
      ..lineTo(5, 63)
      ..lineTo(5, 41)
      ..quadraticBezierTo(10, 22, 22, 14)
      ..close();
  }

  /// Standing figure. Head, torso-with-legs and each arm are separate contours
  /// so the arms read as limbs instead of melting into the torso.
  static Path _person() {
    final torso = Path()
      ..moveTo(45, 22)
      ..lineTo(55, 22)
      ..quadraticBezierTo(64, 25, 66, 34)
      ..lineTo(65, 56)
      ..lineTo(63, 97)
      ..lineTo(53, 97)
      ..lineTo(50, 58)
      // inner leg gap
      ..lineTo(47, 97)
      ..lineTo(37, 97)
      ..lineTo(35, 56)
      ..lineTo(34, 34)
      ..quadraticBezierTo(36, 25, 45, 22)
      ..close();

    final rightArm = Path()
      ..moveTo(68, 30)
      ..lineTo(72, 32)
      ..lineTo(78, 62)
      ..lineTo(72, 64)
      ..lineTo(66, 38)
      ..close();

    final leftArm = Path()
      ..moveTo(32, 30)
      ..lineTo(28, 32)
      ..lineTo(22, 62)
      ..lineTo(28, 64)
      ..lineTo(34, 38)
      ..close();

    return Path()
      ..addOval(const Rect.fromLTWH(42, 2.5, 16, 19))
      ..addPath(torso, Offset.zero)
      ..addPath(rightArm, Offset.zero)
      ..addPath(leftArm, Offset.zero);
  }

  /// Head and shoulders in profile, facing right.
  ///
  /// A front-facing head is a featureless oval once it becomes a flat
  /// silhouette — there is no way to show where the hair ends. In profile the
  /// hair mass, brow, nose and chin all land on the outline, so it reads as a
  /// head with a haircut at a glance.
  static Path _head() {
    return Path()
      ..moveTo(34, 70)
      // back of the head — the hair carries the volume here
      ..quadraticBezierTo(18, 44, 30, 20)
      ..quadraticBezierTo(48, 6, 66, 18)
      // forehead
      ..quadraticBezierTo(73, 25, 71, 35)
      // brow, nose, under the nose
      ..lineTo(75, 41)
      ..lineTo(82, 50)
      ..lineTo(70, 52)
      // lips
      ..quadraticBezierTo(75, 57, 69, 60)
      // chin back along the jaw
      ..quadraticBezierTo(68, 67, 55, 70)
      ..lineTo(47, 71)
      // front of the neck
      ..lineTo(47, 77)
      // right shoulder
      ..quadraticBezierTo(80, 80, 86, 97)
      ..lineTo(14, 97)
      // left shoulder back up to the nape
      ..quadraticBezierTo(20, 80, 38, 76)
      ..lineTo(38, 71)
      ..close();
  }
}
