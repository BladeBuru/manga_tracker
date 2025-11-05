# Configuration de la signature Android

Ce guide explique comment configurer la signature pour les builds de production Android.

## 📋 Prérequis

- Java JDK installé
- `keytool` (inclus avec le JDK)
- Accès aux secrets GitHub pour le CI/CD

## 🔑 Étape 1 : Générer la clé de signature

Exécutez la commande suivante pour générer une clé de signature :

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important :**
- Remplacez `~/upload-keystore.jks` par le chemin où vous souhaitez stocker la clé
- Notez **attentivement** le mot de passe que vous définissez
- Remplissez les informations demandées (nom, organisation, etc.)

## 🔐 Étape 2 : Configurer les secrets GitHub

1. Allez dans les **Settings** de votre repository GitHub
2. Naviguez vers **Secrets and variables** → **Actions**
3. Ajoutez les secrets suivants :

| Secret Name | Description | Exemple |
|------------|-------------|---------|
| `KEYSTORE_BASE64` | Contenu du fichier .jks encodé en base64 | (voir commande ci-dessous) |
| `KEYSTORE_PASSWORD` | Mot de passe du keystore | `votre_mot_de_passe` |
| `KEY_ALIAS` | Alias de la clé (généralement "upload") | `upload` |
| `KEY_PASSWORD` | Mot de passe de la clé (peut être identique au keystore) | `votre_mot_de_passe` |

### Encoder le keystore en base64

**Sur Linux/macOS :**
```bash
base64 -i ~/upload-keystore.jks | pbcopy  # macOS
base64 -i ~/upload-keystore.jks | xclip -selection clipboard  # Linux
```

**Sur Windows (PowerShell) :**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\upload-keystore.jks")) | Set-Clipboard
```

Collez ensuite le résultat dans le secret `KEYSTORE_BASE64` sur GitHub.

## 🏠 Étape 3 : Configuration locale (optionnel)

Pour signer localement, créez un fichier `android/key.properties` :

```properties
storePassword=votre_mot_de_passe
keyPassword=votre_mot_de_passe
keyAlias=upload
storeFile=../path/to/upload-keystore.jks
```

**⚠️ Ne commitez JAMAIS ce fichier dans Git !** Il est déjà dans `.gitignore`.

## ✅ Vérification

Après configuration, vous pouvez tester la signature localement :

```bash
flutter build apk --flavor prod --release
```

Le build devrait utiliser la clé de signature configurée.

## 🔄 Pour le CI/CD

Le workflow GitHub Actions utilisera automatiquement les secrets configurés pour signer les APK de production.

## 📝 Notes importantes

- **Sauvegardez la clé de signature** : Si vous perdez cette clé, vous ne pourrez plus publier de mises à jour pour l'application existante
- **Ne partagez jamais la clé** : Gardez-la secrète et ne la commitez jamais dans le repository
- **Un seul keystore par application** : Utilisez toujours le même keystore pour toutes les versions de production


