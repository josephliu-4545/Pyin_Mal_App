import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/cdn_image.dart';
import 'package:pyin_mal_app/core/favorites_notifier.dart';
import 'package:pyin_mal_app/core/hairstyle_favorites_notifier.dart';
import 'package:pyin_mal_app/data/product_repository.dart';

/// One saved entry in the collection — a product or a hairstyle, unified so
/// they render with the same card and live in the same filterable grid.
class _SavedEntry {
  final String id;
  final String title;
  final String meta; // shop name (product) or "Hairstyle"
  final String image;
  final String chip; // category (product) or "Hairstyle"
  final bool isHairstyle;
  final VoidCallback onRemove;

  _SavedEntry({
    required this.id,
    required this.title,
    required this.meta,
    required this.image,
    required this.chip,
    required this.isHairstyle,
    required this.onRemove,
  });
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _filter = 0; // 0 = All, 1 = Products, 2 = Hairstyles

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _hairstyleName(String path) {
    var name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (name.isEmpty) return 'Hairstyle';
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  List<_SavedEntry> _products(Set<String> favorites) {
    final out = <_SavedEntry>[];
    for (final id in favorites) {
      final p = ProductRepository.getProductById(id);
      final title = p?.name ?? favoritesNotifier.infoCache[id]?.title;
      final image = p?.image ?? favoritesNotifier.infoCache[id]?.image;
      if (title == null || image == null) continue;
      out.add(_SavedEntry(
        id: id,
        title: title,
        meta: p?.shopName ?? p?.brand ?? favoritesNotifier.infoCache[id]?.shop ?? '',
        image: image,
        chip: p?.category ?? favoritesNotifier.infoCache[id]?.category ?? 'Item',
        isHairstyle: false,
        onRemove: () => favoritesNotifier.toggleFavorite(id),
      ));
    }
    return out;
  }

  List<_SavedEntry> _hairstyles(Set<String> paths) {
    return paths
        .map((path) => _SavedEntry(
              id: path,
              title: _hairstyleName(path),
              meta: 'Hairstyle',
              image: path,
              chip: 'Hairstyle',
              isHairstyle: true,
              onRemove: () => hairstyleFavoritesNotifier.toggle(path),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1024 ? 4 : (w >= 640 ? 3 : 2);
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: favoritesNotifier,
          builder: (context, favorites, _) {
            return ValueListenableBuilder<Set<String>>(
              valueListenable: hairstyleFavoritesNotifier,
              builder: (context, hairs, __) {
                final products = _products(favorites);
                final hairstyles = _hairstyles(hairs);
                final total = products.length + hairstyles.length;

                final q = _searchController.text.trim().toLowerCase();
                List<_SavedEntry> base = switch (_filter) {
                  1 => products,
                  2 => hairstyles,
                  _ => [...products, ...hairstyles],
                };
                final items = q.isEmpty
                    ? base
                    : base
                        .where((e) =>
                            e.title.toLowerCase().contains(q) ||
                            e.meta.toLowerCase().contains(q) ||
                            e.chip.toLowerCase().contains(q))
                        .toList();

                return CustomScrollView(
                  slivers: [
                    // ── Header ──
                    SliverToBoxAdapter(
                      child: _buildHeader(ink, muted, accent, total),
                    ),

                    if (total > 0) ...[
                      // ── Search ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: _buildSearch(isDark, ink, muted, accent),
                        ),
                      ),
                      // ── Filter segmented control ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: _buildFilters(
                              isDark, ink, muted, accent,
                              products.length, hairstyles.length),
                        ),
                      ),
                    ],

                    // ── Grid / empty ──
                    if (total == 0)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(ink, muted, accent, isDark),
                      )
                    else if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildNoResults(muted, accent),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.66,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) =>
                                _buildCard(items[i], isDark, ink, muted, accent),
                            childCount: items.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color ink, Color muted, Color accent, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('Saved',
                    style: GoogleFonts.rufina(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        color: ink)),
              ),
              if (total > 0)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    total == 1 ? '1 item' : '$total items',
                    style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your favourite outfits and hairstyles, all in one place.',
            style: GoogleFonts.outfit(fontSize: 13.5, height: 1.4, color: muted),
          ),
        ],
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearch(bool isDark, Color ink, Color muted, Color accent) {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.outfit(fontSize: 14, color: ink),
      decoration: InputDecoration(
        hintText: 'Search your saved items',
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: muted),
        prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: muted),
                onPressed: () => _searchController.clear(),
              ),
        filled: true,
        fillColor: isDark ? AppColors.darkWarm : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
    );
  }

  // ── Filter segmented control ────────────────────────────────────────────────
  Widget _buildFilters(bool isDark, Color ink, Color muted, Color accent,
      int products, int hairstyles) {
    Widget seg(int idx, String label, int count) {
      final sel = _filter == idx;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _filter = idx),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              count > 0 ? '$label · $count' : label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: sel ? (isDark ? AppColors.charcoal : Colors.white) : ink,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
      ),
      child: Row(
        children: [
          seg(0, 'All', products + hairstyles),
          seg(1, 'Products', products),
          seg(2, 'Hairstyles', hairstyles),
        ],
      ),
    );
  }

  // ── Unified saved card ──────────────────────────────────────────────────────
  Widget _buildCard(
      _SavedEntry e, bool isDark, Color ink, Color muted, Color accent) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(17)),
                  child: e.isHairstyle
                      ? Image.asset(
                          e.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imgFallback(isDark, accent, e.isHairstyle),
                        )
                      : CdnImage(
                          e.image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _imgFallback(isDark, accent, e.isHairstyle),
                        ),
                ),
                // type chip
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            e.isHairstyle
                                ? Icons.content_cut_rounded
                                : Icons.checkroom_rounded,
                            size: 10,
                            color: Colors.white),
                        const SizedBox(width: 4),
                        Text(e.chip,
                            style: GoogleFonts.outfit(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                // remove heart
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: e.onRemove,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 16, color: AppColors.burgundy),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: ink),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                          e.isHairstyle
                              ? Icons.content_cut_rounded
                              : Icons.storefront_rounded,
                          size: 11,
                          color: accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          e.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback(bool isDark, Color accent, bool isHairstyle) {
    return Container(
      color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
      child: Icon(
          isHairstyle ? Icons.content_cut_rounded : Icons.image_rounded,
          size: 34,
          color: accent.withOpacity(0.5)),
    );
  }

  // ── Empty states ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(
      Color ink, Color muted, Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border_rounded, size: 44, color: accent),
          ),
          const SizedBox(height: 22),
          Text('No saved items yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.rufina(
                  fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
          const SizedBox(height: 8),
          Text(
            'Tap the heart on any product or hairstyle to keep it here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13.5, height: 1.5, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(Color muted, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: accent.withOpacity(0.6)),
          const SizedBox(height: 14),
          Text('Nothing matches your search.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: muted)),
        ],
      ),
    );
  }
}
