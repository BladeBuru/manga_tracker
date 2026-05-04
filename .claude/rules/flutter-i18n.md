# Internationalisation (i18n) — Manga Tracker Flutter

> Snippet injecté quand vous éditez un fichier `lib/**/*.dart` ou `lib/l10n/**/*.arb`.

## Règle absolue

**TOUT texte visible dans l'UI DOIT être traduit.**
Aucun texte hardcodé dans les widgets — utiliser exclusivement les fichiers ARB.

## Langues supportées (7)

| Code | Langue | Fichier ARB |
|------|--------|-------------|
| `fr` | Français (référence) | `lib/l10n/app_fr.arb` |
| `en` | Anglais | `lib/l10n/app_en.arb` |
| `de` | Allemand | `lib/l10n/app_de.arb` |
| `ja` | Japonais | `lib/l10n/app_ja.arb` |
| `ko` | Coréen | `lib/l10n/app_ko.arb` |
| `pt` | Portugais | `lib/l10n/app_pt.arb` |
| `es` | Espagnol | `lib/l10n/app_es.arb` |

## Utilisation dans les widgets

```dart
// Option 1 — Accès direct
Text(AppLocalizations.of(context)!.mangaTitle)

// Option 2 — Via extension (préférée)
Text(context.l10n.mangaTitle)

// Avec paramètres
Text(AppLocalizations.of(context)!.chaptersRead(42))
// ARB : "chaptersRead": "{count} chapitres lus"
```

## Processus d'ajout d'une clé

1. **Ajouter en français** dans `app_fr.arb` (référence) :
```json
{
  "mangaAddedToLibrary": "Manga ajouté à la bibliothèque",
  "chaptersRead": "{count} chapitres lus",
  "@chaptersRead": {
    "placeholders": {
      "count": { "type": "int" }
    }
  }
}
```

2. **Ajouter dans les 6 autres ARB** (en, de, ja, ko, pt, es) — toutes les clés doivent être présentes dans tous les fichiers.

3. **Régénérer** :
```bash
flutter gen-l10n
```

## Gestion dynamique de la langue

```dart
// Changer la langue (via LanguageService)
await getIt<LanguageService>().setLanguage('ja');

// Récupérer la langue actuelle
final lang = await getIt<LanguageService>().getCurrentLanguage();
```

- `LanguageService` gère la persistance via `shared_preferences`.
- Changement de langue sans redémarrage de l'application.

## Conventions de nommage des clés ARB

| Usage | Convention | Exemple |
|-------|-----------|---------|
| Page/section title | `[section]Title` | `libraryTitle`, `profileTitle` |
| Action button | `[action][Object]` | `addToLibrary`, `updateStatus` |
| Message de feedback | `[action][Object][Result]` | `mangaAddedSuccess`, `updateFailed` |
| Label de champ | `[field]Label` | `emailLabel`, `passwordLabel` |
| Message d'erreur | `[context]Error` | `networkError`, `authError` |
| Statut | `status[Value]` | `statusReading`, `statusCompleted` |
| Confirmation | `confirm[Action]` | `confirmDelete`, `confirmLogout` |
| Accessibilité | `[context]Accessibility` | `addToLibraryAccessibility` |

## Anti-patterns INTERDITS

```dart
// ❌ INTERDIT — texte hardcodé
Text('Ajouter à la bibliothèque')
Text('Add to library')
SnackBar(content: Text('Erreur de connexion'))

// ✅ CORRECT
Text(context.l10n.addToLibrary)
SnackBar(content: Text(context.l10n.networkError))

// ❌ INTERDIT — interpolation directe
Text('${manga.title} ajouté !')

// ✅ CORRECT (avec paramètre ARB)
Text(context.l10n.mangaAdded(manga.title))
```

## Pièges courants

- Une clé ajoutée dans `app_fr.arb` mais oubliée dans une autre langue → l'app crash en runtime sur cette langue.
- Toujours faire les 7 langues ensemble. Pour ajouter rapidement les 6 traductions : utiliser un outil de traduction puis relire.
- Pluriels : utiliser le placeholder ICU `{count, plural, =0{...} =1{...} other{...}}`.
