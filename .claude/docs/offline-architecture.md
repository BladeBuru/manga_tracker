# Documentation : Architecture Offline-First — Manga Tracker Flutter

## Principe général

L'application fonctionne en **offline-first** :
1. Tentative de chargement depuis l'API
2. En cas d'erreur réseau (`SocketException`) → cache
3. Actions utilisateur mises en file d'attente si offline
4. Sync automatique à la reconnexion

---

## Services offline

### `OfflineCacheService`

Cache JSON via `shared_preferences`.

| Clé | Données | TTL |
|-----|---------|-----|
| `cached_library` | `List<MangaQuickViewDto>` | 24h |
| `cached_manga_detail_<muId>` | `MangaDetailsDto` | 24h |
| `cached_homepage` | Données home | 24h |
| `cached_search_<query>` | `List<MangaQuickViewDto>` | 24h |
| `cached_user_info` | `UserInformationDto` | 7 jours |
| `offline_queue` | `List<OfflineAction>` | Persistant |

```dart
// Sauvegarder
await offlineCacheService.saveLibrary(library);
await offlineCacheService.saveMangaDetail(muId, detail);

// Charger
final library = await offlineCacheService.getCachedLibrary();
final detail = await offlineCacheService.getCachedMangaDetail(muId);

// Queue actions offline
await offlineCacheService.queueOfflineAction(action);
final queue = await offlineCacheService.getOfflineQueue();
await offlineCacheService.clearOfflineAction(actionId);
```

---

### `CacheHelperService`

Fallback automatique API → cache.

```dart
try {
  final data = await mangaService.getTrending();
  await offlineCacheService.saveHomePage(data);
  return data;
} on SocketException {
  return await offlineCacheService.getCachedHomePage();
}
```

---

### `SyncService`

Sync automatique à la reconnexion.

- Écoute `ConnectivityBloc` pour détecter la reconnexion
- Traite la queue d'actions offline une par une
- En cas d'échec : action reste dans la queue (retry ultérieur)
- Émet des événements pour mettre à jour les BLoCs

---

### `ConnectivityService`

Détection de la connectivité via `connectivity_plus`.

**Usage** : `SyncService` pour déclencher la sync.
**Ne pas utiliser** pour détecter le mode offline dans les BLoCs (utiliser `SocketException`).

---

## Pattern BLoC offline (OBLIGATOIRE)

```dart
Future<void> _onLoad(LoadEvent event, Emitter<MyState> emit) async {
  emit(MyLoading());
  try {
    final data = await _service.fetchData();
    await _cacheService.saveData(data);
    emit(MyLoaded(data: data, isOffline: false));
  } on SocketException {
    final cached = await _cacheService.getCachedData();
    emit(MyLoaded(data: cached ?? [], isOffline: true));
  } catch (e) {
    emit(MyError(e.toString()));
  }
}
```

---

## Queue d'actions offline

```dart
Future<void> _onAddToLibrary(AddToLibrary event, Emitter<DetailState> emit) async {
  try {
    await _libraryService.addMangaToLibrary(event.muId);
    emit(state.copyWith(isInLibrary: true));
  } on SocketException {
    await _cacheService.queueOfflineAction(
      OfflineAction(
        id: uuid.v4(),
        type: OfflineActionType.addManga,
        payload: {'muId': event.muId},
        createdAt: DateTime.now(),
      ),
    );
    emit(state.copyWith(
      isInLibrary: true,
      isOffline: true,
      pendingActions: state.pendingActions + 1,
    ));
  }
}
```

---

## Indicateur visuel offline (OBLIGATOIRE)

Toujours afficher quand `state.isOffline == true`.

```dart
if (state.isOffline)
  OfflineBanner(pendingActions: state.pendingActions),
```

Composant à créer dans `core/components/offline_banner.dart` (utiliser `AppColors.warning`, `AppSpacing.s` quand dispo, et `context.l10n.offlineMode`).

---

## Cache infos utilisateur (7 jours)

`UserService` utilise un cache spécial avec mise à jour en arrière-plan :

```dart
Future<UserInformationDto> getUserInfo() async {
  final cached = await _cacheService.getCachedUserInfo();

  if (cached != null && !cached.isExpired) {
    if (cached.shouldRefresh) {
      unawaited(_refreshUserInfoInBackground());
    }
    return cached.data;
  }

  return await _fetchAndCacheUserInfo();
}
```

---

## Web — considérations

`shared_preferences` fonctionne sur web (via localStorage). `flutter_secure_storage` aussi (via WebCrypto / IndexedDB). Le pattern offline-first est transposable, mais :

- iOS / Web : pas d'accès au file system général → tout passe par le storage abstrait.
- Pour les téléchargements de chapitres (`download_manager_service.dart`) : à abstraire derrière un service plateforme.
