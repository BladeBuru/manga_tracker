import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary, 
      secondary: AppColors.accent,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textTitle),
      bodySmall: TextStyle(fontSize: 10, color: AppColors.textMuted),
    ),
    useMaterial3: true,
  );
}

