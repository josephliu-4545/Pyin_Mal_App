/// Result of a Bodygram scan: body measurements keyed by Bodygram's
/// camelCase names (bustGirth, waistGirth, hipGirth, ...), stored in mm.
class BodyMeasurements {
  final String scanId;

  /// 'photoScan' or 'statsEstimation'
  final String source;

  /// Bodygram measurement name → value in millimeters.
  final Map<String, double> valuesMm;

  final DateTime? measuredAt;

  BodyMeasurements({
    required this.scanId,
    required this.source,
    required this.valuesMm,
    this.measuredAt,
  });

  double? mm(String name) => valuesMm[name];
  double? cm(String name) {
    final v = valuesMm[name];
    return v == null ? null : v / 10.0;
  }

  // The measurements that matter most for clothing fit, in display order.
  // Names follow Bodygram's API exactly; trailing R = right side.
  static const keyMeasurements = [
    'neckGirth',
    'acrossBackShoulderWidth',
    'bustGirth',
    'underBustGirth',
    'waistGirth',
    'bellyWaistGirth',
    'hipGirth',
    'backNeckPointToWristLengthR',
    'outerArmLengthR',
    'thighGirthR',
    'insideLegLengthR',
    'outseamR',
  ];

  Map<String, dynamic> toMap() => {
        'scanId': scanId,
        'source': source,
        'valuesMm': valuesMm,
        'measuredAt': measuredAt?.toIso8601String(),
      };

  factory BodyMeasurements.fromMap(Map<String, dynamic> data) {
    final raw = Map<String, dynamic>.from(data['valuesMm'] ?? {});
    return BodyMeasurements(
      scanId: data['scanId'] as String? ?? '',
      source: data['source'] as String? ?? 'photoScan',
      valuesMm: raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      measuredAt: data['measuredAt'] != null
          ? DateTime.tryParse(data['measuredAt'] as String)
          : null,
    );
  }
}
