import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const canvas = Color(0xFFF4F6F1);
    const primary = Color(0xFF789448);
    const secondary = Color(0xFFC85D3B);
    const tertiary = Color(0xFF2F6F9F);
    const surface = Color(0xFFFFFFFF);
    const outline = Color(0xFFCAD3CA);
    const text = Color(0xFF202824);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      outline: outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: text,
        ),
        displaySmall: TextStyle(
          fontSize: 30,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: text),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: text),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFF7D7064)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outline, width: 0.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: tertiary.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outline, width: 0.9),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
