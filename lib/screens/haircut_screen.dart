import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/ar_hair_filter_screen.dart';
import 'package:pyin_mal_app/screens/hair_try_on_screen.dart';

class HaircutScreen extends StatefulWidget {
  const HaircutScreen({super.key});

  @override
  State<HaircutScreen> createState() => _HaircutScreenState();
}

class _HaircutScreenState extends State<HaircutScreen> {
  String _selectedFaceShape = 'Oval Face';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 640;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Hair & Grooming', style: GoogleFonts.rufina(
          fontWeight: FontWeight.bold,
          color: accent,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Hero Section
            _buildHero(context, isMobile, isDesktop, isDark, accent),

            // 2. Face Shape Selector
            _buildFaceShapeSelector(isDark, accent),

            // 3. Recommended Hairstyles
            _buildHairstyleSection(context, isMobile, isDark, accent),

            // 4. Smart Assistant Tips
            _buildSmartTips(isDark, accent),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile, bool isDesktop, bool isDark, Color accent) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 60, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppColors.charcoal, AppColors.darkWarm] 
            : [AppColors.creamAlt, AppColors.cream],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'AI HAIR GUIDE',
              style: GoogleFonts.outfit(
                color: AppColors.charcoal,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Find Your Best Hair Look',
            style: GoogleFonts.rufina(
              fontSize: isMobile ? 36 : 52,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Explore hairstyle ideas that match your face shape and personal style. Our AI analysis helps balance your features for a perfect look.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: isDark ? AppColors.paleText : AppColors.inkGrey,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ARHairFilterScreen()),
                  );
                },
                icon: const Icon(Icons.face_retouching_natural),
                label: const Text('AR Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.darkWarm : AppColors.creamCard,
                  foregroundColor: isDark ? Colors.white : AppColors.inkBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HairTryOnScreen()),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('AI Try-On'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: accent.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaceShapeSelector(bool isDark, Color accent) {
    final shapes = [
      {'name': 'Oval Face', 'img': 'assets/images/HairStyle/O.jpg'},
      {'name': 'Round Face', 'img': 'assets/images/HairStyle/R.jpg'},
      {'name': 'Square Face', 'img': 'assets/images/HairStyle/S.jpg'},
      {'name': 'Diamond Face', 'img': 'assets/images/HairStyle/O.jpg'}, // Using O as placeholder
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Text(
            'Select Face Shape',
            style: GoogleFonts.rufina(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: shapes.length,
            itemBuilder: (context, i) {
              final shape = shapes[i];
              final isSelected = _selectedFaceShape == shape['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedFaceShape = shape['name']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamCard),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withOpacity(isDark ? 0.3 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(
                      color: isSelected ? accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.charcoal : AppColors.creamAlt,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          shape['img']!,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Icon(Icons.face, color: isSelected ? Colors.white : Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        shape['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? AppColors.paleText : AppColors.inkGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHairstyleSection(BuildContext context, bool isMobile, bool isDark, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended for You',
                style: GoogleFonts.rufina(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              Text(
                'Trending Now',
                style: GoogleFonts.outfit(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _buildHairstyleCard(
                'Classic Undercut',
                'Sharp sides with a textured top for a versatile modern look.',
                'assets/images/HairStyle/Male/Diamond Face/Diamond - Undercut.jpg',
                'Professional',
                isDark, accent,
              ),
              _buildHairstyleCard(
                'Textured Crop',
                'Low maintenance style that works perfectly with active lifestyles.',
                'assets/images/HairStyle/Male/Diamond Face/Diamond  - Textured Crop.jpg',
                'Casual',
                isDark, accent,
              ),
              _buildHairstyleCard(
                'Long Textured Top',
                'Flowing layers with a clean fade for a sophisticated vintage vibe.',
                'assets/images/HairStyle/Male/Round Face/Round - Longer Textured Top + Fade.jpg',
                'Elegant',
                isDark, accent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHairstyleCard(String title, String desc, String img, String tag, bool isDark, Color accent) {
    return Container(
      width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(24),
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
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.asset(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50)),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.outfit(
                        color: isDark ? AppColors.charcoal : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_outline, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    color: isDark ? AppColors.paleText : AppColors.inkGrey,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.gold, size: 14),
                    const SizedBox(width: 4),
                    Text('Best Match', style: GoogleFonts.outfit(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmartTips(bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 24),
              const SizedBox(width: 12),
              Text(
                'Styling Tips',
                style: GoogleFonts.rufina(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipItem(Icons.check_circle_outline, 'Best for oval and round faces', isDark, accent),
          const SizedBox(height: 12),
          _buildTipItem(Icons.check_circle_outline, 'Works well with casual and formal outfits', isDark, accent),
          const SizedBox(height: 12),
          _buildTipItem(Icons.check_circle_outline, 'Low maintenance for daily styling', isDark, accent),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text, bool isDark, Color accent) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
