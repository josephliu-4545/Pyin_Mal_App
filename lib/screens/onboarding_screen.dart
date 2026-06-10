import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pyin_mal_app/main.dart';
import '../widgets/cdn_image.dart';
import 'package:pyin_mal_app/services/database_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Survey state
  String _selectedStyle = 'Casual';
  String _selectedSize = 'M';
  final Set<String> _selectedClothing = {};
  bool _isSaving = false;

  // Uploaded photo (bytes for cross-platform preview, incl. web)
  Uint8List? _photoBytes;
  String? _photoName;

  // Avatar generation progress
  double _genProgress = 0.0;
  bool _genStarted = false;
  Timer? _genTimer;

  void _startAvatarGeneration() {
    if (_genStarted) return;
    _genStarted = true;
    _genTimer?.cancel();
    _genTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        // Ease the increments so it slows slightly near the end.
        final remaining = 1.0 - _genProgress;
        _genProgress += (remaining * 0.06).clamp(0.012, 0.05);
        if (_genProgress >= 1.0) {
          _genProgress = 1.0;
          timer.cancel();
          // Brief pause at 100%, then advance to customize page.
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && _currentPage == 3) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      });
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  Widget _photoChip(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _genTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Top progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage ? accent : (isDark ? AppColors.darkBorder : AppColors.inkGrey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // PageView content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  if (index == 3) _startAvatarGeneration();
                },
                children: [
                  _buildWelcomePage(isDark, accent),
                  _buildStylePreferencesPage(isDark, accent),
                  _buildUploadPhotoPage(isDark, accent),
                  _buildGenerateAvatarPage(isDark, accent),
                  _buildCustomizeAvatarPage(isDark, accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome ─────────────────────────────────────────────────────
  Widget _buildWelcomePage(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mannequin illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: CdnImage(
                'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Icon(
                  Icons.checkroom_rounded,
                  color: isDark ? AppColors.paleText : AppColors.inkGrey,
                  size: 80,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Welcome',
            style: GoogleFonts.rufina(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'to Pyin Mal',
            style: GoogleFonts.rufina(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Answer a few quick questions to help us understand your style better.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Start the Quiz',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Style Preferences ───────────────────────────────────────────
  Widget _buildStylePreferencesPage(bool isDark, Color accent) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Step badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step 1/3',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tell us about',
                style: GoogleFonts.rufina(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              Text(
                'Your style and preferences',
                style: GoogleFonts.rufina(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              const SizedBox(height: 32),
              
              // Style chips
              Text(
                'Style',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Casual', 'Formal', 'Sporty', 'Streetwear', 'Classic', 'Trendy', 'Other'].map((style) {
                  final isSelected = _selectedStyle == style;
                  return GestureDetector(
                    onTap: () => setLocalState(() => _selectedStyle = style),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        style,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? Colors.white : AppColors.inkBlack),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Size selector
              Text(
                'Size',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
                  final isSelected = _selectedSize == size;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setLocalState(() => _selectedSize = size),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            size,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? Colors.white : AppColors.inkBlack),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Clothing preferences
              Text(
                'Clothing Preferences',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Casual shirts', 'Dress shirts', 'Jeans', 'Chinos', 'Sneakers', 'Boots', 'Coats', 'Hats'].map((item) {
                  final isSelected = _selectedClothing.contains(item);
                  return GestureDetector(
                    onTap: () {
                      setLocalState(() {
                        if (isSelected) {
                          _selectedClothing.remove(item);
                        } else {
                          _selectedClothing.add(item);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? Colors.white : AppColors.inkBlack),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Page 3: Upload Photo ────────────────────────────────────────────────
  Widget _buildUploadPhotoPage(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Upload a photo',
            style: GoogleFonts.rufina(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Upload your photo to help us analyze your body type and color profile.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Upload box (tap to pick / shows preview)
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _photoBytes != null
                      ? accent
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.inkGrey.withOpacity(0.3)),
                  width: 2,
                ),
              ),
              child: _photoBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.memory(_photoBytes!, fit: BoxFit.cover),
                        ),
                        // Change/remove controls
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Row(
                            children: [
                              _photoChip(Icons.swap_horiz_rounded, 'Change',
                                  accent, _pickPhoto),
                              const SizedBox(width: 8),
                              _photoChip(Icons.close_rounded, 'Remove',
                                  Colors.redAccent, () {
                                setState(() {
                                  _photoBytes = null;
                                  _photoName = null;
                                });
                              }),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: isDark ? AppColors.paleText : AppColors.inkGrey,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add a file',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.inkBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to choose from gallery',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color:
                                isDark ? AppColors.paleText : AppColors.inkGrey,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_photoName != null) ...[
            const SizedBox(height: 10),
            Text(
              _photoName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDark ? AppColors.paleText : AppColors.inkGrey,
              ),
            ),
          ],
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _photoBytes != null
                ? ElevatedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor:
                          isDark ? AppColors.charcoal : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: accent),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Page 4: Generate Avatar ──────────────────────────────────────────────
  Widget _buildGenerateAvatarPage(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Generate virtual avatar',
            style: GoogleFonts.rufina(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.inkBlack,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Please wait while we process your photo and create your personalized digital avatar.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? AppColors.paleText : AppColors.inkGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          // Progress indicator (animated)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _genProgress),
                    duration: const Duration(milliseconds: 250),
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.inkGrey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_genProgress * 100).round()}%',
                      style: GoogleFonts.rufina(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.inkBlack,
                      ),
                    ),
                    Text(
                      _genProgress >= 1.0 ? 'Ready!' : 'Generating...',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? AppColors.paleText : AppColors.inkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _genProgress >= 1.0
                ? ElevatedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor:
                          isDark ? AppColors.charcoal : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Skip for now',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: accent),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Page 5: Customize Avatar ─────────────────────────────────────────────
  Widget _buildCustomizeAvatarPage(bool isDark, Color accent) {
    String selectedTab = 'Skin';

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          children: [
            // Top bar with Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 80),
                  Text(
                    'Customize Avatar',
                    style: GoogleFonts.rufina(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_isSaving) return;
                      setState(() => _isSaving = true);
                      
                      // Combine preferences
                      final prefs = [
                        'Style: $_selectedStyle',
                        'Size: $_selectedSize',
                        if (_selectedClothing.isNotEmpty) 'Clothing: ${_selectedClothing.join(", ")}'
                      ];
                      
                      await DatabaseService().updateUserPreferences(prefs);
                      
                      if (mounted) {
                        setState(() => _isSaving = false);
                        Navigator.pop(context); // Go back to app
                      }
                    },
                    child: _isSaving
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accent, strokeWidth: 2))
                        : Text(
                            'Done',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // Avatar display
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 280,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkWarm : AppColors.creamAlt,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: CdnImage(
                          'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(
                            Icons.person_rounded,
                            color: isDark ? AppColors.paleText : AppColors.inkGrey,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Customization tabs
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['Skin', 'Face shape', 'Hairstyle', 'Body type'].map((tab) {
                          final isSelected = selectedTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => setLocalState(() => selectedTab = tab),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? accent : (isDark ? AppColors.darkWarm : AppColors.creamAlt),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isSelected ? accent : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  tab,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? Colors.white : AppColors.inkBlack),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Skin tone colors
                    if (selectedTab == 'Skin')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSkinColor(Colors.brown[900]!, isDark),
                          const SizedBox(width: 12),
                          _buildSkinColor(Colors.brown[700]!, isDark),
                          const SizedBox(width: 12),
                          _buildSkinColor(Colors.brown[500]!, isDark),
                          const SizedBox(width: 12),
                          _buildSkinColor(Colors.brown[300]!, isDark),
                          const SizedBox(width: 12),
                          _buildSkinColor(Colors.brown[100]!, isDark),
                        ],
                      ),
                    // Slider
                    const SizedBox(height: 32),
                    Slider(
                      value: 0.5,
                      onChanged: (value) {},
                      activeColor: accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkinColor(Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.inkGrey.withOpacity(0.3),
          width: 2,
        ),
      ),
    );
  }
}
