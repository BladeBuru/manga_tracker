---
name: ios-readiness
description: Préparer Manga Tracker Flutter pour iOS / App Store — Info.plist permissions, Darwin notifications, signing & provisioning, IAP si applicable, Cupertino fallbacks pour widgets purement Material, stockage iOS sandboxé.
---

# Skill : iOS readiness — Manga Tracker Flutter

Préparer l'app pour App Store Connect.

---

## 1. `Info.plist` — Permissions

Toute API native qui nécessite une permission DOIT déclarer une `NSXxxUsageDescription` avec un message **user-facing localisé**. Sans ça, App Store Review rejette l'app.

### Permissions à anticiper

| Permission | Clé Info.plist | Quand |
|------------|---------------|-------|
| Caméra | `NSCameraUsageDescription` | Si scan QR / photo de profil |
| Photo Library | `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription` | Si import / export images |
| Face ID | `NSFaceIDUsageDescription` | **OUI** (déjà via `local_auth`) |
| Notifications | (pas de clé Info.plist, runtime) | Pour les notifs locales |
| Microphone | `NSMicrophoneUsageDescription` | Non utilisé actuellement |
| Localisation | `NSLocationWhenInUseUsageDescription` | Non utilisé actuellement |

### Exemple

```xml
<key>NSFaceIDUsageDescription</key>
<string>Manga Tracker uses Face ID to securely log you in.</string>
```

À localiser via `InfoPlist.strings` pour les 7 langues.

---

## 2. Signing & Provisioning

- [ ] **Apple Developer account** actif (compte $99/an).
- [ ] **Bundle Identifier** dans Xcode (ex: `com.manga-tracker.app`).
- [ ] **Team ID** configuré.
- [ ] **Provisioning Profile** créé (Development + Distribution).
- [ ] Profils stockés **hors repo** (App Store Connect API key dans GitHub Secrets / vault).
- [ ] Pas de `.mobileprovision` versionné.
- [ ] Pas de certificat (`.p12`) versionné.

CI/CD : utiliser Fastlane Match pour synchroniser certs/profils.

---

## 3. Notifications iOS

`flutter_local_notifications` supporte iOS via Darwin. Vérifier :

```dart
// notification_service.dart — ajouter init iOS
final iosSettings = DarwinInitializationSettings(
  requestAlertPermission: false, // demander à l'usage
  requestBadgePermission: false,
  requestSoundPermission: false,
);

final initSettings = InitializationSettings(
  android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  iOS: iosSettings,
);
```

Pour les **push notifications** (futur) : APNs via Firebase Cloud Messaging.

---

## 4. Background tasks

`workmanager` n'existe pas sur iOS. Utiliser `BGTaskScheduler` (iOS 13+) ou abstraire :

```dart
abstract class BackgroundTaskService {
  Future<void> registerPeriodicTask({
    required String name,
    required Duration frequency,
  });
}

class AndroidBackgroundTaskService implements BackgroundTaskService {
  // workmanager
}

class IOSBackgroundTaskService implements BackgroundTaskService {
  // BGTaskScheduler via flutter_workmanager fork ou plugin custom
}
```

`chapter_check_background_service.dart` actuel est Android-only — à abstraire avant iOS.

---

## 5. Stockage iOS

iOS sandboxe les apps : pas d'accès au file system général.

- [ ] Téléchargements (`download_manager_service.dart`) → utiliser `path_provider` (`getApplicationDocumentsDirectory()`).
- [ ] Pas de `dart:io` direct — déjà flagué dans cross-platform audit.
- [ ] `flutter_secure_storage` → utilise Keychain iOS (OK).
- [ ] `shared_preferences` → utilise NSUserDefaults (OK).

---

## 6. UI — Cupertino fallbacks

Material 3 fonctionne sur iOS mais l'UX iOS attend des éléments natifs (swipe back, transitions, switches Cupertino). Selon la stratégie :

### Option A : Material partout (acceptable)
- L'app garde son look Material sur iOS.
- Plus simple à maintenir.

### Option B : Adaptive (recommandé pour App Store)
- Utiliser `Switch.adaptive`, `CupertinoNavigationBar` quand iOS.
- `CupertinoPageRoute` au lieu de `MaterialPageRoute` sur iOS (swipe back natif).
- Wrappers `Adaptive*` à créer dans `core/components/`.

À documenter dans `.claude/memory-bank/decisions.md` avant implémentation.

---

## 7. App Store metadata

- [ ] App name (30 caractères max)
- [ ] Subtitle (30 caractères max)
- [ ] Description (4000 caractères) — localisée 7 langues
- [ ] Keywords (100 caractères, séparés par virgules)
- [ ] Screenshots iPhone (6.7", 6.5", 5.5") — obligatoires
- [ ] Screenshots iPad si supporté
- [ ] Icon `1024×1024` PNG sans alpha, sans coins arrondis
- [ ] Privacy policy URL — obligatoire pour les apps qui collectent des données
- [ ] Privacy nutrition label (App Privacy section dans App Store Connect)

---

## 8. Conformité App Review

- [ ] Pas de mention de plateformes concurrentes (pas "Android", "Google Play")
- [ ] Pas de fonctionnalité non implémentée mentionnée
- [ ] Si IAP (achats in-app) → utiliser StoreKit (pas Stripe / autres) — Apple le rejettera sinon
- [ ] Compte test fourni avec credentials (pas de SMS / captcha)
- [ ] `Application Loader` ou Xcode pour upload vers App Store Connect

---

## 9. Conformité légale

- [ ] App Tracking Transparency (ATT) si tracking — `NSUserTrackingUsageDescription`
- [ ] Privacy Manifest (`PrivacyInfo.xcprivacy`) — exigence iOS 17+
- [ ] Si SDKs tiers (Firebase, Sentry, etc.) → vérifier qu'ils ont un Privacy Manifest

---

## 10. Plan d'action

```markdown
## iOS readiness — Manga Tracker Flutter

### 🔴 Bloquants build iOS
- [ ] [Item] — [fichier] — fix : [action]

### 🟠 Bloquants App Store
- [ ] Privacy Manifest manquant
- [ ] BGTaskScheduler abstraction
- [ ] Localisation Info.plist

### 🟡 Améliorations UX iOS
- [ ] Cupertino adaptive widgets

### ✅ Déjà OK
- [ ] flutter_secure_storage
- [ ] local_auth (Face ID)

### Plan d'exécution
1. Phase 1 : abstraire BGTaskScheduler + notifications Darwin
2. Phase 2 : Info.plist + Privacy Manifest + ATT
3. Phase 3 : signing & provisioning (manuel par l'utilisateur via Apple Developer)
4. Phase 4 : Adaptive UI optionnel
5. Phase 5 : metadata App Store + screenshots
```

---

## Liens

- `.claude/skills/cross-platform-audit/SKILL.md`
- `.claude/docs/cross-platform.md`
- `.claude/docs/deployment.md`
