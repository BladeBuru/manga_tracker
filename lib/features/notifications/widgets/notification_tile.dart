import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/theme/app_surfaces.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/helpers/notification_presenter.dart';
import 'package:mangatracker/features/notifications/widgets/notification_leading.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Ligne du centre de notifications : visuel + phrase + message éventuel +
/// date relative + point « non lue ».
///
/// Surface « muted » arrondie (16), voile de la couleur de marque tant que
/// la ligne n'est pas lue. Survol (bureau) et appui (mobile) passent par
/// `InkWell` : retour visuel des deux côtés, sans comportement différent.
class NotificationTile extends StatelessWidget {
  final AppNotificationDto notification;
  final VoidCallback? onTap;

  /// Heure de référence des dates relatives (injectable pour les tests).
  final DateTime? now;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final unread = notification.isUnread;
    final message = notification.type == AppNotificationType.mangaShare
        ? notification.shareMessage
        : null;
    return Material(
      color: unread ? AppSurfaces.unreadTint(scheme) : AppSurfaces.muted(scheme),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularXxxl,
        side: BorderSide(color: AppSurfaces.hairline(scheme)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s + AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationLeading(notification: notification),
              const SizedBox(width: AppSpacing.s + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NotificationPresenter.text(notification, l10n),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (message != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          l10n.receivedShareMessage(message),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            fontSize: text.labelMedium?.fontSize,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _relativeDate(l10n, Localizations.localeOf(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) const _UnreadDot(),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(AppLocalizations l10n, Locale locale) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(notification.createdAt);
    if (diff.inSeconds < 60) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return DateFormat.yMMMd(locale.toString())
        .format(notification.createdAt.toLocal());
  }
}

/// Point « non lue », annoncé aux lecteurs d'écran.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context)!.notificationsUnread,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.s,
          top: AppSpacing.xs + 2,
        ),
        child: Container(
          width: AppSpacing.s + 2,
          height: AppSpacing.s + 2,
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
