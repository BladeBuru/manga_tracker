import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
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
///  - `showAcceptReject: true` → trailing = croix « Refuser » (icône) +
///    coche « Accepter » (icône pleine rouge), libellés en infobulle
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
                    '@${friendship.safeOtherUsername}',
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

/// Refuser / Accepter en boutons icône (croix / coche) : les libellés texte
/// prenaient ~190 px sur 200 et écrasaient le nom sur petit écran. Le
/// libellé est l'infobulle, que `IconButton` expose aussi comme nom
/// accessible (TalkBack / VoiceOver) — un `Semantics(label:)` en plus
/// créerait un second nœud lu deux fois.
class _PendingActions extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  const _PendingActions({this.onAccept, this.onReject});

  /// Zone d'appui de 40 × 40 dp.
  static const _buttonConstraints = BoxConstraints.tightFor(
    width: AppSpacing.xl + AppSpacing.s,
    height: AppSpacing.xl + AppSpacing.s,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onReject,
          tooltip: l10n.friendsReject,
          color: scheme.onSurfaceVariant,
          constraints: _buttonConstraints,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.close, size: 20),
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButton.filled(
          onPressed: onAccept,
          tooltip: l10n.friendsAccept,
          style: IconButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
          ),
          constraints: _buttonConstraints,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.check, size: 20),
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
