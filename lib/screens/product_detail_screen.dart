import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/core/constants/api_constants.dart';
import '../widgets/product_3d_viewer.dart';
import '../widgets/cdn_image.dart';
import '../models/product.dart';
import '../widgets/cart_bar.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/size_recommendation_service.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';
import 'package:pyin_mal_app/models/clothing_item.dart';
import 'package:pyin_mal_app/screens/try_on_screen.dart';
import 'package:pyin_mal_app/screens/ar_fitting_room_screen.dart';
import 'package:pyin_mal_app/screens/shop_products_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final String price;
  final String image;
  final String brand;
  final String category;
  final String? description;
  final String? shopName;
  /// When non-null, the product is on sale at this % discount and a
  /// strikethrough original price is shown next to the sale price.
  final int? discount;
  /// colorCode → list of all photos for that color. Empty for OpenCart products.
  final Map<String, List<String>> colorVariants;
  /// Default color to show when the screen opens.
  final String defaultColor;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.brand,
    required this.category,
    this.description,
    this.shopName,
    this.discount,
    this.colorVariants = const {},
    this.defaultColor = '',
  });

  /// Convenience constructor — pass a [Product] directly.
  factory ProductDetailScreen.fromProduct(Product p, {int? discount}) {
    return ProductDetailScreen(
      productId: p.id,
      name: p.name,
      price: p.price,
      image: p.image,
      brand: p.brand,
      category: p.category,
      description: p.description,
      shopName: p.shopName,
      colorVariants: p.colorVariants,
      defaultColor: p.defaultColor,
      discount: discount,
    );
  }

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedSize = 'M';
  bool _isFavorite = false;
  late String _selectedColor;

  // Size recommendation from the user's saved Bodygram measurements.
  SizeRecommendation? _sizeRec;

  // ── Photo gallery ─────────────────────────────────────────────────────────
  final PageController _galleryController = PageController();
  int _galleryPage = 0;

  List<String> get _galleryImages {
    if (widget.colorVariants.isNotEmpty) {
      return widget.colorVariants[_selectedColor] ??
          widget.colorVariants.values.first;
    }
    return [widget.image];
  }

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.defaultColor.isNotEmpty
        ? widget.defaultColor
        : (widget.colorVariants.keys.isNotEmpty
            ? widget.colorVariants.keys.first
            : '');
    _loadSizeRecommendation();
    // Position the PiP at the top-right of the card once layout is known.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = MediaQuery.of(context).size.width;
      setState(() {
        _pipOffset = Offset(w - _pipW - 20, 90);
      });
    });
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }


  // ── Variant picker sheet (color + size + quantity) ──────────────────────────
  void _showVariantSheet(bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final sheetBg = isDark ? AppColors.charcoal : Colors.white;
    final fill = isDark ? AppColors.darkWarm : const Color(0xFFF3F1F0);

    // Local selection state for the sheet.
    String color = _selectedColor;
    String size = _selectedSize;
    int qty = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Widget chip(String label, bool selected, VoidCallback onTap,
                {Widget? recBadge}) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? accent.withOpacity(0.14) : fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? accent : Colors.transparent,
                      width: 1.6,
                    ),
                  ),
                  child: Text(label,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? accent : ink)),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: muted.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Header: image + price + selection summary
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 84,
                                height: 84,
                                child: CdnImage(widget.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: fill,
                                        child: Icon(Icons.image_outlined,
                                            color: muted))),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.price,
                                      style: GoogleFonts.rufina(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: accent)),
                                  const SizedBox(height: 6),
                                  Text('Selected: $color · Size $size',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12, color: muted)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(sheetCtx),
                              child: Icon(Icons.close_rounded, color: muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Color
                        Text('Color',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                        const SizedBox(height: 12),
                        if (widget.colorVariants.isNotEmpty)
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: widget.colorVariants.entries.map((entry) {
                              final colorCode = entry.key;
                              final photos = entry.value;
                              final thumbPhoto = photos.isNotEmpty ? photos.first : '';
                              final sel = color == colorCode;
                              return GestureDetector(
                                onTap: () => setSheet(() => color = colorCode),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: sel ? accent : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: thumbPhoto.isNotEmpty
                                            ? Image.asset(thumbPhoto, fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(color: Colors.grey.shade300))
                                            : Container(color: Colors.grey.shade300),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(colorCode.toUpperCase(),
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                            color: sel ? accent : muted)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 22),
                        // Size
                        Row(
                          children: [
                            Text('Size',
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            if (_sizeRec != null) ...[
                              const SizedBox(width: 8),
                              Text('(recommended: ${_sizeRec!.size})',
                                  style: GoogleFonts.outfit(
                                      fontSize: 11, color: AppColors.gold)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _sizes
                              .map((s) => chip(s, size == s,
                                  () => setSheet(() => size = s)))
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                        // Quantity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Quantity',
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            Row(
                              children: [
                                _qtyBtn(Icons.remove_rounded, fill, ink,
                                    () => setSheet(() {
                                          if (qty > 1) qty--;
                                        })),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  child: Text('$qty',
                                      style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: ink)),
                                ),
                                _qtyBtn(Icons.add_rounded, fill, ink,
                                    () => setSheet(() => qty++)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Confirm
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              CartService.instance.addToCart(CartItem(
                                productId: widget.productId,
                                name: widget.name,
                                price: widget.price,
                                image: widget.image,
                                brand: widget.brand,
                                size: size,
                                color: color,
                                quantity: qty,
                              ));
                              // Reflect the choice on the page too.
                              setState(() {
                                _selectedColor = color;
                                _selectedSize = size;
                              });
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Added $qty × $color · Size $size'),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                            icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                            label: Text('Add to cart',
                                style: GoogleFonts.outfit(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor:
                                  isDark ? AppColors.charcoal : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _qtyBtn(IconData icon, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }

  Future<void> _loadSizeRecommendation() async {
    try {
      final data = await DatabaseService().getUserData();
      final saved = data?['bodyMeasurements'];
      if (saved is! Map) return;
      final rec = SizeRecommendationService.recommend(
        measurements:
            BodyMeasurements.fromMap(Map<String, dynamic>.from(saved)),
        category: widget.category,
        gender: data?['gender'] as String? ?? 'Female',
      );
      if (rec != null && mounted) {
        setState(() {
          _sizeRec = rec;
          _selectedSize = rec.size;
        });
      }
    } catch (_) {} // no measurements / offline — selector works as before
  }

  /// Color code → 3D model asset for the "Star Wear" product. The filename
  /// prefix is the color (e.g. 'w' = white), matching the photo naming scheme
  /// in AssetProductLoader. Add an entry here as you export a model per color.
  static const Map<String, String> _starWearModels = {
    'w': 'assets/models/w_star_wear_p1.glb',
  };

  /// 3D model asset for this product + selected color, or null if none.
  /// Only "Star Wear" ships with a real 3D model for now — every other product
  /// shows photos only (no 360° view).
  String? get _model3dAsset {
    final normalized =
        widget.name.toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
    if (!normalized.contains('starwear')) return null;
    // Prefer the model for the selected color; fall back to any available one
    // so the 3D view still works while only some colors have a model.
    return _starWearModels[_selectedColor] ??
        (_starWearModels.isNotEmpty ? _starWearModels.values.first : null);
  }

  bool get _has3DModel => _model3dAsset != null;

  // Hero view toggle — image (Photo) is default
  bool _show3DView = false;

  // Reviews: collapsed by default (show 2), expandable
  bool _showAllReviews = false;

  // Floating video pip state
  bool _showVideoPip = true;
  // Initialised to the right edge after the first frame (see initState).
  Offset _pipOffset = const Offset(9999, 90);
  static const double _pipW = 100;
  static const double _pipH = 130;
  static const double _heroH = 420;

  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];

  final List<Map<String, dynamic>> _reviews = [
    {'name': 'Aye Myat', 'rating': 5, 'comment': 'Absolutely love it! Great quality and fits perfectly.', 'date': '2 days ago'},
    {'name': 'Ko Zaw',   'rating': 4, 'comment': 'Very good product, fast shipping. Would buy again.', 'date': '1 week ago'},
    {'name': 'Ma Thida', 'rating': 5, 'comment': 'The material feels premium. Highly recommended!',     'date': '2 weeks ago'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final accent  = isDark ? AppColors.gold : AppColors.burgundy;
    final bgColor = isDark ? AppColors.charcoal : const Color(0xFFF5F5F5);
    final cardBg  = isDark ? AppColors.darkWarm  : Colors.white;

    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const SafeArea(top: false, child: CartBar()),
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavBtn(
                    icon: Icons.arrow_back_ios_rounded,
                    isDark: isDark,
                    onTap: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      _NavBtn(
                        icon: _isFavorite ? Icons.favorite : Icons.favorite_outline,
                        isDark: isDark,
                        iconColor: _isFavorite ? AppColors.burgundy : null,
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                      ),
                      const SizedBox(width: 10),
                      _NavBtn(icon: Icons.share_rounded, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── 1. IMAGE (with overlaid size selector + rotation) ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SizedBox(
                              height: _heroH,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // IMAGE VIEW (default) — swipeable gallery
                                  AnimatedOpacity(
                                    opacity: _show3DView ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeInOut,
                                    child: IgnorePointer(
                                      ignoring: _show3DView,
                                      child: Container(
                                        width: double.infinity,
                                        height: _heroH,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkWarm
                                              : const Color(0xFFF0EEF0),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              // Sliding pages — different angles / poses
                                              PageView.builder(
                                                controller: _galleryController,
                                                itemCount: _galleryImages.length,
                                                onPageChanged: (i) => setState(
                                                    () => _galleryPage = i),
                                                itemBuilder: (_, i) => CdnImage(
                                                  _galleryImages[i],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Center(
                                                    child: Icon(
                                                        Icons.image_outlined,
                                                        size: 60,
                                                        color: isDark
                                                            ? Colors.white24
                                                            : Colors.grey
                                                                .withOpacity(
                                                                    0.4)),
                                                  ),
                                                ),
                                              ),
                                              // "1 / N" counter (bottom-left)
                                              if (_galleryImages.length > 1)
                                                Positioned(
                                                  left: 12,
                                                  bottom: 12,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      '${_galleryPage + 1} / ${_galleryImages.length}',
                                                      style: GoogleFonts.outfit(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              // Dot indicators (bottom-center)
                                              if (_galleryImages.length > 1)
                                                Positioned(
                                                  bottom: 14,
                                                  left: 0,
                                                  right: 0,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    children: List.generate(
                                                        _galleryImages.length,
                                                        (i) {
                                                      final sel =
                                                          _galleryPage == i;
                                                      return AnimatedContainer(
                                                        duration: const Duration(
                                                            milliseconds: 220),
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 3),
                                                        width: sel ? 18 : 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          color: sel
                                                              ? Colors.white
                                                              : Colors.white
                                                                  .withOpacity(
                                                                      0.5),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(3),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 3D VIEW — only for products that ship a model
                                  if (_has3DModel)
                                    AnimatedOpacity(
                                      opacity: _show3DView ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 260),
                                      curve: Curves.easeInOut,
                                      child: IgnorePointer(
                                        ignoring: !_show3DView,
                                        child: Product3DViewer(
                                          height: _heroH,
                                          isDark: isDark,
                                          modelAsset: _model3dAsset,
                                        ),
                                      ),
                                    ),

                                  // VIEW TOGGLE PILL (top-center) — only shown
                                  // when this product has a 3D model.
                                  if (_has3DModel)
                                    Positioned(
                                      top: 14,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.45),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _viewTab(
                                                label: 'product.photo'.tr(),
                                                icon: Icons.image_rounded,
                                                active: !_show3DView,
                                                onTap: () => setState(
                                                    () => _show3DView = false),
                                              ),
                                              _viewTab(
                                                label: 'product.360'.tr(),
                                                icon: Icons.view_in_ar_rounded,
                                                active: _show3DView,
                                                onTap: () => setState(
                                                    () => _show3DView = true),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  // (Video PiP is rendered at screen level so
                                  // it can be dragged anywhere on the page.)
                                  if (!_showVideoPip)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _showVideoPip = true;
                                          _pipOffset = Offset(
                                              screenSize.width - _pipW - 16, 90);
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.55),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.play_circle_outline_rounded,
                                                  color: Colors.white,
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text('product.preview'.tr(),
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                ],
                              ),
                            ),
                    ),

                    // ── Size recommendation pill (from body scan) ────────────
                    if (_sizeRec != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.gold
                                  .withOpacity(isDark ? 0.16 : 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.gold.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.straighten_rounded,
                                    size: 15, color: AppColors.gold),
                                const SizedBox(width: 6),
                                Text(
                                  'product.your_size'
                                      .tr(args: [_sizeRec!.size]),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.goldLight
                                        : AppColors.inkBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── 2. COLOR STRIP (directly under product) ──────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Hint row — shown only in 360° view
                          if (_show3DView) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFF0F0F0),
                                  ),
                                  child: Icon(Icons.swap_horiz_rounded,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF888888)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'product.swipe_hint'.tr(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Color thumbnails — one circle per color variant
                          if (widget.colorVariants.length > 1)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.of(context).size.width - 48,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: widget.colorVariants.entries.toList().asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final colorCode = entry.value.key;
                                  final photos = entry.value.value;
                                  final thumbPhoto = photos.isNotEmpty ? photos.first : '';
                                  final sel = _selectedColor == colorCode;
                                  final variants = widget.colorVariants.entries.toList();
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedColor = colorCode;
                                      _galleryPage = 0;
                                      _galleryController.jumpToPage(0);
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOut,
                                      margin: EdgeInsets.only(
                                          right: i < variants.length - 1 ? 16 : 0),
                                      width:  sel ? 64 : 54,
                                      height: sel ? 64 : 54,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: sel
                                              ? (isDark ? Colors.white : AppColors.inkBlack)
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(sel ? 0.22 : 0.08),
                                            blurRadius: sel ? 14 : 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: thumbPhoto.isNotEmpty
                                            ? Image.asset(
                                                thumbPhoto,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: isDark ? Colors.white12 : Colors.black12,
                                                ),
                                              )
                                            : Container(
                                                color: isDark ? Colors.white12 : Colors.black12,
                                              ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── 3. TRY IN AR + TRY ON + SHOP NOW buttons ────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Live AR try-on ──────────────────────────────────
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ARFittingRoomScreen(
                                  productId: widget.productId,
                                  productName: widget.name,
                                  productPrice: widget.price,
                                  productImage: widget.image,
                                  productBrand: widget.brand,
                                  initialItem: mockClothingItems.first,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.view_in_ar_rounded, size: 18),
                            label: Text(
                              'Try in AR',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor:
                                  isDark ? AppColors.gold : AppColors.burgundy,
                              foregroundColor:
                                  isDark ? AppColors.charcoal : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ── AI try-on + Shop Now row ────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(
                                          builder: (_) => TryOnScreen(
                                            initialImageUrl: widget.image,
                                            initialCategory: widget.category,
                                          ))),
                                  icon: const Icon(
                                      Icons.face_retouching_natural_rounded,
                                      size: 16),
                                  label: Text('product.try_on'.tr(),
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    side: BorderSide(
                                        color: isDark
                                            ? Colors.white24
                                            : const Color(0xFFCCCCCC),
                                        width: 1.5),
                                    foregroundColor: isDark
                                        ? Colors.white
                                        : AppColors.inkBlack,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  key: GuideKeys.productAddToCart,
                                  onPressed: () => _showVariantSheet(isDark),
                                  icon: const Icon(Icons.add_shopping_cart_rounded,
                                      size: 16),
                                  label: Text('product.shop_now'.tr(),
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                    backgroundColor: isDark
                                        ? Colors.white
                                        : AppColors.inkBlack,
                                    foregroundColor: isDark
                                        ? AppColors.charcoal
                                        : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── 4. PRODUCT INFO CARD ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDark ? 0.2 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop name chip
                            if (widget.shopName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.storefront_rounded,
                                        size: 12, color: accent),
                                    const SizedBox(width: 5),
                                    Text(widget.shopName!,
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: accent)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Product name + category badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.inkBlack,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.category,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF777777),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Price row — strikethrough original only shown for sale items
                            Row(
                              children: [
                                Text(
                                  widget.price,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: widget.discount != null
                                        ? const Color(0xFFE53935)
                                        : accent,
                                  ),
                                ),
                                if (widget.discount != null) ...[  
                                  const SizedBox(width: 10),
                                  Builder(builder: (_) {
                                    final d = widget.discount!;
                                    final match = RegExp(r'[\d,]+').firstMatch(widget.price);
                                    if (match == null) return const SizedBox.shrink();
                                    final sale = int.tryParse(match.group(0)!.replaceAll(',', ''));
                                    if (sale == null) return const SizedBox.shrink();
                                    final original = (sale / (1 - d / 100)).round();
                                    final label = widget.price.replaceFirst(RegExp(r'[\d,]+'), '').trim();
                                    final withSep = original.toString().replaceAllMapped(
                                        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
                                    return Text(
                                      '$withSep $label'.trim(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: isDark
                                            ? Colors.white30
                                            : const Color(0xFFBBBBBB),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Rating
                            Row(
                              children: [
                                ...List.generate(
                                    5,
                                    (_) => Icon(Icons.star_rounded,
                                        color: AppColors.gold, size: 15)),
                                const SizedBox(width: 6),
                                Text('4.8',
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.inkBlack)),
                                const SizedBox(width: 4),
                                Text('(128 reviews)',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF999999))),
                              ],
                            ),

                            // Divider
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: Divider(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFEEEEEE),
                                height: 1,
                              ),
                            ),

                            // Description
                            if (widget.description != null) ...[
                              Text(
                                widget.description!,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  height: 1.65,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── 4b. SIZE CHART & GUIDE ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _buildSizeGuideSection(isDark, accent, cardBg),
                    ),

                    // ── 5. REVIEWS SECTION ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('product.reviews_title'.tr(args: [_reviews.length.toString()]),
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.inkBlack)),
                              GestureDetector(
                                onTap: _openReviewSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.rate_review_outlined,
                                          size: 14, color: accent),
                                      const SizedBox(width: 5),
                                      Text('product.write_review'.tr(),
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: accent)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...(_showAllReviews
                                  ? _reviews
                                  : _reviews.take(2))
                              .map((r) => _ReviewCard(
                                    review: r,
                                    isDark: isDark,
                                    cardBg: cardBg,
                                  )),
                          // See all / Show less toggle (only if >2 reviews)
                          if (_reviews.length > 2)
                            GestureDetector(
                              onTap: () => setState(
                                  () => _showAllReviews = !_showAllReviews),
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showAllReviews
                                          ? 'product.show_less'.tr()
                                          : 'product.see_all_reviews'.tr(args: [_reviews.length.toString()]),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: accent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showAllReviews
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── 6. SHOP BANNER ────────────────────────────────────────
                    if (widget.shopName != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.2 : 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Shop logo circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.store_rounded,
                                    color: accent, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.shopName!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.inkBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'product.shop_stats'.tr(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF999999),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShopProductsScreen(
                                        shopName: widget.shopName!),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: accent, width: 1.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('product.visit'.tr(),
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accent)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── 7. CHARACTERISTICS ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('product.characteristics'.tr(),
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.inkBlack)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(isDark ? 0.2 : 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _CharRow('product.chars.comfort'.tr(),  'product.chars.comfort_val'.tr(), isDark, isFirst: true),
                                _CharRow('product.chars.textile'.tr(),  'product.chars.textile_val'.tr(),       isDark),
                                _CharRow('product.chars.style'.tr(),    'product.chars.style_val'.tr(), isDark),
                                _CharRow('product.chars.fit'.tr(),      'product.chars.fit_val'.tr(),       isDark),
                                _CharRow('product.chars.material'.tr(), 'product.chars.material_val'.tr(),   isDark, isLast: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),

          // Screen-wide draggable video PiP — floats over the whole page
          if (_showVideoPip)
            Positioned(
              left: _pipOffset.dx,
              top: _pipOffset.dy,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    final nx = (_pipOffset.dx + d.delta.dx)
                        .clamp(0.0, screenSize.width - _pipW);
                    final ny = (_pipOffset.dy + d.delta.dy)
                        .clamp(0.0, screenSize.height - _pipH);
                    _pipOffset = Offset(nx, ny);
                  });
                },
                child: _FloatingVideoPip(
                  isDark: isDark,
                  image: widget.image,
                  accent: accent,
                  onClose: () => setState(() => _showVideoPip = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Size chart data (cm) ──────────────────────────────────────────────────
  // ── Compact "Size & Fit" section (above reviews) ──────────────────────────
  Widget _buildSizeGuideSection(bool isDark, Color accent, Color cardBg) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text('Size & Fit',
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ink)),
            ],
          ),
          const SizedBox(height: 14),
          // Single full-width Size Guide button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openSizeGuideSheet(0),
              icon: const Icon(Icons.straighten_rounded, size: 16),
              label: Text('Size Guide',
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFCCCCCC)),
                foregroundColor: ink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fit stat
          Row(
            children: [
              Icon(Icons.thumb_up_alt_rounded, size: 14, color: accent),
              const SizedBox(width: 6),
              Text('94% found it true to size',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ink)),
              const Spacer(),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks — we\'ll note your feedback')),
                ),
                child: Text('Not your size?',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Full size guide bottom sheet (table + shop chart + fit) ───────────────
  void _openSizeGuideSheet(int initialTab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    int tab = initialTab; // 0 = Product Chart (image), 1 = Body Chart
    // Body Chart state
    String? bodyShape;
    double bust = 34;
    double waist = 27;
    double hips = 37;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scroll) => Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 14),
                  Text('Size Guide',
                      style: GoogleFonts.rufina(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink)),
                  const SizedBox(height: 14),
                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _sizeTab('Product Chart', 0, tab, accent, ink, isDark,
                              () => setSheet(() => tab = 0)),
                          _sizeTab('Body Chart', 1, tab, accent, ink, isDark,
                              () => setSheet(() => tab = 1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: tab == 0
                          ? _shopChart(isDark, accent, ink, muted)
                          : _bodyChart(
                              isDark,
                              accent,
                              ink,
                              muted,
                              bodyShape,
                              bust,
                              waist,
                              hips,
                              (s) => setSheet(() => bodyShape = s),
                              (b) => setSheet(() => bust = b),
                              (w) => setSheet(() => waist = w),
                              (h) => setSheet(() => hips = h),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sizeTab(String label, int idx, int current, Color accent, Color ink,
      bool isDark, VoidCallback onTap) {
    final sel = current == idx;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sel
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : ink)),
        ),
      ),
    );
  }

  // Body-chart reference ranges (inches): Size, Height, Bust, Waist, Hip
  static const _bodyChartRows = <List<String>>[
    ['XS', '63-65', '32.3-33.9', '24.4-26', '34.3-35.8'],
    ['S', '65-66.9', '33.9-35.4', '26-27.6', '35.8-37.4'],
    ['M', '65-66.9', '35.4-37', '27.6-29.1', '37.4-39'],
    ['L', '66.9-68.9', '37-39.4', '29.1-31.5', '39-41.3'],
    ['XL', '66.9-68.9', '39.4-41.7', '31.5-33.9', '41.3-43'],
  ];

  // Upper bounds (inches) used to map a measurement to a size index.
  static const _bustBounds = [33.9, 35.4, 37.0, 39.4];
  static const _waistBounds = [26.0, 27.6, 29.1, 31.5];
  static const _hipsBounds = [35.8, 37.4, 39.0, 41.3];
  static const _sizeLabels = ['XS', 'S', 'M', 'L', 'XL'];

  int _bandFor(double value, List<double> bounds) {
    for (var i = 0; i < bounds.length; i++) {
      if (value <= bounds[i]) return i;
    }
    return bounds.length; // last size
  }

  String _recommendSize(double bust, double waist, double hips) {
    // Bust carries the most weight; average the three bands and round.
    final b = _bandFor(bust, _bustBounds);
    final w = _bandFor(waist, _waistBounds);
    final h = _bandFor(hips, _hipsBounds);
    final idx = ((b * 2 + w + h) / 4).round().clamp(0, 4);
    return _sizeLabels[idx];
  }

  // Interactive Body Chart: reference table + body shape + measurements → size
  Widget _bodyChart(
    bool isDark,
    Color accent,
    Color ink,
    Color muted,
    String? bodyShape,
    double bust,
    double waist,
    double hips,
    ValueChanged<String> onShape,
    ValueChanged<double> onBust,
    ValueChanged<double> onWaist,
    ValueChanged<double> onHips,
  ) {
    final headerBg = isDark ? Colors.white10 : const Color(0xFFF4F2EF);
    final line = isDark ? Colors.white12 : const Color(0xFFEDE9E4);
    const headers = ['Size', 'Height', 'Bust', 'Waist', 'Hip'];
    final recommended = _recommendSize(bust, waist, hips);

    const shapes = [
      ['Hourglass', '⏳'],
      ['Triangle', '▽'],
      ['Rounded', '◯'],
      ['Rectangle', '▭'],
      ['Inverted Triangle', '△'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Reference table ──
        Text('Body size reference (in)',
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w600, color: muted)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: line),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(13)),
                ),
                child: Row(
                  children: headers
                      .map((h) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              child: Text(h,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: ink)),
                            ),
                          ))
                      .toList(),
                ),
              ),
              ..._bodyChartRows.map((row) {
                final isMine = row[0] == recommended;
                return Container(
                  decoration: BoxDecoration(
                    color: isMine ? accent.withOpacity(0.10) : null,
                    border: Border(top: BorderSide(color: line)),
                  ),
                  child: Row(
                    children: List.generate(row.length, (c) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(row[c],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: c == 0 || isMine
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isMine ? accent : ink)),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('*For reference only — depends on body type & fit preference.',
            style: GoogleFonts.outfit(fontSize: 11, color: muted)),
        const SizedBox(height: 24),

        // ── Your Body Shape ──
        Text('Your Body Shape',
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: shapes.map((s) {
            final sel = bodyShape == s[0];
            return GestureDetector(
              onTap: () => onShape(s[0]),
              child: Container(
                width: 96,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? accent.withOpacity(0.12)
                      : (isDark ? Colors.white10 : const Color(0xFFF6F4F1)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? accent : Colors.transparent, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(s[1],
                        style: TextStyle(
                            fontSize: 22,
                            color: sel ? accent : ink)),
                    const SizedBox(height: 6),
                    Text(s[0],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? accent : ink)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // ── Your Measurements ──
        Text('Your Measurements',
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 12),
        _measureSlider('Bust', bust, 28, 48, accent, ink, muted, isDark, onBust),
        const SizedBox(height: 14),
        _measureSlider(
            'Waist', waist, 22, 42, accent, ink, muted, isDark, onWaist),
        const SizedBox(height: 14),
        _measureSlider('Hips', hips, 30, 50, accent, ink, muted, isDark, onHips),
        const SizedBox(height: 24),

        // ── Recommendation ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: accent.withOpacity(isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up_alt_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text('Best fit for you:  $recommended',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: accent)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                bodyShape == null
                    ? 'Based on your measurements'
                    : 'Based on your $bodyShape shape & measurements',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12, color: ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Fit + buyer reviews ──
        _fitBar('Fit Type', ['Skinny', 'Regular', 'Oversized'], 1, accent, ink,
            muted, isDark),
        const SizedBox(height: 16),
        _fitBar('Stretch', ['Non', 'Slight', 'Medium', 'High'], 1, accent, ink,
            muted, isDark),
        const SizedBox(height: 24),
        Text('How buyers reviewed the fit',
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 12),
        _fitReview('Small', 3, accent, ink, muted, isDark),
        const SizedBox(height: 8),
        _fitReview('True to size', 94, accent, ink, muted, isDark),
        const SizedBox(height: 8),
        _fitReview('Large', 3, accent, ink, muted, isDark),
      ],
    );
  }

  Widget _measureSlider(String label, double value, double min, double max,
      Color accent, Color ink, Color muted, bool isDark, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
            Text('${value.toStringAsFixed(1)} in',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: accent,
            inactiveTrackColor:
                isDark ? Colors.white12 : const Color(0xFFEDE9E4),
            thumbColor: accent,
            overlayColor: accent.withOpacity(0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toStringAsFixed(0)} in',
                style: GoogleFonts.outfit(fontSize: 10, color: muted)),
            Text('${max.toStringAsFixed(0)} in',
                style: GoogleFonts.outfit(fontSize: 10, color: muted)),
          ],
        ),
      ],
    );
  }

  Widget _fitBar(String label, List<String> stops, int active, Color accent,
      Color ink, Color muted, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w600, color: ink)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final dotX = (w - 16) * (active / (stops.length - 1));
          return SizedBox(
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 7,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFEDE9E4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  left: dotX,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stops
              .map((s) => Text(s,
                  style: GoogleFonts.outfit(fontSize: 10, color: muted)))
              .toList(),
        ),
      ],
    );
  }

  Widget _fitReview(String label, int pct, Color accent, Color ink, Color muted,
      bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label,
              style: GoogleFonts.outfit(fontSize: 12, color: ink)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor:
                  isDark ? Colors.white12 : const Color(0xFFEDE9E4),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text('$pct%',
              textAlign: TextAlign.right,
              style: GoogleFonts.outfit(
                  fontSize: 12, fontWeight: FontWeight.w700, color: ink)),
        ),
      ],
    );
  }

  Widget _shopChart(bool isDark, Color accent, Color ink, Color muted) {
    // Products don't carry a dedicated size-chart image, so we show the
    // shop's product photo as a reference, or an empty state.
    final hasImage = widget.image.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.shopName != null
              ? 'Size chart from ${widget.shopName}'
              : 'Shop size chart',
          style: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w600, color: ink),
        ),
        const SizedBox(height: 12),
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: CdnImage(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _shopChartEmpty(isDark, muted),
              ),
            ),
          )
        else
          _shopChartEmpty(isDark, muted),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Switch to Body Chart to get your recommended size.',
                  style: GoogleFonts.outfit(fontSize: 12, color: ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shopChartEmpty(bool isDark, Color muted) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF4F2EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 40, color: muted),
          const SizedBox(height: 10),
          Text('This shop hasn\'t uploaded a size chart yet',
              style: GoogleFonts.outfit(fontSize: 12, color: muted)),
        ],
      ),
    );
  }

  // Open the "write a review" bottom sheet
  void _openReviewSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final cardBg = isDark ? AppColors.darkWarm : Colors.white;
    int rating = 5;
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    final List<XFile> pickedImages = [];
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            Future<void> pickImages(ImageSource source) async {
              if (source == ImageSource.gallery) {
                final imgs = await picker.pickMultiImage(imageQuality: 80);
                if (imgs.isNotEmpty) {
                  setSheet(() {
                    for (final img in imgs) {
                      if (pickedImages.length < 5) pickedImages.add(img);
                    }
                  });
                }
              } else {
                final img = await picker.pickImage(
                    source: source, imageQuality: 80);
                if (img != null && pickedImages.length < 5) {
                  setSheet(() => pickedImages.add(img));
                }
              }
            }

            return Padding(
              // Lift above the keyboard
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('product.write_review'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.inkBlack)),
                    const SizedBox(height: 4),
                    Text('product.review_desc'.tr(),
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF888888))),
                    const SizedBox(height: 18),

                    // Star rating selector
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < rating;
                        return GestureDetector(
                          onTap: () => setSheet(() => rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 34,
                              color: filled
                                  ? AppColors.gold
                                  : (isDark
                                      ? Colors.white30
                                      : const Color(0xFFCCCCCC)),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // Name field
                    _sheetField(
                      controller: nameCtrl,
                      hint: 'product.review_name_hint'.tr(),
                      isDark: isDark,
                      accent: accent,
                    ),
                    const SizedBox(height: 12),
                    // Comment field
                    _sheetField(
                      controller: commentCtrl,
                      hint: 'product.review_comment_hint'.tr(),
                      isDark: isDark,
                      accent: accent,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // ── Photo upload row ─────────────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Add photos',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppColors.inkBlack,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(up to 5)',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : const Color(0xFFAAAAAA),
                              ),
                            ),
                            const Spacer(),
                            // Camera button
                            GestureDetector(
                              onTap: pickedImages.length >= 5
                                  ? null
                                  : () => pickImages(ImageSource.camera),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, size: 14, color: accent),
                                    const SizedBox(width: 4),
                                    Text('Camera',
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: accent)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Gallery button
                            GestureDetector(
                              onTap: pickedImages.length >= 5
                                  ? null
                                  : () => pickImages(ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: accent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library_rounded, size: 14, color: accent),
                                    const SizedBox(width: 4),
                                    Text('Gallery',
                                        style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: accent)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (pickedImages.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pickedImages.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(pickedImages[i].path),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => setSheet(() => pickedImages.removeAt(i)),
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.65),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close_rounded,
                                              size: 11, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim().isEmpty
                              ? 'product.anonymous'.tr()
                              : nameCtrl.text.trim();
                          final comment = commentCtrl.text.trim();
                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('product.review_empty'.tr()),
                                  duration: const Duration(seconds: 2)),
                            );
                            return;
                          }
                          setState(() {
                            _reviews.insert(0, {
                              'name': name,
                              'rating': rating,
                              'comment': comment,
                              'date': 'product.just_now'.tr(),
                              'images': pickedImages.map((f) => f.path).toList(),
                            });
                          });
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('product.review_thanks'.tr()),
                                duration: const Duration(seconds: 2)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.white : AppColors.inkBlack,
                          foregroundColor:
                              isDark ? AppColors.charcoal : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('product.submit_review'.tr(),
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color accent,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.outfit(
          fontSize: 13,
          color: isDark ? Colors.white : AppColors.inkBlack),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? Colors.white38 : const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: isDark ? Colors.white10 : const Color(0xFFF4F4F4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }

  // View toggle tab (Photo / 360°)
  Widget _viewTab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? const Color(0xFF1A1A1A) : Colors.white70),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? const Color(0xFF1A1A1A) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small nav button ──────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, required this.isDark, this.iconColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 20,
            color: iconColor ??
                (isDark ? Colors.white : AppColors.inkBlack)),
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isDark;
  final Color cardBg;
  const _ReviewCard({required this.review, required this.isDark, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.burgundy.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (review['name'] as String)[0],
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['name'] as String,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.inkBlack)),
                    Row(
                      children: [
                        ...List.generate(
                            review['rating'] as int,
                            (_) => const Icon(Icons.star_rounded,
                                color: AppColors.gold, size: 12)),
                        const SizedBox(width: 4),
                        Text(review['date'] as String,
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFFAAAAAA))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['comment'] as String,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark ? Colors.white60 : const Color(0xFF666666))),
          // Attached photos (shown only when the user uploaded images)
          if (review['images'] != null &&
              (review['images'] as List).isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: (review['images'] as List).length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final path = (review['images'] as List)[i] as String;
                  return GestureDetector(
                    onTap: () => showDialog(
                      context: ctx,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(File(path), fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Characteristic row ────────────────────────────────────────────────────────
class _CharRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  const _CharRow(this.label, this.value, this.isDark,
      {this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF888888),
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.inkBlack)),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
          ),
      ],
    );
  }
}

// ── Floating PiP video card ───────────────────────────────────────────────────
class _FloatingVideoPip extends StatefulWidget {
  final bool isDark;
  final String image;
  final Color accent;
  final VoidCallback onClose;

  const _FloatingVideoPip({
    required this.isDark,
    required this.image,
    required this.accent,
    required this.onClose,
  });

  @override
  State<_FloatingVideoPip> createState() => _FloatingVideoPipState();
}

class _FloatingVideoPipState extends State<_FloatingVideoPip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(widget.image, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: widget.isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                    child: const Center(
                        child: Icon(Icons.videocam_rounded,
                            color: Colors.white54, size: 32)))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _scale,
                builder: (_, child) =>
                    Transform.scale(scale: _scale.value, child: child),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.25), blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.black87, size: 22),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: const Color(0xFFE53935),
                child: Text('product.pip_preview'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3)),
              ),
            ),
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
            ),
            const Positioned(
              top: 6, left: 6,
              child: Icon(Icons.drag_indicator_rounded,
                  color: Colors.white54, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
