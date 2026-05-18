import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Titre "Rechercher" en haut de la page.
///
/// Source : `.claude-design/manga-tracker/project/screen-search.jsx`.
/// fontSize 24, weight 900, letterSpacing -0.025em, padding 8/16/16.
class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.m,
      ),
      child: Text(
        l10n.searchTitle,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6, // -0.025em * 24
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
