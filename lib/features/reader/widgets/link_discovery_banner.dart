import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Consigne du mode « recherche de lien » : chercher le titre sur ce site
/// (il est déjà copié), ouvrir sa page, puis l'enregistrer comme lien.
class LinkDiscoveryBanner extends StatelessWidget {
  final String? mangaTitle;
  /// `null` pendant l'enregistrement : le bouton est désactivé.
  final VoidCallback? onSaveLink;
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
              AppSpacing.s + 4,
            ),
            // Deux lignes : consigne (avec fermeture), puis l'action. Sur
            // une seule ligne, le bouton écrasait la consigne lettre par
            // lettre sur les petits écrans.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Icon(
                        Icons.travel_explore_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          title == null || title.isEmpty
                              ? l10n.linkDiscoveryHintNoTitle
                              : l10n.linkDiscoveryHint(title),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: onDismiss,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.icon(
                    onPressed: onSaveLink,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(l10n.readerSetAsMangaLink),
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
