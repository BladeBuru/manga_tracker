import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Détail de la note globale : chaque source avec sa note et son nombre de
/// votes, puis la note globale (fusion au prorata des votes, calculée par
/// l'API). Une source sans vote n'est pas affichée.
class DetailRatingBreakdown extends StatelessWidget {
  final double? muRating;
  final int? muRatingVotes;
  final double? appRating;
  final int appRatingCount;
  final double? globalRating;
  final int totalRatingVotes;

  const DetailRatingBreakdown({
    super.key,
    this.muRating,
    this.muRatingVotes,
    this.appRating,
    this.appRatingCount = 0,
    this.globalRating,
    this.totalRatingVotes = 0,
  });

  bool get hasContent =>
      (muRating ?? 0) > 0 || (appRating != null && appRatingCount > 0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final rows = <Widget>[
      if ((muRating ?? 0) > 0)
        _SourceRow(
          icon: Icons.public_outlined,
          label: l10n.ratingSourceMangaUpdates,
          rating: muRating!,
          votes: muRatingVotes,
        ),
      if (appRating != null && appRatingCount > 0)
        _SourceRow(
          icon: Icons.groups_outlined,
          label: l10n.ratingSourceApp,
          rating: appRating!,
          votes: appRatingCount,
        ),
    ];
    final global = globalRating;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...rows,
        if (global != null && global > 0 && rows.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          _SourceRow(
            icon: Icons.star_outline_rounded,
            label: l10n.ratingGlobalLabel,
            rating: global,
            votes: totalRatingVotes,
            emphasize: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.ratingGlobalExplanation,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.dsText3(brightness),
            ),
          ),
        ],
      ],
    );
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double rating;
  final int? votes;
  final bool emphasize;

  const _SourceRow({
    required this.icon,
    required this.label,
    required this.rating,
    this.votes,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final votes = this.votes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.dsText2(brightness)),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (votes != null && votes > 0)
                    TextSpan(
                      text: ' · ${l10n.votesCount(votes)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dsText2(brightness),
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _format(rating),
            style: TextStyle(
              fontSize: emphasize ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          Text(
            '/10',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.dsText3(brightness),
            ),
          ),
        ],
      ),
    );
  }

  static String _format(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
