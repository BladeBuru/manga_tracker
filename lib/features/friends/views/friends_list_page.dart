import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/network/api_error_message.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart' show AppContentWidth;
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/utils/responsive_layout.dart';
import 'package:mangatracker/features/friends/bloc/friends_bloc.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/widgets/friend_list_tile.dart';
import 'package:mangatracker/features/friends/widgets/friends_dialogs.dart';
import 'package:mangatracker/features/friends/widgets/friends_pending_body.dart';
import 'package:mangatracker/features/friends/widgets/friends_section_card.dart';
import 'package:mangatracker/features/friends/widgets/friends_tab_segmented.dart';
import 'package:mangatracker/features/friends/widgets/user_search_field.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page « Mes amis » — design V1 « Refined Classic ».
///
/// Recherche (avec l'état de relation de chaque résultat), onglets Amis /
/// Demandes (reçues + envoyées). À l'ouverture, la liste d'amis est relue
/// sur le serveur (le cache ne sert que hors ligne).
class FriendsListPage extends StatelessWidget {
  /// Onglet d'arrivée : « Demandes » quand on vient d'une pastille.
  final FriendsTab initialTab;

  /// Injectable pour les tests.
  final FriendsBloc Function()? createBloc;

  const FriendsListPage({
    super.key,
    this.initialTab = FriendsTab.accepted,
    this.createBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendsBloc>(
      create: (_) => (createBloc?.call() ?? FriendsBloc())
        ..add(const LoadFriends(forceRefresh: true)),
      child: _FriendsScaffold(initialTab: initialTab),
    );
  }
}

class _FriendsScaffold extends StatelessWidget {
  final FriendsTab initialTab;

  const _FriendsScaffold({required this.initialTab});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          l10n.friendsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        shape: Border(
          bottom: BorderSide(color: AppColors.dsHairline(brightness)),
        ),
      ),
      body: BlocConsumer<FriendsBloc, FriendsState>(
        listenWhen: (a, b) =>
            b is FriendsLoaded && (b.feedback != null || b.actionError != null),
        listener: (context, state) => _showMessage(context, state, l10n),
        builder: (context, state) {
          if (state is FriendsError) {
            return AppErrorState(
              message: userFacingErrorMessage(state.error, l10n),
              retryLabel: l10n.retry,
              onRetry: () =>
                  context.read<FriendsBloc>().add(const LoadFriends()),
            );
          }
          if (state is FriendsLoaded) {
            return _FriendsContent(state: state, initialTab: initialTab);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showMessage(
    BuildContext context,
    FriendsState state,
    AppLocalizations l10n,
  ) {
    if (state is! FriendsLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    final error = state.actionError;
    if (error != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(userFacingErrorMessage(error, l10n)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return;
    }
    final text = switch (state.feedback) {
      FriendsFeedback.requestSent => l10n.friendsRequestSent,
      FriendsFeedback.requestCancelled => l10n.friendsRequestCancelled,
      FriendsFeedback.nowFriends =>
        l10n.friendsNowFriends(state.feedbackName ?? ''),
      null => null,
    };
    if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
  }
}

class _FriendsContent extends StatefulWidget {
  final FriendsLoaded state;
  final FriendsTab initialTab;
  const _FriendsContent({required this.state, required this.initialTab});

  @override
  State<_FriendsContent> createState() => _FriendsContentState();
}

class _FriendsContentState extends State<_FriendsContent>
    with ResponsiveLayoutMixin {
  late FriendsTab _tab = widget.initialTab;

  FriendsBloc get _bloc => context.read<FriendsBloc>();

  /// Action d'un résultat de recherche, toujours après confirmation pour ce
  /// qui part au serveur.
  Future<void> _onSearchAction(
    UserSearchResultDto user,
    FriendRelation relation,
  ) async {
    final s = widget.state;
    final bloc = _bloc;
    final name = user.effectiveDisplayName;
    switch (relation) {
      case FriendRelation.none:
        if (await confirmSendFriendRequest(context, name)) {
          bloc.add(SendFriendRequest(user.id, displayName: name));
        }
      case FriendRelation.pendingSent:
        final sent = s.sentTo(user.id);
        if (sent != null && await confirmCancelFriendRequest(context, name)) {
          bloc.add(CancelFriendRequest(sent.id));
        }
      case FriendRelation.pendingReceived:
        final received = s.receivedFrom(user.id);
        if (received != null) {
          bloc.add(RespondToRequest(
            friendshipId: received.id,
            newStatus: FriendshipStatus.accepted,
          ));
        }
      case FriendRelation.friends:
        _openProfile(user.id, name, user.avatarUrl);
    }
  }

  void _openProfile(int userId, String name, String? avatarUrl) {
    context.push(
      '/friends/$userId',
      extra: FriendProfileExtras(displayName: name, avatarUrl: avatarUrl),
    );
  }

  Future<void> _cancelSent(FriendshipDto f) async {
    final bloc = _bloc;
    if (await confirmCancelFriendRequest(context, f.displayName)) {
      bloc.add(CancelFriendRequest(f.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final hPad = horizontalPadding(context);
    return RefreshIndicator(
      onRefresh: () async => _bloc.add(const LoadFriends(forceRefresh: true)),
      child: AppContentWidth(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
          children: [
            if (s.isOffline) const OfflineBanner(),
            UserSearchField(
              results: s.searchResults,
              loading: s.searchLoading,
              error: s.searchError,
              relationOf: s.relationOf,
              onQueryChanged: (q) => _bloc.add(SearchUsers(q)),
              onAction: _onSearchAction,
            ),
            const SizedBox(height: 18),
            FriendsTabSegmented(
              selected: _tab,
              acceptedCount: s.accepted.length,
              pendingCount: s.pending.length,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 16),
            if (_tab == FriendsTab.accepted)
              _AcceptedBody(items: s.accepted, onOpen: _openProfile)
            else
              FriendsPendingBody(
                received: s.pending,
                sent: s.sent,
                onAccept: (f) => _bloc.add(RespondToRequest(
                  friendshipId: f.id,
                  newStatus: FriendshipStatus.accepted,
                )),
                onReject: (f) => _bloc.add(RemoveFriend(f.id)),
                onCancelSent: _cancelSent,
              ),
          ],
        ),
      ),
    );
  }
}

class _AcceptedBody extends StatelessWidget {
  final List<FriendshipDto> items;
  final void Function(int userId, String name, String? avatarUrl) onOpen;
  const _AcceptedBody({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.person_outline,
        title: l10n.friendsEmptyAccepted,
        subtitle: l10n.friendsEmptyAcceptedSubtitle,
      );
    }
    return FriendsSectionCard(
      label: l10n.friendsSectionAccepted,
      children: [
        for (final f in items)
          FriendListTile(
            friendship: f,
            // Tap → profil de l'ami (sa bibliothèque).
            onTap: () => onOpen(f.otherUserId, f.displayName, f.otherAvatarUrl),
            onRemove: () =>
                context.read<FriendsBloc>().add(RemoveFriend(f.id)),
          ),
      ],
    );
  }
}
