# Commande : Implémenter une Feature — Manga Tracker Flutter

Quand cette commande est déclenchée, suivre ce workflow pour implémenter une nouvelle feature Flutter.

---

## Phase 1 : Analyse (OBLIGATOIRE)

1. **Lire le memory-bank** :
   - `.cursor/memory-bank/architecture.md`
   - `.cursor/memory-bank/progress.md`
   - `.cursor/memory-bank/decisions.md`
   - `.cursor/memory-bank/known-issues.md`

2. **Lire la documentation** :
   - `.cursor/documentation/architecture-feature.md` — Structure d'une feature Flutter
   - `.cursor/documentation/api-contracts.md` — Endpoints API disponibles
   - `.cursor/documentation/offline-architecture.md` — Pattern offline-first

3. **Comprendre le besoin** :
   - Quelle feature ? (`auth`, `home`, `library`, `manga`, `profile`, `search`, `reader`)
   - Nouvelle feature ou modification d'une existante ?
   - Données venant de l'API ou locales ?

4. **Analyser l'existant** :
   - Un composant réutilisable (`core/components/`) peut-il être utilisé ?
   - Un BLoC ou service similaire existe-t-il déjà ?
   - Les DTOs sont-ils déjà définis ?

---

## Phase 2 : Planification (OBLIGATOIRE)

1. **Planifier le BLoC** :
   - Quels Events ? (actions utilisateur)
   - Quels States ? (états de l'UI — inclure `isOffline`)
   - Le BLoC doit-il être Singleton ou Factory ?

2. **Planifier les DTOs** :
   - Les DTOs existent-ils dans `features/[feature]/dto/` ?
   - `fromJson()` et `toJson()` nécessaires ?

3. **Planifier le Service** :
   - Appels HTTP via `HttpService` ?
   - Cache offline via `OfflineCacheService` ?
   - Actions offline via la queue ?

4. **Planifier l'UI** :
   - Les textes sont-ils dans les fichiers ARB ? (7 langues)
   - Découpage en sous-widgets (MAX 150 lignes par widget)
   - Indicateur offline si `isOffline: true`

5. **Ordre d'implémentation** (voir Phase 4)

---

## Phase 3 : i18n d'abord (OBLIGATOIRE)

Avant d'écrire un seul widget :

1. **Ajouter les clés dans `lib/l10n/app_fr.arb`** (référence)
2. **Ajouter les traductions dans les 6 autres fichiers ARB** (en, de, ja, ko, pt, es)
3. Utiliser `context.l10n.maCle` dans les widgets

**Aucun texte hardcodé** dans les widgets — zero exception.

---

## Phase 4 : Implémentation

**Ordre recommandé** :

1. **DTOs** — `fromJson()` / `toJson()`, typage strict, dans `features/[feature]/dto/`
2. **Service** — Appels HTTP via `HttpService`, cache `OfflineCacheService`
3. **BLoC** — Events / States / Logique (pattern offline avec `SocketException`)
4. **Enregistrement GetIt** — Dans `core/service_locator/service_locator.dart`
5. **Widgets** — Sous-composants privés (`_NomWidget`), `const` constructors, Material 3
6. **View** — `BlocBuilder` + switch sur les states, indicateur offline

**Limites strictes** :
- Widgets : MAX 150 lignes → extraire `_SousWidget`
- Si logique complexe dans un widget → la déplacer dans le BLoC ou service

---

## Phase 5 : Validation

**Checklist** :

1. ✅ Aucun texte hardcodé (tout en ARB, 7 langues) ?
2. ✅ Pattern BLoC respecté (Event → BLoC → State) ?
3. ✅ Mode offline géré (`SocketException` → `isOffline: true`) ?
4. ✅ Indicateur offline affiché si `isOffline: true` ?
5. ✅ Service enregistré dans `service_locator.dart` ?
6. ✅ BLoC enregistré (singleton ou factory selon le cas) ?
7. ✅ `cached_network_image` pour toutes les images réseau ?
8. ✅ `const` constructors utilisés partout où possible ?
9. ✅ Thème Material 3 (pas de couleurs hardcodées) ?
10. ✅ Aucun widget > 150 lignes ?
11. ✅ `ListView.builder()` pour les listes dynamiques ?

---

## Phase 6 : Documentation

1. **Mettre à jour `.cursor/memory-bank/progress.md`** — Documenter la feature
2. **Mettre à jour `.cursor/memory-bank/architecture.md`** — Si nouveau service/BLoC
3. **Mettre à jour `.cursor/documentation/architecture-feature.md`** — Si nouveau pattern

---

## Format de Réponse

```markdown
## Feature : [Nom]

### Analyse
- Feature : [auth | home | library | manga | profile | search | reader]
- BLoC : [nouveau | existant modifié]
- Service : [nouveau | existant modifié]
- Enregistrement GetIt : [singleton | lazy singleton | factory]

### Implémentation
- DTOs : [liste]
- Events ajoutés : [liste]
- States ajoutés : [liste]
- Clés ARB ajoutées : [nombre] (7 langues ✅)
- Widgets créés : [liste avec taille]

### Validation
- ✅ Checklist complétée
- Offline géré : ✅ / non applicable

### Memory bank mis à jour
- `.cursor/memory-bank/progress.md` : ✅
- `.cursor/memory-bank/architecture.md` : [✅ / non nécessaire]
```

---

**Rappel** : Lire le memory-bank AVANT de coder. i18n AVANT les widgets. Le vibe coding est interdit.
