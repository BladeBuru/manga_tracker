import 'package:flutter/widgets.dart';

/// Tokens d'espacement de l'application (Phase 10).
///
/// Remplace les `EdgeInsets.all(16)` magiques disséminés dans le code.
/// Inspirés du 4pt baseline grid de Material 3.
///
/// Usage :
/// ```dart
/// Padding(
///   padding: EdgeInsets.all(AppSpacing.m),
///   child: ...,
/// )
/// SizedBox(height: AppSpacing.l)
/// ```
class AppSpacing {
  AppSpacing._();

  /// 4 px — micro espacement (entre icône et texte).
  static const double xs = 4;

  /// 8 px — petit espacement (entre éléments groupés).
  static const double s = 8;

  /// 16 px — espacement standard (la valeur la plus courante).
  static const double m = 16;

  /// 24 px — espacement large (séparation de sections).
  static const double l = 24;

  /// 32 px — espacement extra-large (entre blocs majeurs).
  static const double xl = 32;

  /// 48 px — espacement géant (titre de page, hero).
  static const double jumbo = 48;

  // ─── Helpers EdgeInsets pré-fabriqués ───

  static const EdgeInsets paddingAllS = EdgeInsets.all(s);
  static const EdgeInsets paddingAllM = EdgeInsets.all(m);
  static const EdgeInsets paddingAllL = EdgeInsets.all(l);

  static const EdgeInsets paddingHorizontalM =
      EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets paddingVerticalM =
      EdgeInsets.symmetric(vertical: m);

  static const EdgeInsets paddingHorizontalL =
      EdgeInsets.symmetric(horizontal: l);
}
