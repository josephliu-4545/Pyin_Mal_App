import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _currentIndex = 1; // Default to Basic Plan
  late PageController _pageController;

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Free Plan',
      'price': '0 MMK',
      'subtitle': '“Discover Your Style”',
      'features': [
        'AI Stylist Chat — 5 times/month',
        'AI Outfit Recommendation — 5 outfits/month',
        'Standard AR Try-On — 3 times/month',
        'Smart Scan — 3 scans/month',
        'Hairstyle Try-On — 1 time/month',
        'Save Closet / Outfit — up to 5 outfits',
      ],
      'color': Colors.grey.shade400,
      'isPopular': false,
    },
    {
      'title': 'Basic Plan',
      'price': '10,000 MMK',
      'period': '/ Month',
      'subtitle': '“Elevate Your Wardrobe”',
      'features': [
        'AI Stylist Chat — 50 times/month',
        'AI Outfit Recommendation — 30 outfits/month',
        'AR Try-On — 20 times/month',
        'Smart Scan — 30 scans/month',
        'Hairstyle Try-On — 10 times/month',
        'Save Closet / Outfit — up to 50 outfits',
        'Ad-free browsing',
        'Faster AI response',
        '5% discount from selected partner shops',
      ],
      'color': AppColors.burgundy,
      'isPopular': true,
    },
    {
      'title': 'Premium Plan',
      'price': '25,000 MMK',
      'period': '/ Month',
      'subtitle': '“The Ultimate Fashion Experience”',
      'features': [
        'AI Stylist Chat — Unlimited (fair usage)',
        'AI Outfit Recommendation — Unlimited (fair usage)',
        'Advanced AR Try-On — 100 times/month',
        'Smart Scan — Unlimited (fair usage)',
        'Hairstyle Try-On — 50 times/month',
        'Save Closet / Outfit — Unlimited',
        'Advanced color and style matching',
        'VIP early access to new arrivals',
        '15% VIP discount from selected partner shops',
        '1 free personal stylist consultation/month',
      ],
      'color': AppColors.gold,
      'isPopular': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex, viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final textCol = isDark ? Colors.white : AppColors.inkBlack;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        title: Text(
          'Choose Your Plan',
          style: GoogleFonts.rufina(color: textCol, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Unlock the full potential of your style.',
            style: GoogleFonts.outfit(color: isDark ? AppColors.paleText : AppColors.inkGrey, fontSize: 16),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) {
                setState(() {
                  _currentIndex = idx;
                });
              },
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                final isSelected = _currentIndex == index;
                return _buildPlanCard(plan, isSelected, isDark);
              },
            ),
          ),
          const SizedBox(height: 30),
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _plans.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? AppColors.gold : (isDark ? AppColors.darkBorder : AppColors.creamAlt),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle subscription selection
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${_plans[_currentIndex]['title']}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _plans[_currentIndex]['color'] == Colors.grey.shade400 ? (isDark ? AppColors.darkBorder : AppColors.creamAlt) : _plans[_currentIndex]['color'],
                  foregroundColor: _currentIndex == 0 ? textCol : (isDark && _currentIndex == 2 ? AppColors.charcoal : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _currentIndex == 0 ? 'Current Plan' : 'Subscribe Now',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isSelected, bool isDark) {
    final scale = isSelected ? 1.0 : 0.9;
    final color = plan['color'] as Color;
    final isPremium = plan['title'] == 'Premium Plan';
    
    // For the Free Plan, use a neutral background. For others, use their respective colors.
    final cardBg = plan['title'] == 'Free Plan'
        ? (isDark ? AppColors.darkWarm : AppColors.creamCard)
        : color;

    final textColor = plan['title'] == 'Free Plan'
        ? (isDark ? Colors.white : AppColors.inkBlack)
        : ((isPremium && isDark) ? AppColors.charcoal : Colors.white);

    final subTextColor = plan['title'] == 'Free Plan'
        ? (isDark ? AppColors.paleText : AppColors.inkGrey)
        : ((isPremium && isDark) ? AppColors.charcoal.withOpacity(0.8) : Colors.white.withOpacity(0.8));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      transform: Matrix4.identity()..scale(scale, scale),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ]
            : [],
        border: plan['title'] == 'Free Plan' ? Border.all(color: isDark ? AppColors.darkBorder : AppColors.creamAlt, width: 2) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative background circles
            if (!plan['title'].toString().contains('Free'))
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plan['isPopular'])
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'MOST POPULAR',
                        style: GoogleFonts.outfit(color: AppColors.burgundy, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  Text(
                    plan['title'],
                    style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan['subtitle'],
                    style: GoogleFonts.outfit(fontSize: 14, color: subTextColor, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan['price'],
                        style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      if (plan.containsKey('period'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            plan['period'],
                            style: GoogleFonts.outfit(fontSize: 16, color: subTextColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: (plan['features'] as List).length,
                      itemBuilder: (context, idx) {
                        final feature = plan['features'][idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, color: plan['title'] == 'Free Plan' ? AppColors.gold : textColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: GoogleFonts.outfit(fontSize: 14, color: textColor, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
