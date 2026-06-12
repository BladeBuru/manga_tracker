# Plan de Remédiation — Manga Tracker

## Stratégie

La remédiation suit quatre priorités dans l'ordre : (P0) sécurité et conformité légale non-négociables, (P1) blockers cross-platform iOS/Web qui conditionnent la roadmap, (P2) couverture de tests et découpage des mega-fichiers pour retrouver une maintenabilité acceptable, (P3) dette mineure traitée en opportunité lors des développements futurs. Les actions P0 et P1 sont des prérequis aux nouvelles features — elles doivent précéder tout investissement dans iOS ou Web.

---

## Phase 1 — Corrections critiques / P0 Sécurité + Conformité (Sprint 1)

| # | Action | Feature | Effort estimé | Prérequis |
|---|--------|---------|--------------|-----------|
| 1.1 | **RGPD — Vérifier et compléter le re-consentement dans `StartupPage._onLoginSuccess()`** : confirmer que `GdprService.getConsentStatus()` est appelé après chaque auto-login réussi ; si absent, l'ajouter avec le même comportement bloquant que `BottomNavbar` (ADR RETRO-003). Documenter le flux complet auth → RGPD dans un test d'intégration. | auth | S | Aucun |
| 1.2 | **Sécurité — Externaliser le `serverClientId` Google** hors du source code versionné : déplacer `43781664315-...` dans `assets/env/.env.production` (pattern déjà utilisé pour `MT_API_URL`), le charger via `flutter_dotenv` ou les GitHub Secrets CI. Invalider/renouveler la clé si elle a été exposée dans un repo public. | auth | XS | Rotation de clé côté Google Cloud Console |
| 1.3 | **Sécurité — Garder les `debugPrint` derrière `kDebugMode`** dans `AuthService` et `BiometricService` (25+ occurrences) : wrapper chaque `debugPrint` avec `if (kDebugMode) { debugPrint(...); }` ou supprimer les plus verbeux. Ne jamais logger `jsonCreds != null`, les attempts biométriques ni les payloads JWT. | auth | S | 1.2 |

---

## Phase 2 — Blockers cross-platform / P1 iOS + Web (Sprint 2)

| # | Action | Feature | Effort estimé | Prérequis |
|---|--------|---------|--------------|-----------|
| 2.1 | **Abstraire `workmanager` derrière une interface** `BackgroundTaskService` dans `lib/core/services/` : créer l'interface avec `scheduleChapterCheck()` / `cancelChapterCheck()`, implémenter `WorkManagerBackgroundTaskServiceIo` (Android) et un stub no-op Web + un stub iOS vide (à compléter avec BGTaskScheduler lors du sprint iOS). Enregistrer via le ServiceLocator avec switch sur `defaultTargetPlatform`. | manga, download | M | Aucun (prérequis de tout sprint iOS/Web) |
| 2.2 | **Compléter le fallback Darwin iOS pour `flutter_local_notifications`** : dans le service de notifications, ajouter `DarwinInitializationSettings` avec les permissions `requestAlertPermission`, `requestBadgePermission`, `requestSoundPermission`. Tester sur simulateur iOS que les notifications de nouveaux chapitres et de demandes d'amitié se déclenchent. | manga, friends | S | 2.1 |
| 2.3 | **Migrer `GoogleAuthWebView` vers go_router** : remplacer le `Navigator.push(MaterialPageRoute(...))` restant par `context.push('/auth/google')` ou `context.pushNamed(...)`. Seule exception non-conformité navigation identifiée. | auth | XS | Aucun |

---

## Phase 3 — Découpage des mega-fichiers et testabilité / P2 Maintenabilité (Sprints 3-4)

### 3a. Découpage des fichiers critiques (> 400 lignes)

