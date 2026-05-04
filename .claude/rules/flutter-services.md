# Services & Architecture — Manga Tracker Flutter

> Snippet injecté quand vous éditez un fichier dans `lib/.../services/` ou `lib/core/service_locator/`.

## Pattern Service (OBLIGATOIRE)

```dart
// Les services ne connaissent PAS le BuildContext, les BLoCs ou les widgets.
class LibraryService {
  final HttpService _httpService;
  final OfflineCacheService _cacheService;

  LibraryService({
    required HttpService httpService,
    required OfflineCacheService cacheService,
  })  : _httpService = httpService,
        _cacheService = cacheService;

  Future<List<MangaQuickViewDto>> getUserLibrary() async {
    final response = await _httpService.getWithAuthTokens('/api/library');
    final library = (response as List)
        .map((e) => MangaQuickViewDto.fromJson(e as Map<String, dynamic>))
        .toList();
    await _cacheService.saveLibrary(library);
    return library;
  }
}
```

## 🆕 Cross-platform abstraction (évolution iOS/Web)

Tout service qui touche à une API plateforme **doit** être derrière une interface :

```dart
// ❌ MAUVAIS — direct, ne marche que sur Android
class NotificationService {
  final _plugin = AndroidFlutterLocalNotificationsPlugin();
  // ...
}

// ✅ BON — interface + impl conditionnelle
abstract class NotificationService {
  Future<void> init();
  Future<void> show({required String title, required String body});
}

class AndroidNotificationService implements NotificationService { ... }
class IOSNotificationService implements NotificationService { ... }
class WebNotificationService implements NotificationService { ... }

// service_locator.dart
final NotificationService impl = switch (defaultTargetPlatform) {
  TargetPlatform.android => AndroidNotificationService(),
  TargetPlatform.iOS => IOSNotificationService(),
  _ => WebNotificationService(),
};
getIt.registerSingleton<NotificationService>(impl);
```

Application au codebase actuel :

| Service actuel | Plateforme | À abstraire |
|----------------|-----------|-------------|
| `notification_service.dart` (`AndroidFlutterLocalNotificationsPlugin`) | Android-only | Oui (Darwin pour iOS, web Push API pour Web) |
| `chapter_check_background_service.dart` (`workmanager`) | Android-only | Oui (BGTaskScheduler iOS, service worker web) |
| Téléchargements (`dart:io`) | Android natif | Oui (`path_provider` + abstraction) |

## Services existants

### Core Services
| Service | Rôle | Enregistrement |
|---------|------|---------------|
| `HttpService` | Requêtes HTTP avec JWT auto-refresh | Singleton |
| `StorageService` | flutter_secure_storage wrapper | Async singleton |
| `OfflineCacheService` | Cache des données (JSON) | Singleton |
| `CacheHelperService` | Fallback API → cache automatique | Singleton |
| `SyncService` | Sync des actions offline à la reconnexion | Singleton |
| `ConnectivityService` | Détection connectivité | Async singleton |

### Feature Services
| Service | Rôle | Enregistrement |
|---------|------|---------------|
| `AuthService` | Login/register/refresh token | Singleton |
| `MangaService` | Récupération des mangas | Singleton |
| `LibraryService` | Bibliothèque CRUD | Async singleton |
| `UserService` | Profil utilisateur (cache 7j) | Singleton |
| `LanguageService` | Langue + persistance | Singleton |
| `AppUpdateService` | Vérification mises à jour, changelog | Singleton |

## HttpService — Utilisation

```dart
final response = await _httpService.getWithAuthTokens('/api/mangas/trending');
final body = await _httpService.postWithAuthTokens(
  '/api/library',
  body: {'muId': muId},
);
await _httpService.deleteWithAuthTokens('/api/library/$muId');
await _httpService.putWithAuthTokens(
  '/api/library/$muId/status',
  body: {'readingStatus': status.name},
);
```

- Refresh automatique du JWT — transparent
- 401 → refresh → retry
- Lève `InvalidTokenException` si refresh échoue

## OfflineCacheService — Clés

| Clé | Données | Expiration |
|-----|---------|-----------|
| `cached_library` | Bibliothèque utilisateur | 24h |
| `cached_manga_detail_<muId>` | Détails d'un manga | 24h |
| `cached_homepage` | Page d'accueil | 24h |
| `cached_search_<query>` | Résultats de recherche | 24h |
| `cached_user_info` | Infos utilisateur | 7 jours |
| `offline_queue` | Queue d'actions offline | Persistant |

## Limite

**MAX 300 lignes** par service. Si dépassement → extraire un service spécialisé (voir skill `/refactor-large-file`).

## Enregistrement GetIt — Ordre d'initialisation

```dart
Future<void> setupServiceLocator() async {
  // 1. Storage (async)
  getIt.registerSingletonAsync<StorageService>(() async {
    final service = StorageService();
    await service.init();
    return service;
  });
  await getIt.isReady<StorageService>();

  // 2. Auth (dépend de Storage)
  getIt.registerSingleton<AuthService>(
    AuthService(storageService: getIt<StorageService>()),
  );

  // 3. HTTP (dépend de Storage + Auth)
  getIt.registerSingleton<HttpService>(
    HttpService(
      storageService: getIt<StorageService>(),
      authService: getIt<AuthService>(),
    ),
  );

  // ... continuer dans l'ordre des dépendances
}
```

**Règle** : ne jamais enregistrer un service avant ses dépendances.

## DTOs — Pattern

```dart
class MangaQuickViewDto {
  final String muId;
  final String title;
  final String? coverUrl;

  const MangaQuickViewDto({
    required this.muId,
    required this.title,
    this.coverUrl,
  });

  factory MangaQuickViewDto.fromJson(Map<String, dynamic> json) {
    return MangaQuickViewDto(
      muId: json['muId'] as String,
      title: json['title'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'muId': muId,
    'title': title,
    if (coverUrl != null) 'coverUrl': coverUrl,
  };
}
```

## Exceptions personnalisées

```dart
class InvalidCredentialsException implements Exception {
  final String message;
  const InvalidCredentialsException([this.message = 'Invalid credentials']);
  @override
  String toString() => message;
}

class InvalidTokenException implements Exception {}

if (response.statusCode == 401) {
  throw const InvalidCredentialsException();
}
```
