import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/reader/services/last_site_link_policy.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Pour un titre sans lien : proposer le site de la dernière lecture —
/// y chercher directement ce titre depuis l'app (action principale), ou
/// copier son lien.
///
/// Refonte 2026-10 (retour : « du rouge avec du texte noir ») : surface
/// neutre, icône dans une pastille tonale, textes aux couleurs du thème et
/// à taille lisible.
class LastSiteLinkSuggestion extends StatelessWidget {
  final LastSiteLink suggestion;
  final VoidCallback onCopyLink;
  final VoidCallback onSearchOnSite;

  const LastSiteLinkSuggestion({
    super.key,
    required this.suggestion,
    required this.onCopyLink,
    required this.onSearchOnSite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.circularXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.s),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.travel_explore_rounded,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.s + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.linkSuggestionTitle(suggestion.host),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.linkSuggestionSource(suggestion.sourceTitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s + 4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            children: [
              TextButton.icon(
                onPressed: onCopyLink,
                icon: const Icon(Icons.content_copy_outlined, size: 18),
                label: Text(l10n.linkSuggestionCopy),
              ),
              FilledButton.tonalIcon(
                onPressed: onSearchOnSite,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(l10n.linkSuggestionSearch),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
