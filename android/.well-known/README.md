# Android App Links — `assetlinks.json`

Ce dossier contient le **template** du fichier de validation Android App Links.
Il permet à Google d'établir une relation de confiance entre votre app
Android et le domaine `bladeburu.com`, pour que les liens type
`https://bladeburu.com/auth/verify?token=...` ouvrent **directement** votre
app sans dialog « Ouvrir avec ».

## ⚠️ Le fichier final doit être hébergé sur le domaine, pas dans le repo

Le fichier produit doit être accessible publiquement sur :

```
https://bladeburu.com/.well-known/assetlinks.json
```

Avec le bon `Content-Type: application/json` et HTTPS valide.

## Comment générer la SHA-256 du keystore

### Pour le keystore de développement (debug, local)

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android \
  | grep "SHA-256"
```

### Pour le keystore de release / production

```bash
keytool -list -v \
  -keystore android/app/upload-keystore.jks \
  -alias upload \
  | grep "SHA-256"
```

(Adaptez `-alias` au nom utilisé dans `key.properties`.)

### Format attendu

La sortie ressemble à :

```
SHA256: AB:CD:EF:01:23:45:...:...:..
```

Copiez la chaîne hex (sans le préfixe `SHA256:` mais en gardant les `:`)
dans le champ `sha256_cert_fingerprints` du JSON.

## Pour la prod : INCLURE LES DEUX FINGERPRINTS

Si vous utilisez **Play App Signing** (recommandé), Google re-signe votre
APK avec sa propre clé. Vous devez inclure **les deux** :

1. **App signing certificate** : SHA-256 fournie par Google dans Play Console
   (Setup → App Integrity → App Signing key certificate).
2. **Upload certificate** : SHA-256 de votre `upload-keystore.jks`.

```json
"sha256_cert_fingerprints": [
  "AB:CD:...",  // App signing (Google)
  "12:34:..."   // Upload (votre keystore)
]
```

## Vérifier la validation après hébergement

Une fois `assetlinks.json` en ligne :

```bash
# Test que le fichier est servi correctement
curl -v https://bladeburu.com/.well-known/assetlinks.json

# Test l'API Google de validation
curl "https://digitalassetlinks.googleapis.com/v1/statements:list?\
source.web.site=https://bladeburu.com&\
relation=delegate_permission/common.handle_all_urls"
```

Sur l'appareil Android, après installation de l'app :

```bash
adb shell pm get-app-links com.bladeburu.mangatracker
```

Sortie attendue :
```
com.bladeburu.mangatracker:
    ID: ...
    Signatures: [...]
    Domain verification state:
      bladeburu.com: verified
```

Si `verified` n'apparaît pas, attendez 5–10 min après installation, ou
forcez une re-vérification :

```bash
adb shell pm verify-app-links com.bladeburu.mangatracker
```

## Étapes récapitulatives

1. Trouver la SHA-256 (voir ci-dessus) — pour debug + release
2. Copier `assetlinks.json.template` → `assetlinks.json`
3. Remplacer `REMPLACE_PAR_LE_SHA256_DU_KEYSTORE` par la vraie valeur
4. Vérifier que `package_name` correspond bien à votre `applicationId`
   défini dans `android/app/build.gradle` (probablement
   `com.bladeburu.mangatracker` ou similaire)
5. Uploader sur `https://bladeburu.com/.well-known/assetlinks.json`
6. Réinstaller l'app sur un appareil pour déclencher la vérification
   Android, ou attendre la prochaine vérification automatique
