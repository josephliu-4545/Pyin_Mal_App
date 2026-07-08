import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/nanobanana_api_service.dart';
import '../core/constants/api_constants.dart';
import '../main.dart'; // For AppColors
import '../services/try_on_service.dart';
import '../models/product.dart';
import '../data/product_repository.dart';
import '../widgets/cdn_image.dart';
import 'product_detail_screen.dart';

class TryOnScreen extends StatefulWidget {
  final String? initialImageUrl;
  final String? initialCategory;

  const TryOnScreen({super.key, this.initialImageUrl, this.initialCategory});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  bool _isLoading = false;
  String? _resultImageUrl;

  final ImagePicker _picker = ImagePicker();

  XFile? get _userPhoto => TryOnService.instance.userPhoto;
  set _userPhoto(XFile? val) => TryOnService.instance.userPhoto = val;

  Uint8List? get _userPhotoBytes => TryOnService.instance.userPhotoBytes;
  set _userPhotoBytes(Uint8List? val) => TryOnService.instance.userPhotoBytes = val;

  XFile? get _shirtPhoto => TryOnService.instance.shirtPhoto;
  set _shirtPhoto(XFile? val) => TryOnService.instance.shirtPhoto = val;

  Uint8List? get _shirtPhotoBytes => TryOnService.instance.shirtPhotoBytes;
  set _shirtPhotoBytes(Uint8List? val) => TryOnService.instance.shirtPhotoBytes = val;

  XFile? get _pantsPhoto => TryOnService.instance.pantsPhoto;
  set _pantsPhoto(XFile? val) => TryOnService.instance.pantsPhoto = val;

  Uint8List? get _pantsPhotoBytes => TryOnService.instance.pantsPhotoBytes;
  set _pantsPhotoBytes(Uint8List? val) => TryOnService.instance.pantsPhotoBytes = val;

  XFile? get _shoesPhoto => TryOnService.instance.shoesPhoto;
  set _shoesPhoto(XFile? val) => TryOnService.instance.shoesPhoto = val;

  Uint8List? get _shoesPhotoBytes => TryOnService.instance.shoesPhotoBytes;
  set _shoesPhotoBytes(Uint8List? val) => TryOnService.instance.shoesPhotoBytes = val;

  @override
  void initState() {
    super.initState();
    _loadInitialImage();
  }

  Future<void> _loadInitialImage() async {
    if (widget.initialImageUrl == null || widget.initialImageUrl!.isEmpty) return;
    try {
      String imageUrl = widget.initialImageUrl!;
      if (!imageUrl.startsWith('http')) {
        final String cdnPath = imageUrl.replaceFirst('assets/images/', '');
        imageUrl = '${ApiConstants.cdnBaseUrl}$cdnPath';
      }
      
      // Encode URL to handle spaces in filenames
      final encodedUrl = Uri.encodeFull(imageUrl);
      final request = await HttpClient().getUrl(Uri.parse(encodedUrl));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (mounted) {
        setState(() {
          final cat = widget.initialCategory?.toLowerCase() ?? '';
          final newFile = XFile.fromData(bytes, name: 'downloaded.jpg');
          if (cat.contains('pant') || cat.contains('skirt') || cat.contains('bottom') || cat.contains('short')) {
            _pantsPhotoBytes = bytes;
            _pantsPhoto = newFile;
          } else if (cat.contains('shoe') || cat.contains('sneaker')) {
            _shoesPhotoBytes = bytes;
            _shoesPhoto = newFile;
          } else {
            _shirtPhotoBytes = bytes;
            _shirtPhoto = newFile;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to load initial image: $e');
    }
  }

  Future<void> _pickImage(
    void Function(XFile file, Uint8List bytes) onPicked,
  ) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        onPicked(image, bytes);
      });
    }
  }

