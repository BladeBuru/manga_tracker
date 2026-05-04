# Documentation : Cross-platform — Manga Tracker Flutter

L'app cible Android (actuel), iOS et Web (à venir). Cette doc liste les patterns d'abstraction et les blockers actuels.

---

## Pattern d'abstraction plateforme

Tout service touchant une API plateforme doit être derrière une **interface** dans `core/services/` :

```dart
// 1. Interface
abstract class BackgroundTaskService {
  Future<void> registerPeriodicTask({
    required String name,
    required Duration frequency,
    required Future<void> Function() callback,
  });
  Future<void> cancelTask(String name);
}

// 2. Implémentations conditionnelles
class AndroidBackgroundTaskService implements BackgroundTaskService {
  // workmanager
}

class IOSBackgroundTaskService implements BackgroundTaskService {
  // BGTaskScheduler
}

class WebBackgroundTaskService implements BackgroundTaskService {
  // service worker (ou no-op)
}

// 3. Sélection dans service_locator.dart
import 'package:flutter/foundation.dart';

void _registerBackgroundTaskService() {
  if (kIsWeb) {
    getIt.registerSingleton<BackgroundTaskService>(WebBackgroundTaskService());
    return;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      getIt.registerSingleton<BackgroundTaskService>(AndroidBackgroundTaskService());
      break;
    case TargetPlatform.iOS:
      getIt.registerSingleton<BackgroundTaskService>(IOSBackgroundTaskService());
      break;
    default:
      getIt.registerSingleton<BackgroundTaskService>(WebBackgroundTaskService());
  }
}
```

---

## Blockers actuels (audit)

### `dart:io` direct
- **Fichiers concernés** : multiples dans `lib/` (audit via `grep -rn "import 'dart:io'" lib/`)
- **Impact** : casse le build web (`flutter build web` échoue)
- **Fix** :
  - Remplacer `File`, `Directory` par `path_provider` quand possible
  - Pour les téléchargements, abstraire derrière un `FileStorageService`

### `workmanager` (`chapter_check_background_service.dart`)
- **Plateforme** : Android-only
- **Impact** : aucune périodicité de tâches sur iOS/Web
- **Fix** : abstraction `BackgroundTaskService` (cf. exemple ci-dessus). Sur iOS : `BGTaskScheduler`. Sur Web : service worker ou polling client-side.

### `AndroidFlutterLocalNotificationsPlugin` (`notification_service.dart`)
- **Plateforme** : Android-spécifique
- **Impact** : notifications iOS non fonctionnelles
- **Fix** : ajouter `DarwinInitializationSettings` dans la conf, et un fallback Web (Web Push API ou pas de notif sur web).

### `key.properties` versionné (`android/key.properties`)
- **Plateforme** : Android signing
- **Impact** : secret du keystore exposé dans git
- **Fix** : `git rm --cached android/key.properties`, ajouter au `.gitignore`, stocker hors repo (1Password / GitHub Secrets en base64), rotation du mot de passe keystore.

### `MaterialPageRoute` partout
- **Plateforme** : casse le deep-linking web
- **Impact** : sur web, recharger une URL profonde casse la nav
- **Fix** : migration vers `go_router` (skill `/web-readiness`). Sur iOS, utiliser `CupertinoPageRoute` ou `MaterialPageRoute.fullscreenDialog` selon le contexte.

### Pas de `Platform.isAndroid` / guards
- **Plateforme** : tout code Android-spécifique sans guard se cassera sur iOS/Web
- **Impact** : crash runtime
- **Fix** : utiliser `defaultTargetPlatform` + `kIsWeb` de `flutter/foundation.dart`. Encapsuler dans des services.

---

## Détection plateforme

```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) { /* Web */ }
else {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android
      break;
    case TargetPlatform.iOS:
      // iOS
      break;
    default:
      // Linux, macOS, Windows desktop
  }
}
```

**Ne JAMAIS** disperser ces checks dans le code UI / business — toujours dans le service_locator ou un service abstrait.

---

## Stockage cross-platform

| Type | Android | iOS | Web | Service |
|------|---------|-----|-----|---------|
| Tokens JWT | ✅ Keystore | ✅ Keychain | ✅ WebCrypto | `flutter_secure_storage` |
| Cache JSON | ✅ NSUserDefaults / SharedPreferences | ✅ NSUserDefaults | ✅ localStorage | `shared_preferences` |
| Fichiers téléchargés | ✅ `path_provider` | ✅ `path_provider` (sandboxed) | ❌ pas de FS direct | À abstraire |
| BDD locale (si nécessaire) | ✅ sqflite | ✅ sqflite | ⚠️ sqflite_web | `drift` (cross) ou `isar` |

---

## Layouts responsive

```dart
// Breakpoints standard
const kMobileBreakpoint = 600.0;
const kTabletBreakpoint = 900.0;
const kDesktopBreakpoint = 1200.0;

LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= kDesktopBreakpoint) return _DesktopLayout();
    if (constraints.maxWidth >= kTabletBreakpoint) return _TabletLayout();
    return _MobileLayout();
  },
)
```

À créer un widget utilitaire `ResponsiveBuilder` dans `core/components/` à terme.

---

## UI adaptive (iOS)

Selon la stratégie pour iOS :

### Option A : Material partout (acceptable)
Plus simple. L'app garde son look Material sur iOS. Apple accepte.

### Option B : Adaptive (UX iOS native)
- `Switch.adaptive`, `Slider.adaptive`
- `CupertinoNavigationBar` quand iOS
- `CupertinoPageRoute` au lieu de `MaterialPageRoute`
- Wrappers `Adaptive*` dans `core/components/`

À documenter dans `decisions.md` avant implémentation.
