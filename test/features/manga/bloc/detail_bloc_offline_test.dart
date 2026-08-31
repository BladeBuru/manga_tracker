import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mocktail/mocktail.dart';

class MockMangaService extends Mock implements MangaService {}

class MockLibraryService extends Mock implements LibraryService {}

class MockChapterReportService extends Mock implements ChapterReportService {}

class MockCacheHelperService extends Mock implements CacheHelperService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

MangaDetailDto detailFixture({num muId = 42, String title = 'Solo Leveling'}) =>
    MangaDetailDto(
      muId: muId,
      title: title,
      year: '2018',
      rating: '9.1',
      totalChapters: 179,
    );

void main() {
  late MockMangaService mangaService;
  late MockLibraryService libraryService;
  late MockChapterReportService chapterReportService;
  late MockCacheHelperService cacheHelper;
  late MockConnectivityService connectivityService;
  late StreamController<bool> connectivityController;

  const muId = 42;

  setUp(() {
    mangaService = MockMangaService();
    libraryService = MockLibraryService();
    chapterReportService = MockChapterReportService();
    cacheHelper = MockCacheHelperService();
    connectivityService = MockConnectivityService();
    connectivityController = StreamController<bool>.broadcast();

    when(() => connectivityService.connectivityStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => connectivityService.isConnected).thenReturn(false);

    // L'enrichissement bibliothèque n'est pas le sujet de ces tests.
    when(() => libraryService.getLibraryEntry(any()))
        .thenAnswer((_) async => null);
    when(() => cacheHelper.getOfflineQueue())
        .thenAnswer((_) async => <OfflineAction>[]);

    // `loadMangaDetail` délègue réellement au networkCall pour que l'exception
    // levée par MangaService remonte comme en production.
    when(() => cacheHelper.loadMangaDetail(
          muId: any(named: 'muId'),
          networkCall: any(named: 'networkCall'),
        )).thenAnswer((invocation) async {
      final networkCall = invocation.namedArguments[#networkCall]
          as Future<MangaDetailDto> Function();
      return networkCall();
    });

    getIt.registerSingleton<MangaService>(mangaService);
    getIt.registerSingleton<LibraryService>(libraryService);
    getIt.registerSingleton<ChapterReportService>(chapterReportService);
    getIt.registerSingleton<CacheHelperService>(cacheHelper);
    getIt.registerSingleton<ConnectivityService>(connectivityService);
  });

  tearDown(() async {
    await connectivityController.close();
    await getIt.reset();
  });

  /// Attend l'état stable final du bloc (le chargement émet un état
  /// intermédiaire « cache optimiste » avant la résolution réseau).
  Future<DetailState> settle(DetailBloc bloc) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return bloc.state;
  }

  group('DetailBloc — lecture hors ligne du détail manga', () {
    test(
        'token expiré + hors ligne → sert le détail en cache au lieu d\'une '
        'erreur d\'authentification', () async {
      final cached = detailFixture();
      when(() => cacheHelper.getCachedMangaDetail(muId))
          .thenAnswer((_) async => cached);
      // Ce que HttpService lève quand access ET refresh sont expirés
      // localement : aucun verdict serveur, la session est peut-être encore
      // bonne côté API.
      when(() => mangaService.getMangaDetail(any()))
          .thenThrow(SessionExpiredException('Both tokens expired'));

      final bloc = DetailBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadMangaDetail(muId));

      final state = await settle(bloc);
      expect(state, isA<DetailLoaded>());
      expect((state as DetailLoaded).mangaDetail.title, cached.title);
      expect(state.isOffline, isTrue,
          reason: 'le bandeau hors ligne doit être affiché');
      expect(state.isStale, isTrue);
    });

    test('SocketException → sert le détail en cache', () async {
      final cached = detailFixture();
      when(() => cacheHelper.getCachedMangaDetail(muId))
          .thenAnswer((_) async => cached);
      when(() => mangaService.getMangaDetail(any()))
          .thenThrow(const SocketException('offline'));

      final bloc = DetailBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadMangaDetail(muId));

      final state = await settle(bloc);
      expect(state, isA<DetailLoaded>());
      expect((state as DetailLoaded).isOffline, isTrue);
    });

    test('cache vide + hors ligne → état hors ligne propre, pas une erreur '
        'technique', () async {
      when(() => cacheHelper.getCachedMangaDetail(muId))
          .thenAnswer((_) async => null);
      when(() => mangaService.getMangaDetail(any()))
          .thenThrow(const SocketException('offline'));

      final bloc = DetailBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadMangaDetail(muId));

      final state = await settle(bloc);
      expect(state, isA<DetailError>());
      expect((state as DetailError).isOffline, isTrue,
          reason: 'l\'écran doit dire « hors ligne », pas « erreur »');
    });

    test(
        'session rejetée par le serveur → erreur d\'authentification, PAS de '
        'cache servi', () async {
      final cached = detailFixture();
      when(() => cacheHelper.getCachedMangaDetail(muId))
          .thenAnswer((_) async => cached);
      // Verdict explicite du serveur (401/403 sur /auth/refresh) : on est
      // joignable, donc l'utilisateur peut et doit se reconnecter.
      when(() => mangaService.getMangaDetail(any()))
          .thenThrow(InvalidCredentialsException('Refresh rejected by server'));

      final bloc = DetailBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadMangaDetail(muId));

      final state = await settle(bloc);
      expect(state, isA<DetailError>());
      expect((state as DetailError).requiresLogin, isTrue);
      expect(state.isOffline, isFalse);
    });
  });
}
