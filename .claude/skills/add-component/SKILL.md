---
name: add-component
description: Workflow design-system-first pour ajouter un widget Flutter à Manga Tracker — décide entre core/components/ (réutilisable) ou features/X/widgets/ (spécifique), force l'usage des tokens (AppColors, AppRadius, AppTextStyle, AppSpacing), vérifie i18n et accessibilité, génère un widget test stub.
---

# Skill : Add component — Manga Tracker Flutter

Workflow pour créer un nouveau widget en respectant le design system.

---

## Étape 1 — Décider de l'emplacement

```
Le widget sera-t-il utilisé par plusieurs features ?
│
├── OUI → lib/core/components/<nom>.dart  (réutilisable)
│
└── NON → lib/features/<feature>/widgets/<nom>.dart  (spécifique)
       │
       └── Si trop spécifique à une view → widget privé `_Nom` dans le fichier de la view
```

Règle : la **maturité** d'un composant suit ce parcours :
1. Privé `_Nom` dans la view (premier usage)
2. Fichier dans `features/X/widgets/` (réutilisé dans la feature)
3. Promotion vers `core/components/` (réutilisé entre features)

Ne pas créer directement dans `core/components/` si on ne sait pas s'il sera réutilisé. Promotion par refactoring quand le besoin émerge.

---

## Étape 2 — Vérifier les composants existants

Avant de créer, vérifier `lib/core/components/` :

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

Si un composant similaire existe → l'utiliser (et éventuellement étendre via paramètres optionnels).

---

## Étape 3 — Squelette obligatoire

```dart
import 'package:flutter/material.dart';
import 'package:manga_tracker/core/theme/app_colors.dart';
import 'package:manga_tracker/core/theme/app_radius.dart';
// import 'package:manga_tracker/core/theme/app_spacing.dart'; // si AppSpacing existe
import 'package:manga_tracker/l10n/app_localizations.dart';

class MyComponent extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const MyComponent({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(16), // → AppSpacing.m quand dispo
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
```

Règles non-négociables :

- ✅ `const` constructor
- ✅ `Theme.of(context).colorScheme.*` pour les couleurs (jamais `Colors.X` ni `Color(0xFF...)`)
- ✅ `Theme.of(context).textTheme.*` pour les styles
- ✅ `AppRadius.*` pour les rayons
- ✅ `AppSpacing.*` pour les espacements (à créer si absent — voir progress.md)
- ✅ `Semantics` pour l'accessibilité (label, button, etc.)
- ✅ Texte affiché → `context.l10n.maCle` (jamais hardcodé)
- ✅ MAX 150 lignes — découper sinon

---

## Étape 4 — i18n

Si le composant affiche du texte :
1. Ajouter les clés dans `lib/l10n/app_fr.arb` (référence).
2. Traduire dans les 6 autres ARB.
3. Régénérer : `flutter gen-l10n`.
4. Utiliser `context.l10n.maCle`.

Si le composant prend le texte en paramètre (comme `MyComponent(label: ...)`), l'i18n est faite par le **parent** qui l'utilise.

---

## Étape 5 — Cross-platform

- ✅ Pas de `Platform.isAndroid` direct
- ✅ Pas de `dart:io` direct
- ✅ Si interaction native (caméra, file pick, biométrie...) → passer par un service abstrait dans `core/services/`
- ✅ Tester avec `flutter run -d chrome` en plus de Android (web prévu)

---

## Étape 6 — Widget test stub

Créer `test/<chemin équivalent>/<nom>_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_tracker/core/components/my_component.dart';

void main() {
  testWidgets('MyComponent renders label and reacts to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyComponent(
            label: 'Hello',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    await tester.tap(find.byType(MyComponent));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('MyComponent has accessibility label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MyComponent(label: 'Hello'),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MyComponent)),
      matchesSemantics(label: 'Hello'),
    );
  });
}
```

Au minimum 1 test :
- Le composant rend ce qu'on attend
- L'accessibilité est en place
- (Si callback) Le callback est appelé

---

## Étape 7 — Documentation

Si le composant est dans `core/components/` :

1. Mettre à jour `.claude/docs/design-system.md` (section "Composants réutilisables") avec :
   - Nom
   - Usage en une phrase
   - Snippet d'utilisation typique

2. Si premier usage des tokens `AppSpacing` : noter dans `progress.md` que la création du fichier `app_spacing.dart` a été initiée.

---

## Format de réponse

```markdown
## Composant : [Nom]

### Décision
- Emplacement : [core/components/ | features/X/widgets/ | _privé dans view]
- Réutilisable : [oui | non]
- Justification : [...]

### Implémentation
- Fichier : [chemin]
- Lignes : [X]
- Tokens utilisés : [AppColors.X, AppRadius.Y, AppTextStyle.Z]
- i18n : [N clés ajoutées (7 langues) | aucune (texte en param)]
- Accessibilité : [Semantics ✅]

### Tests
- Fichier : [chemin]
- Cas couverts : [liste]

### Doc mise à jour
- design-system.md : [✅ / non applicable]
- progress.md : [✅ / non applicable]
```
