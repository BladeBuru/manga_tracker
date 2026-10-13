# Décisions Architecturales — Manga Tracker Flutter

**Dernière mise à jour :** Mai 2026

---

## Décisions Prises

### State management : BLoC (flutter_bloc)
**Décision** : BLoC pattern avec `flutter_bloc` et `Equatable`.
**Raison** : Architecture réactive et testable, séparation claire UI/logique métier, flux unidirectionnel prévisible (Event → BLoC → State).
**Impact** : Un BLoC par feature, events et states avec `Equatable`, BLoCs exposés via `BlocProvider`.
**Date** : Conception initiale

---

### Injection de dépendances : GetIt (Service Locator)
**Décision** : GetIt comme service locator central.
**Raison** : Simple, performant, supporte singletons, lazy singletons, factories et init asynchrone.
**Impact** : `service_locator.dart` centralise tout, ordre d'init documenté, pas de `BuildContext` nécessaire pour accéder aux services.
**Date** : Conception initiale

---

### DetailBloc en Factory (CRITIQUE)
**Décision** : `DetailBloc` enregistré en **factory** dans GetIt.
**Raison** : Chaque page de détails doit avoir sa propre instance pour éviter les race conditions (navigation rapide entre pages).
**Impact** : `getIt<DetailBloc>()` crée une nouvelle instance — toujours wrapper dans un `BlocProvider` lors de la navigation.
**Date** : 2025-11 (correction de bug)

---

### Cache offline : SharedPreferences + JSON (pas Hive)
**Décision** : `flutter_secure_storage` + `shared_preferences` pour le cache offline.
**Raison** : Simplicité, pas de dépendance supplémentaire, données en JSON.
**Impact** : `OfflineCacheService` sérialise/désérialise en JSON.
**Date** : Conception initiale

---

### Détection offline : `SocketException` (pas ConnectivityService)
**Décision** : Détecter le mode offline via les `SocketException` sur les appels HTTP.
**Raison** : `ConnectivityService` peut indiquer "connecté" (WiFi) sans accès internet → faux négatifs.
**Impact** : Les BLoCs catchent `SocketException`. `ConnectivityService` utilisé uniquement pour la reconnexion (sync).
**Date** : 2025-11 (correction de bug)

---

### Internationalisation : ARB natif (7 langues)
**Décision** : i18n native Flutter avec ARB, 7 langues (FR, EN, DE, JA, KO, PT, ES).
**Raison** : Standard Flutter officiel, intégration native, génération auto.
**Impact** : Tous les textes visibles dans les ARB, `LanguageService` pour la persistance.
**Date** : Conception initiale

---

### Navigation : go_router, URL réelles, onglets avec URL (2026-10)
**Décision** : `go_router` (14.x) partout. Sur le web : `usePathUrlStrategy()`
(plus de `/#/`) et `GoRouter.optionURLReflectsImperativeAPIs = true` (les pages
empilées ont leur URL). Onglets en `StatefulShellRoute` (`/home`, `/library`,
`/search`, `/profile`) avec un `PageView` comme conteneur (`MainTabsPager`) :
glissement au doigt conservé sur téléphone, coupé à la souris / au pavé
tactile et sur le web ; onglets gardés vivants, rechargement en arrière-plan
au retour sur Accueil / Bibliothèque (comme avant, où l'onglet était
reconstruit). Retour Android hors accueil → onglet accueil.
**Raison** : sur le web, l'URL restait figée sur `/#/home` (F5 = accueil,
retour du navigateur = page de connexion).
**Impact** : toute page doit se reconstruire depuis son URL ; extras
sérialisés par `RouteExtrasCodec` (sauf lecteur et `UserInformationDto`).
**Remplace** : « Navigation : MaterialPageRoute (migration go_router prévue) ».
**Date** : 2026-10-13

---

### Garde d'authentification du routeur (2026-10)
**Décision** : `redirect` pur (`resolveAuthRedirect`) + `AuthSession`
(restaurée avant `runApp` depuis la présence de jetons utilisables).
`refreshListenable` = `AuthSession.routerRefresh`, qui ne notifie QUE la perte
de session : une connexion est toujours suivie d'une navigation explicite
(`AuthNavigation.completeSignIn`) — un rafraîchissement à ce moment quittait
`/login` avant la proposition de biométrie et laissait une entrée d'historique.
**Invariant offline-first** : une session **rejetée** (401/403,
`clearSessionTokens`) ne redirige jamais ; seule l'absence de session renvoie
à `/login?from=…`. `from` : chemin interne uniquement (`safeReturnPath`).
**Date** : 2026-10-13

