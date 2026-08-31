# Documentation : Architecture Offline-First — Manga Tracker Flutter

## Principe général

L'application fonctionne en **offline-first** :
1. Tentative de chargement depuis l'API
2. En cas d'échec **classé comme repli légitime** → cache (voir ci-dessous)
3. Actions utilisateur mises en file d'attente si offline
4. Sync automatique à la reconnexion

---

## ⚠️ Détection d'échec : `classifyFailure`, PAS `on SocketException`

> **Changement 2026-08-31.** La règle historique « détecter le hors-ligne via
> `SocketException` » était fausse sur deux plans et rendait le mode hors
> ligne inutilisable. Elle est remplacée par une classification centralisée.

Pourquoi l'ancienne règle ne marchait pas :

- **Un token expiré ne produit pas de `SocketException`.** `HttpService` lève
  une exception d'authentification sur un chemin d'erreur totalement
  différent, qui ne déclenchait donc jamais le repli sur le cache.
- **`on SocketException` est du code mort sur le web.** `network_compat_web.dart`
  n'expose qu'un *stub* jamais levé : sur web, `package:http` lève
  `ClientException`.

Toute la détection passe désormais par `lib/core/network/failure_classifier.dart` :

```dart
enum FailureMode { network, sessionExpired, sessionRejected, other }

FailureMode classifyFailure(Object error);
bool allowsCachedRead(FailureMode mode);      // tout sauf sessionRejected
bool showsOfflineIndicator(FailureMode mode); // network | sessionExpired
```

| Mode | Déclenché par | Cache servi ? | Bandeau ? |
|------|---------------|---------------|-----------|
| `network` | `SocketException` (mobile), `ClientException` (web), `TimeoutException` | ✅ | ✅ |
| `sessionExpired` | `SessionExpiredException` — tokens expirés localement ou refresh impossible faute de réseau | ✅ | ✅ |
| `sessionRejected` | `InvalidCredentialsException`, `InvalidTokenException` — **verdict explicite du serveur** (401/403) | ❌ | ❌ (→ login) |
| `other` | 5xx, parsing, bug | ✅ | ❌ |

---

## 🔒 Frontière de sécurité (à ne pas déplacer sans y réfléchir)

Le mode hors ligne assouplit la **lecture du cache**, **jamais**
l'authentification.

- **Lecture** : autorisée dès qu'on n'a pas pu joindre le serveur — y compris
  avec des tokens expirés. C'est le cas d'usage explicite : consulter hors
  connexion ce qu'on a déjà vu (« savoir où j'en suis dans le train »). Aucune
  donnée nouvelle n'est révélée : le cache ne contient que ce que cet
  utilisateur avait déjà obtenu en étant authentifié.
- **Écriture** : toujours refusée sans session valide. Les mutations partent
  dans la file d'attente hors ligne et ne sont appliquées côté serveur qu'après
  un refresh réussi.
- **Rejet explicite du serveur** : si l'API répond 401/403, l'appareil est
  joignable — donc l'utilisateur *peut* se reconnecter. La session est morte,
  le cache n'est pas servi et l'écran redirige vers le login (drapeau
  `requiresLogin` sur les états d'erreur). Sans ça, l'utilisateur naviguerait
  dans ses données en croyant être connecté.
- Un refresh est retenté dès que le réseau revient (`SyncService`).

`SessionExpiredException` (tokens expirés, **sans** verdict serveur) et
`InvalidCredentialsException` (verdict serveur) sont deux types distincts
précisément pour porter cette frontière dans le système de types.

---

## Signification de `isOffline`

`isOffline == true` signifie : **« ce que tu vois vient du cache local, faute
d'avoir pu joindre le serveur »**. C'est cette définition — et pas
« le socket est fermé » — qui rend le bandeau déterministe d'un écran à
l'autre.

Conséquences appliquées partout :

- L'état est **ré-évalué** à chaque échec via `classifyFailure`. Ne jamais
  hériter `isOffline` de l'état précédent (`state.copyWith` sur un échec de
  mutation) : une action qui échoue parce que la connexion vient de tomber
  doit afficher le bandeau.
