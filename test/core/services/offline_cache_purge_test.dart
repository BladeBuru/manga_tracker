import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_purge.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

/// Trousseau en memoire, cable sur le mock : `purgeUserScopedCache()` balaie
/// des familles de cles prefixees, il faut donc que `secureKeys()` reponde
/// vraiment ce que le cache contient.
Map<String, String> wireStorage(MockStorageService storage) {
  final store = <String, String>{};

  when(() => storage.secureKeys()).thenAnswer((_) async => store.keys.toList());
  when(() => storage.readSecureData(any()))
      .thenAnswer((i) async => store[i.positionalArguments[0] as String]);
  when(() => storage.writeSecureData(any(), any())).thenAnswer((i) async {
    store[i.positionalArguments[0] as String] =
        i.positionalArguments[1] as String;
  });
  when(() => storage.deleteSecureData(any())).thenAnswer((i) async {
    store.remove(i.positionalArguments[0] as String);
  });

  return store;
}

/// Etat typique d'un appareil apres usage : bibliotheque, deux fiches manga
/// consultees, l'accueil, une recherche, le profil, les recos, les stats, les
/// amis, la file d'attente et les metadonnees.
const _userCacheKeys = <String>[
  'cached_library',
  'cached_manga_detail_42',
  'cached_manga_detail_7',
  'cached_homepage',
  'cached_search_naruto',
  'cached_search_one_piece',
  'cached_user_info',
  'cached_recommendations',
  'cached_recommendations_exhaustive',
  'cached_user_stats',
  'cached_user_stats_at',
  'cached_friends',
  'cached_friends_at',
  'offline_queue',
  'last_sync_timestamp',
  'cache_metadata',
  'cache_owner_id',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService storage;
  late Map<String, String> store;
  late OfflineCacheService cache;

  setUp(() {
    storage = MockStorageService();
    store = wireStorage(storage);
    getIt.registerSingleton<StorageService>(storage);
    cache = OfflineCacheService()..initialize();

    for (final key in _userCacheKeys) {
      store[key] = 'donnees-utilisateur-precedent';
    }
    // Ne doivent PAS partir avec la purge.
    store['secure_credentials'] = '{"email":"a@b.c","password":"x"}';
    store['app_theme_mode'] = 'dark';
  });

  tearDown(() => getIt.reset());

  group('purgeUserScopedCache — contrepartie du cache servi sur 401', () {
    test('efface TOUTES les cles de cache utilisateur, une par une', () async {
      await cache.purgeUserScopedCache();

      // Cle par cle : une purge partielle laisserait les donnees du
      // precedent utilisateur lisibles sur un appareil partage.
      for (final key in _userCacheKeys) {
        expect(store.containsKey(key), isFalse,
            reason: 'la cle "$key" doit etre purgee a la deconnexion');
        verify(() => storage.deleteSecureData(key)).called(greaterThan(0));
      }
      expect(store.keys.where((k) => k.startsWith('cached_')), isEmpty);
    });

    test('conserve les identifiants biometriques et les preferences', () async {
      await cache.purgeUserScopedCache();

      // La biometrie survit volontairement : se reconnecter ne doit pas
      // imposer de retaper son mot de passe.
      expect(store['secure_credentials'], isNotNull);
      expect(store['app_theme_mode'], 'dark');
      verifyNever(() => storage.deleteSecureData('secure_credentials'));
    });

    test('ramasse un detail manga et une recherche jamais enumeres', () async {
      // Ces familles sont a cardinalite variable : le code ne peut pas
      // connaitre a l'avance les muId ni les requetes mis en cache.
      store['cached_manga_detail_999'] = 'x';
      store['cached_search_berserk'] = 'x';

      await cache.purgeUserScopedCache();

      expect(store.containsKey('cached_manga_detail_999'), isFalse);
      expect(store.containsKey('cached_search_berserk'), isFalse);
    });

    test('un trousseau vide ne fait pas echouer la purge', () async {
      store.clear();
      await expectLater(cache.purgeUserScopedCache(), completes);
    });
  });

  group('adoptCacheOwner — changement de compte', () {
    test('meme utilisateur → le cache est CONSERVE', () async {
      store[OfflineCacheService.ownerIdKey] = 'user-1';

      await cache.adoptCacheOwner('user-1');

      expect(store['cached_library'], isNotNull,
          reason: 'se reconnecter avec le meme compte ne doit rien refetch');
      expect(store[OfflineCacheService.ownerIdKey], 'user-1');
    });

    test('utilisateur different → purge, puis adoption', () async {
      store[OfflineCacheService.ownerIdKey] = 'user-1';

      await cache.adoptCacheOwner('user-2');

      for (final key in _userCacheKeys) {
        if (key == OfflineCacheService.ownerIdKey) continue;
        expect(store.containsKey(key), isFalse,
            reason: 'cache du compte precedent encore lisible via "$key"');
      }
      expect(store[OfflineCacheService.ownerIdKey], 'user-2');
    });

    test('proprietaire inconnu → purge par defaut', () async {
      // Cache anterieur au marqueur : on ne peut pas prouver que c'est le
      // meme utilisateur, le doute profite a la confidentialite.
      store.remove(OfflineCacheService.ownerIdKey);

      await cache.adoptCacheOwner('user-2');

      expect(store.containsKey('cached_library'), isFalse);
      expect(store[OfflineCacheService.ownerIdKey], 'user-2');
    });

    test('identite illisible → purge, sans adopter', () async {
      await cache.adoptCacheOwner(null);

      expect(store.containsKey('cached_library'), isFalse);
      expect(store.containsKey(OfflineCacheService.ownerIdKey), isFalse);
    });
  });
}