---

### Historique du navigateur tenu par l'application (web, 2026-10)
**Décision** : `HistoryAwareRouteInformationProvider` enveloppe le fournisseur
go_router (web uniquement). (1) Un retour dans l'app vers l'état de l'entrée
précédente du navigateur devient un vrai `history.go(-n)` (sinon go_router
empile l'écran retrouvé : doublon « en avant », le retour du navigateur
rouvrait la page quittée). (2) Une restauration redirigée (retour vers une page
interdite, déconnexion) remplace l'entrée. (3) Les `await context.push(...)`
sont terminés (`null`) quand le navigateur retire la page, et re-branchés quand
go_router recrée la pile (flutter/flutter#128122). Rang des entrées lu dans
`history.state.serialCount` (moteur Flutter web).
**Limites** : après un F5, les entrées précédentes ne sont pas connues → un
retour in-app empile alors une entrée (pas de faux retour) ; une navigation
lancée pendant les quelques ms de traitement du retour est rejouée après lui.
**Alternatives écartées** : signaler les retours en remplacement (laisse des
entrées mortes) ; rien (doublons).
**Date** : 2026-10-13

---

### Web sans service worker de cache (2026-10)
**Décision** : `flutter build web --pwa-strategy=none` + `web/flutter_bootstrap.js`
sans `serviceWorkerSettings` ; interrupteur d'arrêt
(`deploy/web/flutter_service_worker.js`) et nettoyage dans `web/index.html`
pour les navigateurs qui ont l'ancien ; nginx revalide tout (aucun fichier du
build n'a de hash) ; bandeau « Recharger » (`WebVersionWatcher`,
`MT_WEB_BUILD`).
**Raison** : le service worker « hors ligne d'abord » servait une version de
plusieurs mois jusqu'à l'effacement des données du site. L'app n'a pas de
mode hors ligne web (cache de données dans `shared_preferences`).
**Date** : 2026-10-13

---

### Thème : Material 3 (sombre prévu)
**Décision** : Material 3 avec thème clair actif, sombre commenté.
**Raison** : Standard moderne, design tokens cohérents.
**Impact** : Utiliser `Theme.of(context).colorScheme.*` et `AppRadius` exclusivement.
**Date** : Conception initiale

---

### HTTP client : `http` package (pas Dio)
**Décision** : Package `http` standard, encapsulé dans `HttpService`.
**Raison** : Simplicité, moins de dépendances.
**Impact** : Tout accès réseau via `HttpService`.
**Date** : Conception initiale

---

### 🆕 Platform-agnostic par défaut (évolution)
**Décision** : Tout nouveau code doit fonctionner sur Android, iOS et Web sauf justification documentée.
**Raison** : L'app cible Android (actuel), iOS et Web (à venir). Ajouter des dépendances Android-only sans abstraction crée une dette techniquement coûteuse à rembourser plus tard.
**Impact** :
- Toute API native (notif, background task, file pick) doit être derrière une interface dans `core/services/` avec impl conditionnelle.
- `dart:io` direct interdit dans `lib/` — utiliser `path_provider` ou abstraire.
- `Platform.isAndroid` jamais dispersé — encapsulé dans le service_locator ou un service abstrait.
- Nouveaux packages : vérifier compat iOS/Web AVANT ajout à `pubspec.yaml`.
**Date** : 2026-05 (évolution multi-plateformes)

---

### 🆕 Play Store quality non-négociable (évolution)
**Décision** : L'app doit passer la review Play Store sans ajustement de dernière minute.
**Raison** : Qualité requise pour la distribution publique. Évite les rejections en cascade.
**Impact** :
- `key.properties` et `*.jks` toujours dans `.gitignore`.
- Build App Bundle (`.aab`) pour les releases Play Store.
- `targetSdkVersion` ≥ 34, ProGuard/R8 actif en release.
- Permissions Android justifiées dans le manifest.
- Privacy policy URL renseignée.
- Tests : minimum 1 widget test + 1 BLoC test par feature.
- Accessibilité : labels TalkBack, contraste WCAG AA, font scaling.
**Date** : 2026-05 (évolution qualité)

---

