part of 'notifications_bloc.dart';

enum NotificationsStatus { initial, loading, loaded, failure }

/// État du centre de notifications.
///
/// Une seule classe (et non Loading / Loaded / Error) : la pagination, la
/// lecture optimiste et le repli sur le cache gardent la liste affichée
/// pendant toutes les transitions.
class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<AppNotificationDto> items;
  final int unreadCount;

  /// Curseur de la page suivante ; `null` = fin de liste (ou hors ligne).
  final String? nextBefore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  /// « Ce que tu vois vient du cache, faute d'avoir joint le serveur ».
  /// Ré-évalué à chaque échec via `classifyFailure`, jamais hérité.
  final bool isOffline;

  /// Session refusée par le serveur : invitation non bloquante.
  final bool requiresReauth;

  /// Échec du chargement initial (sans cache) — texte via
  /// `userFacingErrorMessage`.
  final Object? error;

  /// Échec ponctuel d'une action (« tout marquer comme lu »). Chaque échec
  /// porte un numéro distinct pour que la vue l'annonce une fois.
  final Object? actionError;
  final int actionErrorSeq;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unreadCount = 0,
    this.nextBefore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.isOffline = false,
    this.requiresReauth = false,
    this.error,
    this.actionError,
    this.actionErrorSeq = 0,
  });

  bool get hasMore => nextBefore != null;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotificationDto>? items,
    int? unreadCount,
    String? Function()? nextBefore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    bool? isOffline,
    bool? requiresReauth,
    Object? Function()? error,
    Object? actionError,
    int? actionErrorSeq,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      nextBefore: nextBefore != null ? nextBefore() : this.nextBefore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      isOffline: isOffline ?? this.isOffline,
      requiresReauth: requiresReauth ?? this.requiresReauth,
      error: error != null ? error() : this.error,
      actionError: actionError ?? this.actionError,
      actionErrorSeq: actionErrorSeq ?? this.actionErrorSeq,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        unreadCount,
        nextBefore,
        isLoadingMore,
        loadMoreFailed,
        isOffline,
        requiresReauth,
        error,
        actionError,
        actionErrorSeq,
      ];
}
