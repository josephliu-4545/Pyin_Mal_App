import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/data/size_chart_presets.dart';
import 'package:pyin_mal_app/models/item_size_chart.dart';
import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/item_size_chart_service.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

/// Admin list: pick a product to add / edit its size chart. Products that
/// already have a chart are badged.
class SizeChartAdminScreen extends StatefulWidget {
  const SizeChartAdminScreen({super.key});

  @override
  State<SizeChartAdminScreen> createState() => _SizeChartAdminScreenState();
}

class _SizeChartAdminScreenState extends State<SizeChartAdminScreen> {
  final _searchCtrl = TextEditingController();
  Set<String> _charted = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCharted();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCharted() async {
    final ids = await ItemSizeChartService.instance.chartedProductIds();
    if (mounted) setState(() => _charted = ids);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    final products = ProductRepository.allProducts.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Size charts',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.outfit(color: ink),
              decoration: InputDecoration(
                hintText: 'Search products…',
                hintStyle: GoogleFonts.outfit(color: muted),
                prefixIcon: Icon(Icons.search_rounded, color: muted),
                filled: true,
                fillColor: isDark ? AppColors.darkWarm : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_charted.length} of ${ProductRepository.allProducts.length} charted',
                    style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = products[i];
                final has = _charted.contains(p.id);
                return _productTile(p, has, isDark, ink, muted, accent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productTile(Product p, bool has, bool isDark, Color ink, Color muted,
      Color accent) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SizeChartEditorScreen(product: p)),
        );
        _loadCharted();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: CdnImage(p.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: isDark ? AppColors.charcoal : AppColors.creamAlt,
                        child: Icon(Icons.checkroom_rounded, color: muted))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 2),
                  Text('${p.category} · ${p.gender}',
                      style: GoogleFonts.outfit(fontSize: 11.5, color: muted)),
                ],
              ),
            ),
            if (has)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: accent),
                    const SizedBox(width: 4),
                    Text('Charted',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent)),
                  ],
                ),
              )
            else
              Icon(Icons.add_circle_outline_rounded, color: muted),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

/// Editor for one product's size chart. Pick a preset (or reuse an existing
/// chart), set the sizes + measurements, then type one target number per cell
/// (e.g. waist "76") — the ± ease turns it into a fit band. Type "74-80" in a
/// cell to pin an explicit range instead.
class SizeChartEditorScreen extends StatefulWidget {
  final Product product;
  const SizeChartEditorScreen({super.key, required this.product});

  @override
  State<SizeChartEditorScreen> createState() => _SizeChartEditorScreenState();
}

class _SizeChartEditorScreenState extends State<SizeChartEditorScreen> {
  List<String> _sizes = ['S', 'M', 'L'];
  List<String> _measurements = [];
  double _ease = kDefaultSizeEaseCm;
  bool _loading = true;
  bool _existing = false;

