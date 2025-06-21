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
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      titleSmall: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.white,
      ),
      bodySmall: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
      ),
    ),
    useMaterial3: true,
  );
}
