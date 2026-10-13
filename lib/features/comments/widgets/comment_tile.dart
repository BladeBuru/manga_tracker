import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/app_card.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/comments/dto/comment.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Tile d'un commentaire (Phase 7.1, refactor design system).
///
/// Utilise `AppCard` + `AppAvatar` + `AppChip` pour les ratings et badges.
///
/// Menu « ⋮ » : « Supprimer » (mes commentaires, [onDelete]) ou
/// « Signaler » (ceux des autres, [onReport]). Avant, « Supprimer » était
/// proposé partout et répondait 403 sur le commentaire d'un autre.
class CommentTile extends StatelessWidget {
  final CommentDto comment;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onReport,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.s + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  url: comment.authorAvatarUrl,
                  fallback: comment.displayName,
                  size: AppAvatarSize.medium,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.displayName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _formatRelativeDate(context, comment.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (comment.rating != null) ...[
                  AppChip.primary(
                    label: '${comment.rating}/10',
                    icon: Icons.star,
                  ),
                  const SizedBox(width: AppSpacing.s),
                ],
                if (!comment.isDeleted && (onDelete != null || onReport != null))
                  _CommentMenu(onDelete: onDelete, onReport: onReport),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              comment.content,
              style: textTheme.bodyMedium?.copyWith(
                fontStyle: comment.isDeleted ? FontStyle.italic : null,
                color: comment.isDeleted ? scheme.onSurfaceVariant : null,
              ),
            ),
            if (comment.replyCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!
                    .commentsReplyCount(comment.replyCount),
                style: textTheme.bodySmall?.copyWith(color: scheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = AppLocalizations.of(context)!;
    if (diff.inSeconds < 60) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return DateFormat.yMd(Localizations.localeOf(context).toString())
        .format(date);
  }
}

/// Actions d'un commentaire, selon qu'il est à moi ou non.
class _CommentMenu extends StatelessWidget {
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const _CommentMenu({this.onDelete, this.onReport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.commentsMoreActions,
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (v) {
        if (v == 'delete') onDelete?.call();
        if (v == 'report') onReport?.call();
      },
      itemBuilder: (_) => [
        if (onDelete != null)
          PopupMenuItem(value: 'delete', child: Text(l10n.commentsDelete)),
        if (onReport != null)
          PopupMenuItem(value: 'report', child: Text(l10n.commentsReport)),
      ],
    );
  }
}
