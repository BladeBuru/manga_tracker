import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Consigne du mode « recherche de lien » : chercher le titre sur ce site
/// (il est déjà copié), ouvrir sa page, puis l'enregistrer comme lien.
class LinkDiscoveryBanner extends StatelessWidget {
  final String? mangaTitle;
  final VoidCallback onSaveLink;
  final VoidCallback onDismiss;

  const LinkDiscoveryBanner({
    super.key,
    required this.mangaTitle,
    required this.onSaveLink,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = mangaTitle?.trim();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Material(
          color: scheme.primaryContainer,
          elevation: 3,
          borderRadius: AppRadius.circularXl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.s,
              AppSpacing.xs,
              AppSpacing.s,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.travel_explore_rounded,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    title == null || title.isEmpty
                        ? l10n.linkDiscoveryHintNoTitle
                        : l10n.linkDiscoveryHint(title),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSaveLink,
                  child: Text(l10n.readerSetAsMangaLink),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
