import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/network/api_error_message.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/sharing/widgets/friend_pick_row.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Modal "Lire à deux" — crée un reading_group sur le manga courant et
/// invite des amis (Phase 8.3 UI — refactor design system 2026-05-18).
///
/// Refactor 2026-05-18 :
///  - Plus de bordures dures, surfaces tonales empilées (`surfaceContainerLow`)
///  - Pastilles type pilule pour la sélection (au lieu de checkboxes carrées)
///  - Bouton "Créer" désactivé tant qu'aucun ami n'est sélectionné
///  - Helper text "Sélectionne au moins un ami…" en cas de liste vide
class CreateReadingGroupSheet extends StatefulWidget {
  final int muId;
  final String mangaTitle;

  const CreateReadingGroupSheet({
    super.key,
    required this.muId,
    required this.mangaTitle,
  });

  @override
  State<CreateReadingGroupSheet> createState() =>
      _CreateReadingGroupSheetState();
}

class _CreateReadingGroupSheetState extends State<CreateReadingGroupSheet> {
  final FriendsService _friendsService = getIt<FriendsService>();
  final ReadingGroupsService _groupsService = getIt<ReadingGroupsService>();
  final TextEditingController _nameCtrl = TextEditingController();

  List<FriendshipDto>? _friends;
  Object? _loadError;
  final Set<int> _selected = {};
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      // Toujours relue : inviter un ami retiré depuis donnait un 403 brut.
      final list = await _friendsService.getAcceptedFriends(forceRefresh: true);
      if (!mounted) return;
      setState(() => _friends = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _creating = true);
    try {
      final created = await _groupsService.createGroup(
        muId: widget.muId,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        inviteFriendIds: _selected.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.push('/reading-groups/${created.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingErrorMessage(
            e,
            l10n,
            fallback: l10n.readingGroupCreateFailed,
          )),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            _SheetHeader(mangaTitle: widget.mangaTitle),
            const SizedBox(height: AppSpacing.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: _NameField(controller: _nameCtrl),
            ),
            const SizedBox(height: AppSpacing.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.readingGroupCreateInviteSection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(child: _buildFriendsList(context)),
            _HelperRow(visible: _selected.isEmpty),
            _ActionRow(
              creating: _creating,
              canSubmit: _selected.isNotEmpty,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
              selectedCount: _selected.length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Text(
          userFacingErrorMessage(_loadError, l10n, fallback: l10n.shareLoadError),
        ),
      );
    }
    if (_friends == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_friends!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Text(
          l10n.shareNoFriends,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      itemCount: _friends!.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs + 2),
      itemBuilder: (context, i) {
        final f = _friends![i];
        final isSelected = _selected.contains(f.otherUserId);
        return FriendPickRow(
          friend: f,
          selected: isSelected,
          accentColor: scheme.primary,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(f.otherUserId);
              } else {
                _selected.add(f.otherUserId);
              }
            });
          },
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s + 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
        borderRadius: AppRadius.circularXs,
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String mangaTitle;
  const _SheetHeader({required this.mangaTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.readingGroupCreateTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            mangaTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      maxLength: 80,
      decoration: InputDecoration(
        labelText: l10n.readingGroupCreateNameLabel,
        hintText: l10n.readingGroupCreateNameHint,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: AppRadius.circularLg,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularLg,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularLg,
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _HelperRow extends StatelessWidget {
  final bool visible;
  const _HelperRow({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              l10n.readingGroupCreateInviteRequired,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final bool creating;
  final bool canSubmit;
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  const _ActionRow({
    required this.creating,
    required this.canSubmit,
    required this.selectedCount,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s + 4,
        AppSpacing.m,
        AppSpacing.m,
      ),
      // `OverflowBar` : Annuler à gauche, Créer à droite ; si les deux ne
      // tiennent pas sur une ligne (petit écran, texte agrandi, allemand),
      // ils s'empilent, Créer au-dessus, au lieu de déborder.
      child: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        spacing: AppSpacing.s,
        overflowAlignment: OverflowBarAlignment.end,
        overflowDirection: VerticalDirection.up,
        overflowSpacing: AppSpacing.xs,
        children: [
          TextButton(
            onPressed: creating ? null : onCancel,
            child: Text(l10n.shareCancel),
          ),
          FilledButton.icon(
            onPressed: (creating || !canSubmit) ? null : onSubmit,
            icon: creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.group_add_outlined, size: 18),
            label: Text(
              selectedCount > 0
                  ? '${l10n.readingGroupCreateConfirm} ($selectedCount)'
                  : l10n.readingGroupCreateConfirm,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
