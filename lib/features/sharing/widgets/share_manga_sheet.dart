import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/app_card.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Modal "Partager ce manga" (Phase 8.1 — refactor design system 2026-05-18).
///
/// Refactor 2026-05-18 :
///  - Plus de bordures dures, surfaces tonales empilées
///  - Pastilles type pilule pour la sélection (au lieu de checkboxes carrées)
///  - Pas de couleurs hardcodées (Colors.orange, etc.) — uniquement tokens du theme
///
/// Utilisation :
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => ShareMangaSheet(muId: 42),
/// );
/// ```
class ShareMangaSheet extends StatefulWidget {
  final int muId;
  const ShareMangaSheet({super.key, required this.muId});

  @override
  State<ShareMangaSheet> createState() => _ShareMangaSheetState();
}

class _ShareMangaSheetState extends State<ShareMangaSheet> {
  final FriendsService _friendsService = getIt<FriendsService>();
  final SharingService _sharingService = getIt<SharingService>();
  final TextEditingController _msgCtrl = TextEditingController();

  List<FriendshipDto>? _friends;
  String? _loadError;
  final Set<int> _selected = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final list = await _friendsService.getAcceptedFriends();
      if (!mounted) return;
      setState(() => _friends = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    }
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _sharingService.shareMangaWithFriends(
        widget.muId,
        friendIds: _selected.toList(),
        message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.shareSuccess),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppLocalizations.of(context)!.shareFailed}: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
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
            _SheetTitle(selectedCount: _selected.length),
            const SizedBox(height: AppSpacing.s),
            Expanded(child: _buildFriendsList(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: _MessageField(controller: _msgCtrl),
            ),
            _ActionRow(
              sending: _sending,
              canSubmit: _selected.isNotEmpty,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Text('${l10n.shareLoadError}: $_loadError'),
        ),
      );
    }
    if (_friends == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_friends!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Text(
            l10n.shareNoFriends,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
        return _FriendPickRow(
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

class _SheetTitle extends StatelessWidget {
  final int selectedCount;
  const _SheetTitle({required this.selectedCount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.shareTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (selectedCount > 0)
            Text(
              '($selectedCount)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  final TextEditingController controller;
  const _MessageField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      maxLength: 280,
      decoration: InputDecoration(
        hintText: l10n.shareMessageHint,
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

class _FriendPickRow extends StatelessWidget {
  final FriendshipDto friend;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FriendPickRow({
    required this.friend,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s + 4,
        vertical: AppSpacing.s + 2,
      ),
      backgroundColor: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerLow,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '@${friend.safeOtherUsername}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? scheme.onPrimaryContainer
                                .withValues(alpha: 0.85)
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

class _ActionRow extends StatelessWidget {
  final bool sending;
  final bool canSubmit;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  const _ActionRow({
    required this.sending,
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        0,
        AppSpacing.m,
        AppSpacing.m,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: sending ? null : onCancel,
            child: Text(l10n.shareCancel),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: (!canSubmit || sending) ? null : onSubmit,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(l10n.shareSend),
          ),
        ],
      ),
    );
  }
}