### 🆕 Design system mature (évolution)
**Décision** : Étendre les tokens du design system + promouvoir les composants réutilisables.
**Raison** : Aujourd'hui les paddings sont hardcodés, certains composants sont dupliqués entre features. Pour iOS/Web et la qualité Play Store, le design system doit être robuste.
**Impact** :
- Créer `lib/core/theme/app_spacing.dart` (tokens xs/s/m/l/xl/jumbo).
- Promouvoir `MangaCard`, `MangaRow`, `OfflineBanner`, `LoadingSkeleton`, `EmptyState`, `ErrorState` vers `core/components/`.
- Skill `/add-component` à utiliser pour la création.
**Date** : 2026-05 (évolution design)

---

### 🆕 Accueil catalogue : titres déduits côté client, ordre serveur, kind inconnu ignoré
**Décision** : `GET /mangas/home/sections` ne renvoie **aucun titre** ; l'app le déduit de `kind` + `params` (`HomeSectionL10n`, ARB × 7). L'ordre et la présence des sections sont pilotés par le serveur ; un `kind` inconnu est ignoré sans planter.
**Raison** : le catalogue (25 000+ titres) évolue plus vite que l'app — le serveur peut ajouter / réordonner des sections sans release, et les anciens APK ne cassent pas sur un `kind` nouveau. Les titres restent traduits dans les 7 langues, ce qu'un titre serveur ne garantirait pas.
**Impact** : un nouveau `kind` = une clé ARB × 7 + une entrée dans `HomeSectionKind` / `HomeSectionL10n` ; tant qu'elle n'existe pas, la section est simplement absente. Un BLoC dédié (`HomeSectionsBloc`) avec son cache (`cached_home_sections`) — `HomePageBloc` ne charge plus tendances / nouveautés / populaires.
**Date** : 2026-09-05

### 🆕 Lecteur en ligne : réglages WebView figés à la création, user-agent intact (2026-09-05)

**Décision** :
1. Les réglages de la WebView du lecteur sont construits par
   `ReaderWebViewSettings.build()` et posés **uniquement** via
   `initialSettings`. `controller.setSettings(...)` est **interdit** sur cette
   WebView.
2. Le **user-agent de la plateforme n'est pas modifié**. Le module
   `WebViewUserAgent` (v0.13.0, retrait de `; wv` / `Version/4.0`) est retiré.
3. L'en-tête `X-Requested-With` (nom du paquet de l'app, ajouté par la WebView
   Android à chaque requête) n'est envoyé à aucune origine
   (`requestedWithHeaderOriginAllowList: {}`).

**Pourquoi** :
- (1) Côté Android, `setSettings` remplace l'objet de réglages *entier* par un
  objet neuf (`InAppWebView.java`, `customSettings = newCustomSettings`). Tout
  réglage non renseigné reprend sa valeur par défaut — dont
  `useShouldOverrideUrlLoading` (défaut `false`), que le plugin n'infère que
  pour les réglages initiaux. C'est ce qui a rendu la protection
  anti-redirection inerte en v0.13.0.
- (2) Chromium (intent « UA Client Hints on Android WebView », 2023) : *« for
  overridden user-agent strings, we only populate user-agent client hints if
  the overridden user-agent contains the default user-agent »*. Un UA
  « Chrome sans wv » ne contient plus le UA par défaut → plus aucun
  `Sec-CH-UA`, alors que tout Chrome ≥ 116 les envoie. Les vérifications
  anti-robot recoupent explicitement « la cohérence du User-Agent et de la
  plateforme ». Le UA d'origine (WebView annoncée comme telle, indices client
  « Android WebView ») est au moins **cohérent**, et c'est celui avec lequel
  la vérification fonctionnait auparavant.
- (3) API d'opt-in officielle d'Android (déprécation en cours de l'envoi par
  défaut) ; l'en-tête ne sert à aucun site de lecture et identifie
  l'application.

**Ce qui n'a PAS été fait, et pourquoi** : flutter_inappwebview 6.1.5
(dernière stable) n'offre aucun réglage pour limiter ses scripts injectés
(`window.flutter_inappwebview`, etc.) à la frame principale ou par origine ;
ces réglages (`pluginScriptsForMainFrameOnly`, `javaScriptBridgeEnabled`…)
n'existent qu'en 6.2.0-beta. Passer sur une bêta sans test sur appareil est
exclu. Piste documentée dans `known-issues.md`.

