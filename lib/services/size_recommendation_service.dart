import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/models/item_size_chart.dart';

/// Verdict for one label size against the user's body.
enum FitVerdict { tight, fits, loose }

class SizeRecommendation {
  /// 'XS'...'XL'
  final String size;

  /// Bodygram measurement name the recommendation hinges on (e.g. 'waistGirth').
  final String basedOn;

  /// Verdict per label size, for the chips UI.
  final Map<String, FitVerdict> verdicts;

  SizeRecommendation({
    required this.size,
    required this.basedOn,
    required this.verdicts,
  });
}

/// Standard garment size charts (cm) compared against the user's saved
/// Bodygram measurements. The catalog has no per-product size charts, so
/// these are conventional ready-to-wear ranges per category group + gender.
class SizeRecommendationService {
  static const sizes = ['XS', 'S', 'M', 'L', 'XL'];

  // Per size: [min, max) girth in cm. Upper bound of one size = lower of next.
  static const _charts = <String, Map<String, List<double>>>{
    // Tops are driven by bust/chest girth.
    'female-top': {'bustGirth': [78, 84, 90, 96, 103, 111]},
    'male-top':   {'bustGirth': [84, 90, 96, 102, 110, 118]},
    // Bottoms are driven by waist and hip — the larger one wins.
    'female-bottom': {
      'waistGirth': [60, 66, 72, 78, 85, 93],
      'hipGirth':   [84, 90, 96, 102, 109, 117],
    },
    'male-bottom': {
      'waistGirth': [70, 76, 82, 88, 95, 103],
      'hipGirth':   [86, 92, 98, 104, 111, 119],
    },
    // Dresses: bust first, hips checked too.
    'female-dress': {
      'bustGirth': [78, 84, 90, 96, 103, 111],
      'hipGirth':  [84, 90, 96, 102, 109, 117],
    },
    'male-dress': {'bustGirth': [84, 90, 96, 102, 110, 118]},
  };

  /// [gender] is the wearer's gender ('Male' → male charts, anything else →
  /// female charts). Returns null when the needed measurements are missing.
  static SizeRecommendation? recommend({
    required BodyMeasurements measurements,
    required String category,
    required String gender,
  }) {
    final g = gender.toLowerCase() == 'male' ? 'male' : 'female';
    final chart = _charts['$g-${_garmentGroup(category)}']!;

    // Index of the size whose [min, max) range contains the value;
    // clamps to XS/XL when outside the chart.
    int sizeIndex(List<double> bounds, double cm) {
      for (var i = 0; i < sizes.length; i++) {
        if (cm < bounds[i + 1]) return i;
      }
      return sizes.length - 1;
    }

    int? bestIndex;
    String? basedOn;
    for (final entry in chart.entries) {
      final cm = measurements.cm(entry.key);
      if (cm == null) continue;
      final idx = sizeIndex(entry.value, cm);
      // Size up to fit the largest body dimension.
      if (bestIndex == null || idx > bestIndex) {
        bestIndex = idx;
        basedOn = entry.key;
      }
    }
    if (bestIndex == null || basedOn == null) return null;

    final bounds = chart[basedOn]!;
    final cm = measurements.cm(basedOn)!;
    final verdicts = <String, FitVerdict>{};
    for (var i = 0; i < sizes.length; i++) {
      if (cm >= bounds[i + 1]) {
        verdicts[sizes[i]] = FitVerdict.tight;
      } else if (cm < bounds[i]) {
        verdicts[sizes[i]] = FitVerdict.loose;
      } else {
        verdicts[sizes[i]] = FitVerdict.fits;
      }
    }
    return SizeRecommendation(
      size: sizes[bestIndex],
      basedOn: basedOn,
      verdicts: verdicts,
    );
  }

  /// Standard ready-to-wear BODY-measurement ranges (cm) per size XS…XL, one
  /// bounds list of length 6 (upper bound of one size = lower of the next).
  /// Grounded in published men's/women's apparel size charts (ASOS, Nike,
  /// Lands' End, Westside, etc. — figures vary by brand, these are mid-market
  /// averages). Bust/waist/hip are kept identical to [_charts] so the estimated
  /// chart and the size recommendation agree.
  static const _bodyRanges = <String, Map<String, List<double>>>{
    'male': {
      'bustGirth': [84, 90, 96, 102, 110, 118], // chest
      'acrossBackShoulderWidth': [42, 44, 46, 48, 50, 52],
      'outerArmLengthR': [59, 61, 63, 65, 67, 69], // shoulder→wrist sleeve
      'neckGirth': [35, 37, 39, 41, 43, 45],
      'waistGirth': [70, 76, 82, 88, 95, 103],
      'hipGirth': [86, 92, 98, 104, 111, 119],
      'thighGirthR': [50, 54, 58, 62, 66, 70],
      'insideLegLengthR': [76, 78, 79, 80, 81, 82], // inseam
    },
    'female': {
      'bustGirth': [78, 84, 90, 96, 103, 111],
      'underBustGirth': [66, 72, 78, 84, 91, 99],
      'acrossBackShoulderWidth': [35, 37, 39, 41, 43, 45],
      'outerArmLengthR': [54, 56, 58, 60, 62, 64],
      'neckGirth': [30, 32, 34, 36, 38, 40],
      'waistGirth': [60, 66, 72, 78, 85, 93],
      'hipGirth': [84, 90, 96, 102, 109, 117],
      'thighGirthR': [48, 52, 56, 60, 64, 68],
      'insideLegLengthR': [72, 74, 75, 76, 77, 78],
    },
  };

