import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for settings preferences
  bool _pushNotifications = true;
  bool _hapticFeedback = true;
  bool _biometricsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final textCol = isDark ? Colors.white : AppColors.inkBlack;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final secondaryText = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textCol, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'profile.settings'.tr(),
          style: GoogleFonts.rufina(
            color: textCol,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Appearance / Theme ──────────────────────────────────────────
              _buildSectionTitle('settings.appearance'.tr().contains('settings') ? 'Appearance' : 'settings.appearance'.tr(), secondaryText),
              const SizedBox(height: 10),
              ValueListenableBuilder<AppThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, currentMode, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A96E).withOpacity(isDark ? 0.15 : 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC9A96E).withOpacity(0.35)),
                    ),
                    child: Column(
                      children: [
                        _buildThemeOptionTile(
                          title: 'Light Theme',
                          subtitle: 'Bright and clean luxury interface',
                          mode: AppThemeMode.light,
                          currentMode: currentMode,
                          isDark: isDark,
                          accent: accent,
                          isFirst: true,
                        ),
                        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, indent: 56),
                        _buildThemeOptionTile(
                          title: 'Dim Theme',
                          subtitle: 'Soft, vintage cream background',
                          mode: AppThemeMode.dim,
                          currentMode: currentMode,
                          isDark: isDark,
                          accent: accent,
                        ),
                        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, indent: 56),
                        _buildThemeOptionTile(
                          title: 'Premium Dark',
                          subtitle: 'Sleek, battery-saving dark interface',
                          mode: AppThemeMode.dark,
                          currentMode: currentMode,
                          isDark: isDark,
                          accent: accent,
                          isLast: true,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // ── Language ────────────────────────────────────────────────────
              _buildSectionTitle('language.title'.tr(), secondaryText),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A96E).withOpacity(isDark ? 0.15 : 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC9A96E).withOpacity(0.35)),
                ),
                child: Column(
                  children: [
                    _buildLanguageTile(
                      label: 'English',
                      localeCode: 'en',
                      currentLocale: context.locale,
                      isDark: isDark,
                      accent: accent,
                      isFirst: true,
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, indent: 56),
                    _buildLanguageTile(
                      label: 'မြန်မာဘာသာ (Burmese)',
                      localeCode: 'my',
                      currentLocale: context.locale,
                      isDark: isDark,
                      accent: accent,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ── Preferences / Preferences ──────────────────────────────────
              _buildSectionTitle('Preferences', secondaryText),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A96E).withOpacity(isDark ? 0.15 : 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC9A96E).withOpacity(0.35)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.notifications_none_rounded,
                      label: 'Push Notifications',
                      value: _pushNotifications,
                      isDark: isDark,
                      accent: accent,
                      isFirst: true,
                      onChanged: (val) {
                        setState(() {
                          _pushNotifications = val;
                        });
                      },
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, indent: 56),
                    _buildSwitchTile(
                      icon: Icons.vibration_rounded,
                      label: 'Haptic Feedback',
                      value: _hapticFeedback,
                      isDark: isDark,
                      accent: accent,
                      onChanged: (val) {
                        setState(() {
                          _hapticFeedback = val;
                        });
                      },
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, indent: 56),
                    _buildSwitchTile(
                      icon: Icons.fingerprint_rounded,
                      label: 'Biometric Login',
                      value: _biometricsEnabled,
                      isDark: isDark,
                      accent: accent,
                      isLast: true,
                      onChanged: (val) {
                        setState(() {
                          _biometricsEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── App Version / Details ────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'Ta Chat Nhate Fashion App',
                      style: GoogleFonts.rufina(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 (Build 1)',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required AppThemeMode mode,
    required AppThemeMode currentMode,
    required bool isDark,
    required Color accent,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = currentMode == mode;
    IconData icon;
    switch (mode) {
      case AppThemeMode.light:
        icon = Icons.light_mode_outlined;
        break;
      case AppThemeMode.dim:
        icon = Icons.wb_twilight_rounded;
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        break;
    }

    return InkWell(
      onTap: () {
        setThemeMode(mode);
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? accent.withOpacity(0.4) : Colors.transparent,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? accent : (isDark ? AppColors.paleText : AppColors.inkGrey),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.inkBlack,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isDark ? AppColors.paleText.withOpacity(0.7) : AppColors.inkGrey.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: accent, size: 20)
            else
              Icon(Icons.circle_outlined, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String label,
    required String localeCode,
    required Locale currentLocale,
    required bool isDark,
    required Color accent,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = currentLocale.languageCode == localeCode;

    return InkWell(
      onTap: () {
        context.setLocale(Locale(localeCode));
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? accent.withOpacity(0.4) : Colors.transparent,
                ),
              ),
              child: Icon(
                Icons.translate_rounded,
                color: isSelected ? accent : (isDark ? AppColors.paleText : AppColors.inkGrey),
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked_rounded, color: accent, size: 20)
            else
              Icon(Icons.radio_button_off_rounded, color: isDark ? AppColors.darkBorder : AppColors.creamAlt, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required bool isDark,
    required Color accent,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.inkBlack,
                ),
              ),
            ),
            Switch(
              value: value,
              activeColor: accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
