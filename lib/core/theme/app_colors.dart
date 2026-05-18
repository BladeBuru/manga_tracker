import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFD32F2F);
  static const Color accent = Color(0xFFFF9800);
  static const Color background = Colors.white;
  static const Color border = primary;
  static const Color text = primary;
  static const textTitle = Color(0xff1f1f39);
  static const textMuted = Colors.grey;
  static const Color onPrimaryText = Colors.white;
  static const Color splash = Color(0x44D32F2F);
  static const Color highlight = Color(0x33FF9800);
  static const Color success = Color(0xD84EA752);
  static const Color error = primary;
  static const Color info = Color(0xCB2196F3);
  static const Color warning = Color(0xFFFF9800);

  // ─────────────────────────────────────────────────────────────────────────
  // 🎨 Design System V1 « Refined Classic » — tokens issus du handoff
  // Claude Design (`.claude-design/manga-tracker/project/tokens.css`).
  // Conversion oklch → hex pour Flutter (qui ne supporte pas oklch natif).
  // ─────────────────────────────────────────────────────────────────────────

  // Light
  static const Color dsBgLight = Color(0xFFF8F7F5); // --bg
  static const Color dsBgInsetLight = Color(0xFFF2F1EF); // --bg-inset
  static const Color dsHairlineLight = Color(0xFFEAE9E6); // --hairline
  static const Color dsBorderLight = Color(0xFFE3E2DF); // --border
  static const Color dsTextLight = Color(0xFF1F1D1B); // --text
  static const Color dsText2Light = Color(0xFF727069); // --text-2
  static const Color dsText3Light = Color(0xFFA6A39C); // --text-3
  static const Color dsRedSoftLight = Color(0xFFFAE4E1); // --red-soft

  // Dark — gris cool neutre (corrigé dans le chat: pas de chaleur marron)
  static const Color dsBgDark = Color(0xFF1F1F22); // --bg
  static const Color dsBgInsetDark = Color(0xFF18181B); // --bg-inset
  static const Color dsSurfaceDark = Color(0xFF26262A); // --surface
  static const Color dsHairlineDark = Color(0xFF2E2E33); // --hairline
  static const Color dsBorderDark = Color(0xFF393940); // --border
  static const Color dsText2Dark = Color(0xFFB5B5B9); // --text-2
  static const Color dsText3Dark = Color(0xFF82828B); // --text-3
  static const Color dsRedSoftDark = Color(0xFF4A1F1F); // --red-soft

  /// Helper : `bg-inset` selon brightness.
  static Color dsBgInset(Brightness b) =>
      b == Brightness.dark ? dsBgInsetDark : dsBgInsetLight;

  /// Helper : `hairline` selon brightness.
  static Color dsHairline(Brightness b) =>
      b == Brightness.dark ? dsHairlineDark : dsHairlineLight;

  /// Helper : `border` (légèrement plus marqué que hairline).
  static Color dsBorder(Brightness b) =>
      b == Brightness.dark ? dsBorderDark : dsBorderLight;

  /// Helper : `text-2` (texte secondaire).
  static Color dsText2(Brightness b) =>
      b == Brightness.dark ? dsText2Dark : dsText2Light;

  /// Helper : `text-3` (texte tertiaire / placeholders).
  static Color dsText3(Brightness b) =>
      b == Brightness.dark ? dsText3Dark : dsText3Light;

  /// Helper : `red-soft` (bg du chip actif).
  static Color dsRedSoft(Brightness b) =>
      b == Brightness.dark ? dsRedSoftDark : dsRedSoftLight;
}
