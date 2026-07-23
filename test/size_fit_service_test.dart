import 'package:flutter_test/flutter_test.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/models/item_size_chart.dart';
import 'package:pyin_mal_app/services/size_fit_service.dart';

/// A pants chart (waist + hip, cm) sold in S/M/L.
ItemSizeChart _pantsChart() => const ItemSizeChart(
      productId: 'p1',
      sizes: ['S', 'M', 'L'],
      bands: {
        'waistGirth': {
          'S': SizeBand(68, 74),
          'M': SizeBand(74, 80),
          'L': SizeBand(80, 86),
        },
        'hipGirth': {
          'S': SizeBand(88, 94),
          'M': SizeBand(94, 100),
          'L': SizeBand(100, 106),
        },
      },
    );

BodyMeasurements _body({double? waist, double? hip}) => BodyMeasurements(
      scanId: 't',
      source: 'manual',
      valuesMm: {
        if (waist != null) 'waistGirth': waist * 10,
        if (hip != null) 'hipGirth': hip * 10,
      },
    );

void main() {
  group('SizeFitService.evaluate', () {
    test('waist 82 → M is tight, L fits, L recommended', () {
      final r = SizeFitService.evaluate(
        body: _body(waist: 82, hip: 98),
        chart: _pantsChart(),
      )!;

      expect(r.fitFor('M'), Fit.tight); // 82 ≥ M.max(80)
      expect(r.fitFor('L'), Fit.fits); // 82 in [80,86)
      expect(r.recommendedSize, 'L');
      expect(r.gapCm['M'], closeTo(2, 0.001)); // 82 - 80
    });

    test('the larger dimension binds the verdict (hip drives tight)', () {
      // Waist would fit M (76) but hips exceed even L.max(106) → tight on L,
      // and the hip is what makes it tight.
      final r = SizeFitService.evaluate(
        body: _body(waist: 76, hip: 108),
        chart: _pantsChart(),
      )!;
      expect(r.fitFor('L'), Fit.tight);
      expect(r.bindingMeasurement['L'], 'hipGirth');
    });

    test('small body → S is loose, S still the best available', () {
      final r = SizeFitService.evaluate(
        body: _body(waist: 60, hip: 80),
        chart: _pantsChart(),
      )!;
      expect(r.fitFor('S'), Fit.loose);
      expect(r.recommendedSize, 'S'); // nothing fits; smallest loose wins
    });

    test('sizesOff: choosing M when L is recommended → 1 size too small', () {
      final r = SizeFitService.evaluate(
        body: _body(waist: 82, hip: 98),
        chart: _pantsChart(),
      )!;
      expect(r.sizesOff('M'), 1); // recommend L, chose M
      expect(r.sizesOff('L'), 0);
    });

    test('no overlapping measurement → null (cannot judge)', () {
      final r = SizeFitService.evaluate(
        body: _body(), // empty body
        chart: _pantsChart(),
      );
      expect(r, isNull);
    });
  });

  group('messages & render hints', () {
    test('tight size yields a "too small" message naming the suggestion', () {
      final r = SizeFitService.evaluate(
        body: _body(waist: 82, hip: 98),
        chart: _pantsChart(),
      )!;
      final msg = SizeFitService.mismatchMessage(result: r, chosenSize: 'M');
      expect(msg, isNotNull);
      expect(msg, contains('too small'));
      expect(msg, contains('L')); // suggests the recommended size
    });

    test('a fitting size yields no message and no render hint', () {
      final r = SizeFitService.evaluate(
        body: _body(waist: 82, hip: 98),
        chart: _pantsChart(),
      )!;
      expect(SizeFitService.mismatchMessage(result: r, chosenSize: 'L'), isNull);
      expect(
        SizeFitService.renderHint(result: r, chosenSize: 'L', garment: 'bottoms'),
        isNull,
      );
    });

    test('tight size render hint tells NanoBanana to show it snug/straining', () {
      final r = SizeFitService.evaluate(
        body: _body(waist: 82, hip: 98),
        chart: _pantsChart(),
      )!;
      final hint =
          SizeFitService.renderHint(result: r, chosenSize: 'M', garment: 'bottoms');
      expect(hint, isNotNull);
      expect(hint, contains('bottoms'));
    });
  });
}