  Future<void> _processTryOn() async {
    if (_userPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('try_on.err_person'.tr())),
      );
      return;
    }

    if (_shirtPhoto == null && _pantsPhoto == null && _shoesPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('try_on.err_clothing'.tr()),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Call API
      final resultUrl = await NanoBananaApiService.generateTryOnImage(
        userPhoto: _userPhoto!,
        shirtPhoto: _shirtPhoto,
        pantsPhoto: _pantsPhoto,
        shoesPhoto: _shoesPhoto,
      );

      // Update UI
      if (mounted) {
        setState(() {
          _resultImageUrl = resultUrl;
          _isLoading = false;
        });

        if (resultUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('try_on.err_api'.tr()),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('try_on.error'.tr(args: [e.toString()]))));
      }
    }
  }

  void _reset() {
    setState(() {
      TryOnService.instance.clear();
      _resultImageUrl = null;
    });
  }

  // Theme helpers
  bool get _isDark =>
      Theme.of(context).brightness == Brightness.dark;
  Color get _accent => _isDark ? AppColors.gold : AppColors.burgundy;
  Color get _bg => _isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
  Color get _surface => _isDark ? AppColors.darkWarm : Colors.white;
  Color get _ink => _isDark ? Colors.white : AppColors.inkBlack;
  Color get _muted => _isDark ? AppColors.paleText : AppColors.inkGrey;

  int get _itemsAdded {
    int n = 0;
    if (_shirtPhotoBytes != null) n++;
    if (_pantsPhotoBytes != null) n++;
    if (_shoesPhotoBytes != null) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _resultImageUrl != null ? _buildResult() : _buildBody(),
      ),
    );
  }

  // ── Inline top bar ─────────────────────────────────────────────────────────
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
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
                    color: Colors.black.withOpacity(_isDark ? 0.2 : 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: _ink),
            ),
          ),
          const SizedBox(width: 12),
          Text('try_on.title'.tr(),
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: _accent),
                const SizedBox(width: 4),
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
    );
  }

  // ── Build (upload) flow ──────────────────────────────────────────────────
  Widget _buildBody() {
    final canGenerate = _userPhotoBytes != null && _itemsAdded > 0;

    return Column(
      children: [
        _topBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('try_on.mix_match'.tr(),
                    style: GoogleFonts.rufina(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _ink)),
                const SizedBox(height: 6),
                Text('try_on.desc'.tr(),
                    style: GoogleFonts.outfit(
                        fontSize: 13, height: 1.4, color: _muted)),
                const SizedBox(height: 24),

                // Step 1 — your photo
                _stepLabel('1', 'try_on.person'.tr(), 'try_on.required'.tr()),
                const SizedBox(height: 12),
                _personCard(),
                const SizedBox(height: 24),

                // Step 2 — your pieces
                _stepLabel('2', 'try_on.pieces'.tr(),
                    'try_on.selected'.tr(args: [_itemsAdded.toString()])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _garmentCard(
                        title: 'try_on.shirt'.tr(),
                        icon: Icons.checkroom_rounded,
                        imageBytes: _shirtPhotoBytes,
                        onTap: () => _pickImage((f, b) {
                          _shirtPhoto = f;
                          _shirtPhotoBytes = b;
                        }),
                        onRemove: () => setState(() {
                          _shirtPhoto = null;
                          _shirtPhotoBytes = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _garmentCard(
                        title: 'try_on.pants'.tr(),
                        icon: Icons.dry_cleaning_rounded,
                        imageBytes: _pantsPhotoBytes,
                        onTap: () => _pickImage((f, b) {
                          _pantsPhoto = f;
                          _pantsPhotoBytes = b;
                        }),
                        onRemove: () => setState(() {
                          _pantsPhoto = null;
                          _pantsPhotoBytes = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _garmentCard(
                        title: 'try_on.shoes'.tr(),
                        icon: Icons.ice_skating_rounded,
                        imageBytes: _shoesPhotoBytes,
                        onTap: () => _pickImage((f, b) {
                          _shoesPhoto = f;
                          _shoesPhotoBytes = b;
                        }),
                        onRemove: () => setState(() {
                          _shoesPhoto = null;
                          _shoesPhotoBytes = null;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                _generateButton(canGenerate),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    canGenerate
                        ? 'try_on.ready'.tr()
                        : 'try_on.hint'.tr(),
                    style: GoogleFonts.outfit(fontSize: 12, color: _muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepLabel(String num, String title, String trailing) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          child: Center(
            child: Text(num,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? AppColors.charcoal : Colors.white)),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
        const Spacer(),
        Text(trailing,
            style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w500, color: _muted)),
      ],
    );
  }

  // ── Person hero card ──────────────────────────────────────────────────────
  Widget _personCard() {
    final has = _userPhotoBytes != null;
    return GestureDetector(
      onTap: () => _pickImage((f, b) {
        _userPhoto = f;
        _userPhotoBytes = b;
      }),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: has ? _accent : _accent.withOpacity(0.35),
            width: has ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark ? 0.25 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: has
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_userPhotoBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _circleChip(Icons.swap_horiz_rounded, () {
                        _pickImage((f, b) {
                          _userPhoto = f;
                          _userPhotoBytes = b;
                        });
                      }),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('try_on.photo_added'.tr(),
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo_rounded,
                        color: _accent, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text('try_on.upload_photo'.tr(),
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink)),
                  const SizedBox(height: 4),
                  Text('try_on.photo_hint'.tr(),
                      style: GoogleFonts.outfit(fontSize: 12, color: _muted)),
                ],
              ),
      ),
    );
  }

  // ── Garment card ──────────────────────────────────────────────────────────
  Widget _garmentCard({
    required String title,
    required IconData icon,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final has = imageBytes != null;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: has ? _accent : (_isDark ? AppColors.darkBorder : AppColors.creamAlt),
              width: has ? 2 : 1,
            ),
          ),
          child: has
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(imageBytes, fit: BoxFit.cover),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: _muted, size: 28),
                    const SizedBox(height: 8),
                    Text(title,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ink)),
                    const SizedBox(height: 2),
                    Icon(Icons.add_rounded, size: 14, color: _accent),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _circleChip(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _generateButton(bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (enabled && !_isLoading) ? _processTryOn : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor:
              _isDark ? AppColors.darkBorder : Colors.grey.shade300,
          foregroundColor: _isDark ? AppColors.charcoal : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Generate Try-On',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
      ),
    );
  }

  // ── Result view ────────────────────────────────────────────────────────────
  Widget _buildResult() {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text('try_on.ai_fit'.tr(),
                    style: GoogleFonts.rufina(
                        color: _ink,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('try_on.generated_for_you'.tr(),
                    style: GoogleFonts.outfit(fontSize: 13, color: _muted)),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    _resultImageUrl!,
                    height: 440,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, progress) => progress == null
                        ? child
                        : Container(
                            height: 440,
                            color: _surface,
                            child: Center(
                              child: CircularProgressIndicator(color: _accent),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('try_on.try_another'.tr(),
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor:
                          _isDark ? AppColors.charcoal : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                ..._buildMatchSections(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── "Complete the look" — matching pants & shoes from the catalog ─────────

  static const _bottomCats = {'Pants', 'Jeans', 'Skirt', 'Short'};
  static const _shoeCats = {'Shoes', 'Sneakers', 'Footwear'};

  List<Product> _matchesFor(Set<String> cats, {int count = 6}) {
    final all = ProductRepository.allProducts;
    final hits = all
        .where((p) => cats.any(
            (c) => p.category.toLowerCase().contains(c.toLowerCase())))
        .toList();
    return hits.take(count).toList();
  }

  List<Widget> _buildMatchSections() {
    final sections = <Widget>[];
    // Only suggest what the user did NOT already include in the try-on.
    final needsBottom = _pantsPhotoBytes == null;
    final needsShoes = _shoesPhotoBytes == null;

    final bottoms = needsBottom ? _matchesFor(_bottomCats) : <Product>[];
    final shoes = needsShoes ? _matchesFor(_shoeCats) : <Product>[];
    if (bottoms.isEmpty && shoes.isEmpty) return sections;

    sections.add(const SizedBox(height: 32));
    sections.add(Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 18, color: _accent),
        const SizedBox(width: 8),
        Text('try_on.complete_look'.tr(),
            style: GoogleFonts.rufina(
                fontSize: 20, fontWeight: FontWeight.bold, color: _ink)),
      ],
    ));
    sections.add(const SizedBox(height: 4));
    sections.add(Align(
      alignment: Alignment.centerLeft,
      child: Text('try_on.complete_look_desc'.tr(),
          style: GoogleFonts.outfit(fontSize: 12, color: _muted)),
    ));

    if (bottoms.isNotEmpty) {
      sections.add(const SizedBox(height: 18));
      sections.add(_matchRow('try_on.matching_pants'.tr(),
          Icons.airline_seat_legroom_normal_rounded, bottoms));
    }
    if (shoes.isNotEmpty) {
      sections.add(const SizedBox(height: 18));
      sections.add(_matchRow(
          'try_on.matching_shoes'.tr(), Icons.ice_skating_rounded, shoes));
    }
    return sections;
  }

  Widget _matchRow(String title, IconData icon, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: _muted),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 208,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _matchCard(products[i]),
          ),
        ),
      ],
    );
  }

  Widget _matchCard(Product p) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen.fromProduct(p)),
      ),
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 132,
                width: double.infinity,
                child: CdnImage(
                  p.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _isDark ? AppColors.charcoal : AppColors.creamAlt,
                    child: Icon(Icons.checkroom_rounded,
                        size: 30, color: _muted),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _ink)),
                  const SizedBox(height: 3),
                  Text(p.price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
