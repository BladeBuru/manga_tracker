import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:mangatracker/core/network/api_exception.dart';
import 'package:mangatracker/features/notifications/bloc/notifications_bloc.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/services/notifications.service.dart';
import 'package:mocktail/mocktail.dart';

class _Service extends Mock implements NotificationsService {}

AppNotificationDto _n(String id, {bool read = false}) => AppNotificationDto(
      id: id,
      type: AppNotificationType.friendRequest,
      createdAt: DateTime(2026, 10, 13),
      readAt: read ? DateTime(2026, 10, 13) : null,
      actor: NotificationActor(id: '9', username: 'lea$id'),
    );

NotificationsPageDto _page(List<AppNotificationDto> items, {String? next}) =>
    NotificationsPageDto(
      items: items,
      unreadCount: items.where((n) => n.isUnread).length,
      nextBefore: next,
    );

void main() {
  late _Service service;
  late List<int> bell;
  var connected = true;

  setUpAll(() => registerFallbackValue(NotificationsPageDto.empty));

  setUp(() {
    service = _Service();
    bell = [];
    connected = true;
    when(() => service.saveCache(any())).thenAnswer((_) async {});
    when(() => service.readCache()).thenAnswer((_) async => null);
  });

  NotificationsBloc build() => NotificationsBloc(
        service: service,
        isConnected: () => connected,
        onUnreadChanged: bell.add,
        now: () => DateTime(2026, 10, 13, 12),
      );

  Future<NotificationsState> settle(NotificationsBloc bloc) async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return bloc.state;
  }

  test('chargement : première page affichée, mise en cache, cloche à jour',
      () async {
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenAnswer((_) async => _page([_n('1'), _n('2', read: true)], next: 'c1'));
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);

    final state = await settle(bloc);
    expect(state.status, NotificationsStatus.loaded);
    expect(state.items.map((n) => n.id), ['1', '2']);
    expect(state.unreadCount, 1);
    expect(state.hasMore, isTrue);
    expect(state.isOffline, isFalse);
    verify(() => service.saveCache(any())).called(1);
    expect(bell.last, 1);
  });

  test('pagination : la page suivante s\'ajoute sans doublon', () async {
    when(() => service.fetchPage(before: null))
        .thenAnswer((_) async => _page([_n('1'), _n('2')], next: 'c1'));
    when(() => service.fetchPage(before: 'c1'))
        .thenAnswer((_) async => _page([_n('2'), _n('3')]));
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);
    await settle(bloc);

    bloc.add(const LoadMoreNotifications());
    final state = await settle(bloc);
    expect(state.items.map((n) => n.id), ['1', '2', '3']);
    expect(state.hasMore, isFalse);

    bloc.add(const LoadMoreNotifications()); // fin de liste : rien
    await settle(bloc);
    verify(() => service.fetchPage(before: 'c1')).called(1);
  });

  test('marquer lu : optimiste, envoyé au serveur, rétabli si refus',
      () async {
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenAnswer((_) async => _page([_n('1'), _n('2')]));
    when(() => service.markRead('1')).thenAnswer((_) async {});
    when(() => service.markRead('2'))
        .thenThrow(const ApiException(500));
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);
    await settle(bloc);

    bloc.add(const MarkNotificationRead('1'));
    var state = await settle(bloc);
    expect(state.items.first.isUnread, isFalse);
    expect(state.unreadCount, 1);
    verify(() => service.markRead('1')).called(1);

    bloc.add(const MarkNotificationRead('2'));
    state = await settle(bloc);
    expect(state.items[1].isUnread, isTrue, reason: 'refus serveur → rétabli');
    expect(state.unreadCount, 1);
    expect(bell.last, 1);
  });

  test('tout marquer comme lu : compteur à zéro ; échec → rétabli + message',
      () async {
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenAnswer((_) async => _page([_n('1'), _n('2')]));
    when(() => service.markAllRead()).thenAnswer((_) async => 2);
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);
    await settle(bloc);

    bloc.add(const MarkAllNotificationsRead());
    var state = await settle(bloc);
    expect(state.items.every((n) => !n.isUnread), isTrue);
    expect(state.unreadCount, 0);
    expect(bell.last, 0);

    // Second essai sur une liste à nouveau non lue, refusé par le serveur.
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenAnswer((_) async => _page([_n('3')]));
    when(() => service.markAllRead()).thenThrow(const ApiException(429));
    bloc.add(const RefreshNotifications());
    await settle(bloc);
    bloc.add(const MarkAllNotificationsRead());
    state = await settle(bloc);
    expect(state.items.single.isUnread, isTrue);
    expect(state.unreadCount, 1);
    expect(state.actionErrorSeq, 1);
    expect(state.actionError, isA<ApiException>());
  });

  test('hors ligne : le cache est servi en lecture seule', () async {
    final cached = _page([_n('1'), _n('2')]);
    when(() => service.readCache()).thenAnswer((_) async => cached);
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenThrow(ClientException('réseau'));
    connected = false;
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);

    final state = await settle(bloc);
    expect(state.status, NotificationsStatus.loaded);
    expect(state.items.map((n) => n.id), ['1', '2']);
    expect(state.isOffline, isTrue);
    expect(state.hasMore, isFalse, reason: 'pas de pagination hors ligne');

    bloc.add(const MarkNotificationRead('1'));
    bloc.add(const MarkAllNotificationsRead());
    final after = await settle(bloc);
    expect(after.items.first.isUnread, isTrue);
    verifyNever(() => service.markRead(any()));
    verifyNever(() => service.markAllRead());
  });

  test('sans cache ni réseau : état d\'échec (pas de liste vide trompeuse)',
      () async {
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenThrow(TimeoutException('lent'));
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);

    final state = await settle(bloc);
    expect(state.status, NotificationsStatus.failure);
    expect(state.isOffline, isTrue);
    expect(state.error, isA<TimeoutException>());
  });

  test('tirer pour rafraîchir termine son indicateur, même en échec',
      () async {
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenAnswer((_) async => _page([_n('1')]));
    final bloc = build()..add(const LoadNotifications());
    addTearDown(bloc.close);
    await settle(bloc);

    when(() => service.fetchPage(before: any(named: 'before')))
        .thenThrow(ClientException('réseau'));
    final done = Completer<void>();
    bloc.add(RefreshNotifications(completer: done));
    await done.future.timeout(const Duration(seconds: 1));
    expect(bloc.state.items.single.id, '1', reason: 'liste gardée');
    expect(bloc.state.isOffline, isTrue);
  });
}
