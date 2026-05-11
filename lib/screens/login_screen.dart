import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      body: Stack(
        children: [
          // Logo Top Left
          Positioned(
            top: 40,
            left: 40,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4c00ff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('PM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pyin Mal',
                  style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          
          // Back Button
          Positioned(
            top: 40,
            right: 40,
            child: IconButton(
              icon: const Icon(Icons.close, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Main Container
          Center(
            child: Container(
              width: isMobile ? screenWidth * 0.9 : 768,
              height: isMobile ? MediaQuery.of(context).size.height * 0.8 : 480,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        // Sign In Form (Left Side)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          left: _isLogin ? 0 : 768 * 0.5,
          width: 768 * 0.5,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: _isLogin ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_isLogin,
              child: _buildSignInForm(),
            ),
          ),
        ),

        // Sign Up Form (Left Side originally, moves right)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          left: _isLogin ? 0 : 0, // In HTML it stays on left but z-index handles it, we'll keep it left and fade it in
          width: 768 * 0.5,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: !_isLogin ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: _isLogin,
              child: _buildSignUpForm(),
            ),
          ),
        ),

        // Animated Gradient Overlay Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          left: _isLogin ? 768 * 0.5 : 0,
          width: 768 * 0.5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4c00ff), Color(0xFF4099ff)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Stack(
              children: [
                // Right Panel Text (Visible when Login)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  left: _isLogin ? 0 : 768 * 0.5,
                  right: _isLogin ? 0 : -768 * 0.5,
                  top: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Hello, Friend!', style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 20),
                        const Text('Register with your personal details to use all of site features', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 30),
                        OutlinedButton(
                          onPressed: () => setState(() => _isLogin = false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        )
                      ],
                    ),
                  ),
                ),

                // Left Panel Text (Visible when Register)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  left: !_isLogin ? 0 : -768 * 0.5,
                  right: !_isLogin ? 0 : 768 * 0.5,
                  top: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Welcome Back!', style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 20),
                        const Text('Enter your personal details to use all of site features', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 30),
                        OutlinedButton(
                          onPressed: () => setState(() => _isLogin = true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isLogin = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: _isLogin ? const Color(0xFF4c00ff) : Colors.grey[200],
                  child: Text('Sign In', textAlign: TextAlign.center, style: TextStyle(color: _isLogin ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isLogin = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: !_isLogin ? const Color(0xFF4c00ff) : Colors.grey[200],
                  child: Text('Sign Up', textAlign: TextAlign.center, style: TextStyle(color: !_isLogin ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLogin ? _buildSignInForm() : _buildSignUpForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Sign In', style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.g_mobiledata),
              _buildSocialIcon(Icons.facebook),
              _buildSocialIcon(Icons.code),
            ],
          ),
          const SizedBox(height: 15),
          const Text('or use your email and password', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 15),
          _buildTextField('Email', false),
          const SizedBox(height: 10),
          _buildTextField('Password', true),
          const SizedBox(height: 15),
          const Text('Forgot Your Password?', style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Create Account', style: GoogleFonts.rufina(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.g_mobiledata),
              _buildSocialIcon(Icons.facebook),
              _buildSocialIcon(Icons.code),
            ],
          ),
          const SizedBox(height: 15),
          const Text('or use your email for registration', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 15),
          _buildTextField('Name', false),
          const SizedBox(height: 10),
          _buildTextField('Email', false),
          const SizedBox(height: 10),
          _buildTextField('Password', true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          )
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.black87),
    );
  }

  Widget _buildTextField(String hint, bool obscure) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}
