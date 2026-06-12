# RETRO-017 — Platform-split lecteur via conditional exports Dart

| Champ      | Valeur                                          |
|------------|-------------------------------------------------|
| Statut     | Documenté (rétro)                               |
| Date       | 2026-06-04                                      |
| Source     | Rétro-ingénierie                                |
| Features   | reader, download, manga                         |

> **Consolidation (2026-06-04)** : cet ADR fusionne l'ancien RETRO-021 (découvert côté `download`) qui décrivait exactement la même décision. RETRO-021 a été retiré ; cet ADR est désormais l'ADR canonique du platform-split sur les 3 modules.

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | STACK |
| Q1 — Coût de revert > 1j ? | OUI — Remplacer les conditional exports par des vérifications `kIsWeb` ou `Platform.isAndroid` inline nécessiterait de modifier les façades `web_view.dart`, `offline_reader_view.dart`, les deux implémentations équivalentes dans `download` (`chapter_download_service.dart`, `download_manager_service.dart`), tous leurs call sites, et d'introduire `dart:io` guards dans les fichiers actuellement propres. Impact transverse sur reader + download, plus d'une journée. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` liste `flutter_inappwebview`, `url_launcher` et `webview_flutter` sans indiquer lequel est actif selon la plateforme, ni que le mécanisme de sélection est le conditional export plutôt qu'un `if (kIsWeb)` runtime. L'intention architecturale (build-time separation, stubs sans dart:io) n'est pas visible dans les configs. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — reader (web_view.dart + offline_reader_view.dart) ET download (chapter_download_service.dart + download_manager_service.dart) utilisent le même pattern. Toute nouvelle feature avec du code platform-specific doit suivre ce pattern pour rester cohérente. |
| Q4 — Casse un invariant si ignoré ? | OUI — Un développeur qui contourne le pattern en ajoutant un `import 'dart:io'` direct dans un fichier non-`_io.dart` ou en utilisant `Platform.isAndroid` sans abstraction provoque un échec de compilation du build web Flutter (`dart:io` n'existe pas sur le web). |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

---

## Contexte

Flutter supporte plusieurs plateformes (mobile iOS/Android, web, desktop) depuis un unique codebase Dart. Certaines fonctionnalités — la WebView embarquée et le téléchargement de fichiers — nécessitent des APIs natives (`dart:io`, `flutter_inappwebview`) qui n'existent pas sur le web. Dart propose un mécanisme de compilation conditionnelle via la syntaxe `export 'impl.dart' if (dart.library.html) 'stub.dart'` qui sélectionne le fichier exporté au moment de la compilation selon la plateforme cible.

L'application cible Android en production et prépare iOS + Web pour sa roadmap. Le pattern a probablement été introduit lors de la migration vers `go_router` et la mise en place du build web (workflow `web-deploy.yml`).

Trois approches étaient possibles (héritées de l'analyse `download`) :
1. Guards `kIsWeb` à chaque call site — risque d'oubli, bruit dans le code.
2. Abstract class + factory dans GetIt — lourd pour des services non partagés globalement.
3. Conditional exports Dart (`export 'impl_io.dart' if (dart.library.html) 'impl_web.dart'`) — **option retenue**.

## Décision identifiée

Pour toute feature nécessitant du code platform-specific, l'application utilise le pattern conditional exports :

1. Un fichier façade public (`feature.dart`) qui n'exporte que la bonne implémentation selon la plateforme :
   ```dart
   export 'feature_io.dart'
       if (dart.library.html) 'feature_web.dart';
   ```
2. Un fichier `_io.dart` contenant l'implémentation mobile complète (peut importer `dart:io`, `flutter_inappwebview`, etc.).
3. Un fichier `_web.dart` contenant un stub web (ne peut importer aucun package dart:io-dépendant) — soit un `UnsupportedError`, soit un widget informatif, soit une redirection via `url_launcher`.

Implémentations actives suivant ce pattern :
- `lib/features/manga/views/web_view.dart` → `web_view_io.dart` / `web_view_web.dart`
- `lib/features/reader/views/offline_reader_view.dart` → `offline_reader_view_io.dart` / `offline_reader_view_web.dart`
- `lib/features/download/services/chapter_download_service.dart` → impl IO / stub web
- `lib/features/download/services/download_manager_service.dart` → impl IO / stub web

## Conséquences observées

### Positives
- Le build web Flutter compile sans erreur malgré la présence de code `dart:io` dans les fichiers `_io.dart`.
- Les stubs web contiennent des interfaces utilisateur de remplacement (bouton "Ouvrir dans le navigateur", message "non disponible") plutôt que des crashs silencieux.
- La surface d'API publique (façade) est identique entre plateformes, ce qui simplifie les imports dans les call sites.
- L'isolation est statique (compile-time) et non runtime, ce qui évite le dead code dans chaque build.

### Négatives / Dette
- `web_view_io.dart` dépasse 1173 lignes — très au-dessus du seuil de 150 lignes pour les widgets. La complexité de la WebView rend le découpage en sous-widgets difficile mais souhaitable.
- Le pattern est appliqué manuellement (pas d'outil de génération) ; il est possible d'oublier de créer le stub web lors de l'ajout d'une nouvelle implémentation IO.
- Les stubs web ne permettent pas de suivi de progression (limitation intrinsèque) — aucun fallback de progression n'est documenté pour les utilisateurs web.
- Côté `download` : la convention « les call sites guardent avec `kIsWeb` » pour `ChapterDownloadService` (dont le stub web lève `UnsupportedError`) est implicite et non formalisée — un dev peut invoquer `downloadChapter()` sans guard et obtenir une erreur à l'exécution. `DownloadManagerService` n'est pas enregistré dans GetIt : aucune interface abstraite partagée, la substitution repose entièrement sur le conditional export.

## Recommandation

Garder ce pattern — il est la seule solution viable pour maintenir la compilation web sans abstractions de service entières pour des features profondément natives (WebView, filesystem). Documenter dans l'onboarding développeur qu'**toute nouvelle feature avec du code `dart:io` doit créer une façade conditional export**. À terme, envisager d'ajouter une interface abstraite Dart (ex. `abstract class IDownloadManagerService`) implémentée par les deux variantes, pour rendre le contrat explicite et permettre les tests via mocks.
