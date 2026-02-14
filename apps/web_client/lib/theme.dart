import 'package:flutter/material.dart';

/// Shared theme colors matching the SvelteKit marketing site
/// Based on theme-config.json in the project root
class AppColors {
  // Light Mode Colors
  static const lightBackground = Color(0xFFF0FDF4); // 240 253 244
  static const lightForeground = Color(0xFF14532D); // 20 83 45
  static const lightPrimary = Color(0xFF16A34A); // 22 163 74
  static const lightPrimaryForeground = Color(0xFFF0FDF4); // 240 253 244
  static const lightSecondary = Color(0xFFDCFCE7); // 220 252 231
  static const lightSecondaryForeground = Color(0xFF14532D); // 20 83 45
  static const lightAccent = Color(0xFF22C55E); // 34 197 94
  static const lightMuted = Color(0xFFDCFCE7); // 220 252 231
  static const lightMutedForeground = Color(0xFF166534); // 22 101 52
  static const lightCard = Color(0xFFFFFFFF); // 255 255 255
  static const lightBorder = Color(0xFF86EFAC); // 134 239 172
  static const lightError = Color(0xFFEF4444); // 239 68 68
  static const lightSuccess = Color(0xFF22C55E); // 34 197 94

  // Dark Mode Colors (Neon Green Theme)
  static const darkBackground = Color(0xFF052E16); // 5 46 22
  static const darkForeground = Color(0xFFF0FDF4); // 240 253 244
  static const darkPrimary = Color(0xFF4ADE80); // 74 222 128 - Neon Green
  static const darkPrimaryForeground = Color(0xFF052E16); // 5 46 22
  static const darkSecondary = Color(0xFF166534); // 22 101 52
  static const darkSecondaryForeground = Color(0xFFF0FDF4); // 240 253 244
  static const darkAccent = Color(0xFF22FF7A); // 34 255 122 - Bright Neon
  static const darkMuted = Color(0xFF14532D); // 20 83 45
  static const darkMutedForeground = Color(0xFFBBF7D0); // 187 247 208
  static const darkCard = Color(0xFF14532D); // 20 83 45
  static const darkBorder = Color(0xFF166534); // 22 101 52
  static const darkError = Color(0xFFF87171); // 248 113 113
  static const darkSuccess = Color(0xFF4ADE80); // 74 222 128

  AppColors._();
}

/// App theme configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightPrimaryForeground,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightSecondaryForeground,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightForeground,
        error: AppColors.lightError,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.lightForeground,
        iconTheme: IconThemeData(color: AppColors.lightForeground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightPrimaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightBorder, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: AppColors.lightForeground,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: AppColors.lightForeground,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.lightForeground,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.lightForeground,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.lightForeground,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.lightForeground),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.lightMutedForeground,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkSecondaryForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        error: AppColors.darkError,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.darkForeground,
        iconTheme: IconThemeData(color: AppColors.darkForeground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkPrimaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: AppColors.darkPrimary.withOpacity(0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: BorderSide(color: AppColors.darkBorder, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkError, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: AppColors.darkForeground,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: AppColors.darkForeground,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.darkForeground,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.darkForeground,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.darkForeground,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.darkForeground,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.darkForeground),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.darkMutedForeground,
        ),
      ),
    );
  }

  AppTheme._();
}
