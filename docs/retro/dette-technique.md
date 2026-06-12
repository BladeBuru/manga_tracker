# Dette Technique — Manga Tracker

> Classement par criticité : CRITIQUE > MAJEUR > MINEUR
> Sources : discovery.md, 13 specs techniques, 18 ADRs RETRO, vérification des tailles de fichiers.

---

## CRITIQUE — À corriger immédiatement

| # | Description | Feature | Fichier(s) | Impact |
|---|------------|---------|-----------|--------|
| C-1 | `GdprService.getConsentStatus()` absent dans `StartupPage._onLoginSuccess()` — le re-consentement RGPD est déclenché par `BottomNavbar.initState` (ADR RETRO-003) mais PAS dans la machine d'état de démarrage. Si un utilisateur atteignait `/home` via un flux qui bypass BottomNavbar (ex: deep link post-vérification email), le checkpoint RGPD ne serait pas vérifié. L'ADR RETRO-003 documente explicitement ce risque comme "zone d'incertitude". | auth | `lib/features/auth/views/startup_page.dart` | Non-conformité RGPD article 7 — exposition CNIL |
| C-2 | `serverClientId` Google OAuth hardcodé dans le source (`43781664315-4qruuj7eek7j71meh9ccl398r9k20a6k.apps.googleusercontent.com`) — visible dans le dépôt git et extractable du binaire APK compilé. | auth | `lib/features/auth/services/auth.service.dart` (ligne ~414) | Sécurité — clé OAuth exposée |
| C-3 | `workmanager` (Android-only) utilisé sans interface abstraite pour la vérification périodique des chapitres en arrière-plan — bloque la compilation iOS et rend le build Web non fonctionnel sur ce chemin. Documenté ADR RETRO-011 mais non résolu. | manga, download | `lib/features/manga/services/chapter_check_background_service.dart` (et fichier `_io.dart`) | Bloque roadmap iOS et Web |
| C-4 | `detail_bloc_view.dart` dépasse 1317 lignes (seuil critique projet : 400 lignes). Widget non testable, non lisible, viole toutes les règles de découpage du CLAUDE.md. | manga | `lib/features/manga/views/detail_bloc_view.dart` | Maintenabilité et testabilité bloquées |
| C-5 | `web_view_io.dart` dépasse 1173 lignes (seuil critique : 400). StatefulWidget monolithique portant l'ad-blocker, la navigation, le scroll, et la progression. | reader | `lib/features/manga/views/web_view_io.dart` | Maintenabilité et testabilité bloquées |
| C-6 | `detail_bloc.dart` dépasse 780 lignes (seuil BLoC : 200 lignes). Le BLoC orchestre 9 events et plusieurs services directement instanciés dans son constructeur. | manga | `lib/features/manga/bloc/detail_bloc.dart` | Maintenabilité et testabilité bloquées |
| C-7 | `ad_blocker_service.dart` dépasse 834 lignes (seuil service : 300 lignes). Service monolithique gérant les ContentBlockers, JS injection, mode interactif, et liste de domaines. | reader | `lib/features/reader/services/ad_blocker_service.dart` | Maintenabilité et testabilité bloquées |

---

## MAJEUR — À planifier dans les 2 prochains sprints

