import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
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

  Color _rankBadgeColor(UserRank rank) {
    switch (rank) {
      case UserRank.platinum:
        return const Color(0xFF9BB3C8);
      case UserRank.gold:
        return AppColors.gold;
      case UserRank.silver:
        return const Color(0xFFB0B0B0);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  Widget _buildAuthPrompt(bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Stack(
      children: [
        if (isDark)
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.burgundy.withOpacity(0.12), blurRadius: 120, spreadRadius: 60)],
              ),
            ),
          ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Text(
                    'PM',
                    style: GoogleFonts.rufina(color: isDark ? AppColors.charcoal : Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'profile.create_profile'.tr(),
                  style: GoogleFonts.rufina(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'profile.login_desc'.tr(),
                  style: GoogleFonts.outfit(fontSize: 15, height: 1.6, color: isDark ? AppColors.paleText : AppColors.inkGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('profile.login_btn'.tr(), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView(UserProfile profile, bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final rank = RankingUtils.getRank(profile.points);
    final rankName = RankingUtils.getRankName(rank);
    final nextPoints = RankingUtils.pointsToNextRank(profile.points);
    final progress = RankingUtils.getProgressToNextRank(profile.points);
    final badgeColor = _rankBadgeColor(rank);
    final initial = (profile.displayName?.isNotEmpty == true)
        ? profile.displayName!.substring(0, 1).toUpperCase()
        : 'U';

    return CustomScrollView(
      slivers: [
        // ── Hero Header ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkWarm, AppColors.charcoal]
                        : [AppColors.burgundy, AppColors.burgundyLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -24, right: -24,
                      child: Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
                      ),
                    ),
                    Positioned(
                      bottom: -40, left: 24,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.04)),
                      ),
                    ),
                    Positioned(
                      top: 16, left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PYIN MAL',
                          style: GoogleFonts.outfit(color: AppColors.charcoal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar overlapping banner
              Positioned(
                bottom: -50,
                child: Container(
                  width: 100, height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.goldLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: isDark ? AppColors.charcoal : AppColors.cream, width: 4),
                    boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Text(
                    initial,
                    style: GoogleFonts.rufina(fontSize: 40, color: AppColors.charcoal, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Name & Email ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 66, bottom: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.displayName ?? 'Fashionista',
                      style: GoogleFonts.rufina(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.inkBlack),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        rankName.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor, letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email ?? '',
                  style: GoogleFonts.outfit(fontSize: 14, color: isDark ? AppColors.paleText : AppColors.inkGrey),
                ),
              ],
            ),
          ),
        ),

        // ── Rank Progress Card ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A96E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('profile.style_rank'.tr(), style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.gold, size: 13),
                            const SizedBox(width: 5),
                            Text('${profile.points} pts', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(rankName, style: GoogleFonts.rufina(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('profile.progress'.tr(), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11)),
                      Text(
                        nextPoints > 0 ? 'profile.pts_to_next'.tr(args: [nextPoints.toString()]) : 'profile.max_rank'.tr(),
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldLight),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Account Section ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'profile.account'.tr(),
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.paleText : AppColors.inkGrey, letterSpacing: 1.2),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFC9A96E).withOpacity(isDark ? 0.15 : 0.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC9A96E).withOpacity(0.35)),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.settings_outlined,
                    label: 'profile.settings'.tr(),
                    isDark: isDark,
                    accent: accent,
                    isFirst: true,
                    onTap: () {},
                  ),
                  Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, indent: 56),
                  _buildActionTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'profile.order_history'.tr(),
                    isDark: isDark,
                    accent: accent,
                    isLast: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Sign Out ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: OutlinedButton.icon(
              onPressed: () => _auth.signOut(),
              icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFC9A96E)),
              label: Text('profile.sign_out'.tr(), style: GoogleFonts.outfit(fontSize: 15, color: Color(0xFFC9A96E), fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Color(0xFFC9A96E).withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.inkBlack)),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: isDark ? AppColors.paleText : AppColors.inkGrey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
            body: Center(child: CircularProgressIndicator(color: isDark ? AppColors.gold : AppColors.burgundy)),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return Scaffold(
            backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
            body: SafeArea(child: _buildAuthPrompt(isDark)),
          );
        }

        return StreamBuilder<UserProfile?>(
          stream: _db.getUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
                body: Center(child: CircularProgressIndicator(color: isDark ? AppColors.gold : AppColors.burgundy)),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return Scaffold(
                backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
                body: Center(child: CircularProgressIndicator(color: isDark ? AppColors.gold : AppColors.burgundy)),
              );
            }

            return Scaffold(
              backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
              body: SafeArea(child: _buildProfileView(profile, isDark)),
            );
          },
        );
      },
    );
  }
}
