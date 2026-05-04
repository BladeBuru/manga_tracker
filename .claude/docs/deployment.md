# Documentation : Déploiement — Manga Tracker Flutter

## Cibles

| Plateforme | État | Distribution |
|------------|------|--------------|
| Android | ✅ Actif | Play Store + GitHub Releases (APK) |
| iOS | 🔴 Non wiré | App Store (à venir) |
| Web | 🔴 Non wiré | Firebase Hosting / Netlify / Cloudflare Pages (à venir) |

---

## Android

### Signing

- **Keystore** : `android/app/upload-keystore.jks`
- **Config** : `android/key.properties` (lit storePassword, keyPassword, keyAlias, storeFile)

⚠️ **Sécurité non-négociable** :
- ❌ `key.properties` **JAMAIS versionné**
- ❌ `*.jks` **JAMAIS versionné**
- ✅ `.gitignore` doit contenir :
  ```
  android/key.properties
  android/app/*.jks
  android/app/*.keystore
  android/app/google-services.json
  ```
- ✅ Keystore stocké dans 1Password ou similaire
- ✅ CI : keystore décodé depuis GitHub Secret base64, nettoyé après build

### Build local

```bash
# Debug
flutter run -d <android-device>

# Release APK (interne)
flutter build apk --release --flavor prod

# Release App Bundle (Play Store)
flutter build appbundle --release --flavor prod
```

**Pour Play Store** : utiliser App Bundle (`.aab`), pas APK.

### CI / GitHub Actions

Workflow actuel : `.github/workflows/release_workflow.yml`

- Trigger : PR merge vers `dev` avec label `patch` / `minor` / `major`
- Bump version via `version_assist`
- Build APK release
- Upload vers GitHub Releases
- Keystore restauré depuis `secrets.ANDROID_KEYSTORE_BASE64`

À ajouter :
- [ ] Build App Bundle en plus de l'APK
- [ ] Upload Play Console (alpha / beta / prod) via `r0adkll/upload-google-play`
- [ ] Tests + lint avant build

### Versioning

- `pubspec.yaml` → `version: 0.X.Y+Z` où Z = versionCode (entier monotone), 0.X.Y = versionName
- `android/app/build.gradle` lit ces valeurs via `flutterVersionCode` et `flutterVersionName`

---

## iOS (à venir)

### Pré-requis

- [ ] Apple Developer Program ($99/an)
- [ ] Bundle Identifier (ex: `com.manga-tracker.app`)
- [ ] Team ID
- [ ] Provisioning Profile (Development + Distribution)
- [ ] Certificat de distribution

### Signing

- Clés stockées **hors repo** (App Store Connect API key)
- Fastlane Match recommandé pour synchroniser certs/profils dans la team

### Build

```bash
flutter build ios --release
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### CI / GitHub Actions (à créer)

Workflow `.github/workflows/ios_release.yml` (à créer) :
- Runner `macos-latest`
- Setup Xcode
- Fastlane Match pour les certs
- `flutter build ipa`
- Upload TestFlight via Fastlane

Voir skill `/ios-readiness` pour la checklist complète.

---

## Web (à venir)

### Pré-requis

- [ ] Domain configuré (ex: `app.manga-tracker.com`)
- [ ] Hosting choisi (Firebase Hosting / Netlify / Cloudflare Pages)
- [ ] CORS côté API mis à jour avec le domaine web prod

### Build

```bash
flutter build web --release --base-href "/" --web-renderer canvaskit
```

Output : `build/web/`

### Déploiement Firebase Hosting (exemple)

```bash
# Config initiale
firebase init hosting

# Déploiement
firebase deploy --only hosting
```

### CI / GitHub Actions (à créer)

Workflow `.github/workflows/web_release.yml` (à créer) :
- `flutter build web`
- Deploy via `FirebaseExtended/action-hosting-deploy@v0`

Voir skill `/web-readiness` pour la checklist (PWA manifest, service worker, go_router, responsive).

---

## Coordination avec l'API

L'API NestJS (projet `API-mangaTracker/`) doit accepter les origines des clients dans `CORS_ORIGINS` :

```env
# .env.production côté API
CORS_ORIGINS=https://app.manga-tracker.com,https://manga-tracker.com
```

Quand un nouveau client (web prod, web staging, etc.) est déployé, mettre à jour cette liste et redéployer l'API.

---

## Secrets stockage

| Secret | Stockage |
|--------|----------|
| Android keystore | GitHub Secrets (base64) |
| `android/key.properties` | GitHub Secrets (texte) ou reconstitué depuis secrets |
| Apple App Store Connect API key | GitHub Secrets |
| Apple Provisioning Profile | Fastlane Match (repo privé séparé) |
| Firebase service account | GitHub Secrets |
| `.env.production` (côté Flutter) | GitHub Secrets |

**Aucun secret dans le repo principal.** Voir aussi `API-mangaTracker/.claude/rules/env-secret-guard.md` pour la même règle côté API.
