import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart' show AppContentWidth;
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/utils/responsive_layout.dart';
import 'package:mangatracker/features/friends/bloc/friends_bloc.dart';
import 'package:mangatracker/features/friends/dto/friend.dto.dart';
import 'package:mangatracker/features/friends/widgets/friend_list_tile.dart';
import 'package:mangatracker/features/friends/widgets/friends_section_card.dart';
import 'package:mangatracker/features/friends/widgets/friends_tab_segmented.dart';
import 'package:mangatracker/features/friends/widgets/user_search_field.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page « Mes amis » — design V1 « Refined Classic ».
///
/// Structure :
///  - AppBar transparente avec hairline en bas (style profile_edit.view).
///  - Pill search input (radius 14, border rouge si query non vide).
///  - Segmented control (chips pastel) : Amis / Demandes.
///  - Section card V1 (radius 16, hairline outline, dividers entre rows).
///  - Empty states / error state via `AppEmptyState` / `AppErrorState`.
///
/// Le BLoC, les events et la logique métier sont inchangés (UI-only).
class FriendsListPage extends StatelessWidget {
  const FriendsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FriendsBloc>(
      create: (_) => FriendsBloc()..add(const LoadFriends()),
      child: const _FriendsScaffold(),
    );
  }
}

class _FriendsScaffold extends StatelessWidget with ResponsiveLayoutMixin {
  const _FriendsScaffold();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        shape: Border(
          bottom: BorderSide(
            color: AppColors.dsHairline(brightness),
            width: 1,
          ),
        ),
      ),
      body: BlocConsumer<FriendsBloc, FriendsState>(
        listenWhen: (a, b) =>
            b is FriendsLoaded &&
            (b.lastActionMessage != null || b.lastActionError != null),
        listener: (context, state) => _onStateMessage(context, state, l10n),
        builder: (context, state) {
          if (state is FriendsLoading || state is FriendsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FriendsError) {
            return AppErrorState(
              message: state.message,
              retryLabel: l10n.retry,
              onRetry: () =>
                  context.read<FriendsBloc>().add(const LoadFriends()),
            );
          }
          if (state is FriendsLoaded) {
            return _FriendsContent(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onStateMessage(
    BuildContext context,
    FriendsState state,
    AppLocalizations l10n,
  ) {
    if (state is! FriendsLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    if (state.lastActionError != null) {
      messenger.showSnackBar(SnackBar(
        content: Text('${l10n.friendsError}: ${state.lastActionError}'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } else if (state.lastActionMessage == 'request_sent') {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.friendsRequestSent),
      ));
    }
  }
}

class _FriendsContent extends StatefulWidget {
  final FriendsLoaded state;
  const _FriendsContent({required this.state});

  @override
  State<_FriendsContent> createState() => _FriendsContentState();
}

class _FriendsContentState extends State<_FriendsContent>
    with ResponsiveLayoutMixin {
  FriendsTab _tab = FriendsTab.accepted;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final hPad = horizontalPadding(context);
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FriendsBloc>().add(const LoadFriends(forceRefresh: true));
      },
      // Responsive (audit 2026-06-12) : contenu centré via le wrapper
      // unifié AppContentWidth (max 1100) au lieu du maxContentWidth local.
      child: AppContentWidth(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
          children: [
            UserSearchField(
              results: s.searchResults,
              onQueryChanged: (q) =>
                  context.read<FriendsBloc>().add(SearchUsers(q)),
              onSendRequest: (userId) => context
                  .read<FriendsBloc>()
                  .add(SendFriendRequest(userId)),
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
              _AcceptedBody(items: s.accepted)
            else
              _PendingBody(items: s.pending),
          ],
        ),
      ),
    );
  }
}

class _AcceptedBody extends StatelessWidget {
  final List<FriendshipDto> items;
  const _AcceptedBody({required this.items});

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
            onTap: () => context.push(
              '/friends/${f.otherUserId}',
              extra: FriendProfileExtras(
                displayName: f.displayName,
                avatarUrl: f.otherAvatarUrl,
              ),
            ),
            onRemove: () =>
                context.read<FriendsBloc>().add(RemoveFriend(f.id)),
          ),
      ],
    );
  }
}

class _PendingBody extends StatelessWidget {
  final List<FriendshipDto> items;
  const _PendingBody({required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return AppEmptyState(
        icon: Icons.mark_email_read_outlined,
        title: l10n.friendsEmptyPending,
        subtitle: l10n.friendsEmptyPendingSubtitle,
      );
    }
    return FriendsSectionCard(
      label: l10n.friendsSectionPending,
      children: [
        for (final f in items)
          FriendListTile(
            friendship: f,
            showAcceptReject: true,
            onAccept: () => context.read<FriendsBloc>().add(RespondToRequest(
                  friendshipId: f.id,
                  newStatus: FriendshipStatus.accepted,
                )),
            onReject: () =>
                context.read<FriendsBloc>().add(RemoveFriend(f.id)),
          ),
      ],
    );
  }
}
