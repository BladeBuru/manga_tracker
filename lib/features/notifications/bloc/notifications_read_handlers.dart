part of 'notifications_bloc.dart';

/// Lecture d'une ligne / de toutes : **optimiste**, rétablie sur échec, et
/// refusée hors ligne (le cache est en lecture seule). Extrait du BLoC pour
/// respecter la limite de taille.
mixin _NotificationsReadHandlers
    on Bloc<NotificationsEvent, NotificationsState> {
  NotificationsService get _service;
  void Function(int unread) get _onUnreadChanged;
  DateTime Function() get _now;

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final index = state.items.indexWhere((n) => n.id == event.id);
    if (index < 0 || !state.items[index].isUnread || state.isOffline) return;
    final original = state.items[index];
    _emitReadState(emit, {event.id}, read: true);
    try {
      await _service.markRead(event.id);
      await _saveShown();
    } catch (_) {
      // Retour à l'état serveur : la ligne redevient non lue.
      _emitReadState(emit, {original.id}, read: false);
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final unreadIds = {
      for (final n in state.items)
        if (n.isUnread) n.id,
    };
    if (state.isOffline || (unreadIds.isEmpty && state.unreadCount == 0)) {
      return;
    }
    final previousCount = state.unreadCount;
    _emitReadState(emit, unreadIds, read: true, unreadCount: 0);
    try {
      await _service.markAllRead();
      await _saveShown();
    } catch (e) {
      _emitReadState(emit, unreadIds, read: false, unreadCount: previousCount);
      emit(state.copyWith(
        actionError: e,
        actionErrorSeq: state.actionErrorSeq + 1,
      ));
    }
  }

  /// Passe [ids] en lu (ou les rétablit non lus) et ajuste le compteur.
  void _emitReadState(
    Emitter<NotificationsState> emit,
    Set<String> ids, {
    required bool read,
    int? unreadCount,
  }) {
    final now = _now();
    var delta = 0;
    final items = <AppNotificationDto>[];
    for (final n in state.items) {
      if (ids.contains(n.id) && read && n.isUnread) {
        delta--;
        items.add(n.markedRead(now));
      } else if (ids.contains(n.id) && !read && !n.isUnread) {
        delta++;
        items.add(n.markedUnread());
      } else {
        items.add(n);
      }
    }
    final count = unreadCount ?? (state.unreadCount + delta);
    final safe = count < 0 ? 0 : count;
    emit(state.copyWith(items: items, unreadCount: safe));
    _onUnreadChanged(safe);
  }

  /// Le cache reflète ce qui est affiché (lu / non lu), première page seule.
  Future<void> _saveShown() => _service.saveCache(NotificationsPageDto(
        items: state.items.take(NotificationsService.pageSize).toList(),
        unreadCount: state.unreadCount,
        nextBefore: state.nextBefore,
      ));
}
