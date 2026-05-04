import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Thème clair
  static final ThemeData light = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surfaceContainerHighest: Colors.grey.shade200,
      shadow: Colors.black,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textTitle,
      ),
      bodySmall: TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
      ),
    ),
    useMaterial3: true,
  );

  // Thème sombre
  static final ThemeData dark = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      onSurface: Colors.white,
      onPrimary: Colors.white,
      outline: Colors.grey.shade700,
      shadow: Colors.black,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      titleSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade400,
      ),
    ),
    useMaterial3: true,
  );
}
