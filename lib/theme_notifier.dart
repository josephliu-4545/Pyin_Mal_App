import 'package:flutter/material.dart';

/// Global theme notifier — call themeNotifier.value = ThemeMode.light / .dark anywhere
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void toggleTheme() {
  themeNotifier.value =
      themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