| # | Description | Feature | Fichier(s) | Impact |
|---|------------|---------|-----------|--------|
| M-1 | 25+ `debugPrint` avec emoji non gardés par `kDebugMode` dans `AuthService` et `BiometricService` — émettent en production. Certains contiennent `jsonCreds != null` (test de présence de credentials) et les tentatives d'authentification biométrique. | auth | `lib/features/auth/services/auth.service.dart`, `lib/features/auth/services/biometric.service.dart` | Fuite d'informations en production, violation RGPD potentielle |
| M-2 | Couverture de tests insuffisante : 7 fichiers de tests pour 13 features. Aucun test pour home, library, reader, download, search, profile, stats, friends, sharing, comments. CLAUDE.md exige min 1 widget test + 1 BLoC test par feature. | Toutes | `test/` — absents | Régression non détectée, blocage Play Store quality |
| M-3 | `flutter_local_notifications` : les canaux de notification Android sont configurés mais le fallback `DarwinInitializationSettings` pour iOS est incomplet — les notifications de nouveaux chapitres ne fonctionneront pas sur iOS. | manga, friends | `lib/core/services/notification_service.dart` (ou équivalent) | Bloque les notifications iOS |
| M-4 | Features sociales (friends, sharing) et comments sans cache offline — contraire au pattern offline-first du reste de l'application. Une perte réseau sur ces pages produit une erreur sans fallback. | friends, sharing, comments | `lib/features/friends/services/friends.service.dart`, `lib/features/sharing/services/sharing.service.dart`, `lib/features/comments/services/comments.service.dart` | Expérience utilisateur dégradée, incohérence architecturale |
| M-5 | Injection via `getIt<>()` dans le corps des BLoCs récents (pas au constructeur) : `StatsBloc`, `FriendsBloc`, `CommentsBloc`, `ReadingGroupsBloc`. Rend les tests unitaires impossibles sans configurer GetIt complet. Pattern documenté comme dette dans les 4 specs techniques. | stats, friends, sharing, comments | `lib/features/stats/bloc/stats_bloc.dart`, `lib/features/friends/bloc/friends_bloc.dart`, `lib/features/sharing/bloc/reading_groups_bloc.dart`, `lib/features/comments/bloc/comments_bloc.dart` | Testabilité bloquée sur les features récentes |
| M-6 | `late_detail.view.dart` dépasse 816 lignes (seuil widget : 150). Vue scrollable portant chapitres, synopsis, notes, recommandations, et commentaires. | manga | `lib/features/manga/views/late_detail.view.dart` | Maintenabilité et testabilité |
| M-7 | `library_bloc.dart` dépasse 386 lignes (seuil BLoC : 200). Le BLoC gère 8 events avec les mutations bibliothèque, l'enrichissement new chapters, et la logique stale. | library | `lib/features/library/bloc/library_bloc.dart` | Maintenabilité |
| M-8 | `scroll_position_service.dart` dépasse 418 lignes (seuil service : 300). | reader | `lib/features/reader/services/scroll_position_service.dart` | Maintenabilité |
| M-9 | `homepage_bloc_view.dart` dépasse 386 lignes (seuil widget : 150). | home | `lib/features/home/views/homepage_bloc_view.dart` | Maintenabilité |
| M-10 | `create_reading_group_sheet.dart` dépasse 451 lignes (seuil widget : 150). `share_manga_sheet.dart` dépasse 391 lignes. `user_search_field.dart` dépasse 331 lignes. | sharing, friends | `lib/features/sharing/widgets/create_reading_group_sheet.dart`, `lib/features/sharing/widgets/share_manga_sheet.dart`, `lib/features/friends/widgets/user_search_field.dart` | Maintenabilité |
| M-11 | `NotificationService` instancié directement (pas via GetIt) dans `FriendsBloc` — brise le principe de Service Locator du projet et rend le mocking impossible. | friends | `lib/features/friends/bloc/friends_bloc.dart` | Testabilité, incohérence architecturale |
| M-12 | Gestion d'erreurs hétérogène dans les BLoCs : certains catchent `SocketException` explicitement (HomePageBloc, LibraryBloc), d'autres catchent `Exception` générique (CommentsBloc). Pas de crash reporting centralisé (aucun service d'analytics ou crash tracking). | Toutes | Tous les fichiers `_bloc.dart` | Visibilité des erreurs en production |
| M-13 | `GoogleAuthWebView` utilise `MaterialPageRoute` au lieu de `go_router` — exception non documentée à la règle de navigation du projet. | auth | `lib/features/auth/views/google_auth_webview.dart` | Incohérence navigation, blocage deep-linking web |
| M-14 | Update optimiste dans `CommentsBloc` (post/delete) sans rollback automatique en cas d'erreur serveur — la liste peut rester désynchronisée jusqu'au prochain rechargement complet. | comments | `lib/features/comments/bloc/comments_bloc.dart` | Cohérence des données affichées |
| M-15 | `auth.service.dart` dépasse 519 lignes (seuil service : 300). Service orchestrateur qui gère JWT, Google, biométrie, refresh, logout — candidat à la décomposition en services spécialisés. | auth | `lib/features/auth/services/auth.service.dart` | Maintenabilité |

---

## MINEUR — À traiter en opportunité

| # | Description | Feature | Fichier(s) | Impact |
|---|------------|---------|-----------|--------|
| m-1 | Genres populaires hardcodés en français dans `_SearchState._popularGenres` sans i18n (`['Shounen', 'Seinen', 'Romance', ...]`) — contredit la règle i18n du CLAUDE.md (7 langues). | search | `lib/features/search/views/search.dart` | Expérience non localisée |
| m-2 | `FriendshipDto` sans `toJson()` — sérialisation cache via mapping manuel dans `FriendsService._writeCache()`. Si le DTO évolue, le cache peut se désérialiser avec des valeurs manquantes silencieusement. | friends | `lib/features/friends/dto/friend.dto.dart`, `lib/features/friends/services/friends.service.dart` | Fragilité du cache |
| m-3 | Anti-doublon notifications (`Set<int> _notifiedShareIds` dans NotificationCountsService) non persisté sur disque — après redémarrage, les shares récents non vus peuvent re-déclencher des notifications locales. | sharing, friends | `lib/core/services/notification_counts_service.dart` | Spam de notifications post-redémarrage |
| m-4 | Export de données RGPD article 20 via presse-papier uniquement — insuffisant pour une conformité robuste; `share_plus` ou `path_provider` permettraient un vrai téléchargement de fichier. | profile | `lib/features/profile/views/my_data_view.dart` | Conformité RGPD article 20 partielle |
| m-5 | `deleteAccount` (article 17) dans `UserService` et non dans `GdprService` — légère incohérence documentée dans ADR RETRO-029. | profile | `lib/features/profile/services/user.service.dart`, `lib/features/profile/services/gdpr.service.dart` | Cohérence architecturale RGPD |
| m-6 | Vues legacy coexistantes avec les implémentations BLoC : `home_page.dart` (263 lignes) et `library.view.dart` (228 lignes) non référencés par le router. Source de confusion lors des modifications. | home, library | `lib/features/home/views/home_page.dart`, `lib/features/library/views/library.view.dart` | Code mort, confusion future |
| m-7 | `ConnectivitySubscription` dans `HomePageBloc` avec listener vide (`(_) {}`) — la reconnexion automatique n'est pas gérée dans la version BLoC (uniquement dans `home_page.dart` legacy). | home | `lib/features/home/bloc/homepage_bloc.dart` | Reconnexion automatique non fonctionnelle |
| m-8 | Couleur hardcodée dans `BottomNavbar` (`const Color(0xffb8b8d2)`) — non-conforme au design system (AppColors). | home | `lib/features/home/views/bottom_navbar.dart` | Incohérence design system |
| m-9 | `ConsentCheckbox` utilise des paddings hardcodés (`EdgeInsets.symmetric(horizontal: 4, vertical: 2)`) non conformes aux tokens `AppSpacing`. | auth | `lib/features/auth/widgets/consent_checkbox.dart` | Incohérence design system |
| m-10 | `SearchHistoryService` potentiellement non enregistré dans `service_locator.dart` — le fallback défensif dans `_historyService` crée une instance à la volée si GetIt échoue. Pattern inhabituel dans le codebase. | search | `lib/features/search/views/search.dart`, `lib/features/search/services/search_history.service.dart` | Incohérence DI |
| m-11 | `findGroupForManga()` charge tous les groupes de l'utilisateur puis filtre côté client — inefficace si le nombre de groupes croît. Pas d'endpoint dédié `/reading-groups?muId=X`. | sharing | `lib/features/sharing/services/reading_groups.service.dart` | Performance à surveiller |
| m-12 | `imageCount` dans `DownloadedChapter` toujours initialisé à 0 et jamais mis à jour après le téléchargement des images — champ inutilisable. | download | `lib/features/download/models/downloaded_chapter.model.dart`, `lib/features/download/services/chapter_download_service_io.dart` | Intégrité des données |
| m-13 | `StatsService` utilise `flutter_secure_storage` pour le cache stats alors que les autres services utilisent `OfflineCacheService` / `CacheHelperService` — hétérogénéité du mécanisme de cache. | stats | `lib/features/stats/services/stats.service.dart` | Cohérence architecturale |
| m-14 | Heuristique biométrie Huawei dans `BiometricService` (retourne `true` même si `getAvailableBiometrics()` est vide) — peut produire des erreurs silencieuses sur des appareils non-Huawei sans capteur biométrique. | auth | `lib/features/auth/services/biometric.service.dart` | Comportement imprévisible |
| m-15 | `magic number -1` retourné par `getReadChapterByUid()` si le manga est absent de la bibliothèque — convention implicite fragile non documentée par un type (ex: `int?`). | library | `lib/features/library/services/library.service.dart` | Lisibilité du code |

---

## Métriques globales

| Indicateur | Valeur |
|-----------|--------|
| Dette CRITIQUE | 7 items |
| Dette MAJEUR   | 15 items |
| Dette MINEUR   | 15 items |
| Couverture de tests | Estimée : < 10% (7 fichiers de tests, 13 features, dont 4 features entièrement non couvertes) |
| Features sans aucun test | 9 sur 13 (home, library, reader, download, search, profile, stats, friends, sharing, comments) |
| Fichiers dépassant le seuil critique 400 lignes | 6 (detail_bloc_view.dart, web_view_io.dart, detail_bloc.dart, ad_blocker_service.dart, late_detail.view.dart, library_bloc.dart, scroll_position_service.dart) |
| ADRs documentés | 18 |
| ADRs manquants (dette identifiée non ADR) | ~8 (WorkManager abstraction, notifications iOS fallback, offline social features, tests policy) |
