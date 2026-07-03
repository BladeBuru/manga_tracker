# Problèmes Connus — Manga Tracker Flutter

**Dernière mise à jour :** Juillet 2026

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
