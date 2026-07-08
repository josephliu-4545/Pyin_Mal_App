import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/models/wardrobe_item.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/wardrobe_service.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';

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
  final _db = DatabaseService();
  bool _adding = false;
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // viewportFraction controls how close the cards are to each other
    _pageController = PageController(viewportFraction: 0.45);
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

  @override
  Widget build(BuildContext context) {
    // Matching the video's light blue background aesthetic
    const bg = Color(0xFFA1D6E2);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _adding ? null : _openAddSheet,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: _adding
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : const Icon(Icons.add_a_photo_rounded),
      ),
      body: SafeArea(
        child: StreamBuilder<List<WardrobeItem>>(
          stream: _db.streamWardrobe(),
          builder: (context, snap) {
            final items = snap.data ?? const [];

            return Column(
              children: [
                const SizedBox(height: 40),
                // Video Header
                Text(
                  'MY WARDROBE',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Drag to rotate · Click to view',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                
                // 3D Carousel View
                if (items.isEmpty)
                  Center(
                    child: Text('wardrobe.empty'.tr(),
                        style: GoogleFonts.outfit(color: Colors.black54)),
                  )
                else
                  SizedBox(
                    height: 380, // Height of the cards
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: items.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        // Calculate 3D transformation logic based on scroll position
                        final value = (_currentPage - index);
                        final rotationY = value * 0.8; // Y-axis rotation
                        final zTranslate = -value.abs() * 200; // Push side items back
                        final scale = (1 - (value.abs() * 0.15)).clamp(0.6, 1.0); // Scale down side items

                        final matrix = Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Adds 3D perspective
                          ..translate(0.0, 0.0, zTranslate)
                          ..rotateY(-rotationY) // Negative to rotate naturally with swipe
                          ..scale(scale);

                        return Transform(
                          transform: matrix,
                          alignment: FractionalOffset.center,
                          child: _Wardrobe3DCard(
                            item: items[index],
                            isActive: value.abs() < 0.3,
                            onTap: () {
                              // If tapped when centered, open modal. Otherwise, scroll to it.
                              if (value.abs() < 0.5) {
                                _open3DModal(items[index]);
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
              ],
            );
          },
        ),
      ),
    );
  }

  // Maintains your existing photo upload logic
  Future<void> _openAddSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.black),
                title: Text('wardrobe.take_photo'.tr(),
                    style: GoogleFonts.outfit(color: Colors.black)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.black),
                title: Text('wardrobe.choose_photo'.tr(),
                    style: GoogleFonts.outfit(color: Colors.black)),
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

  // The blurred modal pop-up shown in the video
  void _open3DModal(WardrobeItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Background blur handles the dimming
      builder: (context) {
        return Stack(
          children: [
            // Blur Effect over the entire screen
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
            // The Modal Dialog
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Right Close Button
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, size: 20, color: Colors.grey),
                        ),
                      ),
                      // Item Image
                      SizedBox(
                        height: 180,
                        child: _wardrobeImage(item.imageUrl, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 16),
                      // Title & Brand
                      Text(
                        item.brand?.isNotEmpty == true
                            ? item.brand!
                            : 'wardrobe.categories.${item.category}'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'wardrobe.categories.${item.category}'.tr(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Dummy Price matching the video
                      Text(
                        '\$69',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Size Selector (S, M, L, XL)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['S', 'M', 'L', 'XL'].map((size) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: size == 'M' ? Colors.grey[200] : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              size,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: size == 'M' ? Colors.black : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Add to Cart Button (Matches video's yellow button)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Close modal
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5C05C), // Mustard Yellow
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Try On / Add to Cart',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

// Visual Card for the 3D Carousel
class _Wardrobe3DCard extends StatelessWidget {
  final WardrobeItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _Wardrobe3DCard({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85), // Frosted glass look
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isActive) // Glow effect for center item
              BoxShadow(
                color: Colors.white.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                padding: const EdgeInsets.all(20.0),
                child: _wardrobeImage(item.imageUrl, fit: BoxFit.contain),
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.brand?.isNotEmpty == true
                        ? item.brand!
                        : 'wardrobe.categories.${item.category}'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Dummy price to match the video aesthetic
                  Text(
                    '\$69',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
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