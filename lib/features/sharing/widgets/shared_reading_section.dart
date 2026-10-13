import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/app_card.dart';
import 'package:mangatracker/core/components/app_chip.dart';
import 'package:mangatracker/core/router/navigation_helpers.dart';
import 'package:mangatracker/core/router/route_visibility_listener.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Section "Lecture partagée" affichée sur la fiche détail d'un manga
/// quand l'utilisateur fait partie d'un groupe de lecture lié à ce manga
/// (Phase 8.3 — ajout 2026-05-18).
///
/// Comportement :
///  - Au mount : fetch `findGroupForManga(muId)` (silencieux si erreur)
///  - Rechargée quand la fiche repasse au premier plan (retour depuis le
///    groupe) : avant, chargée une seule fois, elle montrait encore
///    l'ancienne progression. La carte affichée reste en place pendant la
///    relecture (pas de clignotement).
///  - Si pas de groupe → widget invisible (`SizedBox.shrink`)
///  - Si groupe → carte tonale avec :
///       * Titre "Lecture partagée"
///       * Pastille membres count
///       * Liste compacte des autres membres + progression
///       * Tap → ouvre la page détail du groupe — ou y revient si elle est
///         juste en dessous (`pushOrPop`) : les allers-retours n'empilent
///         plus de pages.
///
/// Léger : un appel réseau par affichage, pas de polling.
class SharedReadingSection extends StatefulWidget {
  final int muId;
  const SharedReadingSection({super.key, required this.muId});

  @override
  State<SharedReadingSection> createState() => _SharedReadingSectionState();
}

class _SharedReadingSectionState extends State<SharedReadingSection> {
  _SectionData? _data;

  /// Numéro du dernier chargement : seul le plus récent s'affiche.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final (:loaded, :data) = await _load();
    if (!mounted || generation != _generation) return;
    // Échec de relecture : la carte déjà affichée reste. « Aucun groupe »
    // (groupe quitté entre-temps), lui, la retire.
    if (!loaded) return;
    setState(() => _data = data);
  }

  /// [loaded] : le serveur a répondu (avec ou sans groupe pour ce titre).
  Future<({bool loaded, _SectionData? data})> _load() async {
    try {
      final group =
          await getIt<ReadingGroupsService>().findGroupForManga(widget.muId);
      if (group == null) return (loaded: true, data: null);
      int? currentUserId;
      try {
        final info = await getIt<UserService>().getUserInformation();
        currentUserId = info.id;
      } catch (_) {}
      return (
        loaded: true,
        data: _SectionData(group: group, currentUserId: currentUserId),
      );
    } catch (_) {
      return (loaded: false, data: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return RouteVisibilityListener(
      onVisible: _reload,
      child: data == null
          ? const SizedBox.shrink()
          : _SharedReadingCard(data: data),
    );
  }
}

class _SectionData {
  final ReadingGroupDto group;
  final int? currentUserId;
  const _SectionData({required this.group, required this.currentUserId});
}

class _SharedReadingCard extends StatelessWidget {
  final _SectionData data;
  const _SharedReadingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final group = data.group;
    final others = data.currentUserId == null
        ? group.members
        : group.members.where((m) => m.userId != data.currentUserId).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
      ),
      child: AppCard(
        onTap: () => pushOrPop<void>(context, '/reading-groups/${group.id}'),
        backgroundColor: scheme.surfaceContainerHigh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    l10n.readingGroupSharedReading,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                AppChip.primary(
                  label: l10n.readingGroupMembersCount(group.members.length),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s + 4),
            ...others.take(4).map((m) => _MemberLine(member: m)),
            if (others.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '+${others.length - 4}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            const SizedBox(height: AppSpacing.s),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.readingGroupViewGroup,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberLine extends StatelessWidget {
  final ReadingGroupMemberDto member;
  const _MemberLine({required this.member});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AppAvatar(
            url: member.avatarUrl,
            fallback: member.effectiveDisplayName,
            size: AppAvatarSize.small,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              member.effectiveDisplayName,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.readChapters != null)
            Text(
              '${l10n.readingGroupChapterShort} ${member.readChapters}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            )
          else
            Text(
              l10n.readingGroupNotStarted,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
        ],
      ),
    );
  }
}
