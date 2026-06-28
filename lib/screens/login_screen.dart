import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/screens/profile_setup_screen.dart';
import 'package:pyin_mal_app/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;

  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitAuth() async {
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final user = await _auth.signInWithEmail(_emailController.text.trim(), _passwordController.text);
        if (user != null && mounted) {
          Navigator.pop(context); // Go back after success
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login.err_login'.tr())));
        }
      } else {
        final profile = await _auth.registerWithEmail(
          _emailController.text.trim(), 
          _passwordController.text,
          _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Fashionista',
        );
        if (profile != null && mounted) {
          // After sign up: collect body info + style preferences first,
          // which then continues to the avatar onboarding.
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login.err_register'.tr())));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Social sign-in ──────────────────────────────────────────────────────────
  Future<void> _socialSignIn(Future<dynamic> Function() signIn) async {
    setState(() => _isLoading = true);
    try {
      final user = await signIn();
      if (user != null && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in was cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Social sign-in is not enabled yet. Enable the provider in Firebase to use it.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Forgot password ─────────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final controller =
        TextEditingController(text: _emailController.text.trim());

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkWarm : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Reset password',
              style: GoogleFonts.rufina(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.inkBlack)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter your email and we'll send you a reset link.",
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.outfit(
                    color: isDark ? Colors.white : AppColors.inkBlack),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  filled: true,
                  fillColor:
                      isDark ? Colors.white10 : const Color(0xFFF4F4F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(
                      color: isDark ? AppColors.paleText : AppColors.inkGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(dialogCtx);
                final error = await _auth.sendPasswordReset(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ??
                        'Reset link sent to $email. Check your inbox.'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: Text('Send link',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

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
                      ClipOval(
                        child: Image.asset(
                          'pyin-mal-assets/assets/images/logo.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ta Chat Nhate',
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
              'login.style_starts_here'.tr(),
              style: GoogleFonts.outfit(color: AppColors.charcoal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'login.welcome'.tr(),
            style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack),
          ),
          const SizedBox(height: 8),
          Text(
            'login.subtitle'.tr(),
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
                IgnorePointer(
                  ignoring: !_isLogin,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _isLogin ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('login.new_here'.tr(), style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? AppColors.charcoal : Colors.white)),
                          const SizedBox(height: 24),
                          Text(
                            'login.new_here_desc'.tr(),
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
                            child: Text('login.create_account'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                // Left Text (Visible when in Register mode)
                IgnorePointer(
                  ignoring: _isLogin,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: !_isLogin ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('login.welcome_back'.tr(), style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? AppColors.charcoal : Colors.white)),
                          const SizedBox(height: 24),
                          Text(
                            'login.welcome_back_desc'.tr(),
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
                            child: Text('login.sign_in'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          )
                        ],
                      ),
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
              Expanded(child: _buildMobileTab('login.sign_in_tab'.tr(), _isLogin, () => setState(() => _isLogin = true), isDark, accent)),
              Expanded(child: _buildMobileTab('login.sign_up_tab'.tr(), !_isLogin, () => setState(() => _isLogin = false), isDark, accent)),
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
          Text('login.account_login'.tr(), style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.g_mobiledata, isDark, accent,
                  onTap: () => _socialSignIn(_auth.signInWithGoogle)),
              _buildSocialIcon(Icons.facebook, isDark, accent,
                  onTap: () => _socialSignIn(_auth.signInWithFacebook)),
              _buildSocialIcon(Icons.apple, isDark, accent,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Apple sign-in coming soon')))),
            ],
          ),
          const SizedBox(height: 24),
          Text('login.or_email'.tr(), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildTextField('login.email'.tr(), Icons.email_outlined, false, isDark, accent, controller: _emailController),
          const SizedBox(height: 16),
          _buildTextField('login.password'.tr(), Icons.lock_outline, true, isDark, accent, controller: _passwordController),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _forgotPassword,
              child: Text('login.forgot_password'.tr(), style: GoogleFonts.outfit(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('login.sign_in'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
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
          Text('login.create_account_title'.tr(), style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.g_mobiledata, isDark, accent,
                  onTap: () => _socialSignIn(_auth.signInWithGoogle)),
              _buildSocialIcon(Icons.facebook, isDark, accent,
                  onTap: () => _socialSignIn(_auth.signInWithFacebook)),
              _buildSocialIcon(Icons.apple, isDark, accent,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Apple sign-in coming soon')))),
            ],
          ),
          const SizedBox(height: 24),
          Text('login.or_email_reg'.tr(), style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildTextField('login.name'.tr(), Icons.person_outline, false, isDark, accent, controller: _nameController),
          const SizedBox(height: 16),
          _buildTextField('login.email'.tr(), Icons.email_outlined, false, isDark, accent, controller: _emailController),
          const SizedBox(height: 16),
          _buildTextField('login.password'.tr(), Icons.lock_outline, true, isDark, accent, controller: _passwordController),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('login.sign_up'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, bool isDark, Color accent,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoal : Colors.white,
          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: isDark ? Colors.white : AppColors.inkBlack, size: 24),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, bool obscure, bool isDark, Color accent, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
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
