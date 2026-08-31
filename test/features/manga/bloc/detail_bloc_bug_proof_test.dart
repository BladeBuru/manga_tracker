// PROOF-OF-BUG (temporaire) — sera remplacé par detail_bloc_offline_test.dart.
//
// Reproduit le bug rapporté : « si le token n'est pas valide, ça ne l'affiche
// pas » sur le détail d'un manga, alors qu'un détail EST en cache.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
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

void main() {
  test('token expiré + hors ligne → le détail en cache DOIT être affiché',
      () async {
    const muId = 42;
    final cached = MangaDetailDto(
      muId: muId,
      title: 'Solo Leveling',
      year: '2018',
      rating: '9.1',
      totalChapters: 179,
    );

    final mangaService = MockMangaService();
    final libraryService = MockLibraryService();
    final cacheHelper = MockCacheHelperService();
    final connectivityService = MockConnectivityService();
    final controller = StreamController<bool>.broadcast();

    when(() => connectivityService.connectivityStream)
        .thenAnswer((_) => controller.stream);
    when(() => connectivityService.isConnected).thenReturn(false);
    when(() => libraryService.getLibraryEntry(any()))
        .thenAnswer((_) async => null);
    when(() => cacheHelper.getOfflineQueue())
        .thenAnswer((_) async => <OfflineAction>[]);
    when(() => cacheHelper.getCachedMangaDetail(muId))
        .thenAnswer((_) async => cached);
    when(() => cacheHelper.loadMangaDetail(
          muId: any(named: 'muId'),
          networkCall: any(named: 'networkCall'),
        )).thenAnswer((invocation) async {
      final networkCall = invocation.namedArguments[#networkCall]
          as Future<MangaDetailDto> Function();
      return networkCall();
    });
    // Exactement ce que HttpService lève quand les deux tokens sont expirés.
    when(() => mangaService.getMangaDetail(any()))
        .thenThrow(InvalidCredentialsException('Both tokens expired'));

    getIt.registerSingleton<MangaService>(mangaService);
    getIt.registerSingleton<LibraryService>(libraryService);
    getIt.registerSingleton<ChapterReportService>(MockChapterReportService());
    getIt.registerSingleton<CacheHelperService>(cacheHelper);
    getIt.registerSingleton<ConnectivityService>(connectivityService);

    final bloc = DetailBloc();
    bloc.add(const LoadMangaDetail(muId));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = bloc.state;

    await bloc.close();
    await controller.close();
    await getIt.reset();

    expect(state, isA<DetailLoaded>(),
        reason: 'le détail en cache doit rester affiché hors ligne');
    expect((state as DetailLoaded).isOffline, isTrue);
  });
}
