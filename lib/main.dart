import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/app_shell.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const PyinMalApp());
}

// ── Luxury Fashion Palette ────────────────────────────────────────────────────
class AppColors {
  // Accent
  static const burgundy  = Color(0xFF8B1A2F);   // deep burgundy — primary action
  static const burgundyLight = Color(0xFFB0293F); // lighter burgundy for hover
  static const gold      = Color(0xFFC9A96E);   // warm gold — secondary accent
  static const goldLight = Color(0xFFE2C99A);   // pale gold

  // Light theme surfaces
  static const cream     = Color(0xFFF5EFE6);   // warm cream — light scaffold
  static const creamCard = Color(0xFFFFFFFF);   // pure white cards on cream
  static const creamAlt  = Color(0xFFEDE7DC);   // slightly deeper cream for sections

  // Dark theme surfaces
  static const charcoal  = Color(0xFF1C1A1A);   // near-black warm dark scaffold
  static const darkWarm  = Color(0xFF2A2320);   // warm dark card surface
  static const darkBorder= Color(0xFF3D3330);   // warm dark border

  // Text
  static const inkBlack  = Color(0xFF1A1210);   // near-black text on light
  static const inkGrey   = Color(0xFF6B5F5A);   // muted text on light
  static const paleText  = Color(0xFFB8A99F);   // muted text on dark
}

class PyinMalApp extends StatelessWidget {
  const PyinMalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Pyin Mal',
          debugShowCheckedModeBanner: false,
          themeMode: mode,

          // ── Light Theme ──────────────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.cream,
            colorScheme: const ColorScheme.light(
              primary: AppColors.burgundy,
              secondary: AppColors.gold,
              surface: AppColors.creamCard,
              onPrimary: Colors.white,
              onSecondary: AppColors.inkBlack,
              onSurface: AppColors.inkBlack,
            ),
            textTheme: TextTheme(
              displayLarge:  GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.inkBlack),
              headlineLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.inkBlack),
              headlineMedium:GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.inkBlack),
              bodyLarge:     GoogleFonts.outfit(color: AppColors.inkGrey),
              bodyMedium:    GoogleFonts.outfit(color: AppColors.inkGrey),
              labelLarge:    GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.inkBlack),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.cream,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: AppColors.inkBlack,
              titleTextStyle: GoogleFonts.rufina(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkBlack,
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: AppColors.creamAlt,
              selectedColor: AppColors.burgundy,
              labelStyle: GoogleFonts.outfit(fontSize: 13),
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.burgundy,
                side: const BorderSide(color: AppColors.burgundy),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: AppColors.burgundy,
              unselectedLabelColor: AppColors.inkGrey,
              indicatorColor: AppColors.burgundy,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.outfit(),
            ),
          ),

          // ── Dark Theme ───────────────────────────────────────────────────
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.charcoal,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              secondary: AppColors.burgundy,
              surface: AppColors.darkWarm,
              onPrimary: AppColors.charcoal,
              onSecondary: Colors.white,
              onSurface: Colors.white,
            ),
            textTheme: TextTheme(
              displayLarge:  GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
              headlineLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
              headlineMedium:GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
              bodyLarge:     GoogleFonts.outfit(color: AppColors.paleText),
              bodyMedium:    GoogleFonts.outfit(color: AppColors.paleText),
              labelLarge:    GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.charcoal,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.rufina(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: AppColors.darkWarm,
              selectedColor: AppColors.gold,
              labelStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.white),
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.paleText,
              indicatorColor: AppColors.gold,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.outfit(),
            ),
          ),

          home: const MainShell(),
        );
      },
    );
  }
}
