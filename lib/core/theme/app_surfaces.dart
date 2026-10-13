import 'package:flutter/material.dart';

/// Surfaces sobres et translucides (inspiration aniverse.fr : fond « muted »
/// à 90 %, bordures blanches à 10 %, boutons ronds de 40 px) pour les
/// composants récents — centre de notifications, cloche, bandeau
/// « Recommandé par ». Dérivées du `ColorScheme` : clair et sombre suivent
/// le thème, aucune couleur en dur.
class AppSurfaces {
  AppSurfaces._();

  /// Côté des boutons icône ronds (cloche, actions de barre).
  static const double iconButtonSize = 40;

  /// Opacité des surfaces « muted » (`bg-muted/90`).
  static const double mutedOpacity = 0.9;

  /// Opacité des bordures fines (`border-white/10`).
  static const double hairlineOpacity = 0.10;

  /// Largeur max du contenu du centre de notifications sur grand écran.
  static const double panelMaxWidth = 480;

  /// Largeur à partir de laquelle le contenu est centré et borné.
  static const double panelBreakpoint = 768;

  /// Fond « muted » d'une carte ou d'un bouton rond.
  static Color muted(ColorScheme scheme) =>
      scheme.surfaceContainerHigh.withValues(alpha: mutedOpacity);

  /// Fond d'une ligne non lue : léger voile de la couleur de marque.
  static Color unreadTint(ColorScheme scheme) =>
      Color.alphaBlend(scheme.primary.withValues(alpha: 0.07), muted(scheme));

  /// Bordure fine, lisible en clair comme en sombre.
  static Color hairline(ColorScheme scheme) =>
      scheme.onSurface.withValues(alpha: hairlineOpacity);
}
