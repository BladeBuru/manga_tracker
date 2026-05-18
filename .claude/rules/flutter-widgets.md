# Widget Standards — Manga Tracker Flutter

> Snippet injecté quand vous éditez un fichier dans `lib/features/.../views/`, `lib/features/.../widgets/`, ou `lib/core/components/`.

## Découpage (OBLIGATOIRE)

**MAX 150 lignes** par widget. Si plus → extraire des sous-widgets privés (`_NomWidget`).

```dart
// ❌ MAUVAIS — tout dans un seul widget
class LateDetailView extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(children: [/* 300 lignes... */]);
  }
}

// ✅ BON — découpé
class LateDetailView extends StatelessWidget {
  const LateDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const _DetailAppBar(),
        _DetailInfo(),
        const _DetailChapterList(),
        const _DetailActionButtons(),
      ],
    );
  }
}

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar();
  @override
  Widget build(BuildContext context) { /* MAX 50 lignes */ }
}
```

**Règle** : widgets privés (`_`) dans le même fichier si usage unique. Fichier séparé dans `widgets/` si réutilisable.

## `const` constructors (OBLIGATOIRE)

```dart
// ✅ const partout où possible
const Text('Titre')
const SizedBox(height: 16)
const _MyPrivateWidget()
const EdgeInsets.symmetric(horizontal: 16)

class MangaCard extends StatelessWidget {
  final MangaQuickViewDto manga;
  const MangaCard({super.key, required this.manga}); // ✅ const
}
```

## Material 3 — Tokens du thème (obligatoire)

```dart
// ✅ Tokens
color: Theme.of(context).colorScheme.primary
color: Theme.of(context).colorScheme.surface
color: Theme.of(context).colorScheme.onSurface
style: Theme.of(context).textTheme.titleMedium
style: Theme.of(context).textTheme.bodySmall

// ✅ AppRadius pour les arrondis
borderRadius: BorderRadius.circular(AppRadius.card)
borderRadius: BorderRadius.circular(AppRadius.small)

// ❌ JAMAIS hardcoder
color: Colors.blue          // ❌
color: const Color(0xFF1234) // ❌
borderRadius: BorderRadius.circular(12) // ❌
```

## 🆕 Spacing — `AppSpacing` (à créer si absent)

Aujourd'hui les paddings sont hardcodés (`EdgeInsets.all(16)`). À terme, créer `lib/core/theme/app_spacing.dart` :

```dart
class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double jumbo = 48;
}
// Usage : EdgeInsets.all(AppSpacing.m)
```

Si vous éditez un widget : utiliser `AppSpacing` quand il existe, sinon noter dans le commit / progress.md qu'il faut le créer.

## 🆕 Responsive (évolution Web)

Avec l'arrivée prévue du Web, **les layouts doivent être responsive** :

```dart
// LayoutBuilder pour s'adapter à la largeur
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 800) {
      return _DesktopLayout();
    }
    if (constraints.maxWidth > 600) {
      return _TabletLayout();
    }
    return _MobileLayout();
  },
)

// MediaQuery pour les valeurs ponctuelles
final isWide = MediaQuery.of(context).size.width > 600;
```

## 🆕 Accessibilité (Play Store quality)

```dart
// Labels TalkBack / VoiceOver
Semantics(
  label: context.l10n.addToLibraryAccessibility,
  button: true,
  child: IconButton(...),
)

// Contraste WCAG AA (Material 3 colorScheme respecte déjà l'AA dans la plupart des cas)
// Font scaling : ne pas hardcoder fontSize fixe — utiliser textTheme et autoriser MediaQuery.textScaleFactor
```

## Images réseau — `cached_network_image` (obligatoire)

```dart
// ✅
CachedNetworkImage(
  imageUrl: manga.coverUrl,
  placeholder: (context, url) => const _MangaCardSkeleton(),
  errorWidget: (context, url, error) => const _MangaCardFallback(),
  fit: BoxFit.cover,
)

// ❌ Image.network INTERDIT
Image.network(manga.coverUrl)
```

## Listes — `ListView.builder` (obligatoire)

```dart
// ✅
ListView.builder(
  itemCount: mangas.length,
  itemBuilder: (context, index) => MangaRow(manga: mangas[index]),
)

// ❌ ListView avec children INTERDIT pour les listes dynamiques
ListView(
  children: mangas.map((m) => MangaRow(manga: m)).toList(),
)
```

## Composants réutilisables existants — DESIGN SYSTEM CENTRAL

> **🚨 RÈGLE DURE** : avant de créer un widget visuel (card, tile, button,
> empty state, error state, chip, badge…), tu DOIS d'abord vérifier
> `lib/core/components/` et **réutiliser** un primitive existant. Si
> aucun primitive ne couvre le besoin, **CRÉER** le primitive dans
> `core/components/` (PAS dans `features/X/widgets/`) pour qu'il soit
> réutilisable par toutes les futures pages.
>
> **Interdit** : recréer un widget visuel ad-hoc dans `features/X/widgets/`
> alors qu'il pourrait être un primitive du design system. Cela mène à
> 5 versions différentes de "Card" dans l'app et brise la cohérence.

### Primitives du design system (`lib/core/components/`)

