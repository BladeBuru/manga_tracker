import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Override de `FilledButton.tonal` retiré du theme global car ça
  // affecterait aussi `FilledButton` plain. Les call sites qui veulent
  // un tonal rouge utilisent directement
  // `FilledButton.styleFrom(backgroundColor: scheme.primaryContainer,
  //                         foregroundColor: scheme.onPrimaryContainer)`.
  // Voir `AppEmptyState`, `AppErrorState`.

  // Thème clair
  static final ThemeData light = () {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      // **Refactor 2026-05-18** : `secondary` était `accent` (orange #FF9800)
      // → Material 3 utilise `secondary` pour DES TONNES de composants natifs
      // (bordures SegmentedButton, OutlinedButton, ChipThemeData side, etc.).
      // Résultat : orange partout dans l'app sans qu'on demande. On utilise
      // désormais `primary` (rouge) comme secondaire — tous les composants
      // natifs qui voulaient un accent prennent le rouge identitaire au lieu
      // de l'orange parasite. Les rares usages volontaires d'orange (warnings
      // d'expiration de mdp, etc.) passent par `AppColors.warning` direct.
      secondary: AppColors.primary,
      surfaceContainerHighest: Colors.grey.shade200,
      shadow: Colors.black,
    );
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      // NOTE : on n'utilise PAS l'override `_tonalRedOverride` ici car
      // ça affecterait aussi les `FilledButton` plain. À la place, on
      // demande explicitement aux call sites d'utiliser
      // `FilledButton.styleFrom(backgroundColor: scheme.primaryContainer,
      // foregroundColor: scheme.onPrimaryContainer)` quand ils veulent
      // une variante tonal "rouge". Voir `AppEmptyState`, `AppErrorState`.
      // **Refactor 2026-05-18** : passage Inter → Manrope (design system V1
      // « Refined Classic » du handoff Claude Design). Manrope a une grosse
      // densité optique + features OpenType (cv11, ss01, ss03) qui donnent
      // un look plus moderne / éditorial cohérent avec le reste de la refonte.
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
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
  }();

  // Thème sombre
  static final ThemeData dark = () {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      // **Refactor 2026-05-18** : `secondary` était `accent` (orange #FF9800)
      // → Material 3 utilise `secondary` pour DES TONNES de composants natifs
      // (bordures SegmentedButton, OutlinedButton, ChipThemeData side, etc.).
      // Résultat : orange partout dans l'app sans qu'on demande. On utilise
      // désormais `primary` (rouge) comme secondaire — tous les composants
      // natifs qui voulaient un accent prennent le rouge identitaire au lieu
      // de l'orange parasite. Les rares usages volontaires d'orange (warnings
      // d'expiration de mdp, etc.) passent par `AppColors.warning` direct.
      secondary: AppColors.primary,
      surface: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      onSurface: Colors.white,
      onPrimary: Colors.white,
      outline: Colors.grey.shade700,
      shadow: Colors.black,
    );
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: colorScheme,
      textTheme:
          GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).copyWith(
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
  }();
}
