import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/network/api_error_message.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_surfaces.dart';
import 'package:mangatracker/features/notifications/bloc/notifications_bloc.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/helpers/notification_presenter.dart';
import 'package:mangatracker/features/notifications/widgets/notification_list_footer.dart';
import 'package:mangatracker/features/notifications/widgets/notifications_list.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Centre de notifications (`/notifications`) : nouvelles sorties, demandes
/// d'ami, recommandations, lectures partagées — ouvert par la cloche.
///
/// Sur grand écran (≥ 768 px), le contenu est centré et borné à 480 px, à la
/// manière d'un panneau. Hors ligne, la dernière liste connue reste lisible.
class NotificationsPage extends StatelessWidget {
  /// Injectable pour les tests ; sinon une instance par ouverture.
  final NotificationsBloc Function()? createBloc;

  const NotificationsPage({super.key, this.createBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsBloc>(
      create: (_) => (createBloc?.call() ?? NotificationsBloc())
        ..add(const LoadNotifications()),
      child: const _NotificationsScaffold(),
    );
  }
}

class _NotificationsScaffold extends StatelessWidget {
  const _NotificationsScaffold();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;
    final bg =
        brightness == Brightness.dark ? AppColors.dsBgDark : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: AppSurfaces.hairline(scheme))),
        title: Text(
          l10n.notifications,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          const _MarkAllReadButton(),
          IconButton(
            tooltip: l10n.notificationsSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/notifications-settings'),
          ),
        ],
      ),
      body: BlocListener<NotificationsBloc, NotificationsState>(
        listenWhen: (a, b) => b.actionErrorSeq != a.actionErrorSeq,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(userFacingErrorMessage(state.actionError, l10n)),
          ));
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            const body = _NotificationsBody();
            if (constraints.maxWidth < AppSurfaces.panelBreakpoint) return body;
            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSurfaces.panelMaxWidth),
                child: body,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// « Tout marquer comme lu » : icône + infobulle (un libellé texte écrasait
/// le titre sur petit écran), désactivé hors ligne ou sans non lues.
class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocSelector<NotificationsBloc, NotificationsState, bool>(
      selector: (s) =>
          !s.isOffline && s.items.any((n) => n.isUnread),
      builder: (context, enabled) => IconButton(
        tooltip: l10n.notificationsMarkAllRead,
        icon: const Icon(Icons.done_all_outlined),
        onPressed: enabled
            ? () => context
                .read<NotificationsBloc>()
                .add(const MarkAllNotificationsRead())
            : null,
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        final bloc = context.read<NotificationsBloc>();
        switch (state.status) {
          case NotificationsStatus.initial:
          case NotificationsStatus.loading:
            return const NotificationsSkeleton();
          case NotificationsStatus.failure:
            return AppErrorState(
              message: userFacingErrorMessage(
                state.error,
                l10n,
                fallback: l10n.notificationsLoadError,
              ),
              retryLabel: l10n.retry,
              onRetry: () => bloc.add(const LoadNotifications()),
            );
          case NotificationsStatus.loaded:
            return NotificationsList(
              items: state.items,
              isOffline: state.isOffline,
              requiresReauth: state.requiresReauth,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              loadMoreFailed: state.loadMoreFailed,
              onOpen: (n) => _open(context, bloc, n),
              onLoadMore: () => bloc.add(const LoadMoreNotifications()),
              onRefresh: () {
                final done = Completer<void>();
                bloc.add(RefreshNotifications(completer: done));
                return done.future;
              },
            );
        }
      },
    );
  }

  /// Toucher : la ligne passe en lue (sauf hors ligne, lecture seule) et
  /// l'écran concerné s'ouvre.
  void _open(BuildContext context, NotificationsBloc bloc, AppNotificationDto n) {
    bloc.add(MarkNotificationRead(n.id));
    final route = NotificationPresenter.route(n);
    if (route == null) return;
    final Object? extra = switch (n.type) {
      AppNotificationType.friendAccepted when n.actor != null =>
        FriendProfileExtras(displayName: n.actor!.name),
      _ when n.manga != null && route.startsWith('/manga/') =>
        MangaDetailExtras(title: n.manga!.title),
      _ => null,
    };
    context.push(route, extra: extra);
  }
}
