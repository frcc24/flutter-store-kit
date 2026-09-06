import 'package:flutter/material.dart';

/// The palette. Change these and the whole app follows.
class AppColors {
  static const bgDark = Color(0xFF0A102A);
  static const bgLight = Color(0xFF121A3D);
  static const cyan = Color(0xFF18E4FF);
  static const lime = Color(0xFFB9FF3F);
  static const text = Color(0xFFF4F7FF);
  static const muted = Color(0xFF9EB0D8);
  static const danger = Color(0xFFFF5E5E);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.cyan,
    secondary: AppColors.lime,
    error: AppColors.danger,
    surface: AppColors.bgLight,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: AppColors.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.muted),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
  );
}
