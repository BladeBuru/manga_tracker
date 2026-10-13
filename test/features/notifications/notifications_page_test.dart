import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/bloc/notification_counts_cubit.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/features/notifications/bloc/notifications_bloc.dart';
import 'package:mangatracker/features/notifications/dto/app_notification.dto.dart';
import 'package:mangatracker/features/notifications/services/notifications.service.dart';
import 'package:mangatracker/features/notifications/views/notifications_page.dart';
import 'package:mangatracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:mocktail/mocktail.dart';

import '../home/views/home_test_harness.dart';

class _Service extends Mock implements NotificationsService {}

/// Pastilles de substitution : un vrai `Cubit`, sans interrogation réseau.
class _FakeCounts extends Cubit<NotificationCounts>
    implements NotificationCountsCubit {
  _FakeCounts(super.initial);

  @override
  Future<void> refresh() async {}

  @override
  void pause() {}

  @override
  void resume() {}
}

AppNotificationDto _request(String id, DateTime createdAt, {bool read = false}) =>
    AppNotificationDto(
      id: id,
      type: AppNotificationType.friendRequest,
      createdAt: createdAt,
      readAt: read ? createdAt : null,
      actor: NotificationActor(id: '7', username: 'u$id', displayName: 'Léa $id'),
    );

void main() {
  late _Service service;

  setUpAll(() => registerFallbackValue(NotificationsPageDto.empty));

  setUp(() {
    service = _Service();
    when(() => service.readCache()).thenAnswer((_) async => null);
    when(() => service.saveCache(any())).thenAnswer((_) async {});
    when(() => service.markRead(any())).thenAnswer((_) async {});
  });

  Widget page() => NotificationsPage(
        createBloc: () => NotificationsBloc(
          service: service,
          isConnected: () => true,
          onUnreadChanged: (_) {},
        ),
      );

  testWidgets('lignes groupées par jour, texte de chaque notification',
      (tester) async {
    final now = DateTime.now();
    when(() => service.fetchPage(before: any(named: 'before'))).thenAnswer(
      (_) async => NotificationsPageDto(
        items: [
          _request('1', now),
          _request('2', now.subtract(const Duration(days: 3)), read: true),
        ],
        unreadCount: 1,
      ),
    );
    await tester.pumpWidget(frRouterHarness(home: page()));
    await pumpFrames(tester);

    expect(find.text('AUJOURD\'HUI'), findsOneWidget);
    expect(find.text('PLUS TÔT'), findsOneWidget);
    expect(find.text("Léa 1 vous a envoyé une demande d'ami"), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Non lue')), findsOneWidget);
  });

  testWidgets('liste vide : message d\'accueil du centre', (tester) async {
    when(() => service.fetchPage(before: any(named: 'before')))
        .thenAnswer((_) async => NotificationsPageDto.empty);
    await tester.pumpWidget(frRouterHarness(home: page()));
    await pumpFrames(tester);

    expect(find.text('Aucune notification'), findsOneWidget);
    expect(
      find.textContaining('tout arrive ici'),
      findsOneWidget,
    );
  });

  testWidgets('toucher une demande d\'ami : lue, puis onglet Demandes',
      (tester) async {
    when(() => service.fetchPage(before: any(named: 'before'))).thenAnswer(
      (_) async => NotificationsPageDto(
        items: [_request('1', DateTime.now())],
        unreadCount: 1,
      ),
    );
    await tester.pumpWidget(frRouterHarness(
      home: page(),
      extraRoutes: {
        '/friends': (state) =>
            Text('amis:${state.uri.queryParameters['tab']}'),
      },
    ));
    await pumpFrames(tester);

    await tester.tap(find.text("Léa 1 vous a envoyé une demande d'ami"));
    await pumpFrames(tester);

    expect(find.text('amis:pending'), findsOneWidget);
    verify(() => service.markRead('1')).called(1);
  });

  testWidgets('cloche : pastille des non lues, ouvre le centre',
      (tester) async {
    final counts = _FakeCounts(const NotificationCounts(unreadNotifications: 3));
    addTearDown(counts.close);
    await tester.pumpWidget(frRouterHarness(
      home: Scaffold(
        body: BlocProvider<NotificationCountsCubit>.value(
          value: counts,
          child: const Center(child: NotificationBellButton()),
        ),
      ),
      extraRoutes: {'/notifications': (_) => const Text('centre')},
    ));
    await pumpFrames(tester);

    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Notifications, 3 non lues'), findsOneWidget);

    await tester.tap(find.byType(NotificationBellButton));
    await pumpFrames(tester);
    expect(find.text('centre'), findsOneWidget);
  });

  testWidgets('cloche sans compteurs fournis : utilisable, sans pastille',
      (tester) async {
    await tester.pumpWidget(frRouterHarness(
      home: const Scaffold(body: Center(child: NotificationBellButton())),
    ));
    await pumpFrames(tester);
    expect(find.byTooltip('Notifications'), findsOneWidget);
  });
}
