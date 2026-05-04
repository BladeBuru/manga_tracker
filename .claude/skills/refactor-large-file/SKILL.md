---
name: refactor-large-file
description: Découpage d'un fichier Flutter dépassant les seuils (Widget > 150, BLoC > 200, Service > 300, fichier > 400 lignes) — extraction de widgets privés, services spécialisés, helpers BLoC.
---

# Skill : Refactor large file — Manga Tracker Flutter

Découpage d'un fichier Flutter dépassant les seuils.

---

## Seuils

| Type | Seuil d'alerte | Action |
|------|---------------|--------|
| Widget / View | > 150 lignes | Extraire des `_NomWidget` privés |
| Service | > 300 lignes | Extraire des méthodes dans un service spécialisé |
| BLoC | > 200 lignes | Extraire des handlers en méthodes privées / mixins |
| Tout fichier | > 400 lignes | **CRITIQUE** — découpage immédiat |

---

## Étape 1 — Analyser

1. Identifier les blocs visuels indépendants (header, liste, card, footer...).
2. Identifier les logiques répétées dans un service.
3. Choisir le pattern adapté.

---

## Patterns

### Widget / View > 150 lignes

```dart
// ❌ Avant : 300 lignes dans LateDetailView
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
```

**Règle** : widgets privés (`_`) dans le même fichier si usage unique. Fichier séparé dans `widgets/` si réutilisé. Si plus large que la feature → `core/components/`.

### Service > 300 lignes

```
features/library/
├── services/
│   ├── library.service.dart         # Orchestration légère
│   ├── library_cache.service.dart   # Logique de cache dédiée
│   └── library_sync.service.dart    # Logique de sync
```

```dart
class LibraryService {
  final LibraryCacheService _cacheService;

  Future<List<MangaQuickViewDto>> getUserLibrary() async {
    return _cacheService.getUserLibraryWithFallback();
  }
}
```

### BLoC > 200 lignes

```dart
class DetailBloc extends Bloc<DetailEvent, DetailState> {
  Future<void> _onLoadDetail(LoadDetail event, Emitter<DetailState> emit) async {
    await _handleLoadDetail(event, emit);
  }

  Future<void> _handleLoadDetail(...) async { ... }
}
```

Ou extraire dans un mixin :

```dart
mixin _DetailLibraryHandlers on Bloc<DetailEvent, DetailState> {
  Future<void> _onAddToLibrary(...) async { ... }
}
```

---

## Étape 2 — Plan de découpage

1. Lister les extractions (nom des nouveaux widgets/services).
2. Vérifier les dépendances (props, injections).
3. Extraire progressivement — un widget/service à la fois.
4. Tester visuellement après chaque extraction (hot reload).

---

## Étape 3 — Validation

- [ ] Aucun widget > 150 lignes
- [ ] Aucun service > 300 lignes
- [ ] Aucun BLoC > 200 lignes
- [ ] `const` constructors conservés
- [ ] Imports corrects partout
- [ ] Comportement visuel identique (hot reload)
- [ ] Pas de duplication introduite

---

## Format de réponse

```markdown
## Refactoring : [nom-fichier.dart]

### Analyse
- Taille initiale : [X] lignes
- Blocs identifiés : [liste]
- Pattern appliqué : [widget split | service split | BLoC split]

### Découpage
- Fichiers créés : [liste avec taille finale]
- Widgets extraits : [liste]
- Fichier original : [X] → [Y] lignes

### Validation
- ✅ Aucun fichier > seuil
- ✅ Comportement inchangé
- ✅ const constructors conservés
```

---

**Rappel** : Extraire progressivement. Vérifier le hot reload après chaque extraction.
