import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/auth_redirect.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Bouton de tête d'`AppBar` : retour quand une page est en dessous, sinon
/// accueil.
///
/// Une page ouverte directement (lien, F5, bouton « avance » du navigateur)
/// est seule dans la pile : l'`AppBar` n'affichait alors aucun bouton et
/// l'utilisateur restait coincé. Sur mobile, les pages sont toujours
/// empilées : c'est le `BackButton` standard, comportement inchangé.
///
/// [onBack] remplace le retour par défaut (`maybePop`, qui respecte les
/// `PopScope` de la page) — par exemple pour renvoyer un résultat.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onBack;
  final String fallback;
  final Color? color;

  /// Taille d'icône (par défaut celle de l'`AppBar`).
  final double? iconSize;

  const AppBackButton({
    super.key,
    this.onBack,
    this.fallback = homeLocation,
    this.color,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final style =
        iconSize == null ? null : IconButton.styleFrom(iconSize: iconSize);
    if (canPop) return BackButton(onPressed: onBack, color: color, style: style);
    final l10n = AppLocalizations.of(context);
    return IconButton(
      style: style,
      icon: Icon(Icons.home_outlined, color: color),
      tooltip: l10n?.backToHome ?? l10n?.home,
      onPressed: () => GoRouter.of(context).go(fallback),
    );
  }
}
