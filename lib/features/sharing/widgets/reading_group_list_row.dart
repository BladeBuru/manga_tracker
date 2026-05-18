import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ReadingGroupListRow — ligne d'un groupe dans la liste « Lectures à   ║
// ║  deux ». Design V1 « Refined Classic » : dual avatar (moi + ami)     ║
// ║  superposés, titre manga, "Avec {ami}", progression mono. Chevron à  ║
// ║  droite. Conçue pour vivre dans un ProfileEditSection (hairline).    ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ReadingGroupListRow extends StatelessWidget {
  final ReadingGroupDto group;
  final int? currentUserId;
  final VoidCallback onTap;

  const ReadingGroupListRow({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final me = _pickMe();
    final other = _pickOther(me);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _DualAvatar(primary: me, secondary: other),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    group.mangaTitle.isNotEmpty
                        ? group.mangaTitle
                        : group.effectiveName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.075,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (other != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      l10n.readingGroupWithLabel(other.effectiveDisplayName),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.dsText2(brightness),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _progressLine(context, me, other, l10n),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 12.5,
                      color: AppColors.dsText3(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.dsText3(brightness),
            ),
          ],
        ),
      ),
    );
  }

  ReadingGroupMemberDto? _pickMe() {
    if (currentUserId == null) return null;
    for (final m in group.members) {
      if (m.userId == currentUserId) return m;
    }
    return null;
  }

  ReadingGroupMemberDto? _pickOther(ReadingGroupMemberDto? me) {
    for (final m in group.members) {
      if (m.userId != me?.userId) return m;
    }
    // Tous les membres sont "moi" (improbable) → null.
    return null;
  }

  String _progressLine(
    BuildContext context,
    ReadingGroupMemberDto? me,
    ReadingGroupMemberDto? other,
    AppLocalizations l10n,
  ) {
    String formatChapter(int? c) =>
        c != null ? c.toString() : l10n.readingGroupChapterDash;
    final youLabel = l10n.readingGroupYouLabel;
    if (other == null) {
      return '$youLabel : ch. ${formatChapter(me?.readChapters)}';
    }
    return l10n.readingGroupProgressYouVsFriend(
      formatChapter(me?.readChapters),
      other.effectiveDisplayName,
      formatChapter(other.readChapters),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DualAvatar — deux avatars superposés. Le primary (moi) est devant, en
// pleine taille. Le secondary (ami) est derrière à droite, légèrement plus
// petit. Si pas de secondary, on affiche juste le primary centré.
// ─────────────────────────────────────────────────────────────────────────────

class _DualAvatar extends StatelessWidget {
  final ReadingGroupMemberDto? primary;
  final ReadingGroupMemberDto? secondary;

  const _DualAvatar({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ring = AppColors.dsBgInset(brightness) == Colors.transparent
        ? Theme.of(context).colorScheme.surface
        : AppColors.dsBgInset(brightness);

    if (secondary == null) {
      return SizedBox(
        width: 44,
        height: 40,
        child: Center(
          child: AppAvatar(
            url: primary?.avatarUrl,
            fallback: primary?.effectiveDisplayName ?? '?',
            size: AppAvatarSize.medium,
          ),
        ),
      );
    }
    return SizedBox(
      width: 56,
      height: 40,
      child: Stack(
        children: [
          // Ami → derrière, à droite, ring autour pour découpe nette.
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: ring,
                shape: BoxShape.circle,
              ),
              child: AppAvatar(
                url: secondary!.avatarUrl,
                fallback: secondary!.effectiveDisplayName,
                size: AppAvatarSize.medium,
              ),
            ),
          ),
          // Moi → devant, à gauche.
          Positioned(
            left: 0,
            top: 0,
            child: AppAvatar(
              url: primary?.avatarUrl,
              fallback: primary?.effectiveDisplayName ?? '?',
              size: AppAvatarSize.medium,
            ),
          ),
        ],
      ),
    );
  }
}
