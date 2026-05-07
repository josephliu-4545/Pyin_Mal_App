import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/screens/shop_screen.dart';
import 'package:pyin_mal_app/screens/model_preview_screen.dart';
import 'package:pyin_mal_app/screens/haircut_screen.dart';

void main() {
  runApp(const PyinMalApp());
}

class AppColors {
  static const primary600 = Color(0xFF0284c7);
  static const primary500 = Color(0xFF0ea5e9);
  static const primary400 = Color(0xFF38bdf8);
  static const darkBg = Color(0xFF0f0f0f);
  static const darkSurface = Color(0xFF1a1a1a);
  static const darkCard = Color(0xFF242424);
  static const darkBorder = Color(0xFF2d2d2d);
  static const neutral50 = Color(0xFFfafafa);
  static const neutral100 = Color(0xFFf5f5f5);
  static const neutral200 = Color(0xFFe5e5e5);
  static const neutral400 = Color(0xFFa3a3a3);
  static const neutral600 = Color(0xFF525252);
  static const neutral900 = Color(0xFF171717);
}

class PyinMalApp extends StatelessWidget {
  const PyinMalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pyin Mal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary500,
          primary: AppColors.primary600,
          brightness: Brightness.light,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
          displayMedium: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
          headlineLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
          headlineMedium: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
          bodyLarge: GoogleFonts.orbit(color: AppColors.neutral600),
          bodyMedium: GoogleFonts.orbit(color: AppColors.neutral600),
          titleLarge: GoogleFonts.itim(color: AppColors.neutral900),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary500,
          primary: AppColors.primary500,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
          displayMedium: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
          headlineLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
          headlineMedium: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: GoogleFonts.orbit(color: AppColors.neutral400),
          bodyMedium: GoogleFonts.orbit(color: AppColors.neutral400),
          titleLarge: GoogleFonts.itim(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;
    final isMobile = screenWidth < 640;

    return Scaffold(
      appBar: _buildAppBar(context, isDesktop, isDark),
      endDrawer: isDesktop ? null : _buildMobileDrawer(context, isDark),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(context, isMobile),
            _buildFeaturesSection(context, isMobile, isDark),
            _buildTrendingSection(context, isMobile, isDark),
            _buildFaceAnalysisSection(context, isMobile, isTablet, isDesktop, isDark),
            _buildFooterSection(context, isMobile, isTablet, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop, bool isDark) {
    return AppBar(
      backgroundColor: AppColors.darkSurface, 
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            child: const Text('PM', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Text(
            'Pyin Mal',
            style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary400),
          ),
        ],
      ),
      actions: [
        if (isDesktop) ...[
          TextButton(onPressed: (){}, child: Text('Home', style: GoogleFonts.orbit(color: AppColors.primary400, fontWeight: FontWeight.bold))),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ModelPreviewScreen()));
            }, 
            child: Text('Model Preview', style: GoogleFonts.orbit(color: Colors.white70))
          ),
          const SizedBox(width: 16),
          TextButton(onPressed: (){}, child: Text('Favorites', style: GoogleFonts.orbit(color: Colors.white70))),
          const SizedBox(width: 16),
          TextButton(onPressed: (){}, child: Text('Shop', style: GoogleFonts.orbit(color: Colors.white70))),
          const SizedBox(width: 16),
          TextButton(onPressed: (){}, child: Text('More ⌄', style: GoogleFonts.orbit(color: Colors.white70))),
          const SizedBox(width: 32),
        ],
        IconButton(icon: const Icon(Icons.light_mode_outlined, color: Colors.white70), onPressed: () {}),
        IconButton(icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white70), onPressed: () {}),
        if (isDesktop) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2d2d2d),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: Text('Sign In', style: GoogleFonts.orbit()),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text('Get Started', style: GoogleFonts.orbit(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        if (!isDesktop)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          ListTile(title: Text('Home', style: GoogleFonts.orbit(color: AppColors.primary500, fontWeight: FontWeight.bold)), onTap: (){}),
          ListTile(title: Text('Features', style: GoogleFonts.orbit(color: isDark ? Colors.white : Colors.black)), onTap: (){}),
          ListTile(title: Text('Favorites', style: GoogleFonts.orbit(color: isDark ? Colors.white : Colors.black)), onTap: (){}),
          ListTile(title: Text('Shop', style: GoogleFonts.orbit(color: isDark ? Colors.white : Colors.black)), onTap: (){}),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neutral200, foregroundColor: Colors.black, shape: const StadiumBorder()),
            child: Text('Sign In', style: GoogleFonts.orbit()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white, shape: const StadiumBorder()),
            child: Text('Get Started', style: GoogleFonts.orbit()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 120, horizontal: 20),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Hero/index bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Discover Your\nPerfect Style',
            textAlign: TextAlign.center,
            style: GoogleFonts.rufina(
              fontSize: isMobile ? 40 : 64,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI-powered outfit recommendations and\ngrooming suggestions tailored just for you',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbit(
              fontSize: isMobile ? 16 : 20,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HaircutScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                ),
                child: Text('HairStyle Try on', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                ),
                child: Text('Browse Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBg : Colors.white,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 100, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('Our Amazing Features', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: isMobile ? 32 : 48), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Text('Discover how our AI-powered platform can transform your style journey', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: isMobile ? 16 : 20), textAlign: TextAlign.center),
              const SizedBox(height: 64),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  _buildFeatureCard(context, 'HairStyle Booking', 'Get personalized hairstyle suggestions based on your face shape and preferences', 'assets/images/Hero/ai hair recommendation.jpg', isMobile, isDark),
                  _buildFeatureCard(context, 'Outfit Preview', 'Complete outfits curated by AI to match your style, occasion, and preferences', 'assets/images/Photo/Unconfirmed 991804.crdownload', isMobile, isDark),
                  _buildFeatureCard(context, 'Virtual Try-On', 'See how hairstyles look on you by using our website', 'assets/images/Hero/ai hair recommendation.jpg', isMobile, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection(BuildContext context, bool isMobile, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.neutral50,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 100, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text('Trending', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: isMobile ? 32 : 40)),
              const SizedBox(height: 48),
              Wrap(
                spacing: 32,
                runSpacing: 32,
                alignment: WrapAlignment.center,
                children: [
                  _buildTrendingCard(context, 'Summer Collection', 'Light and breezy outfits perfect for warm weather', 'assets/images/Photo/summer collection.jpg', isMobile, isDark),
                  _buildTrendingCard(context, 'Trending Now', 'What\'s hot in the fashion world right now', 'assets/images/Photo/Trendy now1.jpg', isMobile, isDark),
                  _buildTrendingCard(context, 'Featured Styles', 'Most Popular picks for this Year', 'assets/images/Photo/featured style.jpg', isMobile, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceAnalysisSection(BuildContext context, bool isMobile, bool isTablet, bool isDesktop, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBg : Colors.white,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 100, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Text('Face Analysis & Perfect Haircut', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: isMobile ? 28 : 40), textAlign: isDesktop ? TextAlign.left : TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzes your facial features to recommend the perfect haircut that complements your unique face shape, hair type, and personal style.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildBulletPoint('Analyzes face shape detection'),
                    _buildBulletPoint('Personalized haircut Style based on hair cut'),
                    _buildBulletPoint('Virtual try-on before you commit'),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Analyze My Face', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('View Hair Styles', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (!isDesktop) const SizedBox(height: 48),
                  ],
                ),
              ),
              if (isDesktop) const SizedBox(width: 64),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/Hero/index bg.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('💇‍♂️', style: TextStyle(fontSize: 70)),
                      SizedBox(height: 16),
                      Text('Find Your Perfect Cut', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      Text('Upload a photo and let our AI work its magic', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context, bool isMobile, bool isTablet, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.neutral900,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6366f1), Color(0xFFec4899), Color(0xFFf97316)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 48,
                      runSpacing: 48,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        SizedBox(
                          width: isMobile ? double.infinity : 250,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pyin Mal', style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 16),
                              const Text('Curated style. Smarter grooming. Confidence that lasts.', style: TextStyle(color: Color(0xFF9ca3af), fontSize: 15, height: 1.6)),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white70, size: 20),
                                  SizedBox(width: 16),
                                  Icon(Icons.flutter_dash, color: Colors.white70, size: 20),
                                  SizedBox(width: 16),
                                  Icon(Icons.link, color: Colors.white70, size: 20),
                                ],
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? double.infinity : 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Explore', style: TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              _buildFooterLink('Who We Are'),
                              _buildFooterLink('Contact'),
                              _buildFooterLink('Help Center'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? double.infinity : 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Feature', style: TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              _buildFooterLink('Outfit preview'),
                              _buildFooterLink('HairStyle and Face-analysis'),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? double.infinity : 300,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stay Sharp', style: TextStyle(color: Color(0xFF818cf8), fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              const Text('Weekly style tips directly to your inbox.', style: TextStyle(color: Color(0xFF9ca3af), fontSize: 14)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: const BoxDecoration(color: Color(0xFF262626), borderRadius: BorderRadius.horizontal(left: Radius.circular(8))),
                                      child: const Align(alignment: Alignment.centerLeft, child: Text('Your email', style: TextStyle(color: Colors.white54, fontSize: 14))),
                                    ),
                                  ),
                                  Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    decoration: const BoxDecoration(color: Color(0xFF6366f1), borderRadius: BorderRadius.horizontal(right: Radius.circular(8))),
                                    child: const Center(child: Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    const Divider(color: Color(0xFF374151)),
                    const SizedBox(height: 24),
                    const Text('© 2025 Pyin Mal — Designed for those who stand out.', style: TextStyle(color: Color(0xFF6b7280), fontSize: 14)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 14)),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String description, String imagePath, bool isMobile, bool isDark) {
    return Container(
      width: isMobile ? double.infinity : 340,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(imagePath, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 200, color: AppColors.neutral200)),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, String title, String desc, String imagePath, bool isMobile, bool isDark) {
    return Container(
      width: isMobile ? double.infinity : 340,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.asset(imagePath, height: 260, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 260, color: AppColors.neutral200)),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
                const SizedBox(height: 12),
                Text(desc, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Shop Now'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4))),
        ],
      ),
    );
  }
}
