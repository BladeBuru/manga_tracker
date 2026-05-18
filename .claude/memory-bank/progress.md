# Progrès — Manga Tracker Flutter

**Version actuelle** : `0.8.0+17` — **Dernière mise à jour** : Mai 2026

---

## 🔵 À planifier — Upgrade Flutter en session dédiée

**État actuel** : Flutter 3.32.0 (mai 2025) + Dart 3.8.0 + flutter_bloc 8.1.3. Environ 12 mois de retard sur la stable (Flutter ~3.40+).

**Pourquoi upgrade plus tard** : Material 3 "Expressive" (printemps 2026) apporte des nouvelles animations + tokens + composants (`CarouselView` natif, `DropdownMenu` amélioré). Pas critique pour l'UX actuelle mais nice-to-have pour viser un look 2026/2027.

**À faire dans la session dédiée** :
- `flutter upgrade` (channel stable)
- Bump `flutter_bloc 8 → 9` (breaking : signatures `on<Event>` peuvent changer un peu)
- Audit deprecated APIs (`withOpacity` → `withValues`, `MaterialStatePropertyAll` → `WidgetStatePropertyAll`, `WillPopScope` → `PopScope`, etc. — déjà signalés par flutter analyze)
- Test sur tel + Chrome avant de merger
- Bumper `pubspec.yaml > version:` et déclencher une release

**Cible session** : 1-2h focus, hors de l'autonomie générale bug-fix.

---

## ✅ Complété

### 🎨 Design System V1 « Refined Classic » — Refonte massive (2026-05-18)

Bundle handoff Claude Design extrait dans `.claude-design/` (hors repo, gitignoré). Application du design system V1 à **9 pages + 5 dialogs + 1 feature** en une session :

**Tokens infrastructure** :
- Police globale Inter → **Manrope** (`app_theme.dart`)
- Tokens `AppColors.ds*` (light + dark) ajoutés : `dsBg`, `dsBgInset`, `dsHairline`, `dsBorder`, `dsText2`, `dsText3`, `dsRedSoft`, `dsSurfaceDark` (conversions oklch → hex depuis `tokens.css`)

**Primitives partagés créés** :
- `core/components/pastel_tile.dart` — 7 couleurs light+dark (red/yellow/blue/green/purple/pink/teal)
- `features/profile/widgets/profile_menu_row.dart` — row menu avec PastelTile leading
- `features/library/widgets/library_section.dart` — collapsible V1 card
- `features/manga/widgets/reading_progress_bar.dart` — LinearProgressIndicator + tabular counter
- `features/profile/widgets/profile_dialog_shell.dart` — shell de dialog V1 + boutons cancel/confirm