**Alternative écartée** : normaliser le UA en *ajoutant* un suffixe au UA
par défaut (les indices client resteraient envoyés) — sans bénéfice : la
WebView resterait identifiée comme telle par `Sec-CH-UA`.

**Correctif mesuré (2026-09-27)** : le point (3) est **sans effet** sur les
WebView récentes (153 testée) — la fonctionnalité `REQUESTED_WITH_HEADER_ALLOW_LIST`
n'y est plus prise en charge, `X-Requested-With: <paquet>` part toujours. Le
réglage est conservé (inoffensif, utile sur d'anciennes WebView). Mesuré aussi :
cet en-tête n'est PAS ce qui fait échouer Cloudflare (Chrome qui l'envoie passe).

---

### 🆕 Lecteur en ligne : vérification Cloudflare confiée à une WebView brute (2026-09-27)

**Décision** : quand la réponse du document principal est un défi Cloudflare
(`cf-mitigated: challenge`, lu dans `onReceivedHttpError`), le lecteur arrête
aussitôt sa page (`about:blank`) et affiche par-dessus `ChallengeHandoffView` :
une WebView **webview_flutter sans aucun ajout** (ni script, ni canal
JavaScript, ni `onNavigationRequest`). Dès qu'un nouveau `cf_clearance`
apparaît dans le magasin de cookies partagé, la vue se retire et le lecteur
recharge la page. `webview_flutter_android` devient une dépendance directe
(déjà résolue en transitif) pour accepter les cookies tiers du widget.

**Pourquoi** : mesuré sur appareil (Pixel 9 Pro XL, manga-scantrad.io, build
`MT_READER_DIAG` + DevTools) — dans la WebView flutter_inappwebview, Cloudflare
valide le défi et pose un `cf_clearance`, puis le refuse à la requête suivante :
l'environnement injecté par le plugin (pont `window.flutter_inappwebview`,
`window.print` remplacée, dans toutes les frames) est classé comme robot. Une
WebView brute passe du premier coup et son cookie est accepté ensuite par le
lecteur. Essais A/B : garde anti-redirection, UA, `X-Requested-With`,
bloqueur et réseau écartés. Détails : `known-issues.md` (Problèmes résolus).

**Invariants** :
- Le défi ne doit JAMAIS s'exécuter dans le lecteur : son « succès » y pose un
  cookie refusé qui écraserait le bon.
- Aucune résolution automatisée : c'est l'utilisateur qui fait le défi.
- Pendant la délégation, le lecteur ne mesure, ne sauvegarde, ne valide et ne
  télécharge rien.

**Alternatives écartées** :
- flutter_inappwebview 6.2.0-beta (`pluginScriptsForMainFrameOnly`…) : bêta,
  et le défi tourne AUSSI dans la frame principale — restreindre aux frames
  tierces ne suffirait pas ; non prouvé.
- Custom Tab Chrome pour les sites protégés : passe, mais perd bloqueur,
  protection anti-redirection et suivi des chapitres.

---

## Décisions Futures à Prendre

| Sujet | Contexte | Deadline | Options |
|-------|----------|----------|---------|
| Thème sombre | Code déjà préparé | v0.4 | Activer + tester sur toutes les vues |
| Tests | Structure prête | v0.4 | Commencer par les BLoCs critiques |
| Notifications push | Alertes nouvelles sorties | v0.5 | `firebase_messaging` (multi-plateformes) |
| Stockage offline avancé | Si cache JSON insuffisant | v0.5 | Hive vs Isar vs Drift |
| iOS adaptive UI | Material vs Cupertino adaptive | Avant App Store | A : Material partout (simple) / B : Adaptive (UX iOS native) |
| Background tasks iOS | Remplacer workmanager | Avant App Store | BGTaskScheduler via plugin custom ou plugin existant |

---

## Alternatives Considérées

| Décision | Alternative rejetée | Raison du rejet |
|----------|-------------------|-----------------|
| BLoC | Provider / Riverpod / GetX | BLoC plus structuré, meilleure séparation, plus testable |
| GetIt | Injectable / Riverpod DI | GetIt plus simple, pas de code generation |
| SharedPreferences | Hive / Isar | Complexité inutile pour le cache JSON actuel |
| `http` | Dio | Simplicité ; Dio dispo si besoin de fonctionnalités avancées |
| ARB natif | `easy_localization` / `get` i18n | Standard officiel Flutter |
