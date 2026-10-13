import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/bloc/notification_counts_cubit.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/core/theme/app_surfaces.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Cloche du centre de notifications (en haut à droite de l'accueil) avec la
/// pastille des non lues.
///
/// Lit [NotificationCountsCubit] s'il est fourni plus haut (barre de
/// navigation) ; sinon — tests, écran isolé — la cloche reste utilisable,
/// simplement sans pastille. Au retour du centre, les compteurs sont relus.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = _maybeCubit(context);
    if (cubit == null) return const _Bell(unread: 0);
    return BlocSelector<NotificationCountsCubit, NotificationCounts, int>(
      bloc: cubit,
      selector: (counts) => counts.unreadNotifications,
      builder: (context, unread) =>
          _Bell(unread: unread, onReturn: cubit.refresh),
    );
  }

  static NotificationCountsCubit? _maybeCubit(BuildContext context) {
    try {
      return BlocProvider.of<NotificationCountsCubit>(context);
    } catch (_) {
      return null;
    }
  }
}

class _Bell extends StatelessWidget {
  final int unread;
  final Future<void> Function()? onReturn;

  const _Bell({required this.unread, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final icon = Icon(
      unread > 0
          ? Icons.notifications_active_outlined
          : Icons.notifications_none_outlined,
      size: 22,
    );
    // Le libellé (avec le nombre de non lues) est l'infobulle : `IconButton`
    // l'expose aussi aux lecteurs d'écran, sans second nœud lu deux fois.
    return IconButton(
      tooltip: l10n.notificationsBellUnread(unread),
      onPressed: () async {
        await context.push('/notifications');
        await onReturn?.call();
      },
      style: IconButton.styleFrom(
        backgroundColor: AppSurfaces.muted(scheme),
        foregroundColor: scheme.onSurface,
        fixedSize: const Size.square(AppSurfaces.iconButtonSize),
        minimumSize: const Size.square(AppSurfaces.iconButtonSize),
        side: BorderSide(color: AppSurfaces.hairline(scheme)),
        padding: EdgeInsets.zero,
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: icon,
      ),
    );
  }
}