**Pages refondues** :
- ✅ **Modifier mon profil** — hero avatar 96px sans gradient, 4 sections groupées, focused state barre rouge gauche, chips genre red-soft+border, CTA radius 14 height 52 halo rouge
- ✅ **Mon compte** — header clean centré 88px, highlight card "Nouveau" bordée rouge, 7 sections, footer mono "MANGA TRACKER · vX.Y.Z". `profile.dart` 838 → 282 lignes + 7 widgets extraits. Suppressions `profile_option_tile.dart`, `profile_section.dart`, `changelog_card.dart`. « Informations du compte » retirée sur demande.
- ✅ **Recherche** — pill input 14px radius + border rouge dynamique, history card hairline + rows refresh+×, chips genres horizontaux wrap responsive (fix: `Container(alignment)` retiré pour ne plus stretcher), Icons.search_outlined
- ✅ **Statistiques** — `stats_view.dart` 415 → 148L + 6 widgets, hero "Membre depuis X mois" pastel red, 4 sections (Vue d'ensemble / Statuts / Genres / Dernière lecture), pull-to-refresh
- ✅ **Mes amis** — pill search avec border focus, segmented pill chips Tab1/Tab2, FriendsSectionCard custom indent 66px sous avatar
- ✅ **Recommandations (Inbox)** — InboxShareTile 295L (sender + manga + date + pill NOUVEAU + cover thumb), InboxFilterChips (Toutes/Non lues/Lues), groupage par date, badge sync `NotificationCountsService` préservé
- ✅ **Lectures à deux** — list + detail réécrites, hero dual-avatar you-vs-friend, progress comparison bars, polling 30s préservé
- ✅ **Bibliothèque** — `library_bloc_view.dart` 676 → 282L + 6 widgets, **bordures rouges éliminées** des sections (list + grid), **MangaRow.showProgressBar=true** affiche LinearProgressIndicator au lieu de la pill orange ; pour Home/Search le default `false` conserve la pill (désormais red-soft + texte rouge cohérent V1)
- ✅ **Mes données (RGPD)** — info banner + 3 sections (Données / Mes droits / Suppression), tap delete → dialog V1
- ✅ **Notifications** — UI V1 3 toggles (chapitres / demandes ami / shares) + permission info

**Dialogs refondus** (`profile_dialogs.dart` 285 → 62L façade + 6 fichiers dans `widgets/dialogs/`) :
- Logout (red PastelTile) / Delete account (red border 1.5px danger) / Change password (yellow PastelTile + reuse PasswordFields) / Theme selector (purple + pattern focused row) / Biometric reconnect info (purple)

**Feature ajoutée** :
- ✅ **Local notifications pour demandes d'ami + shares reçus** : `NotificationService.showFriendRequestNotification` + `showShareReceivedNotification` (2 channels Android + Darwin iOS), 2 nouvelles prefs `friendRequestNotificationsEnabled` + `shareReceivedNotificationsEnabled`, détection via `FriendsBloc._notifiedPendingIds` + `NotificationCountsService._notifiedShareIds` (anti-doublon + first-poll skip)

**Bugs corrigés en passing** :
- Avatar data URI non sauvegardé : `user.service.dart` skippait silencieusement les `data:image/` (commentaire stale). Fix : accepte data: URIs comme l'API le valide déjà
- Avatar ProfileHeader fallback person même après upload : `Image.network` ne sait pas afficher les data: URIs. Fix : `_resolveImage()` aligné sur `AppAvatar` (MemoryImage si data:, NetworkImage si http)
- Badge "Nouveau" perpétuel sur highlight card : fallback `_changelogInfo = newChangelog ?? allChangelogs` rendait `hasNew` toujours true. Fix : flag `_hasNewChangelog` explicite, dialog utilise version déjà traduite en mémoire
- Chips Genres populaires en colonne verticale : `Container(alignment: Alignment.center)` sans contrainte width = Flutter expand à 100%. Fix : retrait alignment au profit de `Center(widthFactor: 1)`
- MangaRow look daté : double BoxShadow Material 3 → hairline 1px + ombre subtile + radius 16 + density réduite (70×96 cover, padding 10)
- Search bar logo : 🦊 emoji → mask_logo.png 22px → **Icons.search_outlined** (le logo app à 22px était cluttery, magnifying glass est plus design)
- Bannière "action en cours" library : `Colors.blue` hardcodé → `dsBgInset` + primary

**i18n** : ~80 nouvelles clés ARB ajoutées dans les 7 langues (fr/en/de/ja/ko/pt/es), incluant retrofix de 3 clés `newChapter*` qui n'existaient qu'en FR.

**Validation** : `flutter analyze` clean sur tous les fichiers touchés (les 1-6 issues pré-existantes dans `custom_selectors_page.dart` / autres fichiers non-touchés ne sont pas dans ce périmètre).

**Reste à faire** :
- Auth flow (login + register + forgot + reset + verify + startup) — agent en cours
- Page Langues — V1 léger (queued)
- TODO push notif strings dynamiquement traduites (services n'ont pas de BuildContext, hardcoded FR pour l'instant — keys ARB déjà en place pour activation future)
- TODO navigation depuis le tap d'une notif (`_onNotificationTapped` → `/friends` pour friend req, `/manga/:muId` pour share)

### Design System V1 — Page « Mon compte » (2026-05-18 — entrée initiale)
- ✅ Page profil refondue selon le design V1 Claude Design : avatar centré clean sans gradient, sections groupées en cards iOS-style, PastelTile 7 couleurs (red/yellow/blue/green/purple/pink/teal), highlight card « Nouvelles fonctionnalités » bordée rouge, footer mono « MANGA TRACKER · vX.Y.Z-dev ». Comportement métier intact (biométrie, thème, langue, logout, GDPR, password, Discord, downloads, custom selectors). Découpage en `pastel_tile.dart` (core), `profile_menu_row.dart`, `profile_header.dart`, `profile_highlight_card.dart`, `profile_body.dart`, `profile_sections.dart`, `profile_dialogs.dart` ; suppressions `profile_option_tile.dart`, `profile_section.dart`, `changelog_card.dart`.

### Authentification
- ✅ Login / Logout avec persistance JWT
- ✅ Register + suppression de compte
- ✅ Changement de mot de passe
- ✅ Authentification biométrique (`BiometricService` + `local_auth`)
- ✅ Refresh automatique des tokens (via `HttpService`)
- ✅ **[Phase 1 — Mai 2026]** Fix race condition tokens : `logout()` `await` désormais les 2 `deleteSecureData` (sinon fenêtre où le refresh existait encore avec un accessToken déjà supprimé)
- ✅ **[Phase 1 — Mai 2026]** `tryBiometricLogin` : suppression des double-writes redondants (les tokens étaient écrits 2× — fenêtre de race si la 1ère requête partait entre les 2 writes)
- ✅ **[Refresh rejected fix — 2026-05-18]** `refreshAccessToken()` retourne désormais un enum `RefreshResult { success, networkError, rejected }` au lieu d'un bool. Le 401/403 du serveur (session purgée en DB, JWT_REFRESH_SECRET changé, token signé par une autre instance) est traité comme `rejected` → `startup_page.dart` purge les tokens + redirige vers `/login` au lieu de laisser passer en cache. Le 5xx/timeout/SocketException restent `networkError` → tolérance hors-ligne légitime. `http_service.dart` switch sur les 3 cas et appelle `_auth.logout()` quand le refresh est rejeté pour éviter une boucle au prochain boot. Corrige le bug "je relance l'app, je suis pas authentifié mais je vois quand même mon cache" — l'user va maintenant droit au login quand le serveur l'a effectivement déconnecté.
- ✅ **[Login/Register dark mode — 2026-05-18]** Bug "moitié sombre / moitié claire" sur la page login en dark : cause = `Scaffold(backgroundColor: Colors.grey[200])` hardcodé. Fix complet : login.view.dart réécrit (structure alignée sur register, 5 sous-widgets privés), `AuthLogo` nouveau composant partagé (logo enveloppé dans container `surfaceContainerHighest` + border `outlineVariant` → cadre adaptatif au thème), `SquareTile` theme-aware (`outlineVariant` + `surfaceContainerHighest` au lieu de `Colors.white` + `Colors.grey[100]`), tous les `Colors.X` hardcodés (grey/red/orange) remplacés par tokens `colorScheme`. Cohérence visuelle login ↔ register garantie via `AuthLogo` partagé + même `Scaffold`/SafeArea/LayoutBuilder/ConstrainedBox(maxWidth: 480).
- ✅ **[Profile UX cleanup — 2026-05-18]** 3 bugs UX corrigés en batch :
  1. **Badge "Nouveau" changelog supprimé** (`changelog_card.dart` réécrit, 126 lignes vs 286). L'item reste cliquable pour ouvrir le `ChangelogDialog` (qui re-traduit lui-même), mais plus de badge non-persistant qui reflashait à chaque ouverture du profil. La popup au démarrage suffit à signaler les nouveautés.
  2. **Avatar picker DiceBear supprimé** (`avatar_picker_sheet.dart` supprimé). Remplacé par un simple `TextFormField` avec validation URL (require_protocol http/https), preview live de l'avatar via setState, fallback initial si URL vide/invalide. Clés ARB nettoyées + remplacées (`avatarUrlLabel`, `avatarUrlInvalid` × 7 langues). Upload multipart toujours TODO (nécessite multer + sharp + NAS volume).
  3. **Slider notation commentaire supprimé** (`comment_input.dart` réécrit, 91 lignes vs 136). Le Slider 1-10 + bouton "Ajouter une note" supprimés ; la signature `onSubmit(content, int? rating)` est conservée pour compat BLoC mais appelée avec `rating: null`. La rangée "Votre note" en bas du detail manga utilise déjà `UserRatingStars` (5 étoiles tap-to-rate mappées 0-10) — pas de duplication réelle, juste un pattern visuel commun.

### Bibliothèque
- ✅ Add / Remove / Get (CRUD complet)
- ✅ Filtrage du contenu mature
- ✅ Statuts de lecture (`ReadingStatus`)
- ✅ Progression par chapitres (`readChaptersCount`)
- ✅ Mode offline complet (cache + queue + sync)
- ✅ **[Phase 5 — Mai 2026]** `LibraryService.recordChapterLog`, `toggleChapterSkip`, `getChapterLog` — log additif des sessions (replays, hors-séries skippés, scroll position pour reprise de lecture). DTO `ChapterLogDto`. Pas encore intégré dans la UI (TODO : icône skip sur la liste détail).

### Amis (Phase 6)
- ✅ **[Phase 6 — Mai 2026]** `FriendsService` côté Flutter avec cache 24h (`cached_friends`), méthodes `getAcceptedFriends`, `getPendingRequests`, `sendRequest`, `updateStatus`, `deleteFriendship`, `searchUsers`. DTOs `FriendshipDto` (avec helper `displayName`), `UserSearchResultDto`. Enregistré dans GetIt.
- ✅ **[Phase 6.1 — Mai 2026]** UI complète : `FriendsBloc` (events Load/Search/Send/Respond/Remove), `FriendsListPage` avec onglets *Amis* (acceptés) + *Demandes* (pending) avec badges compteurs, `UserSearchField` réutilisable (debounce 300 ms), `FriendListTile` partagé. Route `/friends`. Tile dans Profile (icône People, couleur teal). 7 langues complètes (15 nouvelles clés). 0 issue flutter analyze.
- ✅ **[Phase 6.2 + 8.2 — Mai 2026]** Badge unifié sur l'icône Profile du `BottomNavBar` : `NotificationCountsService` (polling 60s sur `/friends/pending` + `/sharing/inbox/unseen-count`, expose `Stream<int>`), `_NotifBadgedIcon` via `Badge.count` Material 3. Refresh forcé après acceptation d'une demande d'ami ou ouverture de l'Inbox (`getIt<NotificationCountsService>().refresh()`). Service `start()/stop()` géré par le shell `BottomNavbar`.

### Commentaires (Phase 7)
- ✅ **[Phase 7 — Mai 2026]** `CommentsService` côté Flutter (DTOs `CommentDto`, `CommentsPage`, enum `CommentSort`). Méthodes `listForManga`, `listReplies`, `create`, `reply`, `update`, `delete`, `report`. Enregistré dans GetIt.
- ✅ **[Phase 7.1 — Mai 2026]** UI complète : `CommentsBloc` (par muId, events Load/LoadMore/Post/Edit/Delete/ChangeSort), `CommentsSection` widget self-contained avec `BlocProvider`, `CommentInput` (validation 3-2000 chars + rating optionnel via Slider 1-10), `CommentTile` (avatar + displayName + date relative + rating + menu delete). Intégré au bas de `late_detail.view.dart`. Toggle `SegmentedButton` Recent/Top. Pagination "Load more". 7 langues complètes (16 nouvelles clés ICU pluriels). 0 issue flutter analyze.

### Partage entre amis (Phase 8)
- ✅ **[Phase 8 — Mai 2026]** `SharingService` côté Flutter avec DTOs `MangaShareDto` (helper `isNew`). Méthodes `shareMangaWithFriends`, `getInbox`, `markAllSeen`, `getUnseenCount`. Enregistré dans GetIt.
- ✅ **[Phase 8.3 — Mai 2026]** `ReadingGroupsService` côté Flutter + DTOs `ReadingGroupDto` / `ReadingGroupMemberDto` (avec helper `effectiveName`, `effectiveDisplayName`). Méthodes `createGroup` (avec invitations initiales), `getMyGroups`, `getGroup` (à poll 30s pour la sync), `invite`, `leave`. Enregistré dans GetIt (`dependsOn: [HttpService]`).
- ✅ **[Phase 8.3 UI — Mai 2026]** Pages reading groups complètes : `ReadingGroupsBloc` (LoadReadingGroups, LeaveGroupRequested) + `ReadingGroupDetailBloc` dédié (LoadGroupDetail + Timer 30s `PollGroupDetail` cancel au close), `ReadingGroupsListPage` (cards avec membres + progression), `ReadingGroupDetailPage` (header coloré + bouton "Ouvrir le manga" + liste détaillée membres avec badge OWNER + progression). Routes `/reading-groups` + `/reading-groups/:groupId`. Tile dans Profile (icône `groups_outlined`, couleur indigo). 11 nouvelles clés × 7 langues = 77 traductions. 0 issue flutter analyze.
- 🔴 **[Phase 8.3 TODO restant]** Bouton "Lire à deux" sur la fiche manga (modal pour créer un groupe depuis `detail_bloc_view.dart`). Reste à câbler — 1280 lignes du fichier détail à toucher avec précaution.
- ✅ **[Phase 8.1 — Mai 2026]** UI complète : `ShareMangaSheet` modal (multi-select amis avec checkboxes, message 280 chars, bouton Envoyer), `InboxPage` (cartes avec badge "Nouveau", tap pour ouvrir le manga, mark-as-seen auto au mount), bouton share dans AppBar de `detail_bloc_view.dart`, tile Inbox dans Profile. Route `/inbox`. 13 nouvelles clés × 7 langues = 91 traductions.
- ✅ **[Phase 8.2 — Mai 2026]** Badge BottomNavBar (cf. Phase 6.2) inclut désormais les shares non-vues — service unifié + polling 60s.

### Mangas
- ✅ Page d'accueil — `HomePageBloc`
- ✅ Page de détails — `DetailBloc` (factory)
- ✅ Affichage genres avec Chip Material 3 (Wrap)
- ✅ Recherche
- ✅ **[Phase 4 — Mai 2026]** `RefreshableMangaImage` accepte `useProxy: true` → URL stable `/mangas/:muId/cover?size=...` côté API (zéro placeholder, cache CDN 30j). `MangaCard` et `MangaRow` activent désormais le proxy. `MangaQuickViewDto.coverProxyUrl({size})` helper côté DTO.

### Profil
- ✅ Page Profile modernisée (Material 3, composants réutilisables)
- ✅ Changement de mot de passe
- ✅ Suppression de compte
- ✅ Cache infos utilisateur (7 jours, mise à jour en arrière-plan)
- ✅ Changelog intégré
- ✅ **[Phase 2 — Mai 2026]** Page Statistiques `/stats` accessible depuis Profile : total mangas, répartition par statut (barres proportionnelles), chapitres lus, temps de lecture estimé, taux de complétion, dernière lecture, top 5 genres. Cache 1h via StorageService. Responsive 1/2 colonnes via LayoutBuilder. 7 langues complètes (i18n).
- ✅ **[Phase 3 — Mai 2026]** Page d'édition profil `/profile/edit` : displayName, bio (max 500), avatar URL (preview live), date de naissance (DatePicker), genre (ChoiceChips), opt-in profil public. `UserInformationDto` étendu avec `effectiveDisplayName` (fallback username). PATCH `/user/profile` côté API. HttpService gagne la méthode `patchWithAuthTokens`. 7 langues complètes.
- 🔴 **[Phase 3 TODO]** Widget `AvatarPicker` (sélection image cross-platform via `cross_file` / `image_picker` + upload multipart). Repoussé à une session dédiée — le formulaire actuel accepte une URL externe en attendant.

### Infrastructure
- ✅ Architecture BLoC complète
- ✅ Mode offline-first (OfflineCacheService, CacheHelperService, SyncService)
- ✅ i18n 7 langues (FR, EN, DE, JA, KO, PT, ES)
- ✅ Sélecteur de langue dans le profil
- ✅ Composants réutilisables dans `core/components/` (8 composants)
- ✅ `AppRadius` pour la cohérence des arrondis
- ✅ CI/CD GitHub Actions (`release_workflow.yml`) — APK Android + GitHub Releases
- ✅ **[Phase 9 — Mai 2026]** `ResponsiveLayoutMixin` dans `core/utils/responsive_layout.dart` : 4 breakpoints (compact 600 / medium 840 / expanded 1240 / large 1440), helpers `horizontalPadding`, `maxContentWidth`, `gridColumns`, `isMobile/isTablet/isDesktop`. Adopté dans `home_page.dart`.
- ✅ **[Phase 10 — Mai 2026]** `AppSpacing` dans `core/theme/app_spacing.dart` : tokens xs/s/m/l/xl/jumbo + helpers EdgeInsets pré-fabriqués (paddingAllM, paddingHorizontalM, etc.) — remplace les `EdgeInsets.all(16)` magiques.
- 🔴 **[Phase 9/10 TODO]** Adoption progressive du mixin et d'AppSpacing dans les 4 autres pages cibles (`library_bloc_view.dart`, `detail_bloc_view.dart`, `language_selector_button.dart`, etc.). Les pages actuelles fonctionnent déjà, l'enjeu est la cohérence — refactor session-par-session sans risquer la stabilité.
- 🔴 **[Phase 10 TODO]** Refactor des 253 `Colors.*` hardcodés dans 15 fichiers. Étendre `AppColors` avec tokens `surface/inputFill/dividerColor` par brightness. Bascule dark/light propre à valider page par page.

### 🎨 Design System (Session 2026-05-18)

Session de durcissement du design system pour résoudre la critique "les couleurs orange sont moches" + "design Stats/Profile pas joli" + "Detail c'est bien".

#### Primitives `core/components/` créés
- ✅ **`AppCard`** + variantes `tonalPrimary` / `outlined` — carte de contenu standard (radius xxxl, padding 16, surfaceContainerLow)
- ✅ **`AppListTile`** — tile avec leading/title/subtitle/trailing tonal
- ✅ **`AppAvatar`** (small/medium/large) — avatar circulaire avec fallback initiale, plus de CircleAvatar ad-hoc disséminé
- ✅ **`AppChip`** + variantes `primary` / `outlined` — pastilles M3 (radius xl)
- ✅ **`AppCountBadge`** — compteur inline ("12 mangas") 
- ✅ **`AppEmptyState`** — icône + titre + sub + CTA tonal (rouge override)
- ✅ **`AppErrorState`** — error + bouton retry tonal (rouge override)
- ✅ **`OfflineBanner`** — bandeau hors ligne avec `errorContainer` (remplace `Colors.orange` hardcodé partout)

#### Règle de design durcie
- `.claude/rules/flutter-widgets.md` : règle DURE "vérifier `core/components/` AVANT de créer un widget visuel ; si pas trouvé → créer dans `core/components/` (pas dans `features/X/widgets/`)". Tableau des primitives + section "Modern Material 3 Google look" avec règles esthétiques.

#### Pages refactorées vers les primitives (0 nouveau issue analyze)
- ✅ `StatsView` — `AppCard.tonalPrimary` hero, `AppCard` stats, `AppChip` genres, `AppEmptyState`/`AppErrorState`. Supprimé 4 widgets feature-specific redondants.
- ✅ `InboxPage` — `AppCard` (background highlightée si non-vue), `AppAvatar.large`, `AppChip.primary` badge NOUVEAU
- ✅ `FriendsListPage` + `FriendListTile` + `UserSearchField` — `AppCard`, `AppAvatar`, `IconButton.filledTonal`, `AppEmptyState`/`AppErrorState`
- ✅ `ReadingGroupsListPage` + `ReadingGroupDetailPage` — `AppCard.tonalPrimary` hero, `AppChip.primary` badges OWNER + members count, `AppAvatar`
- ✅ `CommentsSection` + `CommentTile` — `AppCard`, `AppAvatar`, `AppChip.primary` rating + sort. **Remplacement SegmentedButton orange par 2 AppChip cliquables**.
- ✅ `ProfileEditView` — Hero avatar cliquable 120px avec badge ✏️, sections labels colorées (`profileSectionIdentity`, `Demographics`, `Privacy`), `AppCard` partout
- ✅ `ProfileHeader` (Phase 3.1) — étendu pour afficher displayName + bio + avatarUrl du Phase 3, badge ✏️ pour ouvrir Profile Edit
- ✅ `ShareMangaSheet` — utilise `AppAvatar`

#### Bugs fixés en session
- ✅ **Auth `column User.createdAt does not exist`** : `npm run migration:run` a appliqué les 5 migrations
- ✅ **Search 500** (MU API durcie) : `safeLimit = 20` par défaut + log détaillé du body MU response
- ✅ **Cover 404 sur `/thumb/`** : `medium_cover_url` toujours préféré, 302 redirect au lieu de fetch Node
- ✅ **PATCH /user/profile 400** (chaînes vides) : skip empty strings + filtrer avatarUrl sans protocole. **Debug logs ajoutés** pour diagnostic si bug persiste.
- ✅ **Cache HTTP `immutable`** sur cover 404 : remplacé par `max-age=300` (5 min) → si une URL casse, le browser réessaye max 5 min plus tard
- ✅ **SegmentedButton orange** (Recent/Top commentaires) → 2 `AppChip` cliquables
- ✅ **`Colors.orange` hardcodé** dans 5 fichiers → primitive `OfflineBanner` + `theme.error`
- ✅ **`FilledButton.tonal` orange par défaut** dans `AppEmptyState`/`AppErrorState` → override style `primaryContainer`/`onPrimaryContainer` (rouge tonal)
- ✅ **Tag "À jour" orange** (`AppColors.accent` dans `reading_status.enum.dart`) → teal `#00897B`

#### Features ajoutées
- ✅ **Bouton "Lire à deux"** dans AppBar fiche manga (icône groups_outlined) → ouvre `CreateReadingGroupSheet` (nom optionnel + multi-select amis) → après création, navigation vers `/reading-groups/:id`
- ✅ **AvatarPickerSheet** — modal 8 styles DiceBear + shuffle + bouton "Importer" disabled (Coming Soon)
- ✅ **Bouton "Lire à deux"** sur fiche manga + bouton "Partager"

#### TODOs résiduels (en attente du user)
- 🔴 Diagnostic exact du PATCH 400 persistant (logs Flutter ou DevTools nécessaires)
- 🔴 Précisions du user sur ce qui déplaît dans Stats / Profile (en attendant, refonte safe-only)
- 🔴 Upload avatar multipart (multer + sharp + volume NAS, ~3h infra)

### 🚀 Prochaine grande étape : **Google Play Store readiness**

Demandée par l'user le 2026-05-18 — **à faire dans une session dédiée**, pas maintenant.

**Skill** : `/playstore-readiness` (déjà existant — voir `.claude/skills/playstore-readiness/SKILL.md`)

**Checklist principale** :
- 🔴 **Signing** : retirer `key.properties` du repo + rotation keystore (CRITIQUE sécurité)
- 🔴 **App Bundle** (`.aab`) au lieu d'APK pour la release (Play Store 2024+ obligatoire)
- 🔴 **targetSdkVersion ≥ 34** (exigence Play Store 2024+)
- 🔴 **ProGuard / R8** activés en release (`minifyEnabled true`, `shrinkResources true`)
- 🔴 **Privacy policy URL** publique et stable (hébergée — actuellement dans `legal/PRIVACY_POLICY.md` à publier)
- 🔴 **Permissions Android** : chaque permission dans `AndroidManifest.xml` doit avoir une justification user-facing claire
- 🔴 **Tests minimum** : 1 widget test + 1 BLoC test par feature
- 🔴 **Accessibilité** : labels TalkBack, contraste WCAG AA, font scaling
- 🔴 **Performance** : cold start < 5s, pas de jank > 16ms
- 🔴 **Upload Play Console automatisé** (alpha / beta / prod) via CI/CD
- 🔴 **Screenshots store** (phone + 7" tablet + 10" tablet) — 8 visuels recommandés
- 🔴 **Feature graphic** 1024×500 + icône 512×512
- 🔴 **Privacy form Play Console** : data safety section (quelles données on collecte, partage, type)

**Estimation** : 1 jour complet de boulot + back-and-forth avec Play Store review.

---

## 🔴 À faire

### 🔒 Sécurité (PRIORITÉ HAUTE — voir known-issues.md)
- 🔴 **Retirer `key.properties` du repo** + rotation du mot de passe keystore
- 🔴 Ajouter `android/key.properties`, `*.jks` au `.gitignore`

### 🌐 Cross-platform (évolution iOS/Web — PRIORITÉ HAUTE)
- 🔴 Audit complet via skill `/cross-platform-audit`
- 🔴 Abstraire `workmanager` derrière `BackgroundTaskService` (impl Android/iOS/Web)
- 🔴 Abstraire `notification_service.dart` avec Darwin fallback iOS
- 🔴 Retirer / abstraire `dart:io` direct dans `lib/`
- 🔴 Migration vers `go_router` (obligatoire avant build web)

### 📱 Play Store quality (évolution)
- 🔴 Build **App Bundle** (`.aab`) en plus de l'APK dans la CI
- 🔴 Upload Play Console automatisé (alpha / beta / prod)
- 🔴 Vérifier `targetSdkVersion` ≥ 34
- 🔴 ProGuard / R8 activés en release
- 🔴 Privacy policy URL
- 🔴 Tests : 1 widget + 1 BLoC test par feature minimum
- 🔴 Audit accessibilité (`Semantics`, contraste, TalkBack)

### 🎨 Design system (évolution)
- 🔴 Créer `lib/core/theme/app_spacing.dart`
- 🔴 Promouvoir `MangaCard`, `MangaRow`, `OfflineBanner`, `LoadingSkeleton`, `EmptyState`, `ErrorState` vers `core/components/`
- 🔴 Migration progressive `EdgeInsets.all(16)` → `AppSpacing.m`

### Court terme (v0.4.0)
- 🔴 Activer le thème sombre (code préparé dans `AppTheme`)
- 🔴 Migration vers `go_router`
- 🔴 Écrire les tests BLoC
- 🔴 GitHub Actions : lint + tests + build App Bundle
- 🔴 Photo de profil (backend prêt)
- 🔴 Proxy images MangaUpdates (endpoint CORS côté API)

### Moyen terme (v0.5.0)
- 🔴 Onboarding utilisateur (âge, langue, genres favoris)
- 🔴 Google OAuth2
- 🔴 Statistiques utilisateur (chapitres lus, streak, top genres)
- 🔴 Historique de recherche
- 🔴 **iOS readiness** (skill `/ios-readiness`)
- 🔴 **Web readiness** (skill `/web-readiness`)

### Long terme (v0.6.0+)
- 🔴 Recommandations LightFM
- 🔴 Alertes nouvelles sorties (Firebase Messaging multi-plateforme)
- 🔴 Espace communautaire
- 🔴 Calendrier des sorties
- 🔴 Privacy Manifest iOS (exigence iOS 17+)

---

## 🐛 Bugs résolus (résumé)

- ✅ Race conditions `DetailBloc` → factory dans GetIt
- ✅ Faux positifs offline → détection via `SocketException`
- ✅ Perte actions offline → gestion échecs `SyncService`
- ✅ `readChaptersCount` incorrect après suppression → reset explicite

> Voir `.claude/memory-bank/known-issues.md` pour le détail (et 7 problèmes actifs détectés à l'audit cross-platform de mai 2026).

---

## 📈 Progression globale

**≈ 58% du MVP** (23/40 fonctionnalités principales).

Prochaines priorités :
1. Sécurité (retirer `key.properties`)
2. Cross-platform (abstractions pour iOS/Web)
3. Design system (AppSpacing + composants promus)
4. Tests (couverture BLoC + widget)
5. Play Store quality (App Bundle + accessibilité)
