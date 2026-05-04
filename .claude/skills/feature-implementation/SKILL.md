---
name: feature-implementation
description: Workflow 6 phases pour implémenter une feature Flutter dans Manga Tracker — analyse memory-bank, planification BLoC/DTO/service, i18n FIRST (7 langues avant les widgets), implémentation DTO→Service→BLoC→GetIt→Widget→View, validation, mise à jour memory-bank.
---

# Skill : Implémenter une feature — Manga Tracker Flutter

Workflow structuré pour implémenter une nouvelle feature Flutter sans déraper.

---

## Phase 1 — Analyse (OBLIGATOIRE)

1. Lire le memory-bank :
   - `.claude/memory-bank/architecture.md`
   - `.claude/memory-bank/progress.md`
   - `.claude/memory-bank/decisions.md`
   - `.claude/memory-bank/known-issues.md`

2. Lire la documentation pertinente :
   - `.claude/docs/architecture-feature.md` — Structure d'une feature
   - `.claude/docs/api-contracts.md` — Endpoints disponibles
   - `.claude/docs/offline-architecture.md` — Pattern offline-first
   - `.claude/docs/design-system.md` — Tokens + composants réutilisables
   - `.claude/docs/cross-platform.md` — Si la feature touche au natif

3. Comprendre le besoin :
   - Quelle feature ? (`auth`, `home`, `library`, `manga`, `profile`, `search`, `reader`, nouvelle)
   - Nouvelle ou modification d'une existante ?
   - Données API ou locales ?
   - Implications iOS/Web ? (si oui → invoquer `/cross-platform-audit` AVANT)

4. Analyser l'existant :
   - Un composant réutilisable (`core/components/`) existe-t-il ?
   - Un BLoC ou service similaire ?
   - Les DTOs sont-ils déjà définis ?

---

## Phase 2 — Planification

1. **Planifier le BLoC** :
   - Events ? (verbe à l'infinitif)
   - States ? (inclure `isOffline`, `pendingActions` si applicable)
   - Singleton ou Factory ? (DetailBloc-like → factory)

2. **Planifier les DTOs** :
   - Existants dans `features/[feature]/dto/` ?
   - `fromJson` / `toJson` ?

3. **Planifier le Service** :
   - HTTP via `HttpService` ?
   - Cache via `OfflineCacheService` ?
   - Queue offline si action mutante ?
   - **Dépendance native ?** → abstraction obligatoire (interface dans `core/services/`)

4. **Planifier l'UI** :
   - i18n FIRST — clés ARB (7 langues)
   - Découpage en sous-widgets (MAX 150 lignes par widget)
   - Indicateur offline si `isOffline: true`
   - **Responsive** : `LayoutBuilder` si layout > taille mobile
   - **Accessibilité** : `Semantics`, contraste, font scaling

5. Ordre d'implémentation (Phase 4).

---

## Phase 3 — i18n d'abord (OBLIGATOIRE)

Avant d'écrire un seul widget :

1. Ajouter les clés dans `lib/l10n/app_fr.arb` (référence).
2. Traduire dans les 6 autres ARB (en, de, ja, ko, pt, es).
3. Régénérer : `flutter gen-l10n`.
4. Utiliser `context.l10n.maCle` dans les widgets.

**Aucun texte hardcodé** — zéro exception.

---

## Phase 4 — Implémentation

Ordre :

1. **DTOs** — `fromJson` / `toJson`, typage strict, dans `features/[feature]/dto/`.
2. **Service** — Appels HTTP via `HttpService`, cache `OfflineCacheService`. Si natif → interface + impl plateforme.
3. **BLoC** — Events / States / Logique (pattern offline avec `SocketException`).
4. **Enregistrement GetIt** — Dans `core/service_locator/service_locator.dart`, ordre des dépendances.
5. **Widgets** — Sous-composants privés (`_NomWidget`), `const`, Material 3, tokens.
6. **View** — `BlocBuilder` + switch sur les states, indicateur offline.

Limites strictes :
- Widget : MAX 150 lignes
- BLoC : MAX 200 lignes
- Service : MAX 300 lignes
- Si dépassement → invoquer `/refactor-large-file`.

---

## Phase 5 — Validation

Checklist :

- [ ] Aucun texte hardcodé (tout en ARB, 7 langues)
- [ ] Pattern BLoC respecté (Event → BLoC → State)
- [ ] Mode offline géré (`SocketException` → `isOffline: true`)
- [ ] Indicateur offline affiché si `isOffline: true`
- [ ] Service enregistré dans `service_locator.dart`
- [ ] BLoC enregistré (singleton ou factory selon le cas)
- [ ] `cached_network_image` pour toutes les images réseau
- [ ] `const` constructors utilisés partout où possible
- [ ] Thème Material 3 (pas de couleurs hardcodées)
- [ ] `AppRadius` / `AppSpacing` (à créer si absent)
- [ ] Aucun widget > 150 lignes
- [ ] `ListView.builder()` pour les listes dynamiques
- [ ] Si nouveau widget réutilisable → placé dans `core/components/`
- [ ] **Cross-platform** : pas de `dart:io` direct, pas de package Android-only sans abstraction
- [ ] **Test** : minimum 1 widget test ou BLoC test (objectif Play Store quality)

---

## Phase 6 — Documentation

1. Mettre à jour `.claude/memory-bank/progress.md` — feature ajoutée
2. Mettre à jour `.claude/memory-bank/architecture.md` — si nouveau service/BLoC
3. Mettre à jour `.claude/docs/architecture-feature.md` — si nouveau pattern
4. Mettre à jour `.claude/docs/design-system.md` — si nouveau composant `core/components/`

---

## Format de réponse

```markdown
## Feature : [Nom]

### Analyse
- Feature : [auth | home | library | manga | profile | search | reader | nouvelle]
- BLoC : [nouveau | existant modifié]
- Service : [nouveau | existant modifié]
- Enregistrement GetIt : [singleton | lazy singleton | factory]
- Cross-platform : [✅ tous | ⚠️ Android-only justifié]

### Implémentation
- DTOs : [liste]
- Events ajoutés : [liste]
- States ajoutés : [liste]
- Clés ARB ajoutées : [nombre] (7 langues ✅)
- Widgets créés : [liste avec taille]

### Validation
- ✅ Checklist complétée
- Offline géré : ✅ / non applicable
- Tests : [liste]

### Memory bank mis à jour
- progress.md : ✅
- architecture.md : [✅ / non nécessaire]
```

---

**Rappel** : Memory-bank AVANT le code. i18n AVANT les widgets. Cross-platform par défaut.
