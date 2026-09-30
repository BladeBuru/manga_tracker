import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/reader/services/last_site_link_policy.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Pour un titre sans lien : proposer le site de la dernière lecture —
/// copier son lien, ou y chercher directement ce titre depuis l'app.
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
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: AppRadius.circularXl,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: scheme.primary),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  l10n.linkSuggestionTitle(suggestion.host),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.linkSuggestionSource(suggestion.sourceTitle),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
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
