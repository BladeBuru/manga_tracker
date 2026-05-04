---
name: bug-fix
description: Workflow 4 phases pour investiguer + corriger + documenter un bug Flutter dans Manga Tracker — identification du layer (Widget / BLoC / Service / DTO / GetIt / offline), correction respectant les patterns, mise à jour known-issues.md, génération d'un rapport tableau.
---

# Skill : Bug Fix — Manga Tracker Flutter

Workflow structuré pour corriger un bug et générer un rapport.

---

## Phase 1 — Investigation

1. Lire le memory-bank :
   - `.claude/memory-bank/known-issues.md` — bug déjà documenté ?
   - `.claude/memory-bank/architecture.md` — comprendre le composant

2. Reproduire le bug :
   - Quelle feature ? (`auth`, `home`, `library`, `manga`, `profile`, `search`, `reader`)
   - Étapes de reproduction ?
   - Comportement attendu vs observé ?
   - Sur quel appareil/OS ? (Android / iOS / Web — important pour les bugs cross-platform)

3. Identifier la cause :
   - Layer : Widget | View | BLoC | Service | DTO | GetIt
   - Lié au mode offline ?
   - Race condition ? (penser à `DetailBloc` factory)
   - i18n ? (clé manquante dans un ARB ?)
   - Plateforme spécifique ? (workmanager Android-only, dart:io sur Web, permissions iOS...)

---

## Phase 2 — Correction

1. Corriger dans le bon layer :
   - Erreur UI → widget ou view
   - Erreur logique → BLoC ou service
   - Erreur de données → DTO (`fromJson`)
   - Erreur offline → gestion des `SocketException`
   - Erreur GetIt → vérifier l'enregistrement
   - Erreur plateforme → ajouter abstraction + impl conditionnelle

2. Vérifier les impacts :
   - Régression possible sur d'autres features ?
   - Tests BLoC impactés ?
   - Cross-platform : la correction casse-t-elle iOS/Web ?

3. Respecter les règles :
   - Pas de texte hardcodé introduit
   - Pattern BLoC conservé
   - `const` constructors maintenus
   - Pas de `dart:io` direct introduit

---

## Phase 3 — Validation

Checklist post-fix :

- [ ] Bug reproduit et corrigé
- [ ] Mode offline toujours fonctionnel
- [ ] Pas de `print()` / `debugPrint()` oubliés
- [ ] Pas de texte hardcodé introduit
- [ ] Pas de régression sur les autres features
- [ ] Hot reload / hot restart testé
- [ ] Si bug plateforme : testé sur Android au minimum (idéalement iOS/Web aussi)
- [ ] Test ajouté pour éviter la régression (objectif Play Store quality)

---

## Phase 4 — Documentation

1. Mettre à jour `.claude/memory-bank/known-issues.md` :
   - Déplacer le bug de "Actifs" vers "Résolus"
   - Documenter cause racine + solution

2. Générer le rapport (format ci-dessous).

---

## Format Rapport

```markdown
| Catégorie | Détails |
|-----------|---------|
| **Date** | [jour mois année] |
| **Durée** | [X minutes] |
| **Sévérité** | 🔴 Critique / 🟠 Haute / 🟡 Moyenne / 🟢 Basse |
| **Feature** | [auth | home | library | manga | profile | search | reader] |
| **Plateforme** | [Android | iOS | Web | toutes] |
| **Fichier** | [nom_fichier.dart] |
| **Type** | Bug fix / Hotfix |
| | |
| **🐛 Symptôme** | [Ce que l'utilisateur observe — 2-3 phrases] |
| | |
| **🛠️ Fix #1** | [Titre] : [Description] → [Impact] |
| **🛠️ Fix #2** | [Titre] : [Description] → [Impact] |
| | |
| **✅ Validation** | ✅ [Point 1]<br>✅ [Point 2]<br>✅ Mode offline : OK |
| **🧪 Test ajouté** | [test_file_test.dart] |
| **⚠️ Note** | [Contexte technique si nécessaire] |
```

---

**Rappel** : `known-issues.md` mis à jour APRÈS chaque bug résolu.
