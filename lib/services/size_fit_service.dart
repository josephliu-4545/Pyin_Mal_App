import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/models/item_size_chart.dart';

/// How a given garment size sits on a given body.
enum Fit {
  tight, // body is larger than the size's band on at least one measurement
  fits, // body sits inside the band
  loose, // body is smaller than the size's band on every measurement
}

/// The outcome of comparing one wearer's body against one item's size chart.
class SizeFitResult {
  /// Verdict per label size.
  final Map<String, Fit> perSize;

  /// Per label size: how many cm the body is *outside* that size's band on the
  /// binding measurement (0 when it fits). Positive for both tight and loose —
  /// pair it with [perSize] to know the direction.
  final Map<String, double> gapCm;

  /// The measurement each size's verdict hinges on (the binding one).
  final Map<String, String> bindingMeasurement;

  /// Ordered label sizes (mirrors the chart), smallest → largest.
  final List<String> sizes;

  /// Best size for this body: the smallest size that isn't tight. Null only
  /// when the chart had no usable measurements for this body.
  final String? recommendedSize;

  SizeFitResult({
    required this.perSize,
    required this.gapCm,
    required this.bindingMeasurement,
    required this.sizes,
    required this.recommendedSize,
  });

  Fit? fitFor(String size) => perSize[size];

  /// How many label sizes [chosenSize] is away from [recommendedSize].
  /// Positive → chosen runs small (body is bigger, size up).
  /// Negative → chosen runs big (body is smaller, size down).
  /// Null when either size isn't in the chart.
  int? sizesOff(String chosenSize) {
    if (recommendedSize == null) return null;
    final ci = sizes.indexOf(chosenSize);
    final ri = sizes.indexOf(recommendedSize!);
    if (ci < 0 || ri < 0) return null;
    return ri - ci;
  }
}

/// Compares a wearer's [BodyMeasurements] against an item's [ItemSizeChart].
/// Everything is per-item — no global size assumptions — so an "M" means only
/// what that specific garment's chart says it means.
class SizeFitService {
  /// Evaluates every size in [chart] against [body]. Returns null when the
  /// chart shares no measurement the body actually has (nothing to compare).
  static SizeFitResult? evaluate({
    required BodyMeasurements body,
    required ItemSizeChart chart,
  }) {
    if (chart.isEmpty) return null;

    // Only the measurements present in BOTH the chart and this body are usable.
    final usable = chart.measurements
        .where((m) => body.cm(m) != null)
        .toList(growable: false);
    if (usable.isEmpty) return null;

    final perSize = <String, Fit>{};
    final gapCm = <String, double>{};
    final binding = <String, String>{};

    for (final size in chart.sizes) {
      // Scan every usable measurement once, tracking the worst overshoot
      // (body past band.max → tight) and worst undershoot (body below band.min
      // → loose), each with the measurement that drove it.
      double tightGap = 0;
      String? tightMeasure;
      double looseGap = 0;
      String? looseMeasure;
      bool anyCharted = false;

      for (final measure in usable) {
        final band = chart.bandFor(measure, size);
        if (band == null) continue;
        anyCharted = true;
        final cm = body.cm(measure)!;

        if (cm >= band.maxCm) {
          final gap = cm - band.maxCm;
          if (gap > tightGap) {
            tightGap = gap;
            tightMeasure = measure;
          }
        } else if (cm < band.minCm) {
          final gap = band.minCm - cm;
          if (gap > looseGap) {
            looseGap = gap;
            looseMeasure = measure;
          }
        }
      }

      if (!anyCharted) continue; // size not charted for any usable measurement

      // Rules: tight if body exceeds any band's max; else loose only if it's
      // below every band's min (i.e. never in range); else it fits.
      final Fit verdict;
      final double gap;
      final String bindingMeasure;
      if (tightMeasure != null) {
        verdict = Fit.tight;
        gap = tightGap;
        bindingMeasure = tightMeasure;
      } else if (looseMeasure != null && tightMeasure == null && looseGap > 0 && _allBelowMin(usable, chart, body, size)) {
        verdict = Fit.loose;
        gap = looseGap;
        bindingMeasure = looseMeasure;
      } else {
        verdict = Fit.fits;
        gap = 0;
        bindingMeasure = usable.first;
      }

      perSize[size] = verdict;
      gapCm[size] = double.parse(gap.toStringAsFixed(1));
      binding[size] = bindingMeasure;
    }

    return SizeFitResult(
      perSize: perSize,
      gapCm: gapCm,
      bindingMeasurement: binding,
      sizes: chart.sizes,
      recommendedSize: _recommend(chart.sizes, perSize),
    );
  }

