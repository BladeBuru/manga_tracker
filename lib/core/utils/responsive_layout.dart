import 'package:flutter/widgets.dart';

/// Breakpoints utilisés par toute l'app (Phase 9).
///
/// Inspirés de Material 3 : 600 (compact → medium), 840 (medium → expanded),
/// 1240 (expanded → large). Le palier 1440 est ajouté pour ultra-wide
/// (desktop 4K) afin de capper la largeur des dialogs et formulaires.
class AppBreakpoints {
  AppBreakpoints._();

  /// < 600 : téléphone portrait.
  static const double compact = 600;

  /// 600–840 : téléphone landscape / petite tablette.
  static const double medium = 840;

  /// 840–1240 : tablette / laptop.
  static const double expanded = 1240;

  /// 1240+ : desktop large / ultra-wide.
  static const double large = 1440;
}

/// Categorisation à partir de la largeur du viewport.
enum LayoutSize { compact, medium, expanded, large }

LayoutSize layoutSizeOf(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < AppBreakpoints.compact) return LayoutSize.compact;
  if (width < AppBreakpoints.medium) return LayoutSize.medium;
  if (width < AppBreakpoints.expanded) return LayoutSize.expanded;
  return LayoutSize.large;
}

/// Mixin à utiliser dans les Stateless/StatefulWidget pour récupérer des
/// padding/spacing/maxContentWidth cohérents et responsifs.
///
/// Usage :
/// ```dart
/// class ProfileView extends StatelessWidget with ResponsiveLayoutMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Padding(
///       padding: EdgeInsets.symmetric(horizontal: horizontalPadding(context)),
///       child: ConstrainedBox(
///         constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
///         ...
///       ),
///     );
///   }
/// }
/// ```
mixin ResponsiveLayoutMixin {
  /// Padding horizontal recommandé selon la largeur du viewport.
  ///  - compact : 16 px (téléphone)
  ///  - medium  : 24 px (téléphone landscape, petite tablette)
  ///  - expanded: 32 px (tablette, laptop)
  ///  - large   : 48 px (desktop large)
  double horizontalPadding(BuildContext context) {
    switch (layoutSizeOf(context)) {
      case LayoutSize.compact:
        return 16;
      case LayoutSize.medium:
        return 24;
      case LayoutSize.expanded:
        return 32;
      case LayoutSize.large:
        return 48;
    }
  }

  /// Largeur max du contenu pour éviter les lignes de texte interminables
  /// sur desktop. ∞ sur mobile, 720 sur tablette, 960 sur desktop.
  double maxContentWidth(BuildContext context) {
    switch (layoutSizeOf(context)) {
      case LayoutSize.compact:
      case LayoutSize.medium:
        return double.infinity;
      case LayoutSize.expanded:
        return 960;
      case LayoutSize.large:
        return 1100;
    }
  }

  /// Nombre de colonnes pour une grille (cards, etc.). 2 sur compact,
  /// 3 sur medium, 4 sur expanded, 5 sur large.
  int gridColumns(BuildContext context) {
    switch (layoutSizeOf(context)) {
      case LayoutSize.compact:
        return 2;
      case LayoutSize.medium:
        return 3;
      case LayoutSize.expanded:
        return 4;
      case LayoutSize.large:
        return 5;
    }
  }

  bool isMobile(BuildContext context) =>
      layoutSizeOf(context) == LayoutSize.compact;
  bool isTablet(BuildContext context) =>
      layoutSizeOf(context) == LayoutSize.medium ||
      layoutSizeOf(context) == LayoutSize.expanded;
  bool isDesktop(BuildContext context) =>
      layoutSizeOf(context) == LayoutSize.large;
}