- Les états `*ActionInProgress` portent `isOffline` **et les vues doivent le
  lire**, sinon le bandeau disparaît pendant chaque mutation.
- Si l'appareil se sait déjà hors ligne (`ConnectivityService.isConnected ==
  false`), le rendu optimiste du cache pose `isOffline: true` immédiatement,
  au lieu d'attendre l'échec réseau.

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

`CacheHelperService` écrit le cache quand le réseau répond et **relaie**
l'exception : c'est le BLoC qui décide du repli, parce que lui seul sait quel
état émettre.

```dart
try {
  final data = await mangaService.getTrending();
  await offlineCacheService.saveHomePage(data);
  return data;
} catch (e) {
  rethrow; // le BLoC classe l'échec et décide
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

**Usage** :
- `SyncService`, pour déclencher la sync à la reconnexion ;
- pour afficher le bandeau **immédiatement** quand l'appareil se sait déjà
  déconnecté, avant même la première requête.

**Ne pas s'en servir seul pour conclure qu'on est en ligne** : un wifi de train
captif rapporte « connecté » alors que rien ne passe. La vérité vient de
l'échec réel, classé par `classifyFailure`.

---

## Pattern BLoC offline (OBLIGATOIRE)

```dart
Future<void> _onLoad(LoadEvent event, Emitter<MyState> emit) async {
  emit(MyLoading());
  try {
    final data = await _service.fetchData();
    await _cacheService.saveData(data);
    emit(MyLoaded(data: data, isOffline: false));
  } catch (e) {
    final mode = classifyFailure(e);

    // Verdict explicite du serveur : login, sans servir le cache.
    if (!allowsCachedRead(mode)) {
      emit(MyError('Authentification requise', requiresLogin: true));
      return;
    }

    // Hors ligne OU session expirée : on sert ce que l'utilisateur a déjà vu.
    final offline = showsOfflineIndicator(mode);
    final cached = await _cacheService.getCachedData();
    if (cached != null && cached.isNotEmpty) {
      emit(MyLoaded(data: cached, isOffline: offline, stale: true));
    } else {
      emit(MyError(e.toString(), isOffline: offline)); // état vide, pas un crash
    }
  }
}
```

**Interdits** (chacun a causé un bug en production) :
- `on SocketException` comme seul filet → code mort sur web, rate les tokens.
- `e.toString().contains('...Exception')` → minifié par dart2js en release web.
- `return` avant le repli cache sur une erreur d'authentification.
- Un handler de mutation qui n'émet **rien** sur un chemin d'erreur → le bloc
  reste bloqué sur `*ActionInProgress` et l'écran affiche un spinner sans issue.

---

## Queue d'actions offline

La mise en file est faite par `LibraryService` (qui renvoie `true` quand
l'action est mise en attente). Le BLoC, lui, doit surtout **toujours émettre un
état**, y compris sur le chemin d'échec :

```dart
Future<void> _onAddToLibrary(AddToLibrary event, Emitter<DetailState> emit) async {
  final current = state as DetailLoaded;
  emit(DetailActionInProgress(mangaDetail: current.mangaDetail, action: '...'));
  try {
    await _libraryService.addMangaToLibrary(event.muId); // met en queue si offline
    emit(current.copyWith(isOffline: !_connectivity.isConnected));
  } catch (e) {
    // INVARIANT : ne jamais sortir sans emit, sinon spinner infini.
    final mode = classifyFailure(e);
    if (allowsCachedRead(mode)) {
      emit(current.copyWith(
        isOffline: showsOfflineIndicator(mode),
        pendingActions: current.pendingActions + 1,
      ));
    } else {
      emit(DetailError(message: e.toString(), requiresLogin: true));
    }
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

Composant : `core/components/offline_banner.dart` (`AppColors.warning`,
`AppSpacing.s`, `context.l10n.offlineMode`).

**Couvrir tous les états qui portent `isOffline`**, y compris
`*ActionInProgress` — c'est l'oubli de cet état qui faisait « clignoter » le
bandeau pendant les mutations.

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
