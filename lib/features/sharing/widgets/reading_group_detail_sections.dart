import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/profile/widgets/profile_edit_sections.dart';
import 'package:mangatracker/features/sharing/bloc/reading_groups_bloc.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_action_row.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_links.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_progress_row.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/router/app_modals.dart';

// ╔═══════════════════════════════════════════════════════════════════════╗
// ║  Sections du détail « Lectures à deux » — extraites pour rester sous   ║
// ║  la limite 400 lignes du fichier view (CLAUDE.md).                    ║
// ║                                                                       ║
// ║  Contenu :                                                            ║
// ║   - ReadingGroupCurrentUserScope : FutureBuilder qui résout l'id du   ║
// ║     user courant via UserService (cache 7j).                          ║
// ║   - ReadingGroupProgressSection : section V1 + 2 rows (toi vs ami).   ║
// ║   - ReadingGroupActionsSection  : section V1 + 3 rows (mark / invite  ║
// ║     / leave-or-delete).                                               ║
// ╚═══════════════════════════════════════════════════════════════════════╝

/// FutureBuilder centralisé qui charge l'id du user courant.
class ReadingGroupCurrentUserScope extends StatefulWidget {
  final Widget Function(BuildContext context, int? userId) builder;
  const ReadingGroupCurrentUserScope({super.key, required this.builder});

  @override
  State<ReadingGroupCurrentUserScope> createState() =>
      _ReadingGroupCurrentUserScopeState();
}

class _ReadingGroupCurrentUserScopeState
    extends State<ReadingGroupCurrentUserScope> {
  late final Future<int?> _future = _load();

  Future<int?> _load() async {
    try {
      final info = await getIt<UserService>().getUserInformation();
      return info.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _future,
      builder: (context, snap) => widget.builder(context, snap.data),
    );
  }
}

// ─── Section "Progression" ───────────────────────────────────────────────────

class ReadingGroupProgressSection extends StatelessWidget {
  final ReadingGroupDto group;
  final int? currentUserId;

