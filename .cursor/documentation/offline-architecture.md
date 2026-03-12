# Documentation : Architecture Offline-First — Manga Tracker Flutter

## Principe général

L'application fonctionne en mode **offline-first** :
1. Tentative de chargement depuis l'API
2. En cas d'erreur réseau (`SocketException`) → chargement depuis le cache
3. Actions utilisateur mises en file d'attente si offline
4. Synchronisation automatique à la reconnexion

---

## Services offline

### `OfflineCacheService`

Gère le cache des données en JSON via `shared_preferences`.

**Clés de cache disponibles** :

| Clé | Données | TTL |
|-----|---------|-----|
| `cached_library` | `List<MangaQuickViewDto>` | 24h |
| `cached_manga_detail_<muId>` | `MangaDetailsDto` | 24h |
| `cached_homepage` | Données home (populaires + tendances + nouveaux) | 24h |
| `cached_search_<query>` | `List<MangaQuickViewDto>` | 24h |
| `cached_user_info` | `UserInformationDto` | 7 jours |
| `offline_queue` | `List<OfflineAction>` | Persistant |

**Méthodes principales** :
```dart
// Sauvegarder
await offlineCacheService.saveLibrary(library);
await offlineCacheService.saveMangaDetail(muId, detail);
await offlineCacheService.saveHomePage(homeData);
await offlineCacheService.saveUserInfo(userInfo);

// Charger
final library = await offlineCacheService.getCachedLibrary();
final detail = await offlineCacheService.getCachedMangaDetail(muId);
final userInfo = await offlineCacheService.getCachedUserInfo();

// Queue actions offline
await offlineCacheService.queueOfflineAction(action);
final queue = await offlineCacheService.getOfflineQueue();
await offlineCacheService.clearOfflineAction(actionId);
```

---

### `CacheHelperService`

Helper avec fallback automatique API → cache.

```dart
// Chargement avec fallback automatique
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

Synchronisation automatique à la reconnexion internet.

- Écoute `ConnectivityBloc` pour détecter la reconnexion
- Traite la queue d'actions offline une par une
- En cas d'échec : l'action reste dans la queue (retry ultérieur)
- Émet des événements pour mettre à jour les BLoCs concernés

---

### `ConnectivityService`

Détection de la connectivité via `connectivity_plus`.

**Usage** : Utilisé par `SyncService` pour déclencher la synchronisation.
**Ne pas utiliser** pour détecter le mode offline dans les BLoCs (utiliser `SocketException`).

---

## Pattern BLoC offline (OBLIGATOIRE)

```dart
Future<void> _onLoad(LoadEvent event, Emitter<MyState> emit) async {
  emit(MyLoading());
  try {
    // 1. Appel API
    final data = await _service.fetchData();
    // 2. Mise en cache systématique
    await _cacheService.saveData(data);
    // 3. État online
    emit(MyLoaded(data: data, isOffline: false));
  } on SocketException {
    // 4. Fallback vers le cache
    final cached = await _cacheService.getCachedData();
    // 5. État offline (peut être null si jamais chargé)
    emit(MyLoaded(data: cached ?? [], isOffline: true));
  } catch (e) {
    emit(MyError(e.toString()));
  }
}
```

---

## Queue d'actions offline

Quand l'utilisateur effectue une action (ajout/suppression manga, mise à jour statut) en mode offline :

```dart
// Dans le BLoC
Future<void> _onAddToLibrary(AddToLibrary event, Emitter<DetailState> emit) async {
  try {
    await _libraryService.addMangaToLibrary(event.muId);
    emit(state.copyWith(isInLibrary: true));
  } on SocketException {
    // Mettre en queue pour sync ultérieure
    await _cacheService.queueOfflineAction(
      OfflineAction(
        id: uuid.v4(),
        type: OfflineActionType.addManga,
        payload: {'muId': event.muId},
        createdAt: DateTime.now(),
      ),
    );
    // Mise à jour optimiste de l'UI
    emit(state.copyWith(
      isInLibrary: true,
      isOffline: true,
      pendingActions: state.pendingActions + 1,
    ));
  }
}
```

---

## Affichage du mode offline (OBLIGATOIRE)

Toujours afficher un indicateur visuel quand `state.isOffline == true` :

```dart
// Dans la view
if (state.isOffline)
  OfflineBanner(pendingActions: state.pendingActions),

// Composant réutilisable (à créer dans core/components/)
class OfflineBanner extends StatelessWidget {
  final int pendingActions;

  const OfflineBanner({super.key, this.pendingActions = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            context.l10n.offlineMode,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
          if (pendingActions > 0) ...[
            const SizedBox(width: 4),
            Text(
              '· $pendingActions ${context.l10n.pendingActions}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Cache des informations utilisateur (7 jours)

`UserService` utilise un cache spécial de 7 jours avec mise à jour en arrière-plan :

```dart
Future<UserInformationDto> getUserInfo() async {
  final cached = await _cacheService.getCachedUserInfo();

  if (cached != null && !cached.isExpired) {
    // Retourner le cache immédiatement
    // Mettre à jour en arrière-plan si > 1h
    if (cached.shouldRefresh) {
      unawaited(_refreshUserInfoInBackground());
    }
    return cached.data;
  }

  // Charger depuis l'API si cache expiré ou absent
  return await _fetchAndCacheUserInfo();
}
```
