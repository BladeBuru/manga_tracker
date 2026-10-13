import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/library/services/chapter_progress.service.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/bloc/detail_bloc.dart';
import 'package:mangatracker/features/manga/bloc/detail_event.dart';
import 'package:mangatracker/features/manga/bloc/detail_state.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mocktail/mocktail.dart';

class MockMangaService extends Mock implements MangaService {}

class MockLibraryService extends Mock implements LibraryService {}

class MockChapterReportService extends Mock implements ChapterReportService {}

class MockCacheHelperService extends Mock implements CacheHelperService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockChapterProgressService extends Mock
    implements ChapterProgressService {}

const muId = 151;

MangaDetailDto detail() => MangaDetailDto(
  muId: muId,
  title: 'Solo Leveling',
  year: '2018',
  rating: '9.1',
  totalChapters: 200,
);

MangaQuickViewDto entry(int read) => MangaQuickViewDto(
  muId: muId,
  title: 'Solo Leveling',
  year: '2018',
  rating: '9.1',
  readChapters: read,
  totalChapters: 200,
  readingStatus: ReadingStatus.reading,
);

int? readOf(DetailState state) =>
    (state as DetailLoaded).mangaDetail.readChaptersCount;

/// DetailBloc — un enregistrement refusé ne remplace plus la fiche, et un
/// chargement en vol ne remet plus l'ancienne progression à l'écran.
void main() {
  late MockMangaService mangaService;
  late MockLibraryService libraryService;
  late MockCacheHelperService cacheHelper;
  late MockConnectivityService connectivity;
  late MockChapterProgressService progress;
  late StreamController<bool> connectivityController;
  late StreamController<ChapterProgressChange> changes;
  Completer<void>? libraryGate;
  var libraryRead = 105;

  setUpAll(() {
    registerFallbackValue(ReadingStatus.reading);
  });

  setUp(() {
    mangaService = MockMangaService();
    libraryService = MockLibraryService();
    cacheHelper = MockCacheHelperService();
    connectivity = MockConnectivityService();
    progress = MockChapterProgressService();
    connectivityController = StreamController<bool>.broadcast();
    changes = StreamController<ChapterProgressChange>.broadcast();
    libraryGate = null;
    libraryRead = 105;

    when(() => connectivity.connectivityStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => connectivity.isConnected).thenReturn(true);
    when(() => progress.changes).thenAnswer((_) => changes.stream);
    when(() => cacheHelper.getOfflineQueue())
        .thenAnswer((_) async => <OfflineAction>[]);
    when(() => cacheHelper.getCachedMangaDetail(any()))
        .thenAnswer((_) async => detail());
    when(() => cacheHelper.loadMangaDetail(
          muId: any(named: 'muId'),
          networkCall: any(named: 'networkCall'),
        )).thenAnswer((invocation) async {
      final call = invocation.namedArguments[#networkCall]
          as Future<MangaDetailDto> Function();
      return call();
    });
    when(() => mangaService.getMangaDetail(any()))
        .thenAnswer((_) async => detail());
    when(() => libraryService.getLibraryEntry(any())).thenAnswer((_) async {
      final read = libraryRead;
      final gate = libraryGate;
      if (gate != null) await gate.future;
      return entry(read);
    });
    when(() => libraryService.updateMangaStatus(any(), any()))
        .thenAnswer((_) async => true);

    getIt.registerSingleton<MangaService>(mangaService);
    getIt.registerSingleton<LibraryService>(libraryService);
    getIt.registerSingleton<ChapterReportService>(MockChapterReportService());
    getIt.registerSingleton<CacheHelperService>(cacheHelper);
    getIt.registerSingleton<ConnectivityService>(connectivity);
  });

  tearDown(() async {
    await connectivityController.close();
    await changes.close();
    await getIt.reset();
  });

  void stubSave(ChapterProgressResult result) {
    when(() => progress.save(
          any(),
          any(),
          autoReportIfAboveTotal: any(named: 'autoReportIfAboveTotal'),
          addToLibraryIfMissing: any(named: 'addToLibraryIfMissing'),
          origin: any(named: 'origin'),
        )).thenAnswer((_) async => result);
  }

  /// Fiche chargée (réseau compris) à 105 chapitres lus.
  Future<DetailBloc> loadedBloc() async {
    final bloc = DetailBloc(progressService: progress);
    addTearDown(bloc.close);
    bloc.add(const LoadMangaDetail(muId));
    await bloc.stream.firstWhere((s) => s is DetailLoaded && !s.isStale);
    expect(readOf(bloc.state), 105);
    return bloc;
  }

  test('refus du serveur → la fiche reste chargée, raison typée signalée',
      () async {
    stubSave(const ChapterProgressThrottled());
    final bloc = await loadedBloc();

    bloc.add(const SaveChapterProgress(muId, 124));
    final failed = await bloc.stream.firstWhere((s) => s is DetailActionFailed)
        as DetailActionFailed;

    expect(failed, isA<DetailLoaded>(),
        reason: 'avant : DetailError remplaçait toute la page');
    expect(failed.notice, const ProgressSaveFailed(
      readChapters: 124,
      reason: ChapterProgressThrottled(),
    ));
    expect(failed.mangaDetail.readChaptersCount, 105,
        reason: 'la valeur enregistrée est conservée');
    expect(bloc.state, isNot(isA<DetailError>()));
    verify(() => progress.save(
          muId,
          124,
          autoReportIfAboveTotal: true,
          addToLibraryIfMissing: any(named: 'addToLibraryIfMissing'),
          origin: bloc,
        )).called(1);
  });

  test('session refusée → fiche conservée + invitation à se reconnecter',
      () async {
    stubSave(const ChapterProgressSessionRejected());
    final bloc = await loadedBloc();

    bloc.add(const SaveChapterProgress(muId, 124));
    final failed = await bloc.stream.firstWhere((s) => s is DetailActionFailed)
        as DetailActionFailed;

    expect(failed.requiresReauth, isTrue);
    expect(failed.mangaDetail.readChaptersCount, 105);
  });

  test('deux refus de suite → deux signalements distincts', () async {
    stubSave(const ChapterProgressFailure(statusCode: 503, message: 'HTTP 503'));
    final bloc = await loadedBloc();

    bloc.add(const SaveChapterProgress(muId, 124));
    final first = await bloc.stream.firstWhere((s) => s is DetailActionFailed)
        as DetailActionFailed;
    bloc.add(const SaveChapterProgress(muId, 124));
    final second = await bloc.stream.firstWhere((s) => s is DetailActionFailed)
        as DetailActionFailed;

    expect(second.attempt, isNot(first.attempt));
  });

  test('enregistré → nouvelle progression affichée', () async {
    stubSave(const ChapterProgressSaved());
    final bloc = await loadedBloc();

    bloc.add(const SaveChapterProgress(muId, 124));
    final saved = await bloc.stream.firstWhere(
      (s) => s is DetailLoaded && readOf(s) == 124,
    );

    expect(saved, isNot(isA<DetailActionFailed>()));
  });

  test('un chargement en vol ne remet pas l\'ancienne progression', () async {
    stubSave(const ChapterProgressSaved());
    final bloc = await loadedBloc();
    final states = <DetailState>[];
    final sub = bloc.stream.listen(states.add);

    // Rechargement lancé, réponse bibliothèque (105) retenue…
    libraryGate = Completer<void>();
    bloc.add(const RefreshMangaDetail());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // …pendant que l'utilisateur enregistre 124.
    bloc.add(const SaveChapterProgress(muId, 124));
    await bloc.stream.firstWhere((s) => s is DetailLoaded && readOf(s) == 124);

    // La réponse périmée arrive APRÈS l'enregistrement.
    libraryGate!.complete();
    libraryGate = null;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(readOf(bloc.state), 124,
        reason: 'avant : le chargement réaffichait 105');
    final after124 =
        states.skipWhile((s) => s is! DetailLoaded || readOf(s) != 124);
    expect(after124.where((s) => s is DetailLoaded && readOf(s) == 105),
        isEmpty);
  });

  test('progression enregistrée ailleurs (lecture partagée) → fiche relue',
      () async {
    final bloc = await loadedBloc();
    clearInteractions(mangaService);
    libraryRead = 124;

    changes.add(ChapterProgressChange(muId: muId, readChapters: 124,
        origin: Object()));
    await bloc.stream.firstWhere((s) => s is DetailLoaded && readOf(s) == 124);

    verify(() => mangaService.getMangaDetail(any())).called(1);
  });

  test('ses propres enregistrements ne déclenchent pas de rechargement',
      () async {
    final bloc = await loadedBloc();
    clearInteractions(mangaService);

    changes.add(ChapterProgressChange(muId: muId, readChapters: 124,
        origin: bloc));
    changes.add(const ChapterProgressChange(muId: 999, readChapters: 3));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    verifyNever(() => mangaService.getMangaDetail(any()));
  });

  test('note refusée → note d\'avant rétablie et échec signalé', () async {
    when(() => libraryService.updateRating(any(), any()))
        .thenAnswer((_) async => false);
    final bloc = await loadedBloc();

    bloc.add(const UpdateUserRating(muId, 8));
    final failed = await bloc.stream.firstWhere((s) => s is DetailActionFailed)
        as DetailActionFailed;

    expect(failed.notice, const RatingSaveFailed(rating: 8, offline: false));
    expect(failed.mangaDetail.userRating, 0);
  });
}
