# Documentation : Design System — Manga Tracker Flutter

## Tokens

Localisation : `lib/core/theme/`

### `AppColors` ([core/theme/app_colors.dart](../../lib/core/theme/app_colors.dart))

Palette principale :

| Token | Valeur | Usage |
|-------|--------|-------|
| `AppColors.primary` | `Color(0xFFD32F2F)` | Couleur principale (rouge manga) |
| `AppColors.accent` | `Color(0xFFFF9800)` | Accent / actions secondaires |
| `AppColors.success` | (vert) | États success |
| `AppColors.error` | (rouge erreur) | États error |
| `AppColors.warning` | (orange) | États warning, banner offline |
| `AppColors.info` | (bleu) | Infos neutres |

**Préférer** `Theme.of(context).colorScheme.*` quand disponible (Material 3 expose primary, secondary, error, surface, onSurface...).

### `AppRadius` ([core/theme/app_radius.dart](../../lib/core/theme/app_radius.dart))

| Token | Valeur (dp) | Usage typique |
|-------|------------|---------------|
| `AppRadius.xs` | 4 | Très petits éléments (chips) |
| `AppRadius.s` | 8 | Boutons, tags |
| `AppRadius.m` | 12 | Cards |
| `AppRadius.card` | (selon impl) | Cards manga |
| `AppRadius.l` | 16 | Containers |
| `AppRadius.jumbo` | 20 | Modaux, dialogs |

Constantes `BorderRadius` pré-fabriquées : `AppRadius.allMedium`, etc.

### `AppTextStyle` ([core/theme/app_text_styles.dart](../../lib/core/theme/app_text_styles.dart))

Styles de texte (titres, corps, captions). **Préférer `Theme.of(context).textTheme.*`** dans les widgets.

### 🆕 `AppSpacing` (À CRÉER)

À créer dans `lib/core/theme/app_spacing.dart` :

```dart
class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double jumbo = 48;
}
```

Aujourd'hui les paddings sont hardcodés (`EdgeInsets.all(16)`). Migration progressive vers `AppSpacing.m`.

---

## Thème

### `AppTheme` ([core/theme/app_theme.dart](../../lib/core/theme/app_theme.dart))

- `useMaterial3: true`
- Light theme actif
- Dark theme préparé (commenté, à activer en v0.4)
- Couleurs dérivées de `AppColors.primary`

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ),
  // ...
)
```

---

## Composants réutilisables

Localisation : `lib/core/components/`

| Composant | Fichier | Usage |
|-----------|---------|-------|
| `AuthButton` | `auth_button.dart` | Bouton auth (login, register, biometric) — variants login/biometric |
| `FilterButton` | `filter_button.dart` | Bouton filtre activable (toggle) |
| `SearchBar` | `search_bar.dart` | Barre de recherche avec icône |
| `PasswordFields` | `password_fields.dart` | Champs mot de passe avec toggle visibility + validation |
| `LanguageSelectorButton` | `language_selector_button.dart` | Sélecteur de langue (modal) |
| `ChangelogDialog` | `changelog_dialog.dart` | Dialog affichant le changelog |
| `WelcomeHeader` | `welcome_header.dart` | En-tête de bienvenue (page accueil) |
| `IntputTextfield` | `intput_textfield.dart` | Champ texte stylisé (note: typo dans le nom) |

### Règles communes

Tous les composants `core/components/` :
- ✅ `const` constructor
- ✅ Paramètres typés explicitement
- ✅ Tokens du thème (jamais de hardcode)
- ✅ Texte affiché passé en paramètre (i18n côté parent) ou via `context.l10n`
- ✅ Accessibilité : `Semantics`, `tooltip`
- ✅ Responsive : `LayoutBuilder` quand pertinent

### Promotion d'un composant

Parcours de maturité :
1. `_NomWidget` privé dans la view → premier usage
2. `lib/features/X/widgets/<nom>.dart` → réutilisé dans la feature
3. `lib/core/components/<nom>.dart` → réutilisé entre features

Voir skill `/add-component`.

---

## Composants à créer (évolution)

| Composant | Raison | Priorité |
|-----------|--------|----------|
| `OfflineBanner` | Centraliser l'affichage du mode offline | Haute |
| `MangaCard` | Carte manga unifiée (image + titre + score) | Haute |
| `MangaRow` | Ligne dans une liste | Haute |
| `MangaGenreChip` | Chip Material 3 avec wrap | Moyenne |
| `LoadingSkeleton` | Skeleton screen générique paramétrable | Moyenne |
| `EmptyState` | État vide avec illustration + action | Moyenne |
| `ErrorState` | État d'erreur avec retry | Moyenne |
| `AdaptiveButton` | Wrapper Cupertino/Material pour iOS adaptive | Basse (après iOS) |

Documenter dans `progress.md` quand créés.

---

## Règles d'usage

### Couleurs

```dart
// ✅
color: Theme.of(context).colorScheme.primary
color: Theme.of(context).colorScheme.surface
color: AppColors.warning  // pour le banner offline

// ❌
color: Colors.blue
color: const Color(0xFF1234)
```

### Espacements

```dart
// ✅ aujourd'hui (en attendant AppSpacing)
padding: const EdgeInsets.all(16)
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)

// ✅ après création de AppSpacing
padding: const EdgeInsets.all(AppSpacing.m)
padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s)
```

### Rayons

```dart
// ✅
borderRadius: BorderRadius.circular(AppRadius.card)

// ❌
borderRadius: BorderRadius.circular(12)
```

### Textes

```dart
// ✅
style: Theme.of(context).textTheme.titleMedium
style: Theme.of(context).textTheme.bodySmall

// ❌
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
```