  // "$measure|$size" → controller. Created lazily; all disposed at the end.
  final Map<String, TextEditingController> _cells = {};
  final TextEditingController _easeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _cells.values) {
      c.dispose();
    }
    _easeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc =
        await ItemSizeChartService.instance.getRawDoc(widget.product.id);
    if (doc != null) {
      _existing = true;
      _sizes = List<String>.from(doc['sizes'] ?? const ['S', 'M', 'L']);
      _ease = (doc['ease'] as num?)?.toDouble() ?? kDefaultSizeEaseCm;
      final rawBands = Map<String, dynamic>.from(doc['bands'] ?? const {});
      _measurements = rawBands.keys
          .where((k) => SizeMeasurements.labels.containsKey(k))
          .toList();
      rawBands.forEach((measure, perSize) {
        final m = Map<String, dynamic>.from(perSize as Map);
        m.forEach((size, cell) {
          _ctrl(measure, size).text = _cellToText(cell);
        });
      });
    } else {
      final preset = SizePreset.guess(widget.product.gender, widget.product.category);
      _measurements = List<String>.from(preset.measurements);
    }
    _easeCtrl.text = _fmt(_ease);
    if (mounted) setState(() => _loading = false);
  }

  String _cellToText(dynamic cell) {
    if (cell is num) return _fmt(cell.toDouble());
    if (cell is List && cell.length == 2) {
      return '${_fmt((cell[0] as num).toDouble())}-${_fmt((cell[1] as num).toDouble())}';
    }
    return '';
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  TextEditingController _ctrl(String measure, String size) =>
      _cells.putIfAbsent('$measure|$size', () => TextEditingController());

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Parses a cell: "76" → 76.0 (scalar), "74-80" → [74,80] (explicit),
  /// empty/invalid → null (skip).
  dynamic _parseCell(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.contains('-')) {
      final parts = t.split('-');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0].trim());
        final b = double.tryParse(parts[1].trim());
        if (a != null && b != null && b > a) return [a, b];
      }
      return null;
    }
    return double.tryParse(t);
  }

  Future<void> _save() async {
    final bands = <String, dynamic>{};
    for (final m in _measurements) {
      final perSize = <String, dynamic>{};
      for (final s in _sizes) {
        final parsed = _parseCell(_ctrl(m, s).text);
        if (parsed != null) perSize[s] = parsed;
      }
      if (perSize.isNotEmpty) bands[m] = perSize;
    }

    if (bands.isEmpty) {
      _snack('Add at least one measurement value before saving.');
      return;
    }

    final doc = <String, dynamic>{
      'productId': widget.product.id,
      'sizes': _sizes,
      'ease': _ease,
      'bands': bands,
    };
    await ItemSizeChartService.instance.saveRawDoc(widget.product.id, doc);
    if (!mounted) return;
    _snack('Size chart saved.');
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    await ItemSizeChartService.instance.deleteChart(widget.product.id);
    if (!mounted) return;
    _snack('Size chart deleted.');
    Navigator.pop(context);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Size chart',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
        actions: [
          if (_existing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: muted,
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _productHeader(isDark, ink, muted),
                const SizedBox(height: 16),
                _presetRow(isDark, ink, muted, accent),
                const SizedBox(height: 16),
                _sizesEditor(isDark, ink, muted, accent),
                const SizedBox(height: 16),
                _easeEditor(isDark, ink, muted, accent),
                const SizedBox(height: 16),
                _measurementsGrid(isDark, ink, muted, accent),
                const SizedBox(height: 12),
                _addMeasurementButton(isDark, muted, accent),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text('Save chart',
                        style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card(bool isDark, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        child: child,
      );

  Widget _productHeader(bool isDark, Color ink, Color muted) {
    final p = widget.product;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: CdnImage(p.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                    child: Icon(Icons.checkroom_rounded, color: muted))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
              Text('${p.category} · ${p.gender}',
                  style: GoogleFonts.outfit(fontSize: 12, color: muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, Color ink) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
      );

  Widget _presetRow(bool isDark, Color ink, Color muted, Color accent) {
    return _card(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Preset', ink),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SizePreset.all.map((preset) {
              return GestureDetector(
                onTap: () => setState(() {
                  _measurements = List<String>.from(preset.measurements);
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Text(preset.name,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text('Tapping a preset replaces the measurement list below.',
              style: GoogleFonts.outfit(fontSize: 11, color: muted)),
        ],
      ),
    );
  }

  Widget _sizesEditor(bool isDark, Color ink, Color muted, Color accent) {
    return _card(
      isDark,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Sizes', ink),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _sizes)
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s,
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accent)),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        icon: Icon(Icons.close_rounded, size: 15, color: accent),
                        onPressed: _sizes.length <= 1
                            ? null
                            : () => setState(() => _sizes.remove(s)),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _addSize,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: muted.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: muted),
                      const SizedBox(width: 3),
                      Text('Add',
                          style:
                              GoogleFonts.outfit(fontSize: 12.5, color: muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _easeEditor(bool isDark, Color ink, Color muted, Color accent) {
    return _card(
      isDark,
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ease (± cm)',
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
                Text('Tolerance around a single target value.',
                    style: GoogleFonts.outfit(fontSize: 11, color: muted)),
              ],
            ),
          ),
          SizedBox(
            width: 74,
            child: TextField(
              controller: _easeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: (v) {
                final e = double.tryParse(v.trim());
                if (e != null && e >= 0) _ease = e;
              },
              style: GoogleFonts.outfit(color: ink, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.charcoal : AppColors.creamAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixText: 'cm',
                suffixStyle: GoogleFonts.outfit(fontSize: 11, color: muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementsGrid(bool isDark, Color ink, Color muted, Color accent) {
    if (_measurements.isEmpty) {
      return _card(
        isDark,
        Text('No measurements yet — pick a preset or add one below.',
            style: GoogleFonts.outfit(fontSize: 12.5, color: muted)),
      );
    }
    return Column(
      children: [
        for (final m in _measurements) ...[
          _card(
            isDark,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(SizeMeasurements.label(m),
                          style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: Icon(Icons.close_rounded, size: 17, color: muted),
                      onPressed: () =>
                          setState(() => _measurements.remove(m)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in _sizes)
                      _cellField(m, s, isDark, ink, muted, accent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _cellField(String measure, String size, bool isDark, Color ink,
      Color muted, Color accent) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(size,
              style: GoogleFonts.outfit(
                  fontSize: 11, fontWeight: FontWeight.w700, color: muted)),
          const SizedBox(height: 4),
          TextField(
            controller: _ctrl(measure, size),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
            ],
            style: GoogleFonts.outfit(color: ink, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'cm',
              hintStyle: GoogleFonts.outfit(color: muted, fontSize: 12),
              isDense: true,
              filled: true,
              fillColor: isDark ? AppColors.charcoal : AppColors.creamAlt,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addMeasurementButton(bool isDark, Color muted, Color accent) {
    final remaining = SizeMeasurements.all
        .where((k) => !_measurements.contains(k))
        .toList();
    return OutlinedButton.icon(
      onPressed: remaining.isEmpty ? null : () => _pickMeasurement(remaining),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text('Add measurement',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: accent.withOpacity(0.5)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _addSize() async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkWarm : Colors.white,
        title: Text('Add size', style: GoogleFonts.outfit()),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'e.g. XL or 32'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !_sizes.contains(result)) {
      setState(() => _sizes.add(result));
    }
  }

  Future<void> _pickMeasurement(List<String> remaining) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 8),
            for (final k in remaining)
              ListTile(
                title: Text(SizeMeasurements.label(k),
                    style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : AppColors.inkBlack)),
                onTap: () => Navigator.pop(context, k),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) setState(() => _measurements.add(chosen));
  }
}
