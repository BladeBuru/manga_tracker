import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/network/api_error_message.dart';
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/core/theme/app_surfaces.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/widgets/friend_relation_button.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Carte des résultats de recherche : chargement, échec (avec la vraie
/// raison), aucun résultat, ou une ligne par personne avec l'action qui
/// correspond à sa relation (Ajouter / Demande envoyée / Accepter / Ami).
class UserSearchResultsCard extends StatelessWidget {
  final List<UserSearchResultDto> results;
  final bool loading;
  final Object? error;
  final FriendRelation Function(UserSearchResultDto user) relationOf;
  final void Function(UserSearchResultDto user, FriendRelation relation)
      onAction;

  const UserSearchResultsCard({
    super.key,
    required this.results,
    required this.loading,
    required this.error,
    required this.relationOf,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.muted(scheme),
        borderRadius: AppRadius.circularXxxl,
        border: Border.all(color: AppSurfaces.hairline(scheme)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (results.isEmpty)
            _Message(text: _emptyText(context))
          else
            for (int i = 0; i < results.length; i++) ...[
              UserSearchResultRow(
                user: results[i],
                relation: relationOf(results[i]),
                onAction: onAction,
              ),
              if (i < results.length - 1)
                Divider(
                  height: 1,
                  indent: AppSpacing.jumbo + AppSpacing.s + 2,
                  color: AppSurfaces.hairline(scheme),
                ),
            ],
        ],
      ),
    );
  }

  String _emptyText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = error;
    if (failure == null) return loading ? '' : l10n.friendsSearchEmpty;
    // 429 / réseau : le vrai motif ; le reste : « La recherche a échoué ».
    if (failure is ApiException && !failure.isTooManyRequests) {
      return l10n.friendsSearchError;
    }
    return userFacingErrorMessage(failure, l10n, fallback: l10n.friendsSearchError);
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: AppSpacing.l);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.l - 2,
        horizontal: AppSpacing.m,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Une personne trouvée. Écran étroit (ou texte agrandi) : l'action passe
/// sous le nom au lieu de l'écraser.
class UserSearchResultRow extends StatelessWidget {
  /// En dessous, l'action passe sous le nom.
  static const double stackBelowWidth = 360;

  final UserSearchResultDto user;
  final FriendRelation relation;
  final void Function(UserSearchResultDto user, FriendRelation relation)
      onAction;

  const UserSearchResultRow({
    super.key,
    required this.user,
    required this.relation,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final identity = Row(
      children: [
        AppAvatar(
          url: user.avatarUrl,
          fallback: user.effectiveDisplayName,
          size: AppAvatarSize.medium,
        ),
        const SizedBox(width: AppSpacing.s + AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.effectiveDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(color: scheme.onSurface),
              ),
              Text(
                '@${user.safeUsername}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final action = FriendRelationButton(
      relation: relation,
      onPressed: () => onAction(user, relation),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s + AppSpacing.xs,
        AppSpacing.s + 2,
        AppSpacing.s + 2,
        AppSpacing.s + 2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < stackBelowWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: AppSpacing.s),
                Align(alignment: AlignmentDirectional.centerEnd, child: action),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.s),
              action,
            ],
          );
        },
      ),
    );
  }
}
