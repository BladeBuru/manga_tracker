import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/offline_cache_service.dart';
import 'package:mangatracker/core/storage/services/storage.service.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/biometric.service.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

class MockBiometricService extends Mock implements BiometricService {}

/// Trousseau en memoire cable sur le mock (cf. offline_cache_purge_test).
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

const _userCacheKeys = <String>[
  'cached_library',
  'cached_manga_detail_42',
  'cached_homepage',
  'cached_search_naruto',
  'cached_user_info',
  'cached_user_stats',
  'offline_queue',
  'cache_metadata',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStorageService storage;
  late Map<String, String> store;
  late AuthService auth;

  setUp(() {
    storage = MockStorageService();
    store = wireStorage(storage);

    getIt.registerSingleton<StorageService>(storage);
    getIt.registerSingleton<BiometricService>(MockBiometricService());
    // Vrai OfflineCacheService : `purgeUserScopedCache` est une extension,
    // donc non stubbable — on exerce le vrai chemin de purge, ce qui est de
    // toute facon ce qu'on veut prouver ici.
    getIt.registerSingleton<OfflineCacheService>(
      OfflineCacheService()..initialize(),
    );

    auth = AuthService();

    store['accessToken'] = 'access';
    store['refreshToken'] = 'refresh';
    store['secure_credentials'] = '{"email":"a@b.c","password":"x"}';
    for (final key in _userCacheKeys) {
      store[key] = 'donnees-utilisateur-precedent';
    }
  });

  tearDown(() => getIt.reset());

  group('AuthService.logout — deconnexion explicite', () {
    test('purge les tokens ET toutes les cles de cache utilisateur', () async {
      await auth.logout();

      expect(store['accessToken'], isNull);
      expect(store['refreshToken'], isNull);
      for (final key in _userCacheKeys) {
        expect(store.containsKey(key), isFalse,
            reason: 'la cle "$key" survit a la deconnexion — sur un appareil '
                'partage, elle resterait lisible par l\'utilisateur suivant');
      }
    });

    test('conserve les identifiants biometriques', () async {
      await auth.logout();
      expect(store['secure_credentials'], isNotNull);
    });
  });

  group('AuthService.clearSessionTokens — invalidation automatique', () {
    test('efface les tokens mais CONSERVE le cache', () async {
      // Chemin du 401 intercepte par HttpService et du refresh rejete au
      // demarrage. Purger ici annulerait la decision produit : c'est
      // precisement quand la session meurt qu'on veut encore pouvoir
      // afficher ce que l'utilisateur a deja consulte.
      await auth.clearSessionTokens();

      expect(store['accessToken'], isNull);
      expect(store['refreshToken'], isNull);
      for (final key in _userCacheKeys) {
        expect(store[key], isNotNull,
            reason: 'un 401 ne doit PAS purger "$key" : le cache doit rester '
                'servi, avec une invitation a se reconnecter');
      }
    });
  });
}
