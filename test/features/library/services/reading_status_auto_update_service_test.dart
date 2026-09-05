import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/auth/exceptions/invalid_credentials.exception.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/library/services/reading_status_auto_update.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mocktail/mocktail.dart';

class MockLibraryService extends Mock implements LibraryService {}

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

MangaQuickViewDto entry(
  int muId, {
  ReadingStatus status = ReadingStatus.caughtUp,
  num read = 39,
  num? reported,
}) =>
    MangaQuickViewDto(
      muId: muId,
      title: 'Manga $muId',
      year: '2020',
      rating: '8.0',
      readingStatus: status,
      readChapters: read,
      totalChapters: 39,
      userReportedTotalChapters: reported,
    );

void main() {
  late MockLibraryService library;
  late MockOfflineCacheService cache;
  late ReadingStatusAutoUpdateService service;

  setUpAll(() {
    registerFallbackValue(ReadingStatus.reading);
    registerFallbackValue(<MangaQuickViewDto>[]);
  });

  setUp(() {
    library = MockLibraryService();
    cache = MockOfflineCacheService();
    when(() => library.updateMangaStatus(any(), any()))
        .thenAnswer((_) async => true);
    when(() => cache.cacheLibrary(any())).thenAnswer((_) async {});
    when(() => cache.getCachedLibrary()).thenAnswer((_) async => null);
    getIt.registerSingleton<LibraryService>(library);
    getIt.registerSingleton<OfflineCacheService>(cache);
    service = ReadingStatusAutoUpdateService();
  });

  tearDown(() => getIt.reset());

  group('reconcileLibrary — bibliothèque + chapitres détectés localement', () {
    test('« à jour » + chapitre 40 détecté → « en cours », un seul appel réseau',
        () async {
      final result = await service.reconcileLibrary(
        [entry(42)],
        {42: [40]},
      );

      expect(result.single.readingStatus, ReadingStatus.reading);
      expect(result.single.hasNewChapters, isTrue);
      verify(() => library.updateMangaStatus(42, ReadingStatus.reading))
          .called(1);
      // Le cache hors ligne reflète la bascule pour un rechargement sans réseau.
      verify(() => cache.cacheLibrary(any(that: predicate<List<MangaQuickViewDto>>(
          (l) => l.single.readingStatus == ReadingStatus.reading)))).called(1);
    });

    test('pas de doublon : une seconde réconciliation (cache puis réseau) ne rappelle pas le serveur',
        () async {
      await service.reconcileLibrary([entry(42)], {42: [40]});
      // Le réseau renvoie encore « à jour » (PUT pas encore visible / en file).
      final again = await service.reconcileLibrary([entry(42)], {42: [40]});

      expect(again.single.readingStatus, ReadingStatus.reading,
          reason: 'l\'entrée doit continuer d\'apparaître « en cours »');
      verify(() => library.updateMangaStatus(42, ReadingStatus.reading))
          .called(1);
    });

    test('une fois confirmée par l\'API (« en cours »), une bascule ultérieure redevient possible',
        () async {
      await service.reconcileLibrary([entry(42)], {42: [40]});
      // L'API a appliqué la bascule, puis l'utilisateur se remet « à jour »
      // au 40 ; le 41 sort ensuite.
      await service.reconcileLibrary(
          [entry(42, status: ReadingStatus.reading, read: 40)], const {});
      await service.reconcileLibrary([entry(42, read: 40)], {42: [41]});

      verify(() => library.updateMangaStatus(42, ReadingStatus.reading))
          .called(2);
    });

    test('« en cours » reste « en cours », sans appel réseau', () async {
      final result = await service.reconcileLibrary(
        [entry(42, status: ReadingStatus.reading)],
        {42: [40]},
      );

      expect(result.single.readingStatus, ReadingStatus.reading);
      expect(result.single.hasNewChapters, isTrue);
      verifyNever(() => library.updateMangaStatus(any(), any()));
      verifyNever(() => cache.cacheLibrary(any()));
    });

    test('« à lire plus tard » et « terminé » ne bougent pas', () async {
      final result = await service.reconcileLibrary(
        [
          entry(1, status: ReadingStatus.readLater),
          entry(2, status: ReadingStatus.completed),
        ],
        {1: [40], 2: [40]},
      );

      expect(result[0].readingStatus, ReadingStatus.readLater);
      expect(result[1].readingStatus, ReadingStatus.completed);
      verifyNever(() => library.updateMangaStatus(any(), any()));
    });

    test('« à jour » sans nouveau chapitre ne bouge pas', () async {
      final result = await service.reconcileLibrary([entry(42)], const {});

      expect(result.single.readingStatus, ReadingStatus.caughtUp);
      expect(result.single.hasNewChapters, isFalse);
      verifyNever(() => library.updateMangaStatus(any(), any()));
    });

    test('les champs non concernés sont conservés (signalement communautaire)',
        () async {
      final result = await service.reconcileLibrary(
        [entry(42, reported: 45)],
        {42: [40]},
      );

      expect(result.single.userReportedTotalChapters, 45);
      expect(result.single.readChapters, 39);
    });

    test('session rejetée → l\'entrée apparaît « en cours » mais la demande n\'est pas mémorisée',
        () async {
      when(() => library.updateMangaStatus(any(), any()))
          .thenThrow(InvalidCredentialsException('403'));

      final first = await service.reconcileLibrary([entry(42)], {42: [40]});
      final second = await service.reconcileLibrary([entry(42)], {42: [40]});

      expect(first.single.readingStatus, ReadingStatus.reading);
      expect(second.single.readingStatus, ReadingStatus.reading);
      // Nouvelle tentative au chargement suivant (rien n'a abouti).
      verify(() => library.updateMangaStatus(42, ReadingStatus.reading))
          .called(2);
    });
  });

  group('onNewChapterDetected — vérification en arrière-plan / fiche détail',
      () {
    test('« à jour » + chapitre détecté → serveur prévenu et cache patché',
        () async {
      when(() => cache.getCachedLibrary())
          .thenAnswer((_) async => [entry(42), entry(7)]);

      final flipped = await service.onNewChapterDetected(
        muId: 42,
        status: ReadingStatus.caughtUp,
        readChapters: 39,
        chapter: 40,
      );

      expect(flipped, isTrue);
      verify(() => library.updateMangaStatus(42, ReadingStatus.reading))
          .called(1);
      final cached = verify(() => cache.cacheLibrary(captureAny()))
          .captured
          .single as List<MangaQuickViewDto>;
      expect(cached.firstWhere((m) => m.muId == 42).readingStatus,
          ReadingStatus.reading);
      expect(cached.firstWhere((m) => m.muId == 7).readingStatus,
          ReadingStatus.caughtUp,
          reason: 'seule l\'entrée concernée est patchée');
    });

    test('« en cours » → rien (ni réseau, ni cache)', () async {
      final flipped = await service.onNewChapterDetected(
        muId: 42,
        status: ReadingStatus.reading,
        readChapters: 39,
        chapter: 40,
      );

      expect(flipped, isFalse);
      verifyNever(() => library.updateMangaStatus(any(), any()));
      verifyNever(() => cache.getCachedLibrary());
    });

    test('même manga signalé deux fois (arrière-plan puis fiche) → un seul appel réseau',
        () async {
      await service.onNewChapterDetected(
          muId: 42, status: ReadingStatus.caughtUp, readChapters: 39, chapter: 40);
      await service.onNewChapterDetected(
          muId: 42, status: ReadingStatus.caughtUp, readChapters: 39, chapter: 40);

      verify(() => library.updateMangaStatus(42, ReadingStatus.reading))
          .called(1);
    });

    test('cache absent → pas de plantage', () async {
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => null);

      await expectLater(
        service.onNewChapterDetected(
            muId: 42, status: ReadingStatus.caughtUp, readChapters: 39, chapter: 40),
        completion(isTrue),
      );
      verifyNever(() => cache.cacheLibrary(any()));
    });
  });
}
