import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      body: Stack(
        children: [
          // Background Gradient Glows
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.burgundy.withOpacity(0.05), boxShadow: [BoxShadow(color: AppColors.burgundy.withOpacity(0.1), blurRadius: 100, spreadRadius: 50)]),
              ),
            ),
          ],

          // Top Header / Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('PM', style: GoogleFonts.rufina(color: isDark ? AppColors.charcoal : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Pyin Mal',
                        style: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 28, color: isDark ? Colors.white : AppColors.inkBlack),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMobile) _buildMobileBrandHeader(isDark, accent),
                  
                  Container(
                    width: isMobile ? screenWidth * 0.9 : 800,
                    height: isMobile ? null : 540,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkWarm : AppColors.creamCard,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: isMobile ? _buildMobileLayout(isDark, accent) : _buildDesktopLayout(isDark, accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBrandHeader(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'STYLE STARTS HERE',
              style: GoogleFonts.outfit(color: AppColors.charcoal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Pyin Mal',
            style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI fashion and beauty companion.',
            style: GoogleFonts.outfit(color: isDark ? AppColors.paleText : AppColors.inkGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark, Color accent) {
    return Stack(
      children: [
        // Forms Layer
        Row(
          children: [
            Expanded(child: _buildSignInForm(isDark, accent)),
            Expanded(child: _buildSignUpForm(isDark, accent)),
          ],
        ),

        // Animated Sliding Overlay
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutQuart,
          left: _isLogin ? 400 : 0,
          top: 0,
          bottom: 0,
          width: 400,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Right Text (Visible when in Login mode)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _isLogin ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New Here?', style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? AppColors.charcoal : Colors.white)),
                        const SizedBox(height: 24),
                        Text(
                          'Join our community to save looks, preview outfits, and discover your best style.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: isDark ? AppColors.charcoal.withOpacity(0.7) : Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 40),
                        OutlinedButton(
                          onPressed: () => setState(() => _isLogin = false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                            side: BorderSide(color: isDark ? AppColors.charcoal : Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('CREATE ACCOUNT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        )
                      ],
                    ),
                  ),
                ),

                // Left Text (Visible when in Register mode)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: !_isLogin ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Welcome Back!', style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? AppColors.charcoal : Colors.white)),
                        const SizedBox(height: 24),
                        Text(
                          'Continue your style journey with your personalized AI fashion assistant.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: isDark ? AppColors.charcoal.withOpacity(0.7) : Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 40),
                        OutlinedButton(
                          onPressed: () => setState(() => _isLogin = true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                            side: BorderSide(color: isDark ? AppColors.charcoal : Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('SIGN IN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
          child: Row(
            children: [
              Expanded(child: _buildMobileTab('Sign In', _isLogin, () => setState(() => _isLogin = true), isDark, accent)),
              Expanded(child: _buildMobileTab('Sign Up', !_isLogin, () => setState(() => _isLogin = false), isDark, accent)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isLogin ? _buildSignInForm(isDark, accent) : _buildSignUpForm(isDark, accent),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTab(String label, bool isSelected, VoidCallback onTap, bool isDark, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isSelected ? (isDark ? AppColors.charcoal : Colors.white) : (isDark ? AppColors.paleText : AppColors.inkGrey),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Account Login', style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.g_mobiledata, isDark, accent),
              _buildSocialIcon(Icons.facebook, isDark, accent),
              _buildSocialIcon(Icons.apple, isDark, accent),
            ],
          ),
          const SizedBox(height: 24),
          Text('or use your email account', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildTextField('Email', Icons.email_outlined, false, isDark, accent),
          const SizedBox(height: 16),
          _buildTextField('Password', Icons.lock_outline, true, isDark, accent),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Forgot Password?', style: GoogleFonts.outfit(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('SIGN IN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSignUpForm(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Create Style Account', style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.g_mobiledata, isDark, accent),
              _buildSocialIcon(Icons.facebook, isDark, accent),
              _buildSocialIcon(Icons.apple, isDark, accent),
            ],
          ),
          const SizedBox(height: 24),
          Text('or use your email for registration', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildTextField('Name', Icons.person_outline, false, isDark, accent),
          const SizedBox(height: 16),
          _buildTextField('Email', Icons.email_outlined, false, isDark, accent),
          const SizedBox(height: 16),
          _buildTextField('Password', Icons.lock_outline, true, isDark, accent),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text('SIGN UP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : Colors.white,
        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: isDark ? Colors.white : AppColors.inkBlack, size: 24),
    );
  }

  Widget _buildTextField(String hint, IconData icon, bool obscure, bool isDark, Color accent) {
    return TextField(
      obscureText: obscure,
      style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : AppColors.inkBlack),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
        prefixIcon: Icon(icon, color: accent, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.charcoal : AppColors.creamAlt,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
