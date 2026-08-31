# Problèmes Connus — Manga Tracker Flutter

**Dernière mise à jour :** Août 2026

---

## 🐛 Problèmes Actifs

### Google Sign-In : OAuth client **Android** absent de la console GCP
- **Module** : auth (Google Sign-In mobile)
- **Sévérité** : 🔴 Critique (la connexion Google ne fonctionne pas du tout)
- **Découvert le** : 2026-07-03
- **Statut** : Actif — **action manuelle console Google Cloud requise**

**Description** : le flux natif Credential Manager (`google_sign_in` v7) exige un
OAuth client de type **Android** (package + SHA-1 de signature) dans le projet
GCP `43781664315`, en plus du client Web utilisé comme `serverClientId`. Aucun
client Android n'est déclaré → le sélecteur de compte s'affiche (UI système)
puis Google refuse d'émettre l'idToken après le choix du compte.

**Diagnostic 2026-07-03 (vérifié)** : le client Web `43781664315-4qruuj…` existe
toujours ; le `GOOGLE_CLIENT_ID` de prod (lu dans la redirection `GET
/auth/google`) est identique au `serverClientId` hardcodé → pas de mismatch
d'audience. Par élimination : client Android manquant/mauvais SHA-1.

**Solution (console GCP → APIs & Services → Credentials → Create OAuth client ID)** :
1. Type **Android** — package `com.example.manga_tracker`, SHA-1
   `F8:A8:85:63:C1:62:9C:12:06:65:29:14:59:DE:1F:2A:9A:5F:52:4B`
   (cert du keystore `upload` — celui de l'APK GitHub Releases, vérifié sur v0.11.0).
2. (Dev) Type **Android** — package `com.example.manga_tracker.dev` + SHA-1 du
   keystore debug (`keytool -list -v -keystore ~/.android/debug.keystore -alias
   androiddebugkey -storepass android`).
3. Ne PAS toucher au client Web (il sert d'audience à l'API et au flux web).
4. À la migration Play Store : ajouter le SHA-1 de re-signature Play App Signing.

Le code affiche désormais un message dédié (`googleLoginConfigError`) et logge
le code d'erreur (`adb logcat | grep GoogleSignInException`) pour confirmer.

---

### `key.properties` versionné dans git
- **Module** : android signing
- **Sévérité** : 🔴 Critique
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : `android/key.properties` est versionné. Ce fichier contient le mot de passe du keystore Android.

**Impact** : Si le keystore (`upload-keystore.jks`) est aussi versionné ou exposé, signature de l'app compromise. Risque réel pour la release Play Store.

**Solution** :
1. `git rm --cached android/key.properties android/app/upload-keystore.jks` (si présents)
2. Ajouter au `.gitignore` :
   ```
   android/key.properties
   android/app/*.jks
   android/app/*.keystore
   ```
3. Stocker le keystore hors repo (1Password, GitHub Secrets en base64)
4. **Rotation du mot de passe keystore** si exposé publiquement

---

### `workmanager` Android-only sans abstraction
- **Module** : `lib/features/manga/services/chapter_check_background_service.dart`
- **Sévérité** : 🟠 Haute (bloque iOS/Web)
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : Le service de vérification périodique des nouveaux chapitres utilise `workmanager` directement, sans abstraction.

**Impact** : Aucune périodicité possible sur iOS et Web. Les notifications de nouveaux chapitres ne fonctionneront que sur Android.

**Solution** : Créer une interface `BackgroundTaskService` dans `core/services/` avec implémentations Android (workmanager), iOS (BGTaskScheduler), Web (service worker ou polling). Voir `.claude/docs/cross-platform.md`.

---

### `AndroidFlutterLocalNotificationsPlugin` explicite
- **Module** : `lib/features/manga/services/notification_service.dart` (lignes 41-44)
- **Sévérité** : 🟠 Haute (bloque iOS)
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : `notification_service.dart` instancie explicitement `AndroidFlutterLocalNotificationsPlugin`. Pas de fallback Darwin pour iOS.

**Impact** : Notifications locales non fonctionnelles sur iOS.

**Solution** : Ajouter `DarwinInitializationSettings` dans la conf, instancier la plugin via `flutter_local_notifications` standard (multi-plateforme), encapsuler derrière une interface `NotificationService`.

---

### `dart:io` direct dans `lib/`
- **Module** : multiple (audit `grep -rn "import 'dart:io'" lib/`)
- **Sévérité** : 🟠 Haute (bloque Web)
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : Plusieurs fichiers importent `dart:io` directement (notamment dans `features/download/`). `dart:io` n'existe pas sur le Web.

**Impact** : `flutter build web` échouera dès qu'on touchera ces fichiers.

**Solution** : Remplacer `File` / `Directory` par `path_provider` quand possible. Pour les téléchargements, abstraire derrière un service plateforme.

---

### iOS et Web scaffoldés mais pas wirés
- **Module** : `ios/`, `web/`
- **Sévérité** : 🟡 Moyenne
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : Les dossiers `ios/` et `web/` existent (scaffolding Flutter par défaut) mais aucun travail spécifique n'a été fait : pas de signing iOS, pas de PWA manifest pour Web, pas de tests sur ces plateformes.

**Impact** : Les builds iOS/Web ne sont pas prêts pour distribution.

**Solution** : Suivre les skills `/ios-readiness` et `/web-readiness` quand le moment viendra de wirer ces plateformes.

---

### Pas de `Platform` guards
- **Module** : transverse
- **Sévérité** : 🟡 Moyenne
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : Aucune utilisation de `Platform.isAndroid` / `Platform.isIOS` / `kIsWeb` dans le code. Tout est implicitement Android.

**Impact** : Code écrit avec l'hypothèse Android implicite — risque de crash sur iOS/Web pour toute fonctionnalité native.

**Solution** : Lors de chaque ajout d'API native, encapsuler dans un service abstrait + impl plateforme. Voir `.claude/skills/cross-platform-audit/SKILL.md`.

---

### Pas de `AppSpacing` token
- **Module** : `core/theme/`
- **Sévérité** : 🟢 Basse
- **Découvert le** : 2026-05
- **Statut** : Actif

**Description** : Les paddings sont hardcodés (`EdgeInsets.all(16)`, etc.) au lieu d'utiliser un token.

**Impact** : Inconsistance dans les espacements, difficile à modifier globalement.

**Solution** : Créer `lib/core/theme/app_spacing.dart` avec `xs/s/m/l/xl/jumbo`. Migration progressive des paddings existants.

---

## ✅ Problèmes Résolus

### Mode hors ligne : cache jamais servi quand le token est expiré
- **Feature** : manga (détail) / library / home / search / stats
- **Résolu le** : 2026-08-31
- **Sévérité** : 🔴 Critique (le mode hors ligne était inutilisable)

**Symptôme utilisateur** : « Si le token n'est pas valide, ça ne l'affiche pas. »
Le détail d'un manga déjà consulté restait inaccessible hors ligne, et le
bandeau hors ligne apparaissait de façon erratique.

**Causes racines (deux, distinctes)** :

1. **Chemin d'erreur d'authentification jamais relié au cache.**
   `HttpService._addAuthHeaders` (`http_service.dart:135`) levait
   `InvalidCredentialsException` dès que les deux tokens étaient expirés
   *d'après l'horloge locale*, sans avoir contacté le serveur. Les BLoCs
   interceptaient cette exception **avant** le repli sur le cache, par
   comparaison de chaîne, puis `return` sec :
   `detail_bloc.dart:126-135`, `library_bloc.dart:97-103`,
   `homepage_bloc.dart:139-142`. Le détail déjà rendu depuis le cache était
   donc remplacé par un écran d'erreur, avec `isOffline: false` — d'où
   l'absence simultanée de contenu **et** de bandeau.

2. **Progression de lecture non mise en cache.**
   `LibraryService.getLibraryEntry` appelait `getUserSavedMangas()`, qui part
   au réseau sans aucun repli. C'est cette entrée qui porte « où j'en suis »
   (chapitres lus, statut). Hors ligne, l'exception était avalée par
   `DetailBloc._enrichWithLibraryInfo`, qui renvoyait le détail **non
   enrichi** : la fiche s'affichait comme si le manga n'était pas dans la
   bibliothèque. Même une fois la cause n°1 corrigée, le cas d'usage
   « je regarde où j'en suis dans le train » restait cassé.

**Causes secondaires du bandeau erratique** :
- `on SocketException` est du **code mort sur le web** : `package:http` y lève
  `ClientException`. Toute panne réseau web tombait dans le `catch` générique
  → `isOffline: false` (`search_bloc.dart`).
- La détection par chaîne `e.toString().contains('InvalidCredentialsException')`
  reposait sur `Object.toString()` — que dart2js minifie en release web — car
  la classe n'avait **pas** de `toString()`.
- Les 6 handlers de mutation de `LibraryBloc` et `_section()` de `HomePageBloc`
  **héritaient** `isOffline` de l'état précédent au lieu de le ré-évaluer.
- `DetailActionInProgress` / `HomePageActionInProgress` n'étaient pas consultés
  par les vues → le bandeau disparaissait pendant chaque mutation.
- `StatsLoaded.isOffline` n'était jamais renseigné → `StatsOfflineBanner`
  inatteignable.
- Les 4 handlers de mutation de `DetailBloc` n'émettaient **rien** hors ligne →
  bloc bloqué sur `DetailActionInProgress`, spinner plein écran sans issue.

**Solution** : taxonomie d'échec centralisée dans
`lib/core/network/failure_classifier.dart` (`network`, `sessionExpired`,
`sessionRejected`, `other`) + nouvelle `SessionExpiredException` pour le cas
« plus de credentials utilisables, **aucun verdict serveur** ». Le cache est
servi en lecture pour `network` et `sessionExpired` ; seul un rejet explicite
du serveur (401/403) renvoie au login sans servir le cache. Voir
`.claude/docs/offline-architecture.md` pour la frontière de sécurité complète.

**Tests** : 26 tests (classifier, DetailBloc, LibraryBloc, LibraryService,
SearchBloc web). Un test rouge a d'abord reproduit le bug.

### Progression perdue en silence quand le chapitre lu dépasse le total connu
- **Feature** : reader / library
- **Résolu le** : 2026-08-28
- **Symptôme** : « MangaUpdates dit 79 chapitres, j'en ai lu 90 ». À la fermeture
  du lecteur, l'utilisateur confirme « Vous avez bien lu jusqu'au 90 ? » → Oui,
  et **rien n'est enregistré, sans aucun message**. Au retour sur la fiche, le
  compteur est resté à l'ancienne valeur.
- **Cause** : l'API cape `readChapters` au total effectif du manga et répond
  **406** au-delà (`library.service.ts`, `updateChapter`). Côté app,
  `LibraryService.saveChapterProgress` ne testait que `statusCode == 200` :
  le 406 tombait dans le `return false` générique, `_lastCommitted` n'était
  pas mis à jour et aucun retour n'était affiché (le `Notifier` n'est appelé
  que sur succès).
