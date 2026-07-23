import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pyin_mal_app/models/item_size_chart.dart';

/// Loads per-item size charts from Firestore (`sizeCharts/{productId}`).
///
/// Charts are entered per garment once the data-entry UI is ready; until a
/// product has one, [forProduct] returns null and every size check downstream
/// simply no-ops. Results are cached in memory (including misses) so repeat
/// look-ups during a try-on / checkout don't re-hit Firestore.
class ItemSizeChartService {
  ItemSizeChartService._();
  static final ItemSizeChartService instance = ItemSizeChartService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// productId → chart (or null cached as a miss).
  final Map<String, ItemSizeChart?> _cache = {};

  /// The size chart for [productId], or null when none has been entered yet.
  Future<ItemSizeChart?> forProduct(String productId) async {
    if (productId.isEmpty) return null;
    if (_cache.containsKey(productId)) return _cache[productId];
    try {
      final snap = await _db.collection('sizeCharts').doc(productId).get();
      final chart = (snap.exists && snap.data() != null)
          ? ItemSizeChart.fromMap(snap.data()!, productId)
          : null;
      _cache[productId] = (chart != null && !chart.isEmpty) ? chart : null;
      return _cache[productId];
    } catch (e) {
      debugPrint('Size chart load failed for $productId: $e');
      return null; // don't cache transient failures
    }
  }

  /// Upsert a chart (for the future data-entry / admin UI). Refreshes the cache.
  Future<void> saveChart(ItemSizeChart chart) async {
    if (chart.productId.isEmpty) return;
    await _db.collection('sizeCharts').doc(chart.productId).set(chart.toMap());
    _cache[chart.productId] = chart.isEmpty ? null : chart;
  }

  /// Raw authoring doc for [productId] (sizes / ease / bands with scalar-or-pair
  /// cells), or null when none exists. Used by the entry UI to load a chart for
  /// editing without losing the single-value-vs-explicit distinction.
  Future<Map<String, dynamic>?> getRawDoc(String productId) async {
    if (productId.isEmpty) return null;
    final snap = await _db.collection('sizeCharts').doc(productId).get();
    return (snap.exists) ? snap.data() : null;
  }

  /// Writes the raw authoring doc from the entry UI and invalidates the cached
  /// resolved chart so the next fit check picks it up.
  Future<void> saveRawDoc(String productId, Map<String, dynamic> doc) async {
    if (productId.isEmpty) return;
    await _db.collection('sizeCharts').doc(productId).set(doc);
    _cache.remove(productId);
  }

  /// Deletes a product's chart.
  Future<void> deleteChart(String productId) async {
    if (productId.isEmpty) return;
    await _db.collection('sizeCharts').doc(productId).delete();
    _cache[productId] = null;
  }

  /// One-shot: does this product have a chart? (No caching — for admin lists.)
  Future<bool> hasChart(String productId) async {
    if (productId.isEmpty) return false;
    final snap = await _db.collection('sizeCharts').doc(productId).get();
    return snap.exists;
  }

  /// The set of product ids that currently have a chart — one read, used to
  /// badge the admin product list.
  Future<Set<String>> chartedProductIds() async {
    final snap = await _db.collection('sizeCharts').get();
    return snap.docs.map((d) => d.id).toSet();
  }

  /// Drop cached entries (e.g. after bulk chart edits).
  void clearCache() => _cache.clear();
}
