import 'package:pyin_mal_app/models/body_measurements.dart';

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