- **Solution** : paramètre **opt-in** `autoReportIfAboveTotal` sur
  `saveChapterProgress`. Sur 406, il déclenche
  `ChapterReportService.reportMoreChapters` (le signalement communautaire
  existant) puis **un seul** rejeu du PUT — la progression aboutit et le total
  du manga est corrigé pour tout le monde. Si le signalement est refusé
  (400 bornes / 404 / 429 throttle / réseau), échec silencieux comme avant,
  sans boucle ni blocage du flux de lecture.
- **Pourquoi opt-in** : `web_view_io.dart` commite aussi sur simple navigation
  vers le chapitre suivant (`_handleDetected`, `ChapterChangeType.nextChapter`),
  sans confirmation. Un numéro mal détecté dans l'URL ne doit jamais alimenter
  la base communautaire. Le flag n'est armé que sur les chemins d'assertion
  explicite : dialogue « Valider la lecture » (`_onWillPop`), dialogue de saut
  de chapitres (`_promptJumpConfirm`), et tap sur un chapitre depuis la fiche
  détail (`DetailBloc._onSaveChapterProgress` + fallback `late_detail.view`).
  Le reader offline n'a aucun dialogue de confirmation (garde near-end seule)
  → volontairement laissé sans rattrapage.
- **Effet de bord corrigé** : `HttpStatus.notAcceptable` (406) manquait dans les
  deux shims `network_compat_io.dart` / `network_compat_web.dart`.
