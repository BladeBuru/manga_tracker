import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Credit de la source de donnees (MangaUpdates), en pied de page.
///
/// Sa politique d'usage demande d'etre creditee la ou ses fiches et ses
/// suggestions sont affichees. Le credit est donc pose en bas de defilement
/// des ecrans qui montrent ce contenu (accueil, page d'une section) plutot
/// que sous chaque carrousel : visible en contexte, jamais dans le chemin de
/// lecture. Le profil en porte une copie permanente, l'application n'ayant
/// pas d'ecran « A propos ».
///
/// Texte traduit dans les 7 langues (`dataSourceCredit`) ; « MangaUpdates »
/// reste tel quel, c'est un nom propre.
class DataSourceCredit extends StatelessWidget {
  const DataSourceCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      child: Text(
        l10n.dataSourceCredit,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
