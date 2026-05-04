# Platform-specific config — Manga Tracker Flutter

> Snippet injecté quand vous éditez un fichier sous `android/`, `ios/`, ou `web/`.

## Règles non-négociables

### `android/`

- ❌ **JAMAIS** committer `android/key.properties` (contient le mot de passe du keystore).
- ❌ **JAMAIS** committer `android/app/upload-keystore.jks` ou un autre `.jks` / `.keystore`.
- ✅ `.gitignore` doit inclure :
  ```
  android/key.properties
  android/app/*.jks
  android/app/*.keystore
  android/app/google-services.json
  ```
- ✅ Le keystore est stocké hors repo (1Password, vault, GitHub Secrets en base64 pour la CI).
- ✅ `android/app/build.gradle` :
  - `signingConfigs.release` lit `android/key.properties` mais ce fichier n'est **jamais versionné**.
  - `versionCode` et `versionName` cohérents avec `pubspec.yaml` (lus via `flutterVersionCode` / `flutterVersionName`).
  - `targetSdkVersion` ≥ 34 (exigence Play Store 2024+).
  - `minSdkVersion` documenté (≥ 21 recommandé).
  - ProGuard / R8 actif en release (`minifyEnabled true`, `shrinkResources true`).
- ✅ `AndroidManifest.xml` :
  - Chaque permission listée DOIT avoir une justification user-facing (Play Store la demande).
  - Pas de permissions superflues (`READ_EXTERNAL_STORAGE` étendue → préférer SAF / scoped storage).

### `ios/` (à wirer pour App Store)

- ✅ `Info.plist` : déclarer chaque permission accédée avec un `NSXxxUsageDescription` user-facing :
  - `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`, etc.
- ✅ `Bundle Identifier` distinct de l'Android (ou identique selon la stratégie).
- ✅ Signing & Capabilities : Team ID, Provisioning Profile (stockés hors repo).
- ✅ Pas de fichiers `.mobileprovision` versionnés.
- ✅ Cupertino fallbacks dans le code Dart pour les widgets purement Material.
- ✅ Notifications via `DarwinInitializationSettings` (déjà dans `flutter_local_notifications`).

### `web/` (à wirer pour PWA)

- ✅ `web/manifest.json` complet (name, short_name, icons multi-tailles, start_url, display, theme_color, background_color).
- ✅ `web/index.html` :
  - Pas de scripts inline non audités.
  - Meta viewport responsive.
  - Liens vers `manifest.json`.
- ✅ Service worker généré par Flutter activé (cache offline minimal).
- ✅ `go_router` utilisé (deep-linking nécessite go_router pour le web).
- ✅ Pas de `dart:io` direct (casse le build web).

## CI / déploiement

- Build Android : **App Bundle** (`.aab`), pas APK, pour la release Play Store.
- Build iOS : `.ipa` signé via Fastlane idéalement.
- Build Web : `flutter build web --release --base-href "/"` puis hosting (Firebase Hosting, Netlify, Cloudflare Pages...).

## Si vous éditez un fichier ici maintenant

1. **Android** : vérifier que rien de sensible n'est ajouté à un fichier versionné.
2. **iOS** : si vous ajoutez une permission dans `Info.plist`, vérifier que la description user-facing est claire et localisée (à terme).
3. **Web** : tester `flutter run -d chrome` pour vérifier que le code n'a pas de `dart:io` introduit ailleurs.

## Skills à invoquer selon le contexte

- `/playstore-readiness` — checklist complète Play Store
- `/ios-readiness` — préparer l'app pour App Store
- `/web-readiness` — préparer le build web
