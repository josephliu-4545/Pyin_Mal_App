import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart'; // For AppColors
import 'package:pyin_mal_app/services/auth_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/models/user_profile.dart';
import 'package:pyin_mal_app/utils/ranking_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pyin_mal_app/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  Widget _buildAuthPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline_rounded, size: 80, color: AppColors.burgundy.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            'Create your style profile',
            style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.inkBlack),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Log in to view your points, rank, and get personalized fashion recommendations from our AI.',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: Text('LOG IN OR SIGN UP', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    final rank = RankingUtils.getRank(profile.points);
    final rankName = RankingUtils.getRankName(rank);
    final nextPoints = RankingUtils.pointsToNextRank(profile.points);
    final progress = RankingUtils.getProgressToNextRank(profile.points);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.gold,
              child: Text(
                profile.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: GoogleFonts.outfit(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.displayName ?? 'Fashionista',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              profile.email ?? '',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Rank Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.burgundy, AppColors.burgundyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.burgundy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Rank', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                      Icon(Icons.star, color: AppColors.gold, size: 32),
                    ],
                  ),
                  Row(
                    children: [
                      Text(rankName, style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${profile.points} pts', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(nextPoints > 0 ? '$nextPoints pts to Next' : 'Max Rank Reached', style: GoogleFonts.outfit(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: AppColors.gold,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Actions
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('Settings', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('Order History', style: GoogleFonts.outfit()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _auth.signOut(),
              child: Text('Sign Out', style: GoogleFonts.outfit(color: Colors.red, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final user = authSnapshot.data;
        if (user == null) {
          return Scaffold(body: _buildAuthPrompt());
        }
        
        return StreamBuilder<UserProfile?>(
          stream: _db.getUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final profile = profileSnapshot.data;
            if (profile == null) {
              // Creating profile...
              return const Center(child: CircularProgressIndicator());
            }
            
            return Scaffold(
              body: SafeArea(child: _buildProfileView(profile)),
            );
          },
        );
      },
    );
  }
}
