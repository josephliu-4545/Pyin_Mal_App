import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/wardrobe_item.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/wardrobe_service.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

const List<String> _kCategories = [
  'top',
  'bottom',
  'shoes',
  'outerwear',
  'dress',
  'accessory',
  'other',
];

/// Renders a wardrobe item's image whether it's a full URL (manual uploads,
/// hosted on catbox.moe) or a relative/CDN-style asset path (items added
/// automatically from a shop purchase) — CdnImage only handles the latter.
Widget _wardrobeImage(String url, {BoxFit fit = BoxFit.cover}) {
  if (url.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, _) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
      errorWidget: (context, _, __) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
  return CdnImage(url, fit: fit);
}

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String _categoryFilter = 'all';
  bool _adding = false;

  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adding ? null : _openAddSheet,
        backgroundColor: accent,
        foregroundColor: isDark ? AppColors.charcoal : Colors.white,
        icon: _adding
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.charcoal : Colors.white),
              )
            : const Icon(Icons.add_a_photo_rounded, size: 18),
        label: Text('wardrobe.add_item'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<WardrobeItem>>(
          stream: _db.streamWardrobe(),
          builder: (context, snap) {
            final allItems = snap.data ?? const [];
            final items = _categoryFilter == 'all'
                ? allItems
                : allItems.where((i) => i.category == _categoryFilter).toList();
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount =
                screenWidth >= 1024 ? 4 : (screenWidth >= 640 ? 3 : 2);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(isDark ? 0.2 : 0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Icon(Icons.arrow_back_ios_rounded,
                                size: 18, color: ink),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('wardrobe.title'.tr(),
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.18),
                            accent.withOpacity(0.06)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(Icons.checkroom_rounded,
                                color: accent, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('wardrobe.hero_title'.tr(),
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: ink)),
                                const SizedBox(height: 3),
                                Text('wardrobe.hero_desc'.tr(),
                                    style: GoogleFonts.outfit(
                                        fontSize: 12, height: 1.35, color: muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      children: [
                        _filterChip('all', 'wardrobe.category_all'.tr(), accent, isDark, ink),
                        for (final c in _kCategories)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _filterChip(
                                c, 'wardrobe.categories.$c'.tr(), accent, isDark, ink),
                          ),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.checkroom_outlined,
                              size: 48, color: muted.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          Text('wardrobe.empty'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13, color: muted)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _WardrobeCard(
                          item: items[i],
                          isDark: isDark,
                          cardBg: cardBg,
                          ink: ink,
                          muted: muted,
                          accent: accent,
                          onTap: () => _openDetailSheet(items[i], isDark, accent),
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(
      String value, String label, Color accent, bool isDark, Color ink) {
    final selected = _categoryFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _categoryFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isDark ? Colors.white10 : const Color(0xFFF0F0F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? (isDark ? AppColors.charcoal : Colors.white)
                    : ink)),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? AppColors.darkWarm : Colors.white;
        final ink = isDark ? Colors.white : AppColors.inkBlack;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: ink),
                title: Text('wardrobe.take_photo'.tr(),
                    style: GoogleFonts.outfit(color: ink)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: ink),
                title: Text('wardrobe.choose_photo'.tr(),
                    style: GoogleFonts.outfit(color: ink)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
        source: source, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    setState(() => _adding = true);
    final item = await WardrobeService.addItem(picked);
    if (!mounted) return;
    setState(() => _adding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item != null
            ? 'wardrobe.added'.tr()
            : 'wardrobe.add_failed'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDetailSheet(WardrobeItem item, bool isDark, Color accent) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: _wardrobeImage(item.imageUrl)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            item.brand?.isNotEmpty == true
                                ? item.brand!
                                : 'wardrobe.categories.${item.category}'.tr(),
                            style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                      ),
                      IconButton(
                        onPressed: () async {
                          await DatabaseService().deleteWardrobeItem(item.id);
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFE53935)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag('wardrobe.categories.${item.category}'.tr(), accent, isDark),
                      if (item.color != null && item.color!.isNotEmpty)
                        _tag(item.color!, muted, isDark),
                      for (final t in item.tags) _tag(t, muted, isDark),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('wardrobe.times_worn'.tr(args: [item.timesWorn.toString()]),
                      style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TryOnScreen(
                              initialImageUrl: item.imageUrl,
                              initialCategory: item.category,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: Text('wardrobe.try_on_this'.tr(),
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}

class _WardrobeCard extends StatelessWidget {
  final WardrobeItem item;
  final bool isDark;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final Color accent;
  final VoidCallback onTap;

  const _WardrobeCard({
    required this.item,
    required this.isDark,
    required this.cardBg,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _wardrobeImage(item.imageUrl),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('wardrobe.categories.${item.category}'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        item.brand?.isNotEmpty == true
                            ? item.brand!
                            : 'wardrobe.categories.${item.category}'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
                    Text(
                        item.timesWorn > 0
                            ? 'wardrobe.times_worn'.tr(args: [item.timesWorn.toString()])
                            : 'wardrobe.never_worn'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 10, color: muted)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
