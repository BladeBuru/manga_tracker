# Discovery — Manga Tracker

> Fichier généré automatiquement par retro-scanner. Usage interne uniquement.
> Ce fichier sera supprimé à la fin de la Phase 1-bis.

---

## Stack identifiée

| Composant | Valeur |
|-----------|--------|
| Framework | Flutter 3.x (Material 3, `useMaterial3: true`) |
| Version app | 0.10.0+21 |
| Langage | Dart 3.7+ (null safety) |
| SGBD | Aucun embarqué — SQLite via `sqflite` pour `flutter_cache_manager` uniquement ; données applicatives stockées via `flutter_secure_storage` + `shared_preferences` |
| API distante | REST sur `api.bladeburu.com` — URL configurée via `MT_API_URL` dans `.env.production` / `.env.development` |
| State management | `flutter_bloc ^8` + `bloc ^8` + `equatable` — pattern BLoC (Events/States) |
| DI | `get_it ^8` — Service Locator, singleton/factory/async selon le cas |
| HTTP | `http ^1.3` via `HttpService` centralisé (retry automatique sur 401 avec rotation JWT) |
| Auth | JWT (access + refresh) — `flutter_secure_storage` (Keystore Android / Keychain iOS / WebCrypto Web) |
| Auth sociale | Google Sign-In (`google_sign_in ^7` — idToken mobile, OAuth WebView web) |
| Auth biométrique | `local_auth ^2` |
| Navigation | `go_router ^14` (migration depuis `MaterialPageRoute`, deep-linking web actif) |
| i18n | `flutter_localizations` + `intl ^0.20.2` — ARB dans `lib/l10n/`, 7 langues (FR, EN, DE, JA, KO, PT, ES) |
| Cache images | `cached_network_image ^3` |
| Notifications | `flutter_local_notifications ^17` |
| Tâches fond | `workmanager ^0.9` (Android-only — à abstraire) |
| WebView | `flutter_inappwebview ^6` (mobile) + `webview_flutter ^4` + stub web |
| Deep links | `app_links ^6` |
| Responsive | `LayoutBuilder` + `AppBreakpoints` (compact/medium/expanded/large) |
| Tests | `flutter_test` + `mocktail ^1` — présents mais limités (7 fichiers) |

---

## Features identifiées

### 1. auth

**Description :** Authentification complète — login/inscription par email avec validation, connexion Google (mobile via idToken, web via OAuth WebView), biométrie (empreinte/face), récupération de mot de passe, vérification email par lien, re-consentement RGPD au login. Gère le cycle de vie JWT (refresh automatique, rotation des tokens, triple distinction success/networkError/rejected).

**Fichiers principaux :**
- `lib/features/auth/services/auth.service.dart` — logique JWT, Google, biométrie
- `lib/features/auth/presentation/cubit/login_cubit.dart` — état du formulaire login (Cubit, pas BLoC)
- `lib/features/auth/presentation/cubit/register_cubit.dart` — état inscription + consentement
- `lib/features/auth/views/login.view.dart`, `register.view.dart`, `startup_page.dart`
- `lib/features/auth/widgets/consent_checkbox.dart`, `social_login_buttons.dart`

**Décision notable :** Auth utilise des **Cubits** (pas des BLoCs complets) — choix assumé pour les formulaires simples, contrairement aux BLoCs event-driven pour les features de données.

---

### 2. home

**Description :** Page d'accueil présentant 3 sections de mangas (populaires, nouveaux, tendances), les recommandations personnalisées et les infos utilisateur. Charge tout en parallèle (`Future.wait`), montre le cache stale en attendant la réponse réseau, bascule offline-first si l'API est injoignable.

**Fichiers principaux :**
- `lib/features/home/bloc/homepage_bloc.dart` — BLoC lazy singleton
- `lib/features/home/helpers/homepage_data_loader.dart` — fetchers extraits du BLoC (respect limite 200 lignes)
- `lib/features/home/views/home_page.dart`, `homepage_bloc_view.dart`
- `lib/features/home/views/bottom_navbar.dart` — shell de navigation (PageView 4 tabs)
- `lib/features/home/widgets/homepage_manga_list.dart`

---

### 3. manga (detail)

**Description :** Fiche détaillée d'un manga — informations, statut de publication, genres, chapitres saison/bonus, actions bibliothèque (ajouter/retirer, changer statut, sauvegarder progression), lien de lecture personnalisable, notation utilisateur (0-10), vérification de nouveaux chapitres en arrière-plan, recommandations similaires, commentaires, partage avec amis.

