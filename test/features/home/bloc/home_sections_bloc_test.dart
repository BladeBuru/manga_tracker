import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';
import 'package:mangatracker/features/home/bloc/home_sections_bloc.dart';
import 'package:mangatracker/features/home/bloc/home_sections_event.dart';
import 'package:mangatracker/features/home/bloc/home_sections_state.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class MockHomeSectionsService extends Mock implements HomeSectionsService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

/// Chargement OK, cache d'abord, et repli hors ligne selon le mode d'echec :
/// reseau / session expiree → `isOffline`, session rejetee → `requiresReauth`,
/// sans cache → erreur marquee hors ligne.
void main() {
  late MockHomeSectionsService service;
  late MockConnectivityService connectivity;
  late HomeSectionsDto fixture;

  HomeSectionsBloc buildBloc() =>
      HomeSectionsBloc(service: service, connectivity: connectivity);

  setUp(() {
    service = MockHomeSectionsService();
    connectivity = MockConnectivityService();
    when(() => connectivity.isConnected).thenReturn(true);
    fixture = HomeSectionsDto.fromJson(loadJsonFixture('home_sections.json'));
  });

  void stubNetwork(HomeSectionsDto dto) =>
      when(() => service.fetchSections(limit: any(named: 'limit')))
          .thenAnswer((_) async => dto);

  void stubNetworkFailure(Object error) =>
      when(() => service.fetchSections(limit: any(named: 'limit')))
          .thenThrow(error);

  void stubCache(HomeSectionsDto? dto) =>
      when(() => service.getCachedSections()).thenAnswer((_) async => dto);

  group('LoadHomeSections', () {
    test('sans cache : Loading puis Loaded frais', () async {
      stubCache(null);
      stubNetwork(fixture);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const HomeSectionsLoading(),
          isA<HomeSectionsLoaded>()
              .having((s) => s.data, 'data', fixture)
              .having((s) => s.isOffline, 'isOffline', false)
              .having((s) => s.isStale, 'isStale', false)
              .having((s) => s.requiresReauth, 'requiresReauth', false),
        ]),
      );
      bloc.add(const LoadHomeSections());
      await expectation;
      verify(() => service.fetchSections(limit: 20)).called(1);
    });

    test('avec cache : affichage immediat (stale) puis donnees fraiches',
        () async {
      final cached = HomeSectionsDto(sections: [fixture.sections.first]);
      stubCache(cached);
      stubNetwork(fixture);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<HomeSectionsLoaded>()
              .having((s) => s.data, 'data', cached)
              .having((s) => s.isStale, 'isStale', true)
              .having((s) => s.isOffline, 'isOffline', false),
          isA<HomeSectionsLoaded>()
              .having((s) => s.data, 'data', fixture)
              .having((s) => s.isStale, 'isStale', false),
        ]),
      );
      bloc.add(const LoadHomeSections());
      await expectation;
    });

    test('appareil deja hors ligne : le cache porte isOffline sans attendre',
        () async {
      when(() => connectivity.isConnected).thenReturn(false);
      stubCache(fixture);
      stubNetworkFailure(const SocketException('offline'));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emits(
          isA<HomeSectionsLoaded>()
              .having((s) => s.isOffline, 'isOffline', true)
              .having((s) => s.isStale, 'isStale', true),
        ),
      );
      bloc.add(const LoadHomeSections());
      await expectation;
    });

    test('echec reseau + cache → Loaded depuis le cache, isOffline', () async {
      stubCache(fixture);
      stubNetworkFailure(const SocketException('offline'));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<HomeSectionsLoaded>().having((s) => s.isOffline, 'isOffline', false),
          isA<HomeSectionsLoaded>()
              .having((s) => s.data, 'data', fixture)
              .having((s) => s.isOffline, 'isOffline', true)
              .having((s) => s.isStale, 'isStale', true)
              .having((s) => s.requiresReauth, 'requiresReauth', false),
        ]),
      );
      bloc.add(const LoadHomeSections());
      await expectation;
    });

    test('session expiree localement + cache → isOffline (pas de verdict)',
        () async {
      stubCache(fixture);
      stubNetworkFailure(SessionExpiredException('Both tokens expired'));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const LoadHomeSections());
      final state = await bloc.stream
          .firstWhere((s) => s is HomeSectionsLoaded && s.isOffline);
      expect((state as HomeSectionsLoaded).requiresReauth, isFalse);
      expect(state.sections, isNotEmpty);
    });

    test('session rejetee par le serveur + cache → servi, avec invite',
        () async {
      // Decision produit 2026-08-31 : un 401/403 n'efface pas l'ecran.
      stubCache(fixture);
      stubNetworkFailure(InvalidCredentialsException('Refresh rejected'));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const LoadHomeSections());
      final state = await bloc.stream
          .firstWhere((s) => s is HomeSectionsLoaded && s.requiresReauth);
      expect((state as HomeSectionsLoaded).isOffline, isFalse,
          reason: 'le serveur repond : ce n\'est pas du hors-ligne');
      expect(state.data, fixture);
    });

    test('echec reseau sans cache → Error marquee hors ligne', () async {
      stubCache(null);
      stubNetworkFailure(const SocketException('offline'));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const HomeSectionsLoading(),
          isA<HomeSectionsError>()
              .having((s) => s.isOffline, 'isOffline', true)
              .having((s) => s.requiresReauth, 'requiresReauth', false),
        ]),
      );
      bloc.add(const LoadHomeSections());
      await expectation;
    });

    test('erreur serveur (5xx) sans cache → Error, ni offline ni reauth',
        () async {
      stubCache(null);
      stubNetworkFailure(Exception('HTTP Request Failed with status: 500.'));
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const LoadHomeSections());
      final state =
          await bloc.stream.firstWhere((s) => s is HomeSectionsError);
      expect(state.isOffline, isFalse);
      expect(state.requiresReauth, isFalse);
    });

    test('un cache vide (aucune section) ne masque pas le squelette', () async {
      stubCache(const HomeSectionsDto());
      stubNetwork(fixture);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const HomeSectionsLoading(), isA<HomeSectionsLoaded>()]),
      );
      bloc.add(const LoadHomeSections());
      await expectation;
    });
  });

  group('RefreshHomeSections', () {
    test('garde les donnees courantes pendant le rafraichissement', () async {
      stubCache(null);
      stubNetwork(fixture);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadHomeSections());
      await bloc.stream.firstWhere((s) => s is HomeSectionsLoaded);
      clearInteractions(service);

      final refreshed = HomeSectionsDto(sections: [fixture.sections.last]);
      stubNetwork(refreshed);
      final expectation = expectLater(
        bloc.stream,
        emits(isA<HomeSectionsLoaded>().having((s) => s.data, 'data', refreshed)),
      );
      bloc.add(const RefreshHomeSections());
      await expectation;
      verifyNever(() => service.getCachedSections());
    });

    test('rafraichissement en echec : donnees courantes conservees, isOffline',
        () async {
      stubCache(null);
      stubNetwork(fixture);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadHomeSections());
      await bloc.stream.firstWhere((s) => s is HomeSectionsLoaded);

      stubNetworkFailure(const SocketException('offline'));
      final expectation = expectLater(
        bloc.stream,
        emits(
          isA<HomeSectionsLoaded>()
              .having((s) => s.data, 'data', fixture)
              .having((s) => s.isOffline, 'isOffline', true)
              .having((s) => s.isStale, 'isStale', true),
        ),
      );
      bloc.add(const RefreshHomeSections());
      await expectation;
    });

    test('un rafraichissement pendant un chargement en vol est ignore',
        () async {
      stubCache(null);
      final completer = Completer<HomeSectionsDto>();
      when(() => service.fetchSections(limit: any(named: 'limit')))
          .thenAnswer((_) => completer.future);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const LoadHomeSections());
      await bloc.stream.firstWhere((s) => s is HomeSectionsLoading);
      bloc.add(const RefreshHomeSections());
      await Future<void>.delayed(Duration.zero);
      completer.complete(fixture);
      await bloc.stream.firstWhere((s) => s is HomeSectionsLoaded);

      verify(() => service.fetchSections(limit: any(named: 'limit'))).called(1);
    });
  });
}
