import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';

/// Dimensions de l'accueil catalogue derivees de la largeur disponible.
///
/// Un seul endroit pour la largeur des cartes, la hauteur des covers (ratio
/// 3:4) et le padding de page : les carrousels, les squelettes et la page
/// « Tout voir » lisent les memes valeurs, donc restent alignes.
class HomeLayoutMetrics {
  /// Hauteur du bloc texte sous la cover d'une [MangaCard] non compacte :
  /// titre sur deux lignes + ligne annee / note.
  static const double cardTextBlockHeight = 62;

  /// Ecart entre deux cartes d'un carrousel.
  static const double cardGap = AppSpacing.s + AppSpacing.xs;

  /// Ecart vertical entre deux sections.
  static const double sectionGap = AppSpacing.l;

  final AppBreakpoints breakpoints;

  const HomeLayoutMetrics._(this.breakpoints);

  factory HomeLayoutMetrics.of(double width) =>
      HomeLayoutMetrics._(AppBreakpoints.of(width));

  /// Padding horizontal du contenu (en-tetes, bandeaux, debut des
  /// carrousels). Le centrage grand ecran est assure par `AppContentWidth`.
  double get horizontalPadding {
    if (breakpoints.isWide || breakpoints.isDesktop) return AppSpacing.xl;
    if (breakpoints.isTablet) return AppSpacing.l;
    return AppSpacing.m;
  }

  /// Largeur d'une carte de carrousel : plus large a mesure que l'ecran
  /// grandit, et de toute facon plus de cartes visibles.
  double get cardWidth {
    if (breakpoints.isWide) return 160;
    if (breakpoints.isDesktop) return 148;
    if (breakpoints.isTablet) return 136;
    return 120;
  }

  /// Cover au ratio 3:4.
  double get coverHeight => (cardWidth * 4 / 3).roundToDouble();

  /// Hauteur totale d'une carte (cover + bloc texte).
  double get cardHeight => coverHeight + cardTextBlockHeight;

  /// Colonnes de la grille « Tout voir ».
  int get gridColumns => breakpoints.gridColumns;

  /// Ratio largeur/hauteur des cellules de la grille, calcule pour que la
  /// cover garde son 3:4 quelle que soit la largeur de colonne.
  double gridAspectRatio(double contentWidth, {double spacing = cardGap}) {
    final columns = gridColumns;
    final cellWidth = (contentWidth - spacing * (columns - 1)) / columns;
    if (cellWidth <= 0) return 0.62;
    return cellWidth / (gridCoverHeight(contentWidth, spacing: spacing) +
        cardTextBlockHeight);
  }

  /// Hauteur de cover d'une cellule de grille (ratio 3:4).
  double gridCoverHeight(double contentWidth, {double spacing = cardGap}) {
    final columns = gridColumns;
    final cellWidth = (contentWidth - spacing * (columns - 1)) / columns;
    return (cellWidth * 4 / 3).roundToDouble();
  }
}
