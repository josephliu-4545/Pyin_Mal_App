import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/cdn_image.dart';
import 'package:easy_localization/easy_localization.dart';

class ModelPreviewScreen extends StatefulWidget {
  const ModelPreviewScreen({super.key});

  @override
  State<ModelPreviewScreen> createState() => _ModelPreviewScreenState();
}

class _ModelPreviewScreenState extends State<ModelPreviewScreen> {
  String _gender = 'Female';
  String _mode = 'Mannequin';
  String? _selectedTop;
  String? _selectedBottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.inkBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('model_preview.title'.tr(), style: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: accent)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.creamAlt,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'model_preview.ai_powered'.tr(),
                      style: GoogleFonts.outfit(
                        color: AppColors.charcoal,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'model_preview.subtitle'.tr(),
                    style: GoogleFonts.rufina(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'model_preview.desc'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: isDark ? AppColors.paleText : AppColors.inkGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Left Selection Panel (Tops / Bottoms)
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: _buildSelectionPanel(isDark, accent),
                  ),
                  const SizedBox(width: 16, height: 16),

                  // 2. Center Model Canvas
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: _buildModelCanvas(isDark, accent),
                  ),
                  const SizedBox(width: 16, height: 16),

                  // 3. Right AI Panel
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: _buildAIPanel(isDark, accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionPanel(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'model_preview.wardrobe'.tr(),
                style: GoogleFonts.rufina(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'model_preview.tops'.tr(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.gold : AppColors.burgundy,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildItemCard('model_preview.items.white_shirt'.tr(), 'assets/images/outfits/top-1.png', 'top', isDark, accent),
              _buildItemCard('model_preview.items.knit_tank'.tr(), 'assets/images/outfits/top-2.png', 'top', isDark, accent),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'model_preview.bottoms'.tr(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.gold : AppColors.burgundy,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _buildItemCard('model_preview.items.wide_trousers'.tr(), 'assets/images/outfits/bottom-1.png', 'bottom', isDark, accent),
              _buildItemCard('model_preview.items.relaxed_denim'.tr(), 'assets/images/outfits/bottom-2.png', 'bottom', isDark, accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(String name, String imagePath, String category, bool isDark, Color accent) {
    final isSelected = (category == 'top' && _selectedTop == imagePath) || 
                       (category == 'bottom' && _selectedBottom == imagePath);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (category == 'top') _selectedTop = imagePath;
          if (category == 'bottom') _selectedBottom = imagePath;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.08) : (isDark ? AppColors.darkBorder : AppColors.creamAlt),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CdnImage(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 30)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCanvas(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Mode Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.charcoal : AppColors.creamAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(child: _buildToggleButton('model_preview.modes.mannequin'.tr(), _mode == 'Mannequin', () => setState(() => _mode = 'Mannequin'), isDark, accent)),
                Expanded(child: _buildToggleButton('model_preview.modes.ai_real_view'.tr(), _mode == 'AI Real View', () => setState(() => _mode = 'AI Real View'), isDark, accent)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Gender Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildToggleButton('model_preview.genders.female'.tr(), _gender == 'Female', () => setState(() => _gender = 'Female'), isDark, accent),
              const SizedBox(width: 8),
              _buildToggleButton('model_preview.genders.male'.tr(), _gender == 'Male', () => setState(() => _gender = 'Male'), isDark, accent),
            ],
          ),
          const SizedBox(height: 20),
          
          // Canvas
          Container(
            height: 480,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1C1A1A), Color(0xFF2A2320)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Background Effect
                Positioned(
                  top: 100,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.1),
                          blurRadius: 100,
                          spreadRadius: 20,
                        )
                      ],
                    ),
                  ),
                ),
                
                // Base Model Placeholder
                Icon(Icons.person, size: 240, color: Colors.white.withOpacity(0.1)),
                
                // Top Overlay Placeholder
                if (_selectedTop != null)
                  Positioned(
                    top: 110,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.burgundy.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CdnImage(
                          _selectedTop!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Center(child: Text('model_preview.top_preview'.tr(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ),
                  
                // Bottom Overlay Placeholder
                if (_selectedBottom != null)
                  Positioned(
                    top: 260,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 140, height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.inkBlack.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CdnImage(
                          _selectedBottom!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Center(child: Text('model_preview.bottom_preview'.tr(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedTop = null;
                      _selectedBottom = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? AppColors.paleText : AppColors.inkGrey),
                    foregroundColor: isDark ? AppColors.paleText : AppColors.inkGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('model_preview.reset'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('model_preview.toast_saved'.tr())),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('model_preview.save_result'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAIPanel(bool isDark, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.gold, size: 24),
              const SizedBox(width: 10),
              Text(
                'model_preview.ai_insights'.tr(),
                style: GoogleFonts.rufina(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Style Metrics
          _buildMetricRow(Icons.bolt, 'model_preview.style_match'.tr(), '92%', isDark),
          const SizedBox(height: 12),
          _buildMetricRow(Icons.event, 'model_preview.best_occasion'.tr(), 'model_preview.casual_out'.tr(), isDark),
          const SizedBox(height: 12),
          _buildMetricRow(Icons.palette, 'model_preview.color_balance'.tr(), 'model_preview.neutral'.tr(), isDark),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          
          Text(
            'model_preview.upload_title'.tr(),
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 16),
          
          DottedBorderPlaceholder(isDark: isDark),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                foregroundColor: isDark ? Colors.white : AppColors.inkBlack,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 20, color: accent),
                  const SizedBox(width: 8),
                  Text('model_preview.upload_button'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.gold, size: 16),
        ),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.outfit(color: isDark ? AppColors.paleText : AppColors.inkGrey, fontSize: 13)),
        const Spacer(),
        Text(value, style: GoogleFonts.outfit(color: isDark ? Colors.white : AppColors.inkBlack, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap, bool isDark, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? AppColors.paleText : AppColors.inkGrey),
          ),
        ),
      ),
    );
  }
}

class DottedBorderPlaceholder extends StatelessWidget {
  final bool isDark;
  const DottedBorderPlaceholder({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal.withOpacity(0.5) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: Colors.grey.withOpacity(0.5), size: 32),
          const SizedBox(height: 8),
          Text('model_preview.drop_photo'.tr(), style: GoogleFonts.outfit(color: Colors.grey.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }
}
