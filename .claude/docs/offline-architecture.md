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
bool showsOfflineIndicator(FailureMode mode); // network | sessionExpired
bool requiresReauthPrompt(FailureMode mode);  // sessionRejected
```

> `allowsCachedRead()` **n'existe plus** (supprimé le 2026-08-31, et non passé
> à `true`, pour qu'aucun appelant ne puisse rebrancher un refus de lecture par
> mégarde). Le cache est servi dans tous les modes.

| Mode | Déclenché par | Cache servi ? | Bandeau |
|------|---------------|---------------|---------|
| `network` | `SocketException` (mobile), `ClientException` (web), `TimeoutException` | oui | hors ligne |
| `sessionExpired` | `SessionExpiredException` — tokens expirés localement ou refresh impossible faute de réseau | oui | hors ligne |
| `sessionRejected` | `InvalidCredentialsException`, `InvalidTokenException` — **verdict explicite du serveur** (401/403) | oui | **reconnexion** (non bloquant) |
| `other` | 5xx, parsing, bug | oui | aucun |

Les deux bandeaux sont distincts **à dessein** : sur `sessionRejected`
l'appareil EST joignable, afficher « hors ligne » serait un mensonge.

---

## 🔒 Frontière de sécurité

> **Décision produit du 2026-08-31.** Mots du propriétaire :
> « **L'authentification ne peut pas empêcher le fait de voir mes données. Si
> j'ai les données qui sont en cache, c'est que j'étais censé pouvoir les
> voir.** »

Le mode hors ligne assouplit la **lecture du cache**, **jamais** l'écriture.

### Lecture — assouplie à tous les modes d'échec

Le cache est servi **quel que soit l'échec**, rejet serveur (401/403) compris.

Pourquoi c'est sûr : le cache local ne contient que ce que **cet** utilisateur
avait déjà obtenu **en étant authentifié**. Le lui réafficher ne révèle rien de
nouveau. Un écran vide ou une redirection forcée ne protégeait aucune donnée —
elle masquait seulement ce qu'il avait déjà légitimement vu.

Sur `sessionRejected`, l'écran affiche `SessionRejectedBanner` : une invitation
**non bloquante** à se reconnecter, par-dessus le contenu resté consultable.
Le drapeau d'état s'appelle `requiresReauth` (ex-`requiresLogin`, renommé parce
que l'ancien nom portait une redirection qui n'existe plus).

❌ **Ne jamais rebrancher un `Navigator.push('/login')` sur ce drapeau.**

### Écriture — inchangée

Toute mutation exige une session valide :

| Situation | Comportement |
|-----------|--------------|
| Hors ligne / réseau KO | mise en **file d'attente** (`offline_queue`), rejouée par `SyncService` |
| Session **rejetée** (401/403) | **refusée**, l'exception remonte — *pas* de mise en file |
| En ligne, session valide | appliquée normalement |

Une mutation dont la session est morte n'est **jamais** mise en file : ce serait
un faux succès, `SyncService` la rejouant indéfiniment sans jamais aboutir.
C'est le rôle de `LibraryService._queueUnlessRejected()`.

Corollaire : un 403 sur `/library` lève `InvalidCredentialsException` (et non
une `Exception` nue, qui se classait à tort en `FailureMode.other` et faisait
donc mettre en file un vrai refus serveur).

### 🔑 Contrepartie : la déconnexion purge le cache

**C'est cette purge qui rend l'assouplissement acceptable.** Sans elle, sur un
appareil partagé — ou après un changement de compte — le cache de l'utilisateur
précédent resterait consultable par le suivant. Ce serait, cette fois, une
vraie fuite.

`OfflineCacheService.purgeUserScopedCache()`
(`core/services/offline_cache_purge.dart`) efface les clés exactes **et** les
familles préfixées, que le code ne peut pas énumérer à l'avance :

| Clé / famille | Contenu |
|---------------|---------|
| `cached_library` | bibliothèque |
| `cached_manga_detail_<muId>` | fiches manga consultées |
| `cached_homepage` | accueil |
| `cached_search_<query>` | résultats de recherche |
| `cached_user_info` | profil |
| `cached_recommendations` / `_exhaustive` | recommandations |
| `cached_user_stats` / `_at` | statistiques |
| `cached_friends` / `_at` | amis |
| `offline_queue` | actions en attente |
| `last_sync_timestamp`, `cache_metadata` | métadonnées |
| `cache_owner_id` | propriétaire du cache |

Le balayage du préfixe `cached_` ramasse aussi les caches tenus **hors** de ce
service. `secure_credentials` (biométrie) survit volontairement : se reconnecter
ne doit pas imposer de retaper son mot de passe.

**Toute nouvelle clé de cache utilisateur doit être ajoutée à
`userScopedExactKeys`, ou porter le préfixe `cached_`.**

### ⚠️ Deux chemins à ne surtout pas confondre

| Méthode | Quand | Tokens | Cache |
|---------|-------|--------|-------|
| `AuthService.logout()` | déconnexion **voulue** : profil, suppression de compte, refus RGPD | effacés | **purgé** |
| `AuthService.clearSessionTokens()` | invalidation **automatique** : 401 dans `HttpService`, refresh rejeté au boot | effacés | **conservé** |

Purger dans le chemin automatique annulerait toute la décision produit : c'est
précisément le moment où l'on veut continuer à servir le cache.

### Changement de compte

`cache_owner_id` porte le `sub` du JWT. À chaque connexion réussie,
`adoptCacheOwner()` compare :

- **même utilisateur** → cache conservé (pas de refetch inutile) ;
- **utilisateur différent** → purge, puis adoption ;
- **propriétaire inconnu / identité illisible** → purge par défaut. Sur un
  appareil partagé, le doute profite à la confidentialité.

`SessionExpiredException` (tokens expirés, **sans** verdict serveur) et
`InvalidCredentialsException` (verdict serveur) restent deux types distincts :
ils ne servent plus à autoriser ou refuser le cache, mais à choisir **quel
bandeau** afficher, et à refuser les écritures.

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
| `cache_owner_id` | `sub` du JWT propriétaire du cache | Persistant |

Toutes ces clés sont purgées à la déconnexion (cf. frontière de sécurité).

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

    // Le cache est servi dans TOUS les modes, rejet serveur compris.
    final offline = showsOfflineIndicator(mode);
    final reauth = requiresReauthPrompt(mode);

    final cached = await _cacheService.getCachedData();
    if (cached != null && cached.isNotEmpty) {
      emit(MyLoaded(
        data: cached, isOffline: offline, stale: true, requiresReauth: reauth));
    } else {
      // État vide propre, pas un crash — l'invite de reconnexion subsiste.
      emit(MyError(e.toString(), isOffline: offline, requiresReauth: reauth));
    }
  }
}
```

**Interdits** (chacun a causé un bug en production) :
- `on SocketException` comme seul filet → code mort sur web, rate les tokens.
- `e.toString().contains('...Exception')` → minifié par dart2js en release web.
- `return` avant le repli cache sur une erreur d'authentification.
- Rebrancher une redirection `/login` sur `requiresReauth` → re-masque du
  contenu que l'utilisateur a déjà vu.
- Appeler `logout()` depuis un chemin d'invalidation automatique → purge le
  cache au moment exact où il fallait le servir.
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
    // ÉCRITURE : une session rejetée ne met RIEN en file et n'applique rien
    // localement — sinon SyncService rejouerait indéfiniment une action qui
    // ne peut pas aboutir.
    if (!requiresReauthPrompt(mode)) {
      emit(current.copyWith(
        isOffline: showsOfflineIndicator(mode),
        pendingActions: current.pendingActions + 1,
      ));
    } else {
      emit(DetailError(message: e.toString(), requiresReauth: true));
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

// Session rejetée : invitation, jamais redirection.
if (state.requiresReauth)
  SessionRejectedBanner(onReconnect: () => context.push('/login')),
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
