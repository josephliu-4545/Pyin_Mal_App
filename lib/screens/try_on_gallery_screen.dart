import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import '../main.dart'; // AppColors
import '../services/database_service.dart';

// ── Gallery Screen ─────────────────────────────────────────────────────────────
class TryOnGalleryScreen extends StatelessWidget {
  const TryOnGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GalleryBody(isDark: isDark);
  }
}

class _GalleryBody extends StatelessWidget {
  final bool isDark;
  const _GalleryBody({required this.isDark});

  Color get _bg => isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
  Color get _ink => isDark ? Colors.white : AppColors.inkBlack;
  Color get _muted => isDark ? AppColors.paleText : AppColors.inkGrey;
  Color get _accent => isDark ? AppColors.gold : AppColors.burgundy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppColors.gold.withOpacity(0.2),
                                    AppColors.gold.withOpacity(0.05)
                                  ]
                                : [
                                    AppColors.burgundy.withOpacity(0.12),
                                    AppColors.burgundy.withOpacity(0.03)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _accent.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 12, color: _accent),
                            const SizedBox(width: 5),
                            Text('AI',
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _accent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'gallery.title'.tr(),
                    style: GoogleFonts.rufina(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'gallery.subtitle'.tr(),
                    style:
                        GoogleFonts.outfit(fontSize: 13, color: _muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Grid ─────────────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseService().streamTryOnGallery(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: _accent),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return _emptyState(context);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          items.length == 1
                              ? 'gallery.item_count_one'
                                  .tr(namedArgs: {'count': '${items.length}'})
                              : 'gallery.item_count_many'
                                  .tr(namedArgs: {'count': '${items.length}'}),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, i) => _GalleryTile(
                            item: items[i],
                            isDark: isDark,
                            onTap: () => _openDetail(context, items, i),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(
      BuildContext context, List<Map<String, dynamic>> items, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: _GalleryDetailView(
            items: items,
            initialIndex: index,
            isDark: isDark,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: _accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'gallery.empty'.tr(),
              style: GoogleFonts.rufina(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'gallery.empty_desc'.tr(),
              style:
                  GoogleFonts.outfit(fontSize: 13, color: _muted, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: _accent),
                  const SizedBox(width: 8),
                  Text(
                    'Try AI Try-On',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _accent,
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
}

// ── Grid Tile ──────────────────────────────────────────────────────────────────
class _GalleryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isDark;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  Color get _accent => isDark ? AppColors.gold : AppColors.burgundy;

  @override
  Widget build(BuildContext context) {
    final url = item['imageUrl'] as String? ?? '';
    final id = item['id'] as String? ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'gallery_$id',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: isDark
                        ? AppColors.darkWarm
                        : const Color(0xFFEEEAE5),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _accent,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark
                        ? AppColors.darkWarm
                        : const Color(0xFFEEEAE5),
                    child: Icon(Icons.broken_image_outlined,
                        color: _accent.withOpacity(0.4)),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // AI badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 9, color: _accent),
                        const SizedBox(width: 3),
                        Text('AI',
                            style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Full-screen Detail View ────────────────────────────────────────────────────
class _GalleryDetailView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int initialIndex;
  final bool isDark;

  const _GalleryDetailView({
    required this.items,
    required this.initialIndex,
    required this.isDark,
  });

  @override
  State<_GalleryDetailView> createState() => _GalleryDetailViewState();
}

class _GalleryDetailViewState extends State<_GalleryDetailView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isSaving = false;

  Color get _accent => widget.isDark ? AppColors.gold : AppColors.burgundy;
  Color get _ink => widget.isDark ? Colors.white : AppColors.inkBlack;
  Color get _muted => widget.isDark ? AppColors.paleText : AppColors.inkGrey;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _current => widget.items[_currentIndex];
  String get _currentUrl => _current['imageUrl'] as String? ?? '';
  String get _currentId => _current['id'] as String? ?? '';

  Future<void> _saveToPhone() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: false);
      }

      final response =
          await http.get(Uri.parse(Uri.encodeFull(_currentUrl)));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      await Gal.putImageBytes(
        response.bodyBytes,
        name: 'tryon_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('gallery.saved_success'.tr(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save to phone error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gallery.save_error'.tr(),
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.darkWarm : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('gallery.delete'.tr(),
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: _ink)),
        content: Text('gallery.delete_confirm'.tr(),
            style: GoogleFonts.outfit(color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('gallery.delete_no'.tr(),
                style: GoogleFonts.outfit(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('gallery.delete_yes'.tr(),
                style: GoogleFonts.outfit(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await DatabaseService().deleteTryOnGalleryItem(_currentId);
    if (!mounted) return;
    if (widget.items.length == 1) {
      Navigator.pop(context);
    } else {
      final newIndex = _currentIndex > 0 ? _currentIndex - 1 : 0;
      setState(() => _currentIndex = newIndex);
      _pageController.jumpToPage(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Page view ─────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              final url = widget.items[i]['imageUrl'] as String? ?? '';
              final id = widget.items[i]['id'] as String? ?? '';
              return InteractiveViewer(
                child: Hero(
                  tag: 'gallery_$id',
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white54, size: 60),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      _iconBtn(Icons.arrow_back_ios_rounded,
                          () => Navigator.pop(context)),
                      const Spacer(),
                      Text(
                        '${_currentIndex + 1} / ${widget.items.length}',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _iconBtn(Icons.delete_outline_rounded, _delete,
                          color: Colors.red.shade300),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom action bar ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveToPhone,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'gallery.save_to_phone'.tr(),
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: widget.isDark
                            ? AppColors.charcoal
                            : Colors.white,
                        disabledBackgroundColor: _accent.withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Page indicator dots ───────────────────────────────────────────
          if (widget.items.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 90,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length.clamp(0, 10),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? _accent
                          : Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
