import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Row d'un ami (ou demande en attente) — design V1 « Refined Classic ».
///
/// Pensé pour vivre dans un `ProfileEditSection` : pas de carte propre, juste
/// padding + Row + actions trailing. Les dividers entre rows sont gérés par
/// `ProfileEditSection` (hairline 16px indent).
///
/// Variantes :
///  - default (accepté)        → trailing = bouton `more_horiz` qui ouvre menu
///  - `showAcceptReject: true` → trailing = "Accepter" (filled rouge) +
///    "Refuser" (text rouge)
class FriendListTile extends StatelessWidget {
  final FriendshipDto friendship;
  final bool showAcceptReject;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const FriendListTile({
    super.key,
    required this.friendship,
    this.showAcceptReject = false,
    this.onAccept,
    this.onReject,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              url: friendship.otherAvatarUrl,
              fallback: friendship.displayName,
              size: AppAvatarSize.medium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    friendship.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.075,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${friendship.otherUsername}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.dsText2(brightness),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showAcceptReject)
              _PendingActions(onAccept: onAccept, onReject: onReject)
            else if (onRemove != null)
              _AcceptedMenu(onRemove: onRemove!),
          ],
        ),
      ),
    );
  }
}

class _PendingActions extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  const _PendingActions({this.onAccept, this.onReject});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: onReject,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(l10n.friendsReject),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: onAccept,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(l10n.friendsAccept),
        ),
      ],
    );
  }
}

class _AcceptedMenu extends StatelessWidget {
  final VoidCallback onRemove;
  const _AcceptedMenu({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: '',
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: AppColors.dsText2(brightness),
      ),
      iconSize: 20,
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'remove') onRemove();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'remove',
          child: Text(l10n.friendsRemove),
        ),
      ],
    );
  }
}
