import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/services/library_index_service.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mocktail/mocktail.dart';

class MockOfflineCacheService extends Mock implements OfflineCacheService {}

MangaQuickViewDto manga(num muId) => MangaQuickViewDto(
      muId: muId,
      title: 'Titre $muId',
      year: '2014',
      rating: '8.0',
    );

/// Index « deja dans ma bibliotheque » : appartenance depuis le cache local,
/// mise a jour apres ajout / retrait, cache vide, et purge (deconnexion).
void main() {
  late MockOfflineCacheService cache;

  LibraryIndexService buildIndex() => LibraryIndexService(cache: cache);

  setUp(() {
    cache = MockOfflineCacheService();
  });

  void stubLibrary(List<MangaQuickViewDto>? library) =>
      when(() => cache.getCachedLibrary()).thenAnswer((_) async => library);

  test('appartenance lue depuis le cache local, sans appel reseau', () async {
    stubLibrary([manga(101), manga(202)]);
    final index = buildIndex();

    expect(index.contains(101), isFalse, reason: 'rien avant chargement');
    await index.ensureLoaded();

    expect(index.contains(101), isTrue);
    expect(index.contains(202), isTrue);
    expect(index.contains(303), isFalse);
    expect(index.ownedMuIds, {101, 202});
  });

  test('un muId decimal et son entier designent le meme titre', () async {
    stubLibrary([manga(101.0)]);
    final index = buildIndex();
    await index.ensureLoaded();

    expect(index.contains(101), isTrue);
    expect(index.contains(101.0), isTrue);
  });

  test('cache vide ou absent : index vide, aucune erreur', () async {
    stubLibrary(null);
    final index = buildIndex();
    await index.ensureLoaded();
    expect(index.ownedMuIds, isEmpty);

    when(() => cache.getCachedLibrary()).thenThrow(Exception('trousseau ko'));
    final broken = buildIndex();
    await broken.ensureLoaded();
    expect(broken.ownedMuIds, isEmpty);
  });

  test('ensureLoaded ne relit le cache qu\'une fois, refresh le force',
      () async {
    stubLibrary([manga(101)]);
    final index = buildIndex();

    await Future.wait([index.ensureLoaded(), index.ensureLoaded()]);
    await index.ensureLoaded();
    verify(() => cache.getCachedLibrary()).called(1);

    stubLibrary([manga(101), manga(102)]);
    await index.refresh();
    expect(index.contains(102), isTrue);
  });

  test('ajout puis retrait : l\'index suit et notifie ses ecouteurs', () async {
    stubLibrary([manga(101)]);
    final index = buildIndex();
    await index.ensureLoaded();

    var notifications = 0;
    index.listenable.addListener(() => notifications++);

    index.setOwned(303, owned: true);
    expect(index.contains(303), isTrue);
    expect(notifications, 1);

    // Idempotent : re-affirmer un etat deja vrai ne notifie pas.
    index.setOwned(303, owned: true);
    expect(notifications, 1);

    index.setOwned(303, owned: false);
    expect(index.contains(303), isFalse);
    expect(notifications, 2);
  });

  test('reecriture du cache bibliotheque : l\'index est remplace', () async {
    stubLibrary([manga(101)]);
    final index = buildIndex();
    await index.ensureLoaded();

    index.setFromLibrary([manga(202), manga(303)]);
    expect(index.ownedMuIds, {202, 303});
    expect(index.contains(101), isFalse, reason: 'plus en bibliotheque');
  });

  test('purge (deconnexion) : index vide ET relecture au prochain besoin',
      () async {
    stubLibrary([manga(101)]);
    final index = buildIndex();
    await index.ensureLoaded();
    expect(index.contains(101), isTrue);

    // Ce que `purgeUserScopedCache()` envoie a l'observateur.
    index.setFromLibrary(null);
    expect(index.ownedMuIds, isEmpty);

    // Compte suivant : le cache est relu, l'ancien index n'est pas garde.
    stubLibrary([manga(999)]);
    await index.ensureLoaded();
    expect(index.contains(101), isFalse);
    expect(index.contains(999), isTrue);
    verify(() => cache.getCachedLibrary()).called(2);
  });
}
