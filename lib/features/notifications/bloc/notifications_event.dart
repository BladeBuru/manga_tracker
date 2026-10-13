part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

/// Ouverture du centre : cache affiché aussitôt (s'il existe), puis réseau.
class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

/// Tirer pour rafraîchir. [completer] se termine quand la réponse (ou
/// l'échec) est arrivée, pour l'indicateur de `RefreshIndicator`.
class RefreshNotifications extends NotificationsEvent {
  final Completer<void>? completer;
  const RefreshNotifications({this.completer});
  @override
  List<Object?> get props => [completer];
}

/// Défilement infini : page suivante (`before` = curseur courant).
class LoadMoreNotifications extends NotificationsEvent {
  const LoadMoreNotifications();
}

/// Toucher d'une ligne : elle passe en lue (optimiste).
class MarkNotificationRead extends NotificationsEvent {
  final String id;
  const MarkNotificationRead(this.id);
  @override
  List<Object?> get props => [id];
}

/// « Tout marquer comme lu ».
class MarkAllNotificationsRead extends NotificationsEvent {
  const MarkAllNotificationsRead();
}
