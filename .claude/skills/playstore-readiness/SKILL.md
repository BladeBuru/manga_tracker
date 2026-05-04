---
name: playstore-readiness
description: Checklist complète Play Store pour Manga Tracker Flutter — signing config gitignored, App Bundle (.aab) build, ProGuard/R8, target SDK ≥ 34, permissions justifiées, privacy policy, content rating, screenshots multi-formats, accessibility (TalkBack, contrast), perf budget (cold start, jank).
---

# Skill : Play Store readiness — Manga Tracker Flutter

Checklist complète pour passer la review Play Store sans souci.

---

## 1. Signing & Build

### Keystore
- [ ] `android/key.properties` dans `.gitignore` (jamais versionné)
- [ ] `android/app/upload-keystore.jks` (ou autre `.jks`) dans `.gitignore`
- [ ] Keystore stocké hors repo (1Password, vault, GitHub Secrets en base64)
- [ ] CI : keystore décodé depuis secrets et nettoyé après build

### `android/app/build.gradle`
- [ ] `signingConfigs.release` lit `android/key.properties` (qui n'est PAS versionné)
- [ ] `versionCode` et `versionName` cohérents avec `pubspec.yaml` (`flutterVersionCode` / `flutterVersionName`)
- [ ] `targetSdkVersion` ≥ 34 (exigence Play Store 2024+)
- [ ] `minSdkVersion` documenté (≥ 21 recommandé)
- [ ] `compileSdkVersion` ≥ 34
- [ ] ProGuard / R8 actif en release :
  ```
  buildTypes {
    release {
      minifyEnabled true
      shrinkResources true
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }
  ```
- [ ] Règles ProGuard pour Flutter dans `android/app/proguard-rules.pro` (préserver `io.flutter.**`, plugins).

### Build
- [ ] **App Bundle** (`.aab`) pour la release Play Store, pas APK :
  ```bash
  flutter build appbundle --release --flavor prod
  ```
- [ ] Taille du bundle < 150 MB (limite Play Store, 200 MB pour App Bundle).
- [ ] Architectures : ARM64 + ARMv7 + x86_64 (App Bundle gère ça automatiquement).

---

## 2. Manifest & Permissions

### `AndroidManifest.xml`
- [ ] `<application android:label>` correctement nommé
- [ ] Chaque permission listée a une **justification user-facing** dans la page Play Store
- [ ] Pas de permissions superflues. Vérifier :
  ```bash
  grep "uses-permission" android/app/src/main/AndroidManifest.xml
  ```
- [ ] Si l'app demande `READ_EXTERNAL_STORAGE` ou `WRITE_EXTERNAL_STORAGE` → migrer vers Storage Access Framework (Android 11+).
- [ ] Si `INTERNET` → OK (justifié pour API).
- [ ] Si `POST_NOTIFICATIONS` (Android 13+) → permission runtime à demander.
- [ ] `android:exported` explicite sur chaque `<activity>`, `<service>`, `<receiver>` (Android 12+ exigence).

### Intent filters
- [ ] Pas d'intent filter qui expose une activité par erreur.

---

## 3. Privacy & Content

### Politique de confidentialité
- [ ] URL renseignée dans Play Console (pré-rempli côté pubspec ou via une page web).
- [ ] Contenu : données collectées, finalité, partage tiers, droits utilisateurs (RGPD/CCPA).
- [ ] Si collecte de données personnelles → déclaration "Data safety" complète dans Play Console.

### Content rating
- [ ] Questionnaire IARC complété.
- [ ] Filtrage du contenu mature implémenté (déjà ✅ dans library).
- [ ] Âge minimum cohérent (ex: 13+ si PEGI).

### Compte test
- [ ] Compte de test fourni à Google pour la review (avec credentials, pas de captcha).

---

## 4. Visuels & Store listing

- [ ] Icône `512×512` PNG avec alpha
- [ ] Feature graphic `1024×500`
- [ ] Screenshots téléphone (min 2, max 8) — dimensions Play Store
- [ ] Screenshots tablette 7" et 10" si supporté
- [ ] Description courte (80 caractères) dans toutes les langues supportées
- [ ] Description longue (4000 caractères max) dans toutes les langues supportées
- [ ] Localisation : 7 langues (FR, EN, DE, JA, KO, PT, ES) cohérent avec l'app

---

## 5. Accessibilité

- [ ] Labels `Semantics` / `tooltip` sur tous les boutons icônes
- [ ] Labels TalkBack testés (`flutter run` → activer TalkBack)
- [ ] Contraste WCAG AA : `Theme.of(context).colorScheme` Material 3 respecte généralement l'AA. Vérifier les états custom.
- [ ] Font scaling : pas de `fontSize` figé qui ignore `MediaQuery.textScaleFactor` (utiliser `textTheme`)
- [ ] Targets tactiles ≥ 48×48 dp
- [ ] Navigation clavier (utile pour l'accessibilité et le futur web)

---

## 6. Performance

- [ ] Cold start < 5s (mesurer via DevTools Performance)
- [ ] Pas de jank > 16ms (60fps) sur écrans principaux
- [ ] Images optimisées (`cached_network_image` actif)
- [ ] Pas de rebuild inutiles (`const` constructors présents)
- [ ] `flutter analyze` sans warning
- [ ] `flutter test` passant
- [ ] Tests : minimum 1 widget test + 1 BLoC test par feature

---

## 7. Stabilité

- [ ] Aucun crash en mode release sur les chemins principaux
- [ ] Crashlytics ou équivalent en place (Firebase Crashlytics, Sentry)
- [ ] Logs : pas de `print()` / `debugPrint()` en release
- [ ] Pas de `assert()` qui pourraient casser en mode profile

---

## 8. CI/CD release flow

Lire `.github/workflows/release_workflow.yml` :

- [ ] Trigger sur PR merge avec label patch/minor/major
- [ ] Bump auto de version
- [ ] Build App Bundle (pas APK)
- [ ] Upload vers Play Console (interne / alpha / beta / prod) via `r0adkll/upload-google-play` ou Fastlane
- [ ] Keystore restauré depuis secrets, nettoyé après build
- [ ] `.env.production` injecté depuis secrets

---

## 9. Si vous lancez cette skill

L'agent doit :

1. Lire les fichiers pertinents (`pubspec.yaml`, `android/app/build.gradle`, `AndroidManifest.xml`, `.gitignore`, `.github/workflows/release_workflow.yml`).
2. Cocher chaque item de la checklist (✅ / ❌ / ⚠️).
3. Produire le rapport :

```markdown
## Play Store readiness — [date]

### 🔴 Bloquants release
- [ ] [Item] — [détail]

### 🟠 Améliorations recommandées
- [ ] [Item] — [détail]

### ✅ Conformes
- [ ] [Item]

### Plan d'action
1. [Action prioritaire]
2. ...
```

4. Si l'utilisateur valide → appliquer les fixes (sauf rotation de keystore qui doit être manuelle).
