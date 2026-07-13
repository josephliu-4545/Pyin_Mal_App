import 'dart:ui';

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

/// Renders a wardrobe item's image whether it's a full URL (manual uploads)
/// or a relative/CDN-style asset path (items added automatically from a shop
/// purchase) — CdnImage only handles the latter.
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
  final _db = DatabaseService();
  bool _adding = false;
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // viewportFraction controls how close the cards are to each other
    _pageController = PageController(viewportFraction: 0.52);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Theme helpers — follows the app's light / dark themes.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _accent => _isDark ? AppColors.gold : AppColors.burgundy;
  Color get _bg => _isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
  Color get _surface => _isDark ? AppColors.darkWarm : Colors.white;
  Color get _ink => _isDark ? Colors.white : AppColors.inkBlack;
  Color get _muted => _isDark ? AppColors.paleText : AppColors.inkGrey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adding ? null : _openAddSheet,
        backgroundColor: _accent,
        foregroundColor: _isDark ? AppColors.charcoal : Colors.white,
        icon: _adding
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _isDark ? AppColors.charcoal : Colors.white),
              )
            : const Icon(Icons.add_a_photo_rounded, size: 18),
        label: Text('Add item',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<WardrobeItem>>(
          stream: _db.streamWardrobe(),
          builder: (context, snap) {
            final items = snap.data ?? const [];

            return Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(_isDark ? 0.2 : 0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Icon(Icons.arrow_back_ios_rounded,
                                size: 18, color: _ink),
                          ),
                        ),
                      const Spacer(),
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              '${items.length} item${items.length == 1 ? '' : 's'}',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _accent)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── Header ──
                Text(
                  'MY WARDROBE',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  items.isEmpty
                      ? 'Your closet, digitized'
                      : 'Drag to rotate · Tap to view',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _muted,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),

                // ── Carousel / empty state ──
                if (items.isEmpty)
                  _emptyState()
                else
                  SizedBox(
                    height: 380,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: items.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        // 3D transformation based on scroll position
                        final value = (_currentPage - index);
                        final rotationY = value * 0.8;
                        final zTranslate = -value.abs() * 200;
                        final scale =
                            (1 - (value.abs() * 0.15)).clamp(0.6, 1.0);

                        final matrix = Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..translate(0.0, 0.0, zTranslate)
                          ..rotateY(-rotationY)
                          ..scale(scale);

                        return Transform(
                          transform: matrix,
                          alignment: FractionalOffset.center,
                          child: _WardrobeCard(
                            item: items[index],
                            isActive: value.abs() < 0.3,
                            isDark: _isDark,
                            accent: _accent,
                            surface: _surface,
                            ink: _ink,
                            muted: _muted,
                            onTap: () {
                              if (value.abs() < 0.5) {
                                _openItemModal(items[index]);
                              } else {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const Spacer(),
                // Hint under the carousel
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_rounded, size: 14, color: _muted),
                        const SizedBox(width: 6),
                        Text('Everything you buy is added automatically',
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: _muted)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: _isDark ? AppColors.darkBorder : AppColors.creamAlt),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.25 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.checkroom_rounded, size: 34, color: _accent),
            ),
            const SizedBox(height: 18),
            Text('Your wardrobe is empty',
                style: GoogleFonts.rufina(
                    fontSize: 20, fontWeight: FontWeight.bold, color: _ink)),
            const SizedBox(height: 8),
            Text(
              'Snap a photo of something you own, or shop the app — every purchase hangs itself here automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 12.5, height: 1.45, color: _muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _adding ? null : _openAddSheet,
                icon: const Icon(Icons.add_a_photo_rounded, size: 17),
                label: Text('Add your first item',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _isDark ? AppColors.charcoal : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add photo sheet ─────────────────────────────────────────────────────────
  Future<void> _openAddSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: _isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: _accent),
                title: Text('wardrobe.take_photo'.tr(),
                    style: GoogleFonts.outfit(color: _ink)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: _accent),
                title: Text('wardrobe.choose_photo'.tr(),
                    style: GoogleFonts.outfit(color: _ink)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1200, imageQuality: 85);
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

  // ── Item modal (blurred backdrop) ───────────────────────────────────────────
  void _openItemModal(WardrobeItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogCtx) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                color: Colors.black.withOpacity(_isDark ? 0.3 : 0.15),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogCtx),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 36,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dialogCtx),
                          child: Icon(Icons.close_rounded,
                              size: 20,
                              color:
                                  _isDark ? Colors.white54 : Colors.black38),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: _wardrobeImage(item.imageUrl,
                              fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.brand?.isNotEmpty == true
                            ? item.brand!
                            : 'wardrobe.categories.${item.category}'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'wardrobe.categories.${item.category}'.tr(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                      if (item.timesWorn > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Worn ${item.timesWorn} time${item.timesWorn == 1 ? '' : 's'}',
                          style:
                              GoogleFonts.outfit(fontSize: 12, color: _muted),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
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
                          icon: const Icon(Icons.auto_fix_high_rounded,
                              size: 17),
                          label: Text(
                            'Try it on',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor:
                                _isDark ? AppColors.charcoal : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Visual card for the 3D carousel ───────────────────────────────────────────
class _WardrobeCard extends StatelessWidget {
  final WardrobeItem item;
  final bool isActive;
  final bool isDark;
  final Color accent;
  final Color surface;
  final Color ink;
  final Color muted;
  final VoidCallback onTap;

  const _WardrobeCard({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.accent,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hanger hook above the card
          Icon(Icons.circle_outlined,
              size: 12, color: ink.withOpacity(isActive ? 0.55 : 0.25)),
          Container(
            width: 2,
            height: 10,
            color: ink.withOpacity(isActive ? 0.4 : 0.18),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive ? accent : Colors.transparent,
                    width: 1.6),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _wardrobeImage(item.imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                    child: Column(
                      children: [
                        Text(
                          item.brand?.isNotEmpty == true
                              ? item.brand!
                              : 'wardrobe.categories.${item.category}'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'wardrobe.categories.${item.category}'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
