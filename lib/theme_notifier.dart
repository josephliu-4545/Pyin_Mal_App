import 'package:flutter/material.dart';

/// Three app themes: light, dim (a softly darkened light theme) and dark.
enum AppThemeMode { light, dim, dark }

/// Global theme notifier — set themeNotifier.value = AppThemeMode.x anywhere.
final ValueNotifier<AppThemeMode> themeNotifier =
    ValueNotifier(AppThemeMode.dark);

/// Cycle light → dim → dark → light.
void toggleTheme() {
  final next =
      AppThemeMode.values[(themeNotifier.value.index + 1) % AppThemeMode.values.length];
  themeNotifier.value = next;
}

void setThemeMode(AppThemeMode mode) => themeNotifier.value = mode;
