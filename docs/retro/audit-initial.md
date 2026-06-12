# Audit Initial — Manga Tracker

| Champ             | Valeur                    |
|-------------------|--------------------------|
| Date              | 2026-06-04               |
| Auditeur          | retro-auditor            |
| Source            | Rétro-ingénierie         |
| Version auditée   | 0.10.0+21                |
| Features auditées | 13                       |
| ADRs identifiés   | 18                       |

---

## Résumé exécutif

Manga Tracker est une application Flutter (Material 3) en version 0.10.0 ciblant Android, avec une feuille de route iOS/Web active. L'architecture est propre et cohérente — BLoC event-driven, offline-first stale-while-revalidate, design system centralisé — avec 18 décisions architecturales documentées. Les forces majeures sont la robustesse du module d'authentification (JWT tristate, RGPD intégré), le pattern offline-first des features core (home, library, manga), et l'adoption de go_router pour le deep-linking Web. Les risques majeurs sont la couverture de tests insuffisante (7 fichiers, 4 features sans aucun test), plusieurs fichiers dépassant sévèrement les seuils de taille réglementaires du projet, l'absence d'abstraction complète du background task Android-only, et une incertitude sur l'effectivité du re-consentement RGPD dans `StartupPage._onLoginSuccess`.

---

## Stack et architecture

| Composant           | Valeur                                                          |
|---------------------|-----------------------------------------------------------------|
| Framework           | Flutter 3.x / Dart 3.7+ (null safety) — Material 3            |
| State management    | flutter_bloc ^8 + BLoC event-driven (factory ou lazy singleton selon le cas) |
| Injection           | get_it ^8 — Service Locator                                    |
| Navigation          | go_router ^14 (migration depuis MaterialPageRoute accomplie)   |
| HTTP                | http ^1.3 via HttpService centralisé (retry 401, JWT refresh tristate) |
| Auth                | JWT access + refresh tokens, flutter_secure_storage, local_auth biométrie, Google Sign-In |
| Cache               | Stale-while-revalidate — CacheHelperService (SharedPreferences) + OfflineCacheService |
| Offline             | Queue OfflineAction + SyncService, détection SocketException   |
| i18n                | flutter_localizations + intl ^0.20.2 — 7 langues (FR/EN/DE/JA/KO/PT/ES) |
| Design system       | AppColors, AppRadius, AppSpacing, AppTextStyle, AppBreakpoints — primitives core/components/ |
| Background tasks    | workmanager ^0.9 (Android-only — non abstrait)                 |
| Tests               | flutter_test + mocktail ^1 — 7 fichiers (partiel)             |

L'architecture suit un pattern **feature-first** (`lib/features/[feature]/bloc|services|views|widgets|dto`) avec le code transverse dans `lib/core/`. Le platform-split est réalisé via conditional exports (`export 'impl_io.dart' if (dart.library.html) 'impl_web.dart'`). Le responsive est implémenté via `LayoutBuilder` + `AppBreakpoints`.

---

## Cartographie fonctionnelle

| # | Feature        | État        | Complexité | Tests          | Spec                        |
|---|---------------|------------|-----------|----------------|-----------------------------|
| 1 | auth          | Fonctionnel | Haute     | Partiel (4 fichiers — Cubit + View; services non couverts) | docs/specs/auth/ |
| 2 | home          | Fonctionnel | Haute     | Absent         | docs/specs/home/            |
| 3 | manga (detail)| Fonctionnel | Haute     | Partiel (1 DTO test répertorié) | docs/specs/manga/ |
| 4 | library       | Fonctionnel | Haute     | Absent         | docs/specs/library/         |
| 5 | reader        | Fonctionnel (mobile) / Stub (web) | Très haute | Absent | docs/specs/reader/ |
| 6 | download      | Fonctionnel (mobile) / Stub (web) | Haute      | Absent | docs/specs/download/ |
| 7 | search        | Fonctionnel | Faible    | Absent         | docs/specs/search/          |
| 8 | profile       | Fonctionnel | Moyenne   | Absent         | docs/specs/profile/         |
| 9 | stats         | Fonctionnel | Faible    | Absent         | docs/specs/stats/           |
| 10 | recommendations | Fonctionnel | Moyenne | Partiel (1 DTO test) | docs/specs/recommendations/ |
| 11 | friends       | Fonctionnel | Haute     | Absent         | docs/specs/friends/         |
| 12 | sharing       | Fonctionnel | Haute     | Absent         | docs/specs/sharing/         |
| 13 | comments      | Fonctionnel | Moyenne   | Absent         | docs/specs/comments/        |

