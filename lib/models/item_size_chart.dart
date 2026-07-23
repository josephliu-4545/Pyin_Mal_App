// Per-item size chart.
//
// Every garment is cut differently — an "M" from one brand is not the same body
// as an "M" from another — so the chart lives on the *item*, not on a global
// convention. Each chart maps every label size the item is sold in (e.g. 'S',
// 'M', 'L' or '28', '30', '32') to the body-measurement bands, in centimetres,
// that size is cut to fit. Measurement names follow Bodygram's keys
// (waistGirth, hipGirth, bustGirth, …) so they line up directly with the
// wearer's saved BodyMeasurements.
//
// The UI to enter these charts is still being designed; until a chart exists
// for a product, lookups return null and every size check simply no-ops.

/// A `[minCm, maxCm)` body-measurement band that one garment size is cut to fit.
class SizeBand {
  final double minCm;
  final double maxCm;

  const SizeBand(this.minCm, this.maxCm);

  /// Half-open so the max of one size equals the min of the next without
  /// double-counting the boundary.
  bool contains(double cm) => cm >= minCm && cm < maxCm;

  double get midCm => (minCm + maxCm) / 2.0;

  factory SizeBand.fromList(List<dynamic> v) =>
      SizeBand((v[0] as num).toDouble(), (v[1] as num).toDouble());

  List<double> toList() => [minCm, maxCm];
}

/// Default ± tolerance (cm) applied to a single target value when a cell is
/// entered as one number rather than an explicit min–max.
const double kDefaultSizeEaseCm = 3.0;

class ItemSizeChart {
  final String productId;

  /// Label sizes in the order they're sold, smallest → largest.
  /// e.g. ['S', 'M', 'L'] or ['28', '30', '32'].
  final List<String> sizes;

  /// measurementName → { sizeLabel → band }.
  /// e.g. bands['waistGirth']['M'] == SizeBand(74, 80).
  /// Only the measurements this garment actually cares about are present
  /// (waist/hip for bottoms, bust for tops, etc.).
  final Map<String, Map<String, SizeBand>> bands;

  const ItemSizeChart({
    required this.productId,
    required this.sizes,
    required this.bands,
  });

  bool get isEmpty => sizes.isEmpty || bands.isEmpty;

  /// The measurement keys this chart drives fit off of.
  Iterable<String> get measurements => bands.keys;

  /// The band for [measurement] at [size], or null if not charted.
  SizeBand? bandFor(String measurement, String size) => bands[measurement]?[size];

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'sizes': sizes,
        'bands': bands.map(
          (measure, perSize) => MapEntry(
            measure,
            perSize.map((size, band) => MapEntry(size, band.toList())),
          ),
        ),
      };

  /// Builds the resolved (engine-facing) chart from the stored authoring doc.
  /// Each cell is either a single target number (→ band = target ± [ease]) or
  /// an explicit `[min, max]` list. Unparseable/empty cells are dropped.
  factory ItemSizeChart.fromMap(Map<String, dynamic> data, String productId) {
    final ease = (data['ease'] as num?)?.toDouble() ?? kDefaultSizeEaseCm;
    final rawBands = Map<String, dynamic>.from(data['bands'] ?? const {});
    final bands = <String, Map<String, SizeBand>>{};
    rawBands.forEach((measure, perSize) {
      final m = Map<String, dynamic>.from(perSize as Map);
      final resolved = <String, SizeBand>{};
      m.forEach((size, cell) {
        final band = _cellToBand(cell, ease);
        if (band != null) resolved[size] = band;
      });
      if (resolved.isNotEmpty) bands[measure] = resolved;
    });
    return ItemSizeChart(
      productId: data['productId'] as String? ?? productId,
      sizes: List<String>.from(data['sizes'] ?? const []),
      bands: bands,
    );
  }

  static SizeBand? _cellToBand(dynamic cell, double ease) {
    if (cell is num) {
      final v = cell.toDouble();
      return SizeBand(v - ease, v + ease);
    }
    if (cell is List && cell.length == 2) {
      return SizeBand.fromList(List<dynamic>.from(cell));
    }
    return null;
  }
}
