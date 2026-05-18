import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  ReadingGroupHeroCard — hero "you vs friend" du détail. Carte blanche  ║
// ║  V1 (hairline + radius 16) : 2 colonnes (moi + ami), grosse pastille  ║
// ║  centrale avec le titre + manga. Sous chaque avatar : nb chapitres lus ║
// ║  en mono + barre de progression visuelle relative.                    ║
// ╚═══════════════════════════════════════════════════════════════════════╝

class ReadingGroupHeroCard extends StatelessWidget {
  final ReadingGroupDto group;
  final int? currentUserId;

  const ReadingGroupHeroCard({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final me = _pickMe();
    final other = _pickOther(me);
    final maxRead = _maxRead([me, other]);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dsSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dsHairline(brightness),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A140A0A),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manga title centered + sub-label "Lecture en cours" mono uppercase.
          Center(
            child: Text(
              l10n.readingGroupSectionHero.toUpperCase(),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: AppColors.dsText3(brightness),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              group.mangaTitle.isNotEmpty
                  ? group.mangaTitle
                  : group.effectiveName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: scheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 22),
          // Side-by-side : me / other
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroMemberColumn(
                  member: me,
                  isYou: true,
                  maxRead: maxRead,
                  fallbackLabel: l10n.readingGroupYouLabel,
                ),
              ),
              SizedBox(
                width: 32,
                child: Center(
                  child: Container(
                    width: 1,
                    height: 90,
                    color: AppColors.dsHairline(brightness),
                  ),
                ),
              ),
              Expanded(
                child: _HeroMemberColumn(
                  member: other,
                  isYou: false,
                  maxRead: maxRead,
                  fallbackLabel: l10n.readingGroupChapterDash,
                ),
              ),
            ],
          ),
        ],
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
    return null;
  }

  int _maxRead(List<ReadingGroupMemberDto?> members) {
    int max = 0;
    for (final m in members) {
      final v = m?.readChapters ?? 0;
      if (v > max) max = v;
    }
    return max == 0 ? 1 : max;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HeroMemberColumn — avatar XL + nom + nb chapitres lus (mono) + barre de
// progression relative au max du groupe (visuel "tu es devant / derrière").
// ─────────────────────────────────────────────────────────────────────────────

class _HeroMemberColumn extends StatelessWidget {
  final ReadingGroupMemberDto? member;
  final bool isYou;
  final int maxRead;
  final String fallbackLabel;

  const _HeroMemberColumn({
    required this.member,
    required this.isYou,
    required this.maxRead,
    required this.fallbackLabel,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final read = member?.readChapters ?? 0;
    final hasRead = member?.readChapters != null;
    final ratio = (read / maxRead).clamp(0.0, 1.0);
    final displayName = member?.effectiveDisplayName ?? fallbackLabel;
    final youLabel = l10n.readingGroupYouLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppAvatar(
          url: member?.avatarUrl,
          fallback: displayName,
          size: AppAvatarSize.large,
        ),
        const SizedBox(height: 8),
        Text(
          isYou ? youLabel : displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasRead ? 'ch. $read' : l10n.readingGroupNotStarted,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: 12.5,
            color: AppColors.dsText2(brightness),
          ),
        ),
        const SizedBox(height: 10),
        // Mini progress bar relative au max du groupe (visuel "avance").
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: AppColors.dsBgInset(brightness),
            valueColor: AlwaysStoppedAnimation<Color>(
              isYou ? scheme.primary : AppColors.dsText2(brightness),
            ),
          ),
        ),
      ],
    );
  }
}
