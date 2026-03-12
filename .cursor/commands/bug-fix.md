# Commande : Bug Fix — Manga Tracker Flutter

Quand cette commande est déclenchée, suivre ce workflow pour corriger un bug et générer un rapport.

---

## Phase 1 : Investigation

1. **Lire le memory-bank** :
   - `.cursor/memory-bank/known-issues.md` — Le bug est-il déjà documenté ?
   - `.cursor/memory-bank/architecture.md` — Comprendre le composant concerné

2. **Reproduire le bug** :
   - Quelle feature est concernée ? (`auth`, `home`, `library`, `manga`, `profile`, `search`)
   - Quelles étapes de reproduction ?
   - Comportement attendu vs observé ?
   - Sur quel appareil/OS ? (Android / iOS / les deux)

3. **Identifier la cause** :
   - Layer concerné : Widget | View | BLoC | Service | DTO | GetIt
   - Est-ce lié au mode offline ?
   - Est-ce une race condition ? (penser à `DetailBloc` factory)
   - Est-ce lié à l'i18n ? (clé manquante dans un ARB ?)

---

## Phase 2 : Correction

1. **Corriger dans le bon layer** :
   - Erreur UI → corriger le widget ou la view
   - Erreur logique → corriger le BLoC ou le service
   - Erreur de données → corriger le DTO (`fromJson`)
   - Erreur offline → corriger la gestion des `SocketException`
   - Erreur GetIt → vérifier l'enregistrement dans `service_locator.dart`

2. **Vérifier les impacts** :
   - La correction peut-elle créer une régression dans d'autres features ?
   - Les tests BLoC sont-ils impactés ?

3. **Respecter les règles** :
   - Pas de texte hardcodé introduit
   - Pattern BLoC conservé
   - `const` constructors maintenus

---

## Phase 3 : Validation

**Checklist post-fix** :

1. ✅ Bug reproduit et corrigé ?
2. ✅ Mode offline toujours fonctionnel ?
3. ✅ Pas de `print()` / `debugPrint()` oubliés ?
4. ✅ Pas de texte hardcodé introduit ?
5. ✅ Pas de régression sur les autres features ?
6. ✅ Hot reload / hot restart testé ?

---

## Phase 4 : Documentation

1. **Mettre à jour `.cursor/memory-bank/known-issues.md`** :
   - Déplacer le bug de "Actifs" vers "Résolus"
   - Documenter la cause racine et la solution
2. **Générer le rapport** (format tableau ci-dessous)

---

## Format Rapport Bug Fix (prêt à copier)

```markdown
| Catégorie | Détails |
|-----------|---------|
| **Date** | [jour mois année] |
| **Durée** | [X minutes] |
| **Sévérité** | 🔴 Critique / 🟠 Haute / 🟡 Moyenne / 🟢 Basse |
| **Feature** | [auth | home | library | manga | profile | search] |
| **Fichier** | [nom_fichier.dart] |
| **Type** | Bug fix / Hotfix |
| | |
| **🐛 Symptôme** | [Ce que l'utilisateur observe — 2-3 phrases] |
| | |
| **🛠️ Fix #1** | [Titre] : [Description courte] → [Impact] |
| **🛠️ Fix #2** | [Titre] : [Description courte] → [Impact] |
| | |
| **✅ Validation** | ✅ [Point 1]<br>✅ [Point 2]<br>✅ Mode offline : OK |
| **⚠️ Note** | [Contexte technique si nécessaire] |
```

---

**Rappel** : Mettre à jour `.cursor/memory-bank/known-issues.md` après chaque bug résolu.
