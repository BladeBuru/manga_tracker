import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/refreshable_manga_image.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_surfaces.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';

/// Visuel d'une ligne : couverture du titre (recommandation, nouveaux
/// chapitres, lecture partagée) ou avatar de l'auteur (amis), avec l'icône
/// du type en pastille en bas à droite.
class NotificationLeading extends StatelessWidget {
  static const double size = 48;
  static const double _badgeSize = 22;

  final AppNotificationDto notification;

  const NotificationLeading({super.key, required this.notification});

  static IconData iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.friendRequest:
        return Icons.person_add_outlined;
      case AppNotificationType.friendAccepted:
        return Icons.how_to_reg_outlined;
      case AppNotificationType.mangaShare:
        return Icons.recommend_outlined;
      case AppNotificationType.readingGroupInvite:
        return Icons.groups_outlined;
      case AppNotificationType.newChapters:
        return Icons.new_releases_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _visual(scheme)),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: _badgeSize,
              height: _badgeSize,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(
                iconFor(notification.type),
                size: 12,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visual(ColorScheme scheme) {
    final manga = notification.manga;
    final actor = notification.actor;
    final showsCover = manga != null &&
        notification.type != AppNotificationType.friendRequest &&
        notification.type != AppNotificationType.friendAccepted;
    if (showsCover) {
      return ClipRRect(
        borderRadius: AppRadius.circularMd,
        child: RefreshableMangaImage(
          muId: '${manga.muId}',
          originalUrl: manga.coverUrl,
          useProxy: true,
          proxySize: 'small',
          width: size,
          height: size,
        ),
      );
    }
    if (actor != null) {
      return Center(
        child: AppAvatar(
          url: null,
          fallback: actor.name,
          size: AppAvatarSize.large,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSurfaces.muted(scheme),
        borderRadius: AppRadius.circularMd,
      ),
      child: Icon(
        iconFor(notification.type),
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