| Composant | Usage | Style "Google Material 3 modern" |
|-----------|-------|-----------------------------------|
| **Buttons** | | |
| `AuthButton` | CTA auth (login, register) | Filled + radius lg |
| `FilterButton` | Filtre activable | Tonal + chip-like quand selected |
| **Inputs** | | |
| `SearchBar` | Barre de recherche globale | Pill shape (radius full) |
| `PasswordFields` | Champs password + validation | Outlined + show/hide |
| `IntputTextfield` | Champ texte stylisé | Outlined + radius lg |
| `LanguageSelectorButton` | Sélecteur de langue | Pill avec drapeau |
| **Sections/Cards** | | |
| `AppCard` *(à créer)* | Carte de contenu standard | surfaceContainerLow + radius xxxl + padding m |
| `AppListSection` *(à créer)* | Section titrée avec children | Titre + Container + tiles intérieures |
| `AppListTile` *(à créer)* | Item de liste avec leading/title/sub/trailing | Card tonal + radius md |
| **States** | | |
| `AppEmptyState` *(à créer)* | Icône + message + CTA optionnel centré | Icon 64px + bodyLarge + tonal button |
| `AppErrorState` *(à créer)* | Erreur avec bouton Retry | error color + retry tonal button |
| **Indicateurs (Google look)** | | |
| `AppChip` *(à créer)* | Pastille couleur (badge/tag/status) | secondaryContainer + radius xl + border outlineVariant |
| `AppCountBadge` *(à créer)* | Compteur rond (notifs, "12 mangas") | primary + onPrimary + radius xs + 11px bold |
| `AppStatusPill` *(à créer)* | Indicateur de statut (status reading, status group) | primaryContainer + radius full + 4-8px padding |
| **Composés** | | |
| `ChangelogDialog` | Dialog changelog | M3 AlertDialog |
| `WelcomeHeader` | Hero de bienvenue | Material 3 |

→ **Workflow obligatoire avant d'écrire `class _MaCard extends StatelessWidget`** :
> 1. **Chercher** dans `core/components/` un composant similaire.
> 2. Si trouvé → **utiliser** directement.
> 3. Si pas trouvé → vérifier que le besoin est suffisamment générique → **créer dans `core/components/`**.
> 4. Si vraiment spécifique à la feature (ex: `MangaCard` avec download dialog) → mettre dans `features/X/widgets/`.

## 🎨 Modern Material 3 "Google look" — règles esthétiques

L'objectif est un design moderne inspiré des dernières apps Google (Wallet,
Tasks, Files) — caractérisé par :

- **Surfaces empilées** : `surface` → `surfaceContainerLow` → `surfaceContainerHigh` (jamais blanc cassé pur)
- **Pastilles (chips/pills) partout** : pour status, count, tag, filter — pas de texte nu
- **Radii généreux** : `AppRadius.xxxl` (16px) pour cards, `xl` (12px) pour pills, `lg` (10px) pour inputs
- **Containers tonals** : `primaryContainer`/`onPrimaryContainer`, `secondaryContainer`/`onSecondaryContainer` pour les blocs colorés
- **Padding 16-20px** dans les cards (jamais 8 ou < 12)
- **Outline subtile** : `outlineVariant` pour séparer sans agresser
- **Icônes "outlined"** par défaut : `Icons.person_outline`, `Icons.inbox_outlined`, `Icons.groups_outlined`
- **Tonal buttons** plutôt que Elevated pour les actions secondaires : `FilledButton.tonal` > `OutlinedButton`
- **Badge.count** Material 3 pour les compteurs sur icônes
- **SegmentedButton** pour les choix mutuellement exclusifs (sort, filter)

### Exemple : convertir un "ancien" widget en "Google look"

```dart
// ❌ AVANT (Material 2-ish, ad-hoc)
Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(6),
  ),
  child: Row(
    children: [
      Icon(Icons.person, color: Colors.grey),
      Text('Username'),
    ],
  ),
)

// ✅ APRÈS (Material 3 + design system primitives)
AppListTile(
  leadingIcon: Icons.person_outline,
  title: 'Username',
  trailing: AppCountBadge(count: 3),
)
// (avec couleurs `scheme.surfaceContainerLow`, radius `xxxl`, padding 16)
```

## Indicateur offline (obligatoire si `state.isOffline`)

```dart
if (state.isOffline)
  Container(
    color: Colors.orange,
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    child: Row(
      children: [
        const Icon(Icons.cloud_off, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          context.l10n.offlineMode,
          style: const TextStyle(color: Colors.white),
        ),
        if (state.pendingActions > 0)
          Text(' · ${state.pendingActions} ${context.l10n.pendingActions}',
            style: const TextStyle(color: Colors.white)),
      ],
    ),
  ),
```

## États de chargement — Skeleton screens

```dart
FeatureLoading() => const _MangaListSkeleton(),
// Pour les petits composants : CircularProgressIndicator OK
```

## Formulaires — Validation

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: TextFormField(
    validator: (value) {
      if (value == null || value.isEmpty) {
        return context.l10n.fieldRequired;
      }
      return null;
    },
  ),
)

if (_formKey.currentState!.validate()) {
  context.read<MyBloc>().add(SubmitForm(data: ...));
}
```

## Auto-size text

```dart
import 'package:auto_size_text/auto_size_text.dart';

AutoSizeText(
  manga.title,
  maxLines: 2,
  minFontSize: 12,
  overflow: TextOverflow.ellipsis,
  style: Theme.of(context).textTheme.titleMedium,
)
```
