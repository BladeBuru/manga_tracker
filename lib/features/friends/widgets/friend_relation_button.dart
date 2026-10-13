import 'package:flutter/material.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Action d'un résultat de recherche selon la relation :
///
/// | Relation           | Bouton                 | Effet (après confirmation) |
/// |--------------------|------------------------|----------------------------|
/// | aucune             | « Ajouter »            | envoie une demande         |
/// | demande envoyée    | « Demande envoyée »    | propose de l'annuler       |
/// | demande reçue      | « Accepter »           | accepte                    |
/// | amis               | « Ami »                | ouvre son profil           |
class FriendRelationButton extends StatelessWidget {
  final FriendRelation relation;
  final VoidCallback onPressed;

  const FriendRelationButton({
    super.key,
    required this.relation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    switch (relation) {
      case FriendRelation.none:
        return FilledButton.tonalIcon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(l10n.friendsRelationAdd, maxLines: 1),
        );
      case FriendRelation.pendingSent:
        return Tooltip(
          message: l10n.friendsCancelRequest,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.schedule_send_outlined, size: 18),
            label: Text(l10n.friendsRequestSent, maxLines: 1),
          ),
        );
      case FriendRelation.pendingReceived:
        return FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.check, size: 18),
          label: Text(l10n.friendsAccept, maxLines: 1),
        );
      case FriendRelation.friends:
        return TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.how_to_reg_outlined, size: 18),
          label: Text(l10n.friendsRelationFriends, maxLines: 1),
        );
    }
  }
}
