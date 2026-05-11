import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class HaircutScreen extends StatelessWidget {
  const HaircutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 640;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
        title: Text('Hair Recommendations', style: GoogleFonts.rufina(
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.gold : AppColors.burgundy,
        )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Hero / Face Scan Section
            Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 24),
              child: Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                children: [
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: Column(
                      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                      children: [
                        Text('Find your best look today.', style: GoogleFonts.rufina(fontSize: isMobile ? 40 : 56, fontWeight: FontWeight.bold), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
                        const SizedBox(height: 16),
                        Text(
                          'Upload a photo or use your camera to analyze your face shape. We\'ll match you with haircuts that balance proportions and reflect your style.',
                          style: GoogleFonts.orbit(fontSize: 16, color: Colors.grey),
                          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.gold : AppColors.burgundy,
                            foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Start Face Analysis'),
                        ),
                        if (!isDesktop) const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  if (isDesktop) const SizedBox(width: 48),
                  Expanded(
                    flex: isDesktop ? 1 : 0,
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF242424) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.face, size: 100, color: Colors.grey),
                      ),
                    ),
                  )
                ],
              ),
            ),

            const Divider(),

            // 2. Trending Hairstyles
            Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 24),
              child: Column(
                children: [
                  Text('TRENDING NOW', style: GoogleFonts.outfit(
                    color: isDark ? AppColors.gold : AppColors.burgundy,
                    fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12,
                  )),
                  const SizedBox(height: 8),
                  Text('Popular Hairstyles', style: GoogleFonts.rufina(fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Discover the most sought-after hairstyles of the season', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 350,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTrendingHairCard('Undercut', 'Classic with a modern twist', 'assets/images/HairStyle/Male/Diamond Face/Diamond - Undercut.jpg', isDark),
                        _buildTrendingHairCard('Textured Crop', 'Easy maintenance', 'assets/images/HairStyle/Male/Diamond Face/Diamond  - Textured Crop.jpg', isDark),
                        _buildTrendingHairCard('Longer Textured Top', 'Vintage style', 'assets/images/HairStyle/Male/Round Face/Round - Longer Textured Top + Fade.jpg', isDark),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // 3. Face Shapes
            Container(
              color: isDark ? const Color(0xFF1a1a1a) : Colors.grey[100],
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80, horizontal: 24),
              child: Column(
                children: [
                  Text('Understanding Face Shapes', style: GoogleFonts.rufina(fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Let\'s Check', style: TextStyle(
                    color: Color(0xFF8B1A2F), fontWeight: FontWeight.bold, fontSize: 18,
                  )),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildFaceShapeCard('Oval Face', 'Balanced proportions with slightly wider cheekbones', 'assets/images/HairStyle/O.jpg', isDark),
                      _buildFaceShapeCard('Round Face', 'Similar width and length with soft angles', 'assets/images/HairStyle/R.jpg', isDark),
                      _buildFaceShapeCard('Square Face', 'Strong jawline and forehead with similar width', 'assets/images/HairStyle/S.jpg', isDark),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingHairCard(String title, String subtitle, String img, bool isDark) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(img, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 50))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFaceShapeCard(String title, String desc, String img, bool isDark) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            child: Image.asset(img, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.face, size: 100, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
