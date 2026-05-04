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

## Composants réutilisables existants

Vérifier ces composants avant d'en créer un nouveau (`lib/core/components/`) :

| Composant | Usage |
|-----------|-------|
| `AuthButton` | Bouton auth |
| `FilterButton` | Bouton filtre activable |
| `SearchBar` | Barre de recherche |
| `PasswordFields` | Champs mot de passe |
| `LanguageSelectorButton` | Sélecteur de langue |
| `ChangelogDialog` | Dialog changelog |
| `WelcomeHeader` | En-tête de bienvenue |
| `IntputTextfield` | Champ texte stylisé |

→ **Toujours vérifier** avant d'en créer un nouveau. Si manque → utiliser skill `/add-component`.

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