| # | Action | Feature | Effort estimé | Prérequis |
|---|--------|---------|--------------|-----------|
| 3.1 | **Découper `detail_bloc_view.dart` (1317 lignes)** : utiliser le skill `/refactor-large-file`. Extraire au minimum `_DetailHeader`, `_DetailBottomBar`, `_DetailModals` (dialogs status/rating/link) et `_DetailActionHandlers` (BlocConsumer.listener). Objectif : fichier principal < 200 lignes, fichiers extraits < 150. | manga | L | Aucun |
| 3.2 | **Découper `web_view_io.dart` (1173 lignes)** : extraire `_AdBlockerBridge` (injection JS), `_CaptchaHandler`, `_ChapterProgressTracker`, `_ScrollRestorer` comme classes privées ou mixins. Le `StatefulWidget` principal ne doit contenir que l'orchestration (`InAppWebView` + callbacks de haut niveau). | reader | L | Aucun |
| 3.3 | **Découper `detail_bloc.dart` (780 lignes, seuil 200)** : extraire les handlers en méthodes privées dans des mixins (`_LibraryMutationMixin`, `_ChapterProgressMixin`, `_RatingMixin`), ou dans une classe `DetailBlocHandlers` séparée. Injecter les services au constructeur (au lieu de `getIt` direct). | manga | M | 3.1 |
| 3.4 | **Découper `ad_blocker_service.dart` (834 lignes)** : extraire `ContentBlockerBuilder`, `JsInjector`, et `InteractiveSelectorManager` comme services spécialisés. | reader | M | 3.2 |
| 3.5 | **Découper `late_detail.view.dart` (816 lignes)** : extraire `_ChaptersBlock`, `_SynopsisSection`, `_AssociatedNamesSection` comme widgets privés dans des fichiers dédiés sous `lib/features/manga/widgets/`. | manga | M | 3.1 |
| 3.6 | **Découper `library_bloc.dart` (386 lignes, seuil 200)** : extraire `_LibraryMutationHandlers` et `_NewChaptersEnricher` comme méthodes privées ou helpers. | library | S | Aucun |
| 3.7 | **Découper `scroll_position_service.dart` (418 lignes)** : extraire `_CookiePersistenceHelper` et `_ScrollPositionStore` comme classes privées. | reader | S | 3.2 |
| 3.8 | **Découper les widgets social > 300 lignes** : `create_reading_group_sheet.dart` (451), `share_manga_sheet.dart` (391), `user_search_field.dart` (331) — extraire les sections de formulaire en sous-widgets privés. | sharing, friends | S | Aucun |

### 3b. Migration injection vers constructeur

| # | Action | Feature | Effort estimé | Prérequis |
|---|--------|---------|--------------|-----------|
| 3.9 | **Migrer `StatsBloc` et `StatsService`** pour injecter `HttpService` et `StorageService` au constructeur plutôt que via `getIt<>()` dans le corps. Ajuster l'instanciation dans `StatsView`. | stats | XS | Aucun |
| 3.10 | **Migrer `FriendsBloc`** : injecter `FriendsService` et `NotificationService` au constructeur. Enregistrer `NotificationService` dans GetIt si pas déjà fait (remplacer `NotificationService()` direct). | friends | S | Aucun |
| 3.11 | **Migrer `ReadingGroupsBloc`** : injecter `ReadingGroupsService` au constructeur au lieu de `getIt<>()` dans le corps. | sharing | XS | Aucun |

### 3c. Couverture de tests

| # | Action | Feature | Effort estimé | Prérequis |
|---|--------|---------|--------------|-----------|
| 3.12 | **Tests auth services** : `AuthService.refreshAccessToken` (tristate, verrou Completer), `GdprService.getConsentStatus` + `recordConsent`, `StartupPage` machine d'état. | auth | M | 1.1, 3.3 |
| 3.13 | **Tests HomePageBloc** : stale-while-revalidate, chargement parallèle, bascule offline. | home | M | 3.6 |
| 3.14 | **Tests LibraryBloc** : mutations online, mutations offline (queue), enrichissement new chapters. | library | M | 3.6 |
| 3.15 | **Tests DetailBloc** : LoadMangaDetail cache/réseau, AddToLibrary optimiste, UpdateUserRating rollback. | manga | M | 3.3 |
| 3.16 | **Tests StatsBloc et StatsService** : cache frais, cache expiré, erreur réseau → stale. | stats | S | 3.9 |
| 3.17 | **Tests FriendsBloc** : LoadFriends, SearchUsers debounce guard, RespondToRequest. | friends | S | 3.10 |
| 3.18 | **Tests CommentsBloc** : LoadComments pagination, PostComment optimiste, DeleteComment. | comments | S | 3.11 |

---

## Phase 4 — Amélioration continue / P3 Dette mineure (Sprints 5+)

