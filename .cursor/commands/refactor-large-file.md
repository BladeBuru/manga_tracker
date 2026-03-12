# Commande : Découper un fichier trop long — Manga Tracker Flutter

Quand cette commande est déclenchée, suivre ce guide pour découper un fichier Flutter trop long.

---

## Seuils de découpage

| Type | Seuil d'alerte | Action |
|------|---------------|--------|
| Widget / View | > 150 lignes | Extraire des sous-widgets `_NomWidget` |
| Service | > 300 lignes | Extraire des méthodes dans un service spécialisé |
| BLoC | > 200 lignes | Extraire des handlers dans des mixins ou helper methods |
| Tout fichier | > 400 lignes | **CRITIQUE** — découpage obligatoire immédiat |

---

## Étape 1 : Analyser le fichier

1. **Identifier les blocs visuels indépendants** dans un widget (header, liste, card, footer…)
2. **Identifier les logiques répétées** dans un service
3. **Choisir le pattern de découpage adapté** (voir ci-dessous)

---

## Patterns de découpage

### Widget / View trop long (> 150 lignes)

**Pattern** : Extraire des widgets privés dans le même fichier ou dans `widgets/`

```dart
// ❌ Avant : tout dans LateDetailView (300 lignes)
class LateDetailView extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(children: [
      // header (60 lignes)
      // info section (80 lignes)
      // chapter list (100 lignes)
      // action buttons (60 lignes)
    ]);
  }
}

// ✅ Après : découpé
class LateDetailView extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(children: [
      const _DetailHeader(),         // 60 lignes
      const _DetailInfoSection(),    // 80 lignes
      const _DetailChapterList(),    // 100 lignes — peut aller dans widgets/
      const _DetailActionButtons(),  // 60 lignes
    ]);
  }
}

// Widgets privés dans le même fichier
class _DetailHeader extends StatelessWidget { ... }
class _DetailInfoSection extends StatelessWidget { ... }

// Ou dans features/manga/widgets/ si réutilisable
```

**Règle** : Widgets privés (`_`) dans le même fichier si usage unique. Fichier séparé dans `widgets/` si réutilisé.

---

### Service trop long (> 300 lignes)

**Pattern** : Extraire des méthodes dans un service spécialisé

```
features/library/
├── services/
│   ├── library.service.dart         # Service principal (orchestration)
│   ├── library_cache.service.dart   # Logique de cache dédiée
│   └── library_sync.service.dart    # Logique de synchronisation
```

```dart
// library.service.dart — orchestration légère
class LibraryService {
  final LibraryCacheService _cacheService;

  Future<List<MangaQuickViewDto>> getUserLibrary() async {
    return _cacheService.getUserLibraryWithFallback();
  }
}
```

---

### BLoC trop long (> 200 lignes)

**Pattern** : Extraire les handlers complexes en méthodes privées ou helpers

```dart
class DetailBloc extends Bloc<DetailEvent, DetailState> {
  // Garder le bloc < 200 lignes
  // Extraire la logique complexe dans des méthodes privées

  Future<void> _onLoadDetail(LoadDetail event, Emitter<DetailState> emit) async {
    // Déléguer à une méthode privée si > 30 lignes
    await _handleLoadDetail(event, emit);
  }

  Future<void> _handleLoadDetail(...) async { ... }
}
```

---

## Étape 2 : Plan de découpage

1. **Lister les extractions** à faire (avec nom du nouveau widget/service)
2. **Vérifier les dépendances** (props à passer au widget, injections service)
3. **Extraire progressivement** — un widget/service à la fois
4. **Tester visuellement** après chaque extraction (hot reload)

---

## Étape 3 : Validation post-découpage

**Checklist** :

1. ✅ Aucun widget > 150 lignes ?
2. ✅ Aucun service > 300 lignes ?
3. ✅ `const` constructors conservés sur les widgets statiques ?
4. ✅ Imports corrects dans tous les fichiers ?
5. ✅ Comportement visuel identique (hot reload vérifié) ?
6. ✅ Pas de duplication de logique introduite ?

---

## Format de Réponse

```markdown
## Refactoring : [nom-fichier.dart]

### Analyse
- Taille initiale : [X] lignes
- Blocs identifiés : [liste]
- Pattern appliqué : [widget split | service split | BLoC split]

### Découpage
- Fichiers créés : [liste avec taille finale]
- Widgets extraits : [liste]
- Fichier original : [X] lignes → [Y] lignes

### Validation
- ✅ Aucun fichier > seuil
- ✅ Comportement inchangé
- ✅ const constructors conservés
```

---

**Rappel** : Extraire progressivement. Vérifier le hot reload après chaque extraction.
