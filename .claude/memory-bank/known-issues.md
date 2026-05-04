# Problèmes Connus — Manga Tracker Flutter

**Dernière mise à jour :** Mai 2026

---

## 🐛 Problèmes Actifs

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