  /// True when the body is below the band minimum on every charted measurement
  /// for [size] — i.e. genuinely loose everywhere, not just on one dimension.
  static bool _allBelowMin(
    List<String> usable,
    ItemSizeChart chart,
    BodyMeasurements body,
    String size,
  ) {
    for (final measure in usable) {
      final band = chart.bandFor(measure, size);
      if (band == null) continue;
      final cm = body.cm(measure)!;
      if (cm >= band.minCm) return false;
    }
    return true;
  }

  /// Smallest size that isn't tight — i.e. the first size the body actually
  /// fits into (sizing up past anything too small). Falls back to the largest
  /// size if every size is tight, and the smallest if every size is loose.
  static String? _recommend(List<String> sizes, Map<String, Fit> perSize) {
    if (sizes.isEmpty) return null;
    // First size that fits.
    for (final s in sizes) {
      if (perSize[s] == Fit.fits) return s;
    }
    // No exact fit: first size that's loose (can be taken in / acceptable),
    // scanning small → large means the snuggest acceptable size.
    for (final s in sizes) {
      if (perSize[s] == Fit.loose) return s;
    }
    // Everything is tight → recommend the largest available.
    return sizes.last;
  }

  // ── Consumer-facing helpers ───────────────────────────────────────────────

  /// A short, non-blocking message when [chosenSize] doesn't fit this body, or
  /// null when it fits (or can't be judged). Shown in the inline size banner at
  /// try-on and checkout. [wearerLabel] personalises it ("you" vs a name).
  static String? mismatchMessage({
    required SizeFitResult result,
    required String chosenSize,
    String wearerLabel = 'you',
  }) {
    final fit = result.fitFor(chosenSize);
    if (fit == null || fit == Fit.fits) return null;

    final off = result.sizesOff(chosenSize);
    final rec = result.recommendedSize;
    final gap = result.gapCm[chosenSize] ?? 0;

    final bySizes = (off != null && off.abs() >= 1)
        ? '${off.abs()} size${off.abs() == 1 ? '' : 's'}'
        : null;

    if (fit == Fit.tight) {
      final amount = bySizes ?? '~${gap.round()}cm';
      final suggest = (rec != null && rec != chosenSize) ? ' Try $rec.' : '';
      return 'Size $chosenSize looks about $amount too small for $wearerLabel.$suggest';
    } else {
      final amount = bySizes ?? '~${gap.round()}cm';
      final suggest = (rec != null && rec != chosenSize) ? ' Try $rec.' : '';
      return 'Size $chosenSize looks about $amount too big for $wearerLabel.$suggest';
    }
  }

  /// A phrase describing how [chosenSize] should *look* on this body, fed into
  /// the NanoBanana try-on prompt so the render is true-to-size instead of
  /// magically tailored. [garment] is the piece ('top', 'bottoms', 'shoes').
  /// Returns null when it fits (render normally) or can't be judged.
  static String? renderHint({
    required SizeFitResult result,
    required String chosenSize,
    required String garment,
  }) {
    final fit = result.fitFor(chosenSize);
    if (fit == null || fit == Fit.fits) return null;
    final gap = result.gapCm[chosenSize] ?? 0;
    final off = result.sizesOff(chosenSize)?.abs() ?? 0;
    final strong = off >= 2 || gap >= 6;

    if (fit == Fit.tight) {
      return strong
          ? 'the $garment is clearly too small: render it tight and straining, '
              'stretched fabric hugging the body, riding up, visibly not fitting'
          : 'the $garment is a bit small: render it snug and close-fitting, '
              'slightly tight across the body';
    } else {
      return strong
          ? 'the $garment is clearly too big: render it loose, baggy and '
              'oversized, draping and sagging off the body'
          : 'the $garment is a bit large: render it slightly loose and relaxed, '
              'with a little extra room';
    }
  }
}