---

## Points forts

1. **Architecture BLoC disciplinée** : séparation Events/States/BLoC cohérente sur les 13 features, avec choix pragmatiques documentés (factory pour DetailBloc, Cubits pour les formulaires auth, StatefulWidget pour les pages sans état partagé).
2. **Offline-first robuste** : stale-while-revalidate + queue OfflineAction + SyncService déployés sur les features core (home, library, manga detail) — l'utilisateur voit des données immédiates même sans réseau, et ses mutations sont rejouées automatiquement.
3. **Sécurité auth solide** : JWT tristate (success/networkError/rejected), verrou Completer pour les refreshes simultanés, stockage dans Keystore/Keychain/WebCrypto, biométrie optionnelle — conforme à l'état de l'art.
4. **RGPD structuré** : GdprService centralisé, consentement versioned (versions récupérées dynamiquement depuis l'API), articles 15/20/17 exposés, cases non pré-cochées à l'inscription, re-consentement bloquant au mount du shell (ADR RETRO-003).
5. **Design system cohérent** : tokens AppColors/AppRadius/AppSpacing/AppTextStyle + composants core/components/ + AppBreakpoints pour le responsive — base solide pour l'extension iOS et Web.
6. **Transition Web amorcée** : go_router opérationnel avec URL stables, platform-split via conditional exports sur reader, download, et WebView — les deux tiers du chemin sont faits.
7. **Décisions architecturales documentées** : 18 ADRs RETRO capturant les invariants de sécurité, de modèle de données et de performance — le projet est auto-documenté pour les futurs développeurs.

---

## Risques identifiés

| # | Risque | Criticité | Impact | Feature(s) |
|---|--------|-----------|--------|------------|
| 1 | Re-consentement RGPD absent dans `StartupPage._onLoginSuccess` : `GdprService.getConsentStatus()` n'est pas appelé explicitement après l'auto-login — le re-consentement est déclenché par BottomNavbar (RETRO-003) mais pas par la machine d'état de démarrage. Si un utilisateur atteint `/home` via un flux qui bypass BottomNavbar, le re-consentement n'est pas vérifié. | CRITIQUE | Non-conformité RGPD article 7 — exposition CNIL | auth, home |
| 2 | `serverClientId` Google hardcodé dans `auth.service.dart` (valeur `43781664315-...`) — une clé API visible dans le code source versionnée. | CRITIQUE | Sécurité — clé extractable du binaire APK | auth |
| 3 | `workmanager` Android-only non abstrait : `chapter_check_background_service.dart` bloque la compilation/fonctionnalité iOS et le build Web sans abstraction derrière une interface. | CRITIQUE | Bloque la roadmap iOS et Web | download, manga |
| 4 | `debugPrint` non gardés par `kDebugMode` dans AuthService (25+ occurrences) et BiometricService — émettent en production, certains contiennent `jsonCreds != null` (test de présence de credentials). | MAJEUR | Fuite potentielle d'informations en production | auth |
| 5 | Fichiers dépassant massivement les seuils du projet : `web_view_io.dart` (1173 lignes, seuil widget 150), `detail_bloc_view.dart` (1317 lignes), `late_detail.view.dart` (816 lignes), `detail_bloc.dart` (780 lignes, seuil BLoC 200), `library_bloc.dart` (386 lignes), `ad_blocker_service.dart` (834 lignes, seuil service 300). Ces fichiers sont inmaintenables et non testables en isolation. | MAJEUR | Maintenabilité et testabilité | manga, reader, library |
| 6 | Couverture de tests insuffisante : 7 fichiers de tests pour 13 features. Aucun test pour home, library, reader, download, search, profile, stats, friends, sharing, comments. | MAJEUR | Régression non détectée, blocage Play Store quality (exigence CLAUDE.md : min 1 widget + 1 BLoC par feature) | Toutes |
| 7 | Features sociales (friends, sharing, comments) sans cache offline — contraire au pattern offline-first du reste de l'app. Une perte réseau sur ces pages produit une erreur sans fallback. | MAJEUR | Expérience utilisateur dégradée, incohérence de l'app | friends, sharing, comments |
| 8 | Injection de dépendances via `getIt<>()` dans le corps des BLoCs (StatsBloc, FriendsBloc, CommentsBloc, ReadingGroupsBloc) plutôt qu'au constructeur — rend les tests unitaires impossibles sans configurer GetIt complet. | MAJEUR | Testabilité nulle des BLoCs récents | stats, friends, sharing, comments |
| 9 | `flutter_local_notifications` sans fallback Darwin iOS complet pour les notifications de nouveaux chapitres — bloque le fonctionnement des notifications sur iOS. | MAJEUR | Bloque les notifications iOS | manga, friends |
| 10 | Fichiers vues legacy coexistant avec les implémentations BLoC : `home_page.dart` (263 lignes) et `library.view.dart` (228 lignes) non référencés par le router mais présents dans le codebase — source de confusion et de dette morte. | MINEUR | Maintenabilité | home, library |
| 11 | Genres populaires hardcodés en français dans `search.dart` sans i18n — contredit la règle i18n du projet (CLAUDE.md : tout texte visible traduit en 7 langues). | MINEUR | Expérience utilisateur non localisée | search |
| 12 | `FriendshipDto` sans `toJson()` — sérialisation cache via mapping manuel dans `_writeCache()`. Si le DTO évolue, le cache peut se désérialiser silencieusement avec des valeurs manquantes. | MINEUR | Intégrité du cache friends | friends |
| 13 | Anti-doublon notifications (`Set<int> _notifiedShareIds`) non persisté — après redémarrage, les shares récents non vus peuvent re-déclencher des notifications locales. | MINEUR | Expérience utilisateur (spam notifications) | sharing, friends |
| 14 | Export de données RGPD article 20 via presse-papier uniquement (pas de fichier téléchargeable) — insuffisant pour une conformité robuste. | MINEUR | Conformité RGPD article 20 | profile |

---

## Recommandations stratégiques

1. **Sécuriser la conformité RGPD avant tout** : vérifier et compléter l'appel à `GdprService.getConsentStatus()` dans `StartupPage._onLoginSuccess`, et déplacer le `serverClientId` Google dans les assets `.env.*`.
2. **Découper les mega-fichiers en priorité** : `detail_bloc_view.dart` (1317 lignes), `web_view_io.dart` (1173 lignes), `detail_bloc.dart` (780 lignes), et `ad_blocker_service.dart` (834 lignes) bloquent la testabilité et la lisibilité — c'est le refactoring avec le meilleur ROI sur la maintenabilité.
3. **Abstraire `workmanager` derrière une interface** avant d'investir dans iOS ou Web — c'est le prerequisite technique non-négociable pour la roadmap multi-plateforme.
4. **Ajouter les tests des features core** (home, library, manga detail, auth services) avant les features sociales — le BLoC stale-while-revalidate et la queue offline sont les patterns les plus risqués à régresser.
5. **Migrer l'injection dans les BLoCs récents** (stats, friends, sharing, comments) vers le constructeur pour débloquer leur testabilité unitaire sans friction.
