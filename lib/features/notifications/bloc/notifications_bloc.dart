import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/services/notifications.service.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';
part 'notifications_read_handlers.dart';

/// BLoC du centre de notifications — une instance par ouverture de la page.
///
/// Offline-first : la première page est mise en cache ; à l'ouverture, le
/// cache s'affiche aussitôt puis le réseau le remplace. Sur échec, le cache
/// est servi en **lecture seule** (ni « lu », ni « tout lu », ni page
/// suivante), quel que soit le mode d'échec (`classifyFailure`).
///
/// La pastille de la cloche suit chaque changement du nombre de non lues
/// ([onUnreadChanged], par défaut `NotificationCountsService`).
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState>
    with _NotificationsReadHandlers {
  @override
  final NotificationsService _service;
  final bool Function() _isConnected;
  @override
  final void Function(int unread) _onUnreadChanged;
  @override
  final DateTime Function() _now;

  NotificationsBloc({
    NotificationsService? service,
    bool Function()? isConnected,
    void Function(int unread)? onUnreadChanged,
    DateTime Function()? now,
  })  : _service = service ?? getIt<NotificationsService>(),
        _isConnected = isConnected ?? _deviceIsConnected,
        _onUnreadChanged = onUnreadChanged ?? _updateBell,
        _now = now ?? DateTime.now,
        super(const NotificationsState()) {
    on<LoadNotifications>(_onLoad);
    on<RefreshNotifications>(_onRefresh);
    on<LoadMoreNotifications>(_onLoadMore);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    final cached = await _service.readCache();
    if (cached != null) {
      // Rendu optimiste : appareil qui se sait hors ligne → bandeau tout de
      // suite, sans attendre l'échec réseau.
      emit(NotificationsState(
        status: NotificationsStatus.loaded,
        items: cached.items,
        unreadCount: cached.unreadCount,
        isOffline: !_isConnected(),
      ));
    } else {
      emit(state.copyWith(status: NotificationsStatus.loading));
    }
    await _fetchFirstPage(emit, fallback: cached);
  }

  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final shown = state.status == NotificationsStatus.loaded
          ? NotificationsPageDto(items: state.items, unreadCount: state.unreadCount)
          : null;
      await _fetchFirstPage(emit, fallback: shown);
    } finally {
      final completer = event.completer;
      if (completer != null && !completer.isCompleted) completer.complete();
    }
  }

  Future<void> _fetchFirstPage(
    Emitter<NotificationsState> emit, {
    NotificationsPageDto? fallback,
  }) async {
    try {
      final page = await _service.fetchPage();
      await _service.saveCache(page);
      emit(NotificationsState(
        status: NotificationsStatus.loaded,
        items: page.items,
        unreadCount: page.unreadCount,
        nextBefore: page.nextBefore,
      ));
      _onUnreadChanged(page.unreadCount);
    } catch (e) {
      final mode = classifyFailure(e);
      final shown = fallback ?? await _service.readCache();
      emit(NotificationsState(
        status: shown != null
            ? NotificationsStatus.loaded
            : NotificationsStatus.failure,
        items: shown?.items ?? const [],
        unreadCount: shown?.unreadCount ?? 0,
        isOffline: showsOfflineIndicator(mode),
        requiresReauth: requiresReauthPrompt(mode),
        error: shown == null ? e : null,
      ));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    final cursor = state.nextBefore;
    if (cursor == null || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final page = await _service.fetchPage(before: cursor);
      final known = state.items.map((n) => n.id).toSet();
      emit(state.copyWith(
        items: [
          ...state.items,
          ...page.items.where((n) => !known.contains(n.id)),
        ],
        unreadCount: page.unreadCount,
        nextBefore: () => page.nextBefore,
        isLoadingMore: false,
        isOffline: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        loadMoreFailed: true,
        isOffline: showsOfflineIndicator(classifyFailure(e)),
      ));
    }
  }

  static bool _deviceIsConnected() {
    try {
      return getIt<ConnectivityService>().isConnected;
    } catch (_) {
      return true;
    }
  }

  static void _updateBell(int unread) {
    try {
      getIt<NotificationCountsService>().setUnreadNotifications(unread);
    } catch (_) {
      // Service absent (tests, démarrage interrompu) : rien à mettre à jour.
    }
  }
}
