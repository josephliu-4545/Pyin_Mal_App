import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/services/fitting_session.dart';
import 'package:pyin_mal_app/services/item_size_chart_service.dart';
import 'package:pyin_mal_app/services/size_fit_service.dart';
import 'package:pyin_mal_app/services/size_recommendation_service.dart';

/// The verdict for one garment + size against the active wearer, ready for the
/// UI: a banner [message] and a NanoBanana [renderHint]. Both are null when the
/// piece fits, or when fit can't be judged yet (no chart, no saved sizes).
class SizeCheck {
  final Fit? fit;
  final String? message;
  final String? renderHint;

  const SizeCheck({this.fit, this.message, this.renderHint});

  static const SizeCheck none = SizeCheck();

  bool get hasWarning => message != null;
}

/// One call that screens use for size feedback. It pulls the item's chart, the
/// active wearer's measurements (self or guest, from [FittingSession]), runs
/// the comparison, and hands back a ready-to-show [SizeCheck]. Every "can't
/// tell" path (no chart entered yet, no measurements on file, size not charted)
/// collapses to [SizeCheck.none] so callers never have to special-case them.
class SizeAdvisor {
  SizeAdvisor._();

  /// Demo convenience: when a product has no real chart in `sizeCharts/{id}`,
  /// fall back to a synthetic chart from conventional ranges so every item can
  /// be demoed without manual entry. In production (shops supply real charts)
  /// set this false to only warn on genuinely-charted items.
  static bool useSyntheticFallback = true;

  /// [garment] is a short noun for the render hint: 'top', 'bottoms', 'shoes'…
  static Future<SizeCheck> checkGarment({
    required String productId,
    required String size,
    required String garment,
  }) async {
    if (productId.isEmpty || size.isEmpty) return SizeCheck.none;

    var chart = await ItemSizeChartService.instance.forProduct(productId);
    if (chart == null && useSyntheticFallback) {
      final p = ProductRepository.getProductById(productId);
      if (p != null) {
        chart = SizeRecommendationService.syntheticChart(
          productId: productId,
          category: p.category,
          gender: p.gender,
        );
      }
    }
    if (chart == null) return SizeCheck.none;

    final body = await FittingSession.instance.currentMeasurements();
    if (body == null) return SizeCheck.none;

    final result = SizeFitService.evaluate(body: body, chart: chart);
    if (result == null) return SizeCheck.none;

    return SizeCheck(
      fit: result.fitFor(size),
      message: SizeFitService.mismatchMessage(
        result: result,
        chosenSize: size,
        wearerLabel: FittingSession.instance.wearerLabel,
      ),
      renderHint: SizeFitService.renderHint(
        result: result,
        chosenSize: size,
        garment: garment,
      ),
    );
  }
}