  /// The measurements a garment of this [category] is realistically described
  /// by — inferred from the type, mirroring how real charts differ (a tee lists
  /// chest + shoulder; a button shirt adds neck + sleeve; pants list waist, hip,
  /// thigh, inseam). Order-sensitive: casual tops are matched before "shirt" so
  /// a "t-shirt" isn't treated as a collared dress shirt.
  static List<String> _syntheticMeasures(String category) {
    final c = category.toLowerCase();
    // Bottoms
    if (c.contains('pant') || c.contains('jean') || c.contains('trouser') ||
        c.contains('chino') || c.contains('legging')) {
      return ['waistGirth', 'hipGirth', 'thighGirthR', 'insideLegLengthR'];
    }
    if (c.contains('short')) return ['waistGirth', 'hipGirth', 'thighGirthR'];
    if (c.contains('skirt')) return ['waistGirth', 'hipGirth'];
    // Full-body
    if (c.contains('dress') || c.contains('gown') || c.contains('jumpsuit') ||
        c.contains('romper')) {
      return ['bustGirth', 'waistGirth', 'hipGirth'];
    }
    // Casual / short-sleeve tops — matched BEFORE "shirt".
    if (c.contains('tee') || c.contains('t-shirt') || c.contains('tshirt') ||
        c.contains('polo') || c.contains('tank') || c.contains('vest') ||
        c.contains('singlet') || c.contains('crop')) {
      return ['bustGirth', 'acrossBackShoulderWidth'];
    }
    // Long-sleeve / structured tops & outerwear — sleeve matters.
    if (c.contains('hoodie') || c.contains('sweater') || c.contains('sweat') ||
        c.contains('cardigan') || c.contains('knit') || c.contains('pullover') ||
        c.contains('jacket') || c.contains('coat') || c.contains('blazer') ||
        c.contains('outer')) {
      return ['bustGirth', 'acrossBackShoulderWidth', 'outerArmLengthR'];
    }
    // Collared / button shirts & blouses — add neck.
    if (c.contains('shirt') || c.contains('blouse')) {
      return [
        'neckGirth',
        'bustGirth',
        'acrossBackShoulderWidth',
        'outerArmLengthR'
      ];
    }
    // Anything else → treat as a basic top.
    return ['bustGirth', 'acrossBackShoulderWidth'];
  }

  /// Builds a stand-in per-item [ItemSizeChart] from realistic body-measurement
  /// ranges, choosing the measurement set from the product's category (so a tee,
  /// a dress shirt and a pair of jeans each get the rows that garment type would
  /// really list) and the range table from its gender. Used as a demo fallback
  /// so every product has plausible sizing without a chart entered — a
  /// shop-supplied chart in `sizeCharts/{id}` overrides it entirely.
  static ItemSizeChart? syntheticChart({
    required String productId,
    required String category,
    required String gender,
  }) {
    final ranges =
        _bodyRanges[gender.toLowerCase() == 'male' ? 'male' : 'female']!;
    final bands = <String, Map<String, SizeBand>>{};
    for (final measure in _syntheticMeasures(category)) {
      final bounds = ranges[measure];
      if (bounds == null) continue;
      final perSize = <String, SizeBand>{};
      for (var i = 0; i < sizes.length; i++) {
        // Upper bound of one size is the lower bound of the next.
        perSize[sizes[i]] = SizeBand(bounds[i], bounds[i + 1]);
      }
      bands[measure] = perSize;
    }
    if (bands.isEmpty) return null;
    return ItemSizeChart(
      productId: productId,
      sizes: List<String>.of(sizes),
      bands: bands,
    );
  }

  static String _garmentGroup(String category) {
    final c = category.toLowerCase();
    if (c.contains('pant') || c.contains('jean') || c.contains('trouser') ||
        c.contains('short') || c.contains('skirt') || c.contains('chino') ||
        c.contains('bottom')) {
      return 'bottom';
    }
    if (c.contains('dress') || c.contains('gown') || c.contains('one-piece')) {
      return 'dress';
    }
    // Hoodie, T-Shirt, Set, Jacket, Shirt … default to top sizing.
    return 'top';
  }
}
