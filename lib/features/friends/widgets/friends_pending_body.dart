import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/widgets/friend_list_tile.dart';
import 'package:mangatracker/features/friends/widgets/friends_section_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Onglet « Demandes » : demandes reçues (accepter / refuser) puis demandes
/// envoyées (annuler). Les envoyées étaient invisibles : on ne savait pas
/// si une demande était partie.
class FriendsPendingBody extends StatelessWidget {
  final List<FriendshipDto> received;
  final List<FriendshipDto> sent;
  final ValueChanged<FriendshipDto> onAccept;
  final ValueChanged<FriendshipDto> onReject;
  final ValueChanged<FriendshipDto> onCancelSent;

  const FriendsPendingBody({
    super.key,
    required this.received,
    required this.sent,
    required this.onAccept,
    required this.onReject,
    required this.onCancelSent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (received.isEmpty && sent.isEmpty) {
      return AppEmptyState(
        icon: Icons.mark_email_read_outlined,
        title: l10n.friendsEmptyPending,
        subtitle: l10n.friendsEmptyPendingSubtitle,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (received.isNotEmpty)
          FriendsSectionCard(
            label: l10n.friendsSectionPending,
            children: [
              for (final f in received)
                FriendListTile(
                  friendship: f,
                  showAcceptReject: true,
                  onAccept: () => onAccept(f),
                  onReject: () => onReject(f),
                ),
            ],
          ),
        if (received.isNotEmpty && sent.isNotEmpty)
          const SizedBox(height: AppSpacing.l),
        if (sent.isNotEmpty)
          FriendsSectionCard(
            label: l10n.friendsSectionSent,
            children: [
              for (final f in sent)
                FriendListTile(
                  friendship: f,
                  onCancelRequest: () => onCancelSent(f),
                ),
            ],
          ),
      ],
    );
  }
}
