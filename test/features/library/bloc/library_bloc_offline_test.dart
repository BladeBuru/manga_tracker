import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/auth/exceptions/session_expired.exception.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/bloc/library_state.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockLibraryService extends Mock implements LibraryService {}

class MockCacheHelperService extends Mock implements CacheHelperService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

MangaQuickViewDto manga(num muId, String title) => MangaQuickViewDto(
      muId: muId,
      title: title,
      year: '2020',
      rating: '8.0',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLibraryService libraryService;
  late MockCacheHelperService cacheHelper;
  late MockConnectivityService connectivityService;
  late StreamController<bool> connectivityController;

  setUpAll(() {
    registerFallbackValue(ReadingStatus.reading);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    libraryService = MockLibraryService();
    cacheHelper = MockCacheHelperService();
    connectivityService = MockConnectivityService();
    connectivityController = StreamController<bool>.broadcast();

    when(() => connectivityService.connectivityStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => connectivityService.isConnected).thenReturn(false);
    when(() => connectivityService.checkConnectivity())
        .thenAnswer((_) async => false);
    when(() => cacheHelper.getOfflineQueue())
        .thenAnswer((_) async => <OfflineAction>[]);
    when(() => cacheHelper.loadLibraryData(
          networkCall: any(named: 'networkCall'),
        )).thenAnswer((invocation) async {
      final networkCall = invocation.namedArguments[#networkCall]
          as Future<List<MangaQuickViewDto>> Function();
      return networkCall();
    });

    getIt.registerSingleton<LibraryService>(libraryService);
    getIt.registerSingleton<CacheHelperService>(cacheHelper);
    getIt.registerSingleton<ConnectivityService>(connectivityService);
  });

  tearDown(() async {
    await connectivityController.close();
    await getIt.reset();
  });

  Future<LibraryState> settle(LibraryBloc bloc) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return bloc.state;
  }

  group('LibraryBloc — lecture hors ligne', () {
    test('token expiré + hors ligne → sert la bibliothèque en cache', () async {
      final cached = [manga(1, 'Berserk'), manga(2, 'Vagabond')];
      when(() => cacheHelper.getCachedLibrary()).thenAnswer((_) async => cached);
      when(() => libraryService.getUserSavedMangas())
          .thenThrow(SessionExpiredException('Both tokens expired'));

      final bloc = LibraryBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadLibrary());

      final state = await settle(bloc);
      expect(state, isA<LibraryLoaded>());
      expect((state as LibraryLoaded).mangas.length, 2);
      expect(state.isOffline, isTrue);
    });

    test('SocketException → sert la bibliothèque en cache', () async {
      when(() => cacheHelper.getCachedLibrary())
          .thenAnswer((_) async => [manga(1, 'Berserk')]);
      when(() => libraryService.getUserSavedMangas())
          .thenThrow(const SocketException('offline'));

      final bloc = LibraryBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadLibrary());

      final state = await settle(bloc);
      expect(state, isA<LibraryLoaded>());
      expect((state as LibraryLoaded).isOffline, isTrue);
    });

    test('cache vide + hors ligne → erreur marquée hors ligne', () async {
      when(() => cacheHelper.getCachedLibrary()).thenAnswer((_) async => []);
      when(() => libraryService.getUserSavedMangas())
          .thenThrow(const SocketException('offline'));

      final bloc = LibraryBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadLibrary());

      final state = await settle(bloc);
      expect(state, isA<LibraryError>());
      expect((state as LibraryError).isOffline, isTrue);
      expect(state.requiresReauth, isFalse);
    });

    test('session rejetée par le serveur → le cache EST servi, avec invite',
        () async {
      // Décision produit 2026-08-31 : « si j\'ai les données en cache, c\'est
      // que j\'étais censé pouvoir les voir ». Un 401 n\'efface plus l\'écran.
      when(() => cacheHelper.getCachedLibrary())
          .thenAnswer((_) async => [manga(1, 'Berserk')]);
      when(() => libraryService.getUserSavedMangas())
          .thenThrow(InvalidCredentialsException('Refresh rejected by server'));

      final bloc = LibraryBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadLibrary());

      final state = await settle(bloc);
      expect(state, isA<LibraryLoaded>());
      expect((state as LibraryLoaded).mangas, hasLength(1));
      expect(state.requiresReauth, isTrue,
          reason: 'invitation à se reconnecter, non bloquante');
      expect(state.isOffline, isFalse,
          reason: 'le serveur répond : ce n\'est pas du hors-ligne');
    });

    test('session rejetée + cache vide → état vide propre, invite conservée',
        () async {
      when(() => cacheHelper.getCachedLibrary()).thenAnswer((_) async => []);
      when(() => libraryService.getUserSavedMangas())
          .thenThrow(InvalidCredentialsException('Refresh rejected by server'));

      final bloc = LibraryBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadLibrary());

      final state = await settle(bloc);
      expect(state, isA<LibraryError>());
      expect((state as LibraryError).requiresReauth, isTrue);
      expect(state.isOffline, isFalse);
    });
  });

  group('LibraryBloc — mutations hors ligne', () {
    test(
        'une mutation qui échoue hors ligne marque isOffline, sans hériter de '
        'l\'état précédent', () async {
      // Chargement initial réussi : isOffline == false dans l'état courant.
      when(() => connectivityService.isConnected).thenReturn(true);
      when(() => cacheHelper.getCachedLibrary()).thenAnswer((_) async => []);
      when(() => libraryService.getUserSavedMangas())
          .thenAnswer((_) async => [manga(1, 'Berserk')]);

      final bloc = LibraryBloc();
      addTearDown(bloc.close);
      bloc.add(const LoadLibrary());
      await bloc.stream.firstWhere(
          (s) => s is LibraryLoaded && !s.isOffline);

      // La connexion tombe pendant la mutation.
      when(() => libraryService.updateMangaStatus(any(), any()))
          .thenThrow(const SocketException('offline'));
      bloc.add(const UpdateMangaStatus(1, ReadingStatus.reading));

      final state = await bloc.stream.firstWhere((s) => s is LibraryError);
      expect((state as LibraryError).isOffline, isTrue,
          reason: 'l\'état réseau doit être ré-évalué, pas hérité');
    });
  });
}