  const ReadingGroupProgressSection({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context)!;

    final me = _pickMe();
    final other = _pickOther(me);
    final maxRead = _maxRead([me, other]);

    return ProfileEditSection(
      label: l10n.readingGroupSectionProgress,
      children: [
        ReadingGroupProgressRow(
          label: l10n.readingGroupYouLabel,
          read: me?.readChapters,
          max: maxRead,
          barColor: scheme.primary,
          emphasized: true,
        ),
        if (other != null)
          ReadingGroupProgressRow(
            label: other.effectiveDisplayName,
            read: other.readChapters,
            max: maxRead,
            barColor: AppColors.dsText2(brightness),
          ),
      ],
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

// ─── Section "Actions" ───────────────────────────────────────────────────────

class ReadingGroupActionsSection extends StatelessWidget {
  final ReadingGroupDto group;
  final int? currentUserId;

  const ReadingGroupActionsSection({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  bool get _isOwner =>
      currentUserId != null && currentUserId == group.ownerId;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final result = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _markProgress(BuildContext context) async {
    final muId = int.tryParse(group.mangaMuId);
    if (muId == null || muId <= 0) return;
    await context.push(
      '/manga/$muId',
      extra: MangaDetailExtras(title: group.mangaTitle),
    );
  }

  void _inviteFriend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // L'endpoint POST /reading-groups/:id/invite existe côté service, mais
    // l'UX de sélection d'ami depuis le détail n'est pas encore wirée. Pour
    // l'instant on affiche une SnackBar "bientôt" afin de signaler la
    // direction sans perdre l'utilisateur. Quand l'écran sera prêt, remplacer
    // par un context.push vers la liste d'amis filtrée.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.readingGroupInviteSoonMessage)),
    );
  }

  Future<void> _leaveOrDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final detailBloc = context.read<ReadingGroupDetailBloc>();
    if (_isOwner) {
      final ok = await _confirm(
        context,
        title: l10n.readingGroupDeleteConfirmTitle,
        body: l10n.readingGroupDeleteConfirm,
        confirmLabel: l10n.readingGroupDelete,
      );
      if (!ok) return;
      detailBloc.add(const DeleteGroupRequested());
    } else {
      final ok = await _confirm(
        context,
        title: l10n.readingGroupLeaveConfirmTitle,
        body: l10n.readingGroupLeaveConfirm,
        confirmLabel: l10n.readingGroupActionsLeave,
      );
      if (!ok) return;
      // ignore: use_build_context_synchronously
      await _doLeave(context);
    }
  }

  /// Quitte le groupe via ReadingGroupsService directement.
  ///
  /// Le `ReadingGroupDetailBloc` n'expose pas d'event `LeaveGroupRequested`
  /// (seul le `ReadingGroupsBloc` liste le fait, et notre détail page n'a
  /// pas accès à ce BLoC). On appelle donc le service, puis on pop avec
  /// `true` pour que la list page recharge — comportement identique à
  /// celui de la suppression par l'owner.
  Future<void> _doLeave(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final scheme = Theme.of(context).colorScheme;
    final service = getIt<ReadingGroupsService>();
    try {
      await service.leave(group.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.readingGroupLeaveSuccess)),
      );
      if (router.canPop()) {
        router.pop(true);
      } else {
        router.go('/reading-groups');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.readingGroupLeaveFailed}: $e'),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muId = int.tryParse(group.mangaMuId);
    final canOpenManga = muId != null && muId > 0;
    final links =
        ReadingGroupLinks(group: group, currentUserId: currentUserId);
    final friend = links.friendWithLink();
    final targetChapter = links.targetChapter();

    return ProfileEditSection(
      label: l10n.readingGroupSectionActions,
      children: [
        ReadingGroupActionRow(
          icon: Icons.bookmark_outline,
          color: PastelTileColor.green,
          title: l10n.readingGroupActionsMarkProgress,
          subtitle: l10n.readingGroupActionsMarkProgressSubtitle,
          onTap: canOpenManga ? () => _markProgress(context) : null,
        ),
        // **2026-05-19** : nouvelle action « Copier le lien de l'ami ».
        // Visible uniquement si l'ami a configuré un customLink sur ce
        // manga. Substitue le numéro de chapitre via `ChapterLinkResolver`
        // pour pointer sur le prochain chapitre à lire côté user.
        // Copie réelle dans le presse-papiers (son lien, sinon celui de
        // l'ami adapté à son prochain chapitre).
        if (links.hasAnyLink)
          ReadingGroupActionRow(
            icon: Icons.content_copy_outlined,
            color: PastelTileColor.teal,
            title: l10n.readingGroupActionsCopyLink,
            subtitle: l10n.readingGroupActionsCopyLinkSubtitle,
            onTap: () => copyReadingGroupLink(context, links),
          ),
        if (friend != null)
          ReadingGroupActionRow(
            icon: Icons.link_outlined,
            color: PastelTileColor.purple,
            title: l10n.readingGroupActionsCopyFriendLink(
              friend.effectiveDisplayName,
            ),
            subtitle: l10n.readingGroupActionsCopyFriendLinkSubtitle(
              targetChapter,
            ),
            onTap: () => applyReadingGroupFriendLink(context, links),
          ),
        ReadingGroupActionRow(
          icon: Icons.person_add_alt_1_outlined,
          color: PastelTileColor.blue,
          title: l10n.readingGroupActionsInvite,
          subtitle: l10n.readingGroupActionsInviteSubtitle,
          onTap: () => _inviteFriend(context),
        ),
        ReadingGroupActionRow(
          icon: _isOwner ? Icons.delete_outline : Icons.logout_outlined,
          color: PastelTileColor.red,
          title: _isOwner
              ? l10n.readingGroupDelete
              : l10n.readingGroupActionsLeave,
          subtitle: _isOwner
              ? l10n.readingGroupActionsDeleteSubtitle
              : l10n.readingGroupActionsLeaveSubtitle,
          danger: true,
          onTap: () => _leaveOrDelete(context),
        ),
      ],
    );
  }
}