| # | Action | Feature | Effort estimé | Prérequis |
|---|--------|---------|--------------|-----------|
| 4.1 | **i18n genres populaires** : remplacer les genres hardcodés dans `search.dart` par des clés ARB dans les 7 fichiers de langue (ou charger dynamiquement depuis un endpoint API). | search | XS | Aucun |
| 4.2 | **Ajouter `toJson()` à `FriendshipDto`** et unifier la sérialisation cache dans `FriendsService` (remplacer le mapping manuel). | friends | XS | Aucun |
| 4.3 | **Persister `_notifiedShareIds`** dans `SharedPreferences` pour éviter le spam de notifications après redémarrage. | sharing, friends | XS | Aucun |
| 4.4 | **Export RGPD article 20 via fichier** : implémenter `path_provider` + `share_plus` pour livrer le JSON de données utilisateur comme un vrai fichier téléchargeable plutôt que via le presse-papier. | profile | S | Aucun |
| 4.5 | **Migrer `deleteAccount` vers `GdprService`** pour regrouper tous les droits article 17 au même endroit (cohérence avec ADR RETRO-029). | profile | XS | Aucun |
| 4.6 | **Supprimer les vues legacy** : `home_page.dart` et `library.view.dart` non référencés par le router. Confirmer qu'aucun test ou chemin de navigation ne les référence avant suppression. | home, library | XS | Aucun |
| 4.7 | **Corriger le `ConnectivitySubscription` vide** dans `HomePageBloc` : implémenter la reconnexion automatique (dispatch `LoadHomePage`) ou supprimer le listener mort. | home | XS | Aucun |
| 4.8 | **Remplacer la couleur hardcodée** `Color(0xffb8b8d2)` dans `BottomNavbar` par un token `AppColors`. | home | XS | Aucun |
| 4.9 | **Normaliser le cache stats** : migrer `StatsService` vers `CacheHelperService` (pattern du reste du projet) au lieu de `flutter_secure_storage` direct. | stats | S | 3.9 |
| 4.10 | **Corriger `imageCount`** dans `DownloadedChapter` : mettre à jour le champ après le téléchargement des images ou le retirer du modèle s'il n'est pas utilisé. | download | XS | Aucun |
| 4.11 | **Cache offline pour les features sociales** : ajouter un cache 24h pour `FriendsService.getFriends()` (déjà partiellement présent), compléter avec un fallback stale pour les demandes en attente et le compteur de shares non vus. | friends, sharing | M | 3.10 |
| 4.12 | **Normaliser la gestion d'erreurs dans les BLoCs** : standardiser sur `SocketException` explicite pour les erreurs réseau (remplacer les `Exception` génériques), documenter la convention dans CLAUDE.md. Ajouter un service de crash reporting (ex: Sentry) pour la visibilité production. | Toutes | M | 3.12-3.18 |

---

## Dépendances entre actions

```
1.1 (RGPD StartupPage)
  └── doit précéder → 3.12 (tests auth services)

1.2 (serverClientId externalisation)
  └── doit précéder → 1.3 (debugPrint)

2.1 (WorkManager abstraction)
  └── doit précéder → 2.2 (notifications iOS)
  └── est prérequis de → tout sprint iOS/Web

3.1 (découper detail_bloc_view)
  └── facilite → 3.3 (découper detail_bloc)
  └── facilite → 3.5 (découper late_detail.view)
  └── facilite → 3.15 (tests DetailBloc)

3.3 (découper detail_bloc)
  └── doit précéder → 3.15 (tests DetailBloc)

3.6 (découper library_bloc)
  └── doit précéder → 3.14 (tests LibraryBloc)

3.9 (migrer StatsBloc injection)
  └── doit précéder → 3.16 (tests StatsBloc)
  └── doit précéder → 4.9 (normaliser cache stats)

3.10 (migrer FriendsBloc injection)
  └── doit précéder → 3.17 (tests FriendsBloc)
  └── doit précéder → 4.11 (cache offline friends)

3.11 (migrer ReadingGroupsBloc injection)
  └── doit précéder → 3.18 (tests CommentsBloc/Sharing)
```

### Ordre absolu (actions ne pouvant pas être parallélisées)

1. `1.1` → `1.2` → `1.3` (sécurité/RGPD en séquence)
2. `2.1` → `2.2` (abstraction avant notifications iOS)
3. `3.1` → `3.3` → `3.15` (découpage manga en cascade)
4. `3.9` → `3.16` (stats : injection puis tests)
5. `3.10` → `3.17` → `4.11` (friends : injection, tests, cache)

### Actions parallélisables au sein d'un sprint

- `3.6` + `3.8` + `3.9` + `3.11` peuvent être faites en parallèle (fichiers distincts)
- `3.12` + `3.13` + `3.14` peuvent être faites en parallèle après leurs prérequis respectifs
- `4.1` + `4.2` + `4.3` + `4.6` + `4.7` + `4.8` + `4.10` sont indépendants et peuvent être traités à tout moment en opportunité
