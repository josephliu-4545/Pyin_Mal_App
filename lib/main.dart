import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/theme_notifier.dart';
import 'package:pyin_mal_app/app_shell.dart';

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Pyin Mal',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFfafafa),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary500,
              primary: AppColors.primary600,
              brightness: Brightness.light,
            ),
            textTheme: TextTheme(
              displayLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
              headlineLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
              headlineMedium: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: AppColors.neutral900),
              bodyLarge: GoogleFonts.orbit(color: AppColors.neutral600),
              bodyMedium: GoogleFonts.orbit(color: AppColors.neutral600),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFFfafafa),
              elevation: 0,
              foregroundColor: AppColors.neutral900,
              titleTextStyle: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutral900),
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
              headlineLarge: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
              headlineMedium: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: Colors.white),
              bodyLarge: GoogleFonts.orbit(color: AppColors.neutral400),
              bodyMedium: GoogleFonts.orbit(color: AppColors.neutral400),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkSurface,
              elevation: 0,
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.rufina(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          home: const MainShell(),
        );
      },
    );
  }
}
