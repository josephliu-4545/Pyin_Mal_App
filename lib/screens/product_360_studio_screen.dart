import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/product_3d_viewer.dart';

/// Immersive 360° studio view of a product. Shows the product's 3D model when
/// one is available, otherwise a placeholder from [Product3DViewer].
class Product360StudioScreen extends StatelessWidget {
  final String productName;
  final String? modelAsset;

  const Product360StudioScreen({
    super.key,
    required this.productName,
    this.modelAsset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('360° Studio',
            style: GoogleFonts.rufina(
                color: ink, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              productName,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w600, color: ink),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Product3DViewer(
                height: size.height * 0.62,
                isDark: isDark,
                modelAsset: modelAsset,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.threesixty_rounded, size: 16, color: accent),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Drag to rotate · pinch to zoom for a full 360° view.',
                    style: GoogleFonts.outfit(fontSize: 12, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
