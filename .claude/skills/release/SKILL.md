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

Présenter à l'user comme draft, en suggérant de :
- Filtrer les commits techniques (chore, refactor pur, ci/cd)
- Reformuler en français orienté utilisateur (pas de "feat:", "fix:")
- Regrouper par catégorie : ✨ Nouveautés / 🐛 Corrections / ⚡ Améliorations

### d. Confirmer le changelog final

Montrer le changelog proposé à l'user, attendre validation ou édition.

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

## Format du changelog

Exemple cible :

```markdown
✨ Nouveautés
- Support Flutter Web : l'app est désormais accessible depuis n'importe quel navigateur
- Recommendations personnalisées par genre

🐛 Corrections
- Fix du refresh token qui se perdait après navigation profonde
- Correction du crash sur la page profil quand l'avatar est null

⚡ Améliorations
- Démarrage 30% plus rapide (lazy loading des BLoCs)
- Cache offline étendu à 24h pour les détails manga
```

**Règles** :
- Pas de "feat:", "fix:", "chore:" (orienté utilisateur, pas dev)
- Français
- Une bullet par changement (pas de paragraphes)
- Emoji par catégorie pour la lisibilité

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
