import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pyin_mal_app/services/tps.dart';

void main() {
  group('ThinPlateSpline', () {
    // The defining property: every source control point must land EXACTLY on
    // its destination. If this fails, garments won't pin to body landmarks.
    test('interpolates control points exactly', () {
      final src = [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
        const Offset(0, 100),
        const Offset(50, 50),
      ];
      final dst = [
        const Offset(10, 5),
        const Offset(130, 20),
        const Offset(120, 140),
        const Offset(-5, 110),
        const Offset(70, 60),
      ];

      final tps = ThinPlateSpline(src, dst);
      for (int i = 0; i < src.length; i++) {
        final out = tps.transform(src[i]);
        expect((out - dst[i]).distance, lessThan(1e-6),
            reason: 'control point $i did not map onto its destination');
      }
    });

    // A pure affine target (translate + scale) has no bending — TPS should
    // reproduce the affine map everywhere, not just at control points.
    test('reproduces an affine map between control points', () {
      Offset affine(Offset p) => Offset(2 * p.dx + 30, 1.5 * p.dy - 10);

      final src = [
        const Offset(0, 0),
        const Offset(200, 0),
        const Offset(200, 200),
        const Offset(0, 200),
      ];
      final dst = src.map(affine).toList();
      final tps = ThinPlateSpline(src, dst);

      // Sample interior points that are NOT control points.
      for (final p in [
        const Offset(50, 50),
        const Offset(137, 88),
        const Offset(10, 190),
      ]) {
        final out = tps.transform(p);
        expect((out - affine(p)).distance, lessThan(1e-3),
            reason: 'affine not reproduced at $p');
      }
    });

    // Smoothness / locality sanity: nudging one destination point should move
    // a nearby sample more than a far one.
    test('warp is local — nearby points move more than distant ones', () {
      final src = [
        const Offset(0, 0),
        const Offset(300, 0),
        const Offset(300, 300),
        const Offset(0, 300),
        const Offset(150, 150),
      ];
      final flat = [
        const Offset(0, 0),
        const Offset(300, 0),
        const Offset(300, 300),
        const Offset(0, 300),
        const Offset(150, 150),
      ];
      // Same, but pull the center control point 40px to the right.
      final pulled = List<Offset>.from(flat);
      pulled[4] = const Offset(190, 150);

      final base = ThinPlateSpline(src, flat);
      final warped = ThinPlateSpline(src, pulled);

      final near = const Offset(160, 150); // close to the moved point
      final far = const Offset(20, 20); // near a corner that didn't move

      final nearShift =
          (warped.transform(near) - base.transform(near)).distance;
      final farShift = (warped.transform(far) - base.transform(far)).distance;

      // TPS is a global interpolant, so a far point still shifts slightly when
      // a control point moves — but far should move much less than near, and
      // only a small fraction of the 40px pull.
      expect(nearShift, greaterThan(farShift));
      expect(farShift, lessThan(nearShift * 0.5),
          reason: 'far corner should move much less than the nearby point');
    });

    test('handles a realistic shoulders+hips control set without NaN', () {
      // Rough garment anchors (image px) → body landmarks (screen px).
      final src = [
        const Offset(200, 40), // neck
        const Offset(80, 100), // lShoulder
        const Offset(320, 100), // rShoulder
        const Offset(120, 460), // lHip
        const Offset(280, 460), // rHip
      ];
      final dst = [
        const Offset(190, 120),
        const Offset(120, 160),
        const Offset(260, 155),
        const Offset(150, 400),
        const Offset(240, 405),
      ];
      final tps = ThinPlateSpline(src, dst);
      final out = tps.transform(const Offset(200, 250));
      expect(out.dx.isFinite && out.dy.isFinite, isTrue);
      expect(out.dx, greaterThan(100));
      expect(out.dx, lessThan(300));
    });
  });
}