- Tests : `test/features/library/services/library_service_chapter_progress_test.dart`.

### Reader : chapitre non détecté quand le numéro est un segment d'URL isolé
- **Feature** : reader
- **Résolu le** : 2026-08-25
- **Symptôme** : sur `https://raijin-scans.fr/manga/the-great-mage-returns-after-4000-years/190/`,
  aucun suivi de chapitre (le 190 n'était pas détecté) et bouton « chapitre
  suivant » mort. Piège associé : le `4000` du slug ne devait jamais être pris
  pour un chapitre.
- **Cause** : `ChapterLinkResolver` ne connaissait que les query params et les
  patterns de chemin préfixés (`chapitre-N`, `cN`, `/manga/N`…) ; une URL dont
  le chapitre est un segment numérique nu (`/manga/<slug>/190/`) ne matchait
  rien → `extractChapter` retournait null.
- **Solution** : étape 3 de fallback « segment numérique isolé »
  (`lib/features/reader/utils/chapter_url_heuristics.dart`) appliquée APRÈS
  les sélecteurs custom (étape 0) et les patterns connus (étapes 1-2) :
  seuls les segments de chemin entièrement numériques sont candidats, le
  dernier gagne (gère `/190/chapter/xxx`), garde-fous anti-faux-positifs
  (paires date `/2024/05/`, segments > 6 chiffres). Symétrie assurée dans
  `buildUrlForChapter(Sync)` pour la navigation chapitre suivant (`/190/` →
  `/191/`). Duplication async/sync factorisée (listes de patterns partagées).
  Tests : `test/features/reader/chapter_link_resolver_test.dart` (20 cas).

### Recherche : résultats non pertinents, plafonnés à 20, sans pagination
- **Feature** : search
- **Résolu le** : 2026-07-03
- **Symptôme** : « Shadow System » introuvable (1er résultat sur mangaupdates.com),
  « Naruto » mal classé, liste limitée à ~20 résultats sans scroll infini.
- **Cause** : côté API, `orderby: 'rating'` écrasait le tri par pertinence de
  MangaUpdates (les titres de niche sortaient du top-60 téléchargé, le re-tri
  local ne pouvait pas les repêcher) ; côté Flutter, aucun paramètre de
  pagination envoyé et un `FutureBuilder` sans `ScrollController`.
- **Solution** : API alignée sur le classement MangaUpdates (pas d'`orderby`,
  `perpage = limit`, enveloppe paginée `{results, totalHits, page, perPage,
  hasMore}` rétrocompatible) ; côté app, `SearchBloc` (accumulation des pages,
  dédoublonnage par `muId`, fallback cache offline) + `SearchResultsList`
  (scroll infini, seuil 400 px). Tests : `test/features/search/search_bloc_test.dart`.

### Google Sign-In : annulation affichée comme un échec
- **Feature** : auth
- **Résolu le** : 2026-07-03
- **Symptôme** : fermer le sélecteur de compte Google affichait « Échec de la
  connexion avec Google » ; toutes les erreurs (annulation, config, réseau,
  backend) produisaient le même message, rendant le diagnostic impossible.
- **Solution** : `loginWithGoogle` retourne `GoogleLoginResult`
  (success/cancelled/configError/failed) ; l'annulation est silencieuse, les
  erreurs de configuration OAuth ont un message dédié (`googleLoginConfigError`,
  7 langues) et le code `GoogleSignInException` est loggé.

### Race conditions sur DetailBloc
- **Feature** : manga/detail
- **Résolu le** : 2025-11
- **Symptôme** : En naviguant rapidement entre plusieurs pages de détails, les états se mélangeaient.
- **Solution** : `DetailBloc` enregistré en **factory** dans GetIt (une nouvelle instance par page).

### Détection offline incorrecte (faux positifs)
- **Feature** : mode offline / tous les BLoCs
- **Résolu le** : 2025-11
- **Symptôme** : L'app passait en mode offline alors que la connexion était présente.
- **Solution** : Détection basée sur `SocketException` plutôt que `ConnectivityService`.

### Perte silencieuse des actions offline
- **Feature** : library / offline queue
- **Résolu le** : 2025-11
- **Symptôme** : Actions effectuées offline disparaissaient sans être synchronisées.
- **Solution** : Gestion explicite des échecs dans `SyncService` — conservation dans la queue pour retry.

### `readChaptersCount` incorrect après suppression
- **Feature** : manga/detail, library
- **Résolu le** : 2025-11
- **Symptôme** : Compteur de chapitres lus incorrect après suppression d'un manga.
- **Solution** : Reset explicite de `readChaptersCount` lors de la suppression.

---

## ⚠️ Workarounds Temporaires

_(À compléter)_

---

## 💡 Améliorations Identifiées

- Tests : étendre la couverture (actuellement 6 fichiers de test)
- Promouvoir `OfflineBanner`, `MangaCard`, `MangaRow`, `LoadingSkeleton` vers `core/components/`
- CI : ajouter `flutter analyze` + `flutter test` avant build
- Web : configurer Firebase Hosting (ou autre) avant le premier déploiement web

---

## 📋 Format d'un problème

```
### [Titre court]

- **Feature/Module** : [auth | home | library | manga | profile | search | reader | infra]
- **Sévérité** : [Critique | Haute | Moyenne | Basse]
- **Découvert le** : AAAA-MM-JJ
- **Statut** : [Actif | En cours | Résolu]

**Description** : Explication.

**Reproduction** :
1. Étape 1
2. Étape 2

**Cause** : Explication technique.

**Solution / Workaround** : Ce qui est fait ou prévu.
```
