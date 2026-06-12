import 'package:flutter/widgets.dart';

/// Breakpoints responsive unifiés (audit design 2026-06-12).
///
/// Avant, chaque page définissait les siens (home : 1200/600 ; recos :
/// 1200/800/600 ; auth : 1200/900/600) — incohérent. Stratégie unique :
///
/// | Largeur      | Catégorie | Usage typique                      |
/// |--------------|-----------|------------------------------------|
/// | < 600        | mobile    | téléphone — 1 colonne, 3 cols grid |
/// | 600 - 799    | tablet    | petite tablette — 4 cols grid      |
/// | 800 - 1199   | desktop   | tablette paysage / laptop — 5 cols |
/// | ≥ 1200       | wide      | desktop large — 6 cols, maxWidth   |
///
/// Usage :
/// ```dart
/// LayoutBuilder(builder: (context, constraints) {
///   final bp = AppBreakpoints.of(constraints.maxWidth);
///   return GridView(... crossAxisCount: bp.gridColumns ...);
/// })
/// ```
class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 800;
  static const double wide = 1200;

  /// Largeur max du contenu centré sur très grand écran (lecture confort).
  static const double contentMaxWidth = 1100;

  final double width;

  const AppBreakpoints.of(this.width);

  bool get isMobile => width < tablet;
  bool get isTablet => width >= tablet && width < desktop;
  bool get isDesktop => width >= desktop && width < wide;
  bool get isWide => width >= wide;

  /// ≥ tablet (600) — utile pour les layouts 2 colonnes.
  bool get isAtLeastTablet => width >= tablet;

  /// Colonnes de grille standard pour les covers manga (3/4/5/6).
  int get gridColumns => isWide
      ? 6
      : isDesktop
          ? 5
          : isTablet
              ? 4
              : 3;

  /// Padding horizontal de page : serré sur mobile, centré au-delà de
  /// [contentMaxWidth] sur très grand écran.
  double get pagePadding {
    if (width >= contentMaxWidth + 96) {
      return (width - contentMaxWidth) / 2;
    }
    if (isDesktop || isWide) return 48;
    if (isTablet) return 24;
    return 12;
  }
}

/// Contraint le contenu à [AppBreakpoints.contentMaxWidth] et le centre —
/// wrapper standard pour rendre une page lisible sur desktop large sans
/// réécrire son layout interne.
class AppContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
