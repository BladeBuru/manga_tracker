import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/app_card.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';

/// Ami sélectionnable (pastille ronde cochée) des feuilles « Recommander à
/// un ami » et « Lire à deux » — auparavant dupliqué dans les deux.
class FriendPickRow extends StatelessWidget {
  final FriendshipDto friend;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const FriendPickRow({
    super.key,
    required this.friend,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s + 4,
        vertical: AppSpacing.s + 2,
      ),
      backgroundColor:
          selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      child: Row(
        children: [
          AppAvatar(
            url: friend.otherAvatarUrl,
            fallback: friend.displayName,
            size: AppAvatarSize.medium,
          ),
          const SizedBox(width: AppSpacing.s + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${friend.safeOtherUsername}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer.withValues(alpha: 0.85)
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? accentColor : Colors.transparent,
              border: Border.all(
                color: selected ? accentColor : scheme.outlineVariant,
                width: 2,
              ),
            ),
            child: selected
                ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                : null,
          ),
        ],
      ),
    );
  }
}