**Fichiers principaux :**
- `lib/features/manga/bloc/detail_bloc.dart` — **factory** (une instance par page, évite les race conditions)
- `lib/features/manga/views/detail.dart`, `detail_bloc_view.dart`, `late_detail.view.dart`
- `lib/features/manga/services/manga.service.dart`, `chapter_check_service.dart`, `new_chapter_service.dart`
- `lib/features/manga/dto/manga_detail.dto.dart`
- `lib/features/manga/widgets/` — 10+ widgets découpés (appbar, info card, chapter section, rating, recommendations, bottom bar...)

**Décision notable :** `DetailBloc` est en **factory** (GetIt `registerFactory`) — non-négociable pour éviter les race conditions entre pages de détail simultanées.

---

### 4. library

**Description :** Bibliothèque personnelle de l'utilisateur — liste des mangas sauvegardés avec filtres par statut de lecture (à lire, en cours, à jour, terminé), vues liste et grille, badge "nouveau chapitre" par manga, mise à jour statut, sauvegarde de la progression de lecture, gestion des liens personnalisés. Offline-first avec queue de synchronisation.

**Fichiers principaux :**
- `lib/features/library/bloc/library_bloc.dart` — BLoC lazy singleton
- `lib/features/library/services/library.service.dart` — CRUD bibliothèque
- `lib/features/library/views/library.view.dart`, `library_bloc_view.dart`
- `lib/features/library/widgets/` — grid view, list view, filtering, top bar, section
- `lib/features/library/dto/chapter_log.dto.dart`

---

### 5. reader

**Description :** Lecteur de chapitres en ligne via WebView embarqué (`flutter_inappwebview` sur mobile, redirection `url_launcher` sur web). Fonctionnalités avancées : ad-blocker, détection de captcha, sauvegarde de position de scroll, navigation intelligente entre chapitres. Lecteur hors-ligne pour les chapitres téléchargés (mobile uniquement — stub web).

**Fichiers principaux :**
- `lib/features/manga/views/web_view.dart` — façade conditionnelle io/web
- `lib/features/manga/views/web_view_io.dart` — impl mobile (flutter_inappwebview)
- `lib/features/reader/views/offline_reader_view.dart` — façade conditionnelle io/web
- `lib/features/reader/services/ad_blocker_service.dart`, `captcha_detection_service.dart`, `scroll_position_service.dart`, `webview_navigation_service.dart`
- `lib/features/reader/utils/chapter_link_resolver.dart`, `reading_progress_helper.dart`

---

### 6. download

**Description :** Téléchargement de chapitres pour lecture hors-ligne (HTML + images). Architecture platform-split : implémentation IO complète sur mobile (dart:io, path_provider), stub UnsupportedError sur web. Manager de téléchargements avec file d'attente, page de liste des chapitres téléchargés.

**Fichiers principaux :**
- `lib/features/download/services/chapter_download_service.dart` — façade conditionnelle
- `lib/features/download/services/chapter_download_service_io.dart` — impl mobile
- `lib/features/download/services/download_manager_service.dart` — façade conditionnelle
- `lib/features/download/views/downloads_page.dart`
- `lib/features/download/models/downloaded_chapter.model.dart`

---

### 7. search

**Description :** Recherche de mangas avec debounce (500 ms), historique des recherches persisté localement, genres populaires (chips), résultats affichés via `HomepageMangaList`. Pas de BLoC dédié — logique dans un StatefulWidget (cas simple, pas de cache réseau).

**Fichiers principaux :**
- `lib/features/search/views/search.dart` — vue principale (StatefulWidget)
- `lib/features/search/services/search_history.service.dart`
- `lib/features/search/widgets/search_bar_input.dart`, `popular_genres_wrap.dart`, `search_history_list.dart`, `search_header.dart`

---

### 8. profile

**Description :** Page "Mon compte" — affichage du profil utilisateur (avatar, pseudo, email), édition du profil (photo avatar via image_picker, pseudo), changement de mot de passe, gestion de la biométrie, sélecteur de thème (light/dark/system), sélecteur de langue (7 langues), lien Discord, accès aux téléchargements et sélecteurs personnalisés, déconnexion, suppression de compte, page "Mes données" (RGPD).

**Fichiers principaux :**
- `lib/features/profile/views/profile.dart` — vue principale
- `lib/features/profile/views/my_data_view.dart` — RGPD (articles 15, 20, 17)
- `lib/features/profile/services/user.service.dart`, `gdpr.service.dart`
- `lib/features/profile/widgets/profile_body.dart`, `profile_dialogs.dart`, `profile_header.dart`
- `lib/features/profile/dto/user_information.dto.dart`, `user.dto.dart`

