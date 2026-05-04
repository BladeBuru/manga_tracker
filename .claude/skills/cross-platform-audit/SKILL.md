---
name: cross-platform-audit
description: Audite un fichier ou une feature Flutter pour la compatibilité Android/iOS/Web — repère dart:io direct, Platform.isAndroid non guardé, packages Android-only (workmanager, AndroidFlutterLocalNotificationsPlugin), MaterialPageRoute à migrer en go_router, layouts non responsive. Produit un rapport avec les blockers.
---

# Skill : Cross-platform audit — Manga Tracker Flutter

Audite la compatibilité Android / iOS / Web d'un fichier, feature ou de tout le code.

L'app cible aujourd'hui Android, mais iOS et Web sont planifiés. Cette skill repère tout ce qui bloquera l'expansion plateforme.

---

## Étape 1 — Périmètre

Demander à l'utilisateur :
- **Tout le code** (`lib/`) ?
- **Une feature** (`lib/features/X/`) ?
- **Un fichier précis** ?

---

## Étape 2 — Checklist d'audit

### A. Imports / API Dart bloquants pour le Web

```bash
# dart:io — interdit dans lib/ (sauf via une abstraction)
grep -rn "import 'dart:io'" lib/
grep -rn "import \"dart:io\"" lib/

# Platform.isAndroid / isIOS sans guard
grep -rn "Platform\.is" lib/
```

- ❌ `dart:io` casse le build web. Remplacer par `path_provider`, `cross_file`, ou abstraire.
- ❌ `Platform.isAndroid` doit être encapsulé dans un service ou via `defaultTargetPlatform`.

### B. Packages Android-only

Lire `pubspec.yaml` et chercher :

| Package | Plateforme | Action |
|---------|-----------|--------|
| `workmanager` | Android-only | Abstraire derrière `BackgroundTaskService` |
| `android_intent_plus` | Android-only | Vérifier l'usage. Si non utilisé → retirer |
| `flutter_local_notifications` avec `AndroidFlutterLocalNotificationsPlugin` explicite | usage Android-spécifique | Ajouter `DarwinNotificationDetails` fallback iOS, `WebPushOptions` pour web futur |
| Tout package marqué "android" sur pub.dev sans iOS/web | Android-only | Cherche alternative cross-platform ou abstraire |

### C. Navigation

```bash
grep -rn "MaterialPageRoute" lib/
grep -rn "Navigator\.\(of\|push\|pushNamed\)" lib/
```

- ⚠️ `MaterialPageRoute` casse le **deep-linking web** : quand l'utilisateur recharge une page profonde, l'état est perdu.
- ✅ Migration vers `go_router` obligatoire avant le build web.

### D. Layouts responsive

```bash
# Largeurs/hauteurs hardcodées
grep -rn "width:\s*[0-9]\{3,\}" lib/
grep -rn "SizedBox(width:\s*[0-9]\{3,\}" lib/
```

- ⚠️ Layout fixé à 400px de large casse sur tablette/desktop/web.
- ✅ Utiliser `LayoutBuilder` + breakpoints (mobile / tablette / desktop).

### E. File system / stockage

```bash
grep -rn "File(" lib/
grep -rn "Directory(" lib/
```

- ❌ `File`/`Directory` directs cassent sur Web.
- ✅ Utiliser `path_provider` (multi-plateforme) ou abstraire.

### F. Notifications & background tasks

- iOS et Web nécessitent du code spécifique pour les notifications push (APNs, Web Push).
- iOS `BGTaskScheduler` au lieu de `workmanager`.
- Web : service worker pour la persistance.

### G. Permissions

- iOS → `Info.plist` (NSCameraUsageDescription, etc.).
- Web → permissions API du navigateur (peuvent ne pas exister).
- Toute API qui demande une permission doit avoir un fallback documenté pour Web.

---

## Étape 3 — Rapport

```markdown
## Audit cross-platform — [périmètre] — [date]

### 🔴 Bloquants Web
- [ ] [Fichier:ligne] — [problème] — fix : [action]

### 🔴 Bloquants iOS
- [ ] [Fichier:ligne] — [problème] — fix : [action]

### 🟠 Améliorations responsive
- [ ] [Fichier:ligne] — [problème] — fix : [action]

### 🟡 Packages à abstraire
- [ ] [Package] — [usage actuel] — fix : [interface + impl]

### ✅ Bonnes pratiques détectées
- [ ] [Élément OK]

### Plan de remédiation suggéré
1. [Action prioritaire — bloque le build cible]
2. ...
```

---

## Étape 4 — Application des fixes (optionnel)

Si l'utilisateur valide :

1. Ajouter les abstractions dans `core/services/` (interface + impl `Android`/`IOS`/`Web`).
2. Remplacer `dart:io` par `path_provider` ou abstraction.
3. Remplacer `Platform.is*` dispersés par un appel au service abstrait.
4. Documenter les décisions dans `.claude/memory-bank/decisions.md`.
5. Mettre à jour `.claude/memory-bank/known-issues.md` (résoudre ou tracker).

---

## Liens

- `.claude/docs/cross-platform.md` — patterns d'abstraction
- `.claude/skills/web-readiness/SKILL.md` — préparer le build web
- `.claude/skills/ios-readiness/SKILL.md` — préparer iOS
