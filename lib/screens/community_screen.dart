import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/models/outfit_post.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/image_host_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _posting = false;
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
        onPressed: _posting ? null : _openPostSheet,
        backgroundColor: accent,
        foregroundColor: isDark ? AppColors.charcoal : Colors.white,
        icon: _posting
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.charcoal : Colors.white),
              )
            : const Icon(Icons.add_a_photo_rounded, size: 18),
        label: Text('community.post_ootd'.tr(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<OutfitPost>>(
          stream: _db.streamFeed(),
          builder: (context, snap) {
            final posts = snap.data ?? const [];
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
                        Text('community.title'.tr(),
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
                            child: Icon(Icons.auto_awesome_rounded,
                                color: accent, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('community.hero_title'.tr(),
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: ink)),
                                const SizedBox(height: 3),
                                Text('community.hero_desc'.tr(),
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
                if (posts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_outlined,
                              size: 48, color: muted.withOpacity(0.6)),
                          const SizedBox(height: 12),
                          Text('community.empty'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 13, color: muted)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _OutfitCard(
                          post: posts[i],
                          isDark: isDark,
                          cardBg: cardBg,
                          ink: ink,
                          muted: muted,
                          accent: accent,
                          onTap: () => _openDetailSheet(posts[i], isDark, accent),
                        ),
                        childCount: posts.length,
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

  // ── Post OOTD sheet ──────────────────────────────────────────────────────────
  Future<void> _openPostSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    final captionCtrl = TextEditingController();
    XFile? photo;
    Uint8List? photoBytes;
    final wardrobeItems = await _db.getWardrobeItemsOnce();
    final selectedIds = <String>{};

    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          Future<void> pickPhoto(ImageSource source) async {
            final picked = await ImagePicker().pickImage(
                source: source, maxWidth: 1200, imageQuality: 85);
            if (picked == null) return;
            final bytes = await picked.readAsBytes();
            setSheet(() {
              photo = picked;
              photoBytes = bytes;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Text('community.post_title'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 4),
                    Text('community.post_desc'.tr(),
                        style: GoogleFonts.outfit(fontSize: 12, color: muted)),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final source = await showModalBottomSheet<ImageSource>(
                          context: sheetCtx,
                          builder: (c) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt_rounded),
                                  title: Text('wardrobe.take_photo'.tr()),
                                  onTap: () => Navigator.pop(c, ImageSource.camera),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library_rounded),
                                  title: Text('wardrobe.choose_photo'.tr()),
                                  onTap: () => Navigator.pop(c, ImageSource.gallery),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (source != null) await pickPhoto(source);
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF4F4F4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent.withOpacity(0.35)),
                        ),
                        child: photoBytes != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: Image.memory(photoBytes!, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text('resell.change'.tr(),
                                          style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      color: accent, size: 28),
                                  const SizedBox(height: 6),
                                  Text('community.add_photo'.tr(),
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accent)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: captionCtrl,
                      maxLines: 2,
                      style: GoogleFonts.outfit(fontSize: 13, color: ink),
                      decoration: InputDecoration(
                        hintText: 'community.caption_hint'.tr(),
                        hintStyle: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFFAAAAAA)),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF4F4F4),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (wardrobeItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('community.wearing'.tr(),
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: muted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: wardrobeItems.map((item) {
                          final selected = selectedIds.contains(item.id);
                          return GestureDetector(
                            onTap: () => setSheet(() {
                              if (selected) {
                                selectedIds.remove(item.id);
                              } else {
                                selectedIds.add(item.id);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? accent
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFF0F0F0)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                  item.brand?.isNotEmpty == true
                                      ? item.brand!
                                      : 'wardrobe.categories.${item.category}'.tr(),
                                  style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? (isDark ? AppColors.charcoal : Colors.white)
                                          : ink)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: photo == null
                            ? null
                            : () => Navigator.pop(sheetCtx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor:
                              isDark ? AppColors.charcoal : Colors.white,
                          disabledBackgroundColor: accent.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('community.post'.tr(),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (confirmed != true || photo == null) return;

    setState(() => _posting = true);
    bool ok = false;
    try {
      final bytes = await ImageHostService.compress(photo!);
      final imageUrl = await ImageHostService.upload(bytes, 'ootd_post');
      if (imageUrl != null) {
        final id = await _db.createOutfitPost(
          imageUrl: imageUrl,
          caption: captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
          wardrobeItemIds: selectedIds.toList(),
        );
        ok = id != null;
      }
    } catch (e) {
      debugPrint('CommunityScreen: failed to post OOTD: $e');
    }
    if (!mounted) return;
    setState(() => _posting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'community.posted'.tr() : 'community.post_failed'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Detail / like sheet ──────────────────────────────────────────────────────
  void _openDetailSheet(OutfitPost post, bool isDark, Color accent) {
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => FutureBuilder<bool>(
        future: _db.isLikedByMe(post.id),
        builder: (context, likeSnap) {
          return StatefulBuilder(builder: (sheetCtx, setSheet) {
            var liked = likeSnap.data ?? false;
            var likeCount = post.likeCount;
            return Container(
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
                      height: 260,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: accent.withOpacity(0.15),
                              backgroundImage: post.avatarUrl != null
                                  ? NetworkImage(post.avatarUrl!)
                                  : null,
                              child: post.avatarUrl == null
                                  ? Text(
                                      post.username.isNotEmpty
                                          ? post.username[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: accent))
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(post.username,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                          ],
                        ),
                        if (post.caption != null && post.caption!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(post.caption!,
                              style: GoogleFonts.outfit(
                                  fontSize: 13, height: 1.4, color: ink)),
                        ],
                        if (post.wardrobeItemIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                'community.items_tagged'
                                    .tr(args: [post.wardrobeItemIds.length.toString()]),
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accent)),
                          ),
                        ],
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: () async {
                            try {
                              final nowLiked = await _db.toggleLike(post.id);
                              setSheet(() {
                                liked = nowLiked;
                                likeCount += nowLiked ? 1 : -1;
                              });
                            } catch (e) {
                              debugPrint('CommunityScreen: toggleLike failed: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('community.post_failed'.tr())),
                                );
                              }
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                  liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: liked ? const Color(0xFFE53935) : muted,
                                  size: 24),
                              const SizedBox(width: 8),
                              Text('community.likes'.tr(args: [likeCount.toString()]),
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  final OutfitPost post;
  final bool isDark;
  final Color cardBg;
  final Color ink;
  final Color muted;
  final Color accent;
  final VoidCallback onTap;

  const _OutfitCard({
    required this.post,
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
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                  ),
                ),
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
                    Text(post.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w600, color: ink)),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            size: 12, color: Color(0xFFE53935)),
                        const SizedBox(width: 4),
                        Text('${post.likeCount}',
                            style: GoogleFonts.outfit(fontSize: 11, color: muted)),
                      ],
                    ),
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