---

### 9. stats

**Description :** Statistiques de lecture de l'utilisateur — total chapitres lus, mangas par statut, répartition par genre. Cache 1h côté service. Vue lecture seule, pas de mutations.

**Fichiers principaux :**
- `lib/features/stats/bloc/stats_bloc.dart`
- `lib/features/stats/services/stats.service.dart`
- `lib/features/stats/views/stats_view.dart`
- `lib/features/stats/widgets/` — hero card, overview section, genres section, status section
- `lib/features/stats/dto/user_stats.dto.dart`

---

### 10. recommendations

**Description :** Recommandations personnalisées basées sur la bibliothèque de l'utilisateur. Deux modes : vue paginée (flux unique par score décroissant, infinite scroll) et vue par genre (SegmentedButton + carrousels). Pas de BLoC — StatefulWidget avec chargement scroll-driven.

**Fichiers principaux :**
- `lib/features/recommendations/views/paginated_recommendations_view.dart`
- `lib/features/recommendations/views/recommendations_by_genre_view.dart`
- `lib/features/recommendations/widgets/recommendations_segmented_toggle.dart`
- `lib/features/manga/services/recommendation.service.dart`
- `lib/features/manga/dto/manga_recommendation_view.dto.dart`

---

### 11. friends

**Description :** Réseau social — liste d'amis confirmés (cache 24h), demandes d'amitié reçues/envoyées, recherche d'utilisateurs par pseudo (autocomplete >= 2 chars), acceptation/refus de demandes, suppression d'amis. Notifications locales pour les nouvelles demandes (anti-doublon via Set d'IDs). Badge BottomNavBar mis à jour via `NotificationCountsService`.

**Fichiers principaux :**
- `lib/features/friends/bloc/friends_bloc.dart`
- `lib/features/friends/services/friends.service.dart`
- `lib/features/friends/views/friends_list_page.dart`
- `lib/features/friends/widgets/` — friend_list_tile, friends_section_card, friends_tab_segmented, user_search_field
- `lib/features/friends/dto/friend.dto.dart`

---

### 12. sharing (inbox + reading groups)

**Description :** Partage de mangas entre amis — envoi depuis la fiche manga, réception dans une "inbox" avec filtres (non-vus / tous). Groupes de lecture collaboratifs : créer/rejoindre un groupe, suivre la progression des membres en quasi-réel (polling 30s via `ReadingGroupDetailBloc`). Badge notifications fusionné (pending friends + unread shares) via `NotificationCountsService`.

**Fichiers principaux :**
- `lib/features/sharing/bloc/reading_groups_bloc.dart` — 2 BLoCs dans un fichier : `ReadingGroupsBloc` (liste) + `ReadingGroupDetailBloc` (détail + polling 30s)
- `lib/features/sharing/services/sharing.service.dart`, `reading_groups.service.dart`
- `lib/features/sharing/views/inbox_page.dart`, `reading_groups_list_page.dart`, `reading_group_detail_page.dart`
- `lib/features/sharing/dto/share.dto.dart`, `reading_group.dto.dart`

---

### 13. comments

**Description :** Commentaires par manga — chargement paginé, tri (recent/top), réponses imbriquées (1 niveau), notation (0-5 étoiles), édition et suppression soft-delete. Une instance de `CommentsBloc` par manga (pas de singleton). Affichée comme section dans la fiche manga via `CommentsSection`.

**Fichiers principaux :**
- `lib/features/comments/bloc/comments_bloc.dart`
- `lib/features/comments/services/comments.service.dart`
- `lib/features/comments/widgets/comments_section.dart`, `comment_tile.dart`, `comment_input.dart`
- `lib/features/comments/dto/comment.dto.dart`

---

## Décisions techniques clés

1. **BLoC factory pour DetailBloc** — `DetailBloc` est enregistré en `registerFactory` dans GetIt, pas en singleton. Chaque page détail crée sa propre instance pour éviter les race conditions si l'utilisateur navigue rapidement entre deux fiches.

2. **Cubits pour les formulaires auth** — Le module `auth` utilise des Cubits (`LoginCubit`, `RegisterCubit`, `ForgotPasswordCubit`, `ResetPasswordCubit`) plutôt que des BLoCs event-driven. Choix pragmatique pour des formulaires à état local simple.

3. **Platform-split par conditional exports** — Les features sensibles à la plateforme (WebView, offline reader, download) utilisent le pattern `export 'impl_io.dart' if (dart.library.html) 'impl_web.dart'` — ce qui rend les façades transparentes à l'import mais isole le code platform-specific.

4. **Offline-first avec queue de synchronisation** — Toutes les mutations bibliothèque peuvent être effectuées hors-ligne via `OfflineCacheService` + `OfflineAction` queue. `SyncService` rejoue la queue automatiquement à la reconnexion (écoute `connectivityStream`).

5. **Cache stale-while-revalidate** — BLoCs `HomePageBloc`, `LibraryBloc`, `DetailBloc` émettent d'abord le cache existant (`stale: true`) avant de charger depuis le réseau. L'utilisateur voit des données immédiatement même sans connexion.

6. **JWT refresh avec verrou et RefreshResult enum** — `AuthService.refreshAccessToken()` utilise un `Completer` pour sérialiser les appels simultanés (evite plusieurs refreshes en parallèle). Le résultat est typé `{success, networkError, rejected}` pour distinguer l'erreur réseau (mode offline OK) du rejet serveur (force login).

7. **HttpService comme intercepteur centralisé** — Un seul point d'entrée pour tous les appels API authentifiés. Retry automatique sur 401 : refresh token → retry. Si refresh échoue → `InvalidCredentialsException` → BLoC bascule sur erreur d'auth.

8. **go_router pour le deep-linking web** — Migration depuis `MaterialPageRoute` vers `go_router ^14`. Routes nommées, URL stables (`/manga/:muId`, `/home`, `/auth/verify`), `DeepLinkHandler` pour intercepter les liens entrants (email verify, reset password via `app_links`).

9. **Design System "Refined Classic"** — Tokens dans `lib/core/theme/` : `AppColors`, `AppRadius`, `AppTextStyle`, `AppSpacing`, `AppTheme` (light + dark Material 3). `AppBreakpoints` + `ResponsiveLayoutMixin` pour le responsive. Plusieurs primitives dans `lib/core/components/` (`AppCard`, `AppListTile`, `AppEmptyState`, `AppChip`, `AppCountBadge`, etc.).

10. **NotificationCountsService avec polling 60s** — Badge BottomNavBar (pending friend requests + unread shares) rafraîchi toutes les 60s. Anti-doublon via `Set<int>` d'IDs déjà notifiés. Premier poll silencieux pour ne pas inonder l'utilisateur au démarrage.

11. **workmanager Android-only non abstrait** — La vérification périodique des nouveaux chapitres en arrière-plan (`chapter_check_background_service.dart`) utilise `workmanager` via le fichier `_io` mais sans interface abstraite complète — blocker documenté pour iOS/Web.

12. **RGPD intégré** — `GdprService` expose Articles 15 (accès), 20 (export), consentement (`recordConsent`). Flow d'inscription avec `ConsentCheckbox` (cases non pré-cochées). Re-consentement vérifié à chaque login. Page "Mes données" accessible depuis le profil.

---

## Évaluation qualité globale

| Critère | État |
|---------|------|
| Tests présents | Partiels — 7 fichiers de tests : 2 widget tests (login/register views), 2 cubit tests (login/register), 1 test composant (PasswordFields), 1 test DTO (manga_recommendation), 1 widget_test générique. Couverture très partielle des BLoCs, services et features récentes (stats, friends, sharing, comments non couverts). |
| Structure | Organisée — feature-first (`lib/features/[feature]/bloc|services|views|widgets|dto`), code transverse dans `lib/core/`. Découpage respecté dans les features récentes. |
| Gestion d'erreurs | Partiellement centralisée — `HttpService` centralise le retry 401/refresh. Dans les BLoCs, le catch est présent mais hétérogène : certains catchent `SocketException` explicitement, d'autres catchent `Exception` générique. Pas de reporting d'erreurs centralisé (crash analytics absent). |
| Documentation | Partielle — CLAUDE.md très complet, `.claude/memory-bank/` documenté (architecture, roadmap, decisions, known-issues). Commentaires Dart présents dans les services clés et les décisions importantes. Pas de documentation Dart publique (`///`) systématique sur les DTOs et services feature. |
| Offline-first | Solide — pattern cohérent (stale-while-revalidate + queue offline + sync automatique) appliqué aux features bibliothèque, home et détail manga. Features sociales (friends, sharing) sans cache offline. |
| Cross-platform | En transition — go_router et platform-split via conditional exports en place. Blockers restants : `workmanager` Android-only non abstrait, `flutter_local_notifications` avec canaux Android sans fallback Darwin iOS complet. |
