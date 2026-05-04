# Skill : `/release` — Release APK Manga Tracker

Workflow guidé pour créer une release APK depuis `master` sans avoir à passer par une PR.

Déclenche `release_workflow.yml` via `workflow_dispatch` avec les inputs corrects (version_type + changelog).

---

## Quand utiliser cette skill

- ✅ Tu es sur `master`, ton working tree est clean, tu veux releaser une nouvelle version.
- ✅ Tu veux un changelog propre, structuré, sans avoir à ouvrir GitHub UI.

**À NE PAS faire avec cette skill** :
- ❌ Si tu es sur une feature branch → finis ta PR d'abord (le flow PR + label fonctionne toujours).
- ❌ Si `flutter analyze` ou les tests cassent → corrige avant.

---

## Phase 1 — Pré-requis (vérifications automatiques)

L'agent vérifie dans cet ordre :

1. **Branche actuelle** :
   ```bash
   git branch --show-current
   ```
   Doit être `master`. Si non → demander confirmation à l'user (peut-être qu'il release depuis une autre branche volontairement).

2. **Working tree clean** :
   ```bash
   git status --short
   ```
   Doit être vide. Si non → bloquer ; demander à l'user de commit/stash.

3. **Up-to-date avec origin** :
   ```bash
   git fetch origin
   git status -uno
   ```
   Si la branche locale est en retard → `git pull` avant de continuer.

4. **`gh` CLI authentifié** :
   ```bash
   gh auth status
   ```
   Si non → demander à l'user de faire `gh auth login`.

5. **flutter analyze passe** (sanity check) :
   ```bash
   flutter analyze --no-fatal-infos --no-fatal-warnings
   ```
   Si erreur → bloquer.

---

## Phase 2 — Collecte des infos

### a. Version actuelle
```bash
grep '^version:' pubspec.yaml | cut -d ' ' -f2
```
Affiche à l'user : `Version actuelle : 0.8.0+17`.

### b. Demander le type de bump

```
Quel type de version ?
  • patch (0.8.0 → 0.8.1) — corrections de bug
  • minor (0.8.0 → 0.9.0) — nouvelles features compat
  • major (0.8.0 → 1.0.0) — breaking changes
```

Attendre la réponse de l'user.

### c. Générer le draft de changelog

Récupérer les commits depuis le dernier tag :
```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  git log "${LAST_TAG}..HEAD" --pretty=format:'- %s' --no-merges
else
  git log --pretty=format:'- %s' --no-merges -20
fi
```

⚠️ **Le changelog des commits est uniquement une matière première.** Il ne doit
**PAS** être copié-collé tel quel. La règle absolue : **le changelog visible
par l'utilisateur final ne contient AUCUN jargon technique**. Voir la section
"Format du changelog" ci-dessous (règles strictes + exemples avant/après).

L'agent doit :
1. Lire les commits comme une liste de "qu'est-ce qui change pour l'user".
2. Filtrer **complètement** : ci/cd, refactoring pur, migrations techniques,
   compat plateforme interne, etc. → **rien** dans le changelog public.
3. Pour les nouveautés/corrections user-facing, **réécrire** dans le langage
   d'un utilisateur qui découvre l'app — pas un dev qui a relu le diff.

### d. Confirmer le changelog final

Montrer le changelog proposé à l'user, attendre validation ou édition.
**Toujours demander** explicitement : « Cette release sera vue par les
utilisateurs finaux dans la GitHub Release et l'écran "Quoi de neuf ?" de
l'app. Tu valides ce changelog tel quel ? »

---

## Phase 3 — Déclencher le workflow

Une fois validé :

```bash
gh workflow run release_workflow.yml \
  --ref master \
  -f version_type=<patch|minor|major> \
  -f changelog="$(cat <<'EOF'
✨ Nouveautés
- Support Flutter Web (lecture biblio + recherche + détails manga)
- ...

🐛 Corrections
- ...
EOF
)"
```

Puis suivre l'exécution :

```bash
# Récupérer l'ID du run le plus récent
RUN_ID=$(gh run list --workflow=release_workflow.yml --limit=1 --json databaseId --jq '.[0].databaseId')
gh run watch "$RUN_ID"
```

---

## Phase 4 — Post-release

Une fois le workflow réussi :

1. Confirmer que la release est créée :
   ```bash
   gh release view --json tagName,name,url
   ```

2. Vérifier que `version.json` est à jour sur GitHub Pages (peut prendre 1-2 min de propagation Pages) :
   ```bash
   curl -s https://bladeburu.github.io/manga_tracker/assets/version.json | jq .latestVersion
   ```

3. Vérifier que les utilisateurs Android verront la mise à jour au prochain `AppUpdateService.isUpdateAvailable()`.

---

## Inputs attendus du workflow

`release_workflow.yml` `workflow_dispatch` accepte :

| Input | Type | Description |
|---|---|---|
| `version_type` | choice | `patch`, `minor`, ou `major` |
| `changelog` | string | Markdown (utiliser `\n` littéral pour les retours ligne) |

