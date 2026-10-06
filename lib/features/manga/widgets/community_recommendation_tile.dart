import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/refreshable_manga_image.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/manga/dto/community_recommendation.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Une œuvre recommandée : couverture, titre, total des recommandations
/// (MangaUpdates + Manga Tracker) et bouton « je recommande aussi ».
class CommunityRecommendationTile extends StatelessWidget {
  final CommunityRecommendationDto item;
  final bool pending;
  final VoidCallback onToggle;

  const CommunityRecommendationTile({
    super.key,
    required this.item,
    required this.pending,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: AppRadius.circularXl,
      onTap:
          () => context.push(
            '/manga/${item.muId}',
            extra: MangaDetailExtras(
              title: item.title,
              coverPath: item.mediumCoverUrl,
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.circularSm,
              child: RefreshableMangaImage(
                muId: item.muId.toString(),
                originalUrl: item.mediumCoverUrl,
                width: 48,
                height: 68,
                useProxy: true,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.totalVotes == 0 && item.muSuggested
                        ? l10n.communityRecoMuSuggested
                        : l10n.communityRecoVotes(item.totalVotes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.appVotes > 0)
                    Text(
                      l10n.communityRecoAppVotes(item.appVotes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.dsText3(brightness),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip:
                  item.recommendedByMe
                      ? l10n.communityRecoToggleOff
                      : l10n.communityRecoToggleOn,
              onPressed: pending ? null : onToggle,
              isSelected: item.recommendedByMe,
              icon: const Icon(Icons.thumb_up_alt_outlined),
              selectedIcon: Icon(Icons.thumb_up_alt, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