---

## Format du changelog (règles ABSOLUES)

Le changelog est lu par **les utilisateurs finaux** dans :
- la **GitHub Release** publique
- l'écran **« Quoi de neuf ? »** affiché à l'ouverture de l'app après mise à jour

Donc on parle **à un utilisateur**, pas à un dev. Comme un message de
"Updates" sur l'App Store.

### ✅ Règles à respecter

1. **Français**, ton naturel, action-oriented (« Vous pouvez maintenant... »).
2. **Une bullet = une chose que l'utilisateur va voir/utiliser/sentir**.
3. **Emoji par catégorie** pour le scan rapide :
   - ✨ Nouveautés
   - ⚡ Améliorations
   - 🐛 Corrections
4. **3-8 bullets max par catégorie**. Si tu as 15 lignes, c'est qu'il y a du
   bruit technique à filtrer.

### ❌ Interdits absolus

- **Aucun nom de techno** : pas de Flutter Web, pas de NestJS, pas de
  go_router, pas de Docker, pas de `dart:io`, pas de "magic link", pas de
  CI/CD, pas de pipeline, pas de Nginx, pas de Postgres, pas de schéma de
  routing, pas de "deep-linking", pas de "JWT".
- **Aucun nom de classe/fichier/commit** : pas de "AuthService", pas de
  "uri_builder.dart", pas de "fix(release): ...".
- **Aucun préfixe conventional commits** : pas de `feat:`, `fix:`, `chore:`.
- **Aucun changement uniquement interne** : refactoring, migration de
  l'archi, mise à jour CI/CD, garde-fous de sécurité réseau, etc. → **rien**
  dans le changelog public. Ces changements existent pour préparer le
  terrain, pas pour être annoncés.

### 📐 Pattern de réécriture

Pour chaque commit ou groupe de commits :
1. Demande-toi : **« Qu'est-ce que l'utilisateur peut faire / voir / sentir
   de différent ? »**
2. Si la réponse est **« rien de visible »** → exclus.
3. Sinon, écris UN bullet en parlant à l'utilisateur :
   - « Vous pouvez maintenant... »
   - « L'inscription accepte désormais... »
   - « Le mode sombre est disponible... »

### 🪞 Exemples — AVANT (mauvais) / APRÈS (bon)

**AVANT** (jargon dev, à NE PAS faire) :
```
- Support Flutter Web complet : auth, bibliothèque, recherche, recommandations
- Connexion Google OAuth (mobile via idToken + web via OAuth WebView)
- Migration vers go_router : URL stables et partageables, deep-linking
- Cubits dédiés pour forgot_password et reset_password
- Pipeline CI/CD : déploiement web automatisé sur le NAS (Docker + Nginx)
- Compatibilité Flutter Web : suppression de dart:io dans les services core
- Pipeline release tourne maintenant sur master au lieu de dev
- Migration MaterialPageRoute → go_router pour deep-linking web
```

**APRÈS** (orienté utilisateur, ton à utiliser) :
```
✨ Nouveautés
- Vous pouvez maintenant vous connecter avec votre compte Google
- Mode sombre / clair / automatique selon les réglages système
- Application disponible dans votre navigateur — plus besoin d'installer l'app
- Recommandations personnalisées par genre

⚡ Améliorations
- Mot de passe oublié : vous recevez désormais un mail pour le réinitialiser
- Confirmation d'adresse email à l'inscription
- Lecture hors ligne des chapitres téléchargés

🐛 Corrections
- Le partage d'un lien de manga ouvre désormais directement la bonne fiche
```

Note : tout ce qui est purement technique (CI/CD, refactoring, compat web
interne) **a disparu**. C'est volontaire. L'utilisateur s'en fiche.

### 🔧 Cas spéciaux

- **Sécurité importante** : si une faille est corrigée, on l'annonce sobrement
  (« 🔒 Correctif de sécurité — il est recommandé de mettre à jour »).
- **Breaking change utilisateur** (ex : doit re-login) : annoncer clairement
  (« ⚠️ Vous devrez vous reconnecter après cette mise à jour »).
- **Re-consentement RGPD** : « Nouvelles conditions d'utilisation à accepter
  au prochain login ».

---

## Erreurs courantes

| Symptôme | Cause | Fix |
|---|---|---|
| `gh: command not found` | `gh` CLI absent | Installer GitHub CLI (https://cli.github.com/) |
| `workflow_dispatch` n'apparaît pas dans Actions UI | Le workflow n'est pas sur `master` | Push d'abord la nouvelle version du workflow |
| Le bump ne se fait pas | Dans le PR flow : pas de label patch/minor/major | Ajouter le label sur la PR |
| Le keystore décode mal | Secret `KEYSTORE_BASE64` corrompu | Re-exporter avec `base64 -w 0 keystore.jks > keystore.b64` |

---

## Liens

- `release_workflow.yml` — le workflow lui-même
- `bin/update_version_json.dart` — script de génération de `version.json`
- `assets/version.json` — fichier exposé via GitHub Pages depuis `master`
