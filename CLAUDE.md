# CLAUDE.md — Manga Tracker (Flutter)

> Instructions chargées automatiquement à chaque session Claude Code dans ce projet.
> Migration depuis `.cursor/rules/rules.mdc` + `.cursor/rules/00-memory-bank-always.mdc` + sections évolution (cross-platform iOS/Web, Play Store, design system).

---

## 🏗️ Stack technique

- **Langage** : Dart 3.7+ — null safety obligatoire
- **Framework** : Flutter 3.x — Material 3
- **State management** : `flutter_bloc ^8`, `bloc ^8`, `equatable`
- **Injection de dépendances** : `get_it ^8` (Service Locator)
- **HTTP** : `http ^1.3` via `HttpService` centralisé
- **Stockage sécurisé** : `flutter_secure_storage` (tokens JWT)
- **Préférences** : `shared_preferences` (données non sensibles)
- **Images** : `cached_network_image`
- **i18n** : `flutter_localizations` + `intl ^0.20.2` — ARB dans `lib/l10n/`
- **Auth biométrique** : `local_auth`
- **WebView** : `flutter_inappwebview` + `webview_flutter`
- **Connectivité** : `connectivity_plus`
- **Navigation** : `MaterialPageRoute` (migration vers `go_router` prévue, **obligatoire pour Web**)

---

## 🎯 Cibles plateformes (évolution)

L'application cible aujourd'hui **Android**. La feuille de route inclut :

1. **iOS** — App Store
2. **Web** — PWA / build web Flutter

**Conséquence non-négociable** : tout nouveau code DOIT être platform-agnostic par défaut. Les exceptions Android-only doivent être :
- isolées derrière une interface dans `core/services/`
- documentées dans `.claude/memory-bank/decisions.md`
- explicitement justifiées (ex: feature qui n'a pas d'équivalent iOS/Web)

Voir skill `/cross-platform-audit` pour vérifier un fichier ou feature.

---

## 📖 Lecture obligatoire avant tout code

**AVANT TOUTE MODIFICATION**, lire dans cet ordre :

1. [.claude/memory-bank/architecture.md](.claude/memory-bank/architecture.md) — Stack, BLoC, GetIt, services, navigation
2. [.claude/memory-bank/progress.md](.claude/memory-bank/progress.md) — État d'avancement, priorités
3. [.claude/memory-bank/roadmap.md](.claude/memory-bank/roadmap.md) — Vue d'ensemble des features (✅ / 🔵 / ⏳ / ❌) + mindmap mermaid
4. [.claude/memory-bank/known-issues.md](.claude/memory-bank/known-issues.md) — Bugs actifs et workarounds
5. [.claude/memory-bank/decisions.md](.claude/memory-bank/decisions.md) — Décisions architecturales (lire avant de proposer autre chose)

**Si la feature touche une page existante → lire son code avant de modifier.**
**Si pattern incertain → DEMANDER avant de coder.**

---

## 🚫 Interdiction absolue du vibe coding

- ❌ **JAMAIS** de code sans avoir lu le memory-bank
- ❌ **JAMAIS** de widget monolithique (> 150 lignes → découper)
- ❌ **JAMAIS** de logique métier dans un widget/view
- ❌ **JAMAIS** de BLoC qui gère plus d'une feature
- ❌ **JAMAIS** de texte hardcodé (utiliser ARB d'i18n — 7 langues)
- ❌ **JAMAIS** de couleurs ou dimensions hardcodées (utiliser tokens du thème + `AppRadius` + `AppSpacing`)
- ✅ **TOUJOURS** analyser l'architecture existante avant d'implémenter
- ✅ **TOUJOURS** respecter le pattern BLoC
- ✅ **TOUJOURS** traduire tous les textes visibles
- ✅ **TOUJOURS** mettre à jour `memory-bank/progress.md` après chaque feature
- ✅ **TOUJOURS** mettre à jour `memory-bank/roadmap.md` (statut `⏳` → `🔵` ou `✅`) quand une feature avance

---

## 🔄 Pattern BLoC (OBLIGATOIRE)

```
UI (View) → Event → BLoC → State → UI (View)
```

| BLoC | Enregistrement GetIt | Rôle |
|------|---------------------|------|
| `HomePageBloc` | Lazy singleton | Tendances / nouveautés / populaires |
| `LibraryBloc` | Lazy singleton | Bibliothèque utilisateur |
| `DetailBloc` | **FACTORY** ⚠️ | Détails manga — une instance par page |
| `ConnectivityBloc` | Singleton | État connexion réseau |

**`DetailBloc` en factory = NON-NÉGOCIABLE** (évite les race conditions entre pages).

---

## 📐 Limites strictes

| Type | Limite | Si dépassement |
|------|--------|---------------|
| Widget / View | 150 lignes | Extraire `_NomWidget` privés ou dans `widgets/` |
| Service | 300 lignes | Extraire un service spécialisé |
| BLoC | 200 lignes | Extraire les handlers en méthodes privées / mixins |
| Tout fichier | 400 lignes | **CRITIQUE** — découpage immédiat |

Voir skill `/refactor-large-file`.

---

## 🌍 Internationalisation (OBLIGATOIRE)

**TOUT texte visible DOIT être traduit.** 7 langues : FR (référence), EN, DE, JA, KO, PT, ES.

```dart
// ✅ BON
Text(AppLocalizations.of(context)!.libraryTitle)
Text(context.l10n.libraryTitle)

// ❌ MAUVAIS
Text('Ma bibliothèque')
```

Avant d'écrire un widget : ajouter les clés dans `app_fr.arb` + traduire dans les 6 autres ARB.

---

## 🎨 Design System & Material 3 (évolution)

Tokens existants dans `lib/core/theme/` :

- `AppColors` — palette (primary, accent, success, error, warning, info)
- `AppRadius` — rayons d'arrondi (xs, s, m, l, jumbo + BorderRadius pré-fabriqués)
- `AppTextStyle` — styles de texte
- `AppTheme` — ThemeData light + dark (Material 3, `useMaterial3: true`)

**🆕 À créer** : `AppSpacing` — tokens d'espacement (s, m, l, xl). Aujourd'hui les paddings sont hardcodés.

### Composants réutilisables (`lib/core/components/`)

Avant de créer un nouveau widget, vérifier ces composants :

| Composant | Usage |
|-----------|-------|
| `AuthButton` | Bouton auth (login, register, biometric) |
| `FilterButton` | Bouton de filtre activable |
| `SearchBar` | Barre de recherche |
| `PasswordFields` | Champs mot de passe avec validation |
| `LanguageSelectorButton` | Sélecteur de langue |
| `ChangelogDialog` | Dialog changelog |
| `WelcomeHeader` | En-tête de bienvenue |
| `IntputTextfield` | Champ texte stylisé |

Si un composant manque → invoquer skill `/add-component` (décide entre `core/components/` réutilisable vs `features/X/widgets/` spécifique, force l'usage des tokens, génère un widget test stub).

### Règles Material 3

```dart
// ✅ Tokens du thème
color: Theme.of(context).colorScheme.primary
style: Theme.of(context).textTheme.titleMedium

// ✅ AppRadius pour la cohérence
borderRadius: BorderRadius.circular(AppRadius.card)

// ❌ JAMAIS
color: Colors.blue
borderRadius: BorderRadius.circular(12)
```

### Règles UI

- `const` constructors obligatoires sur tous les widgets statiques
- `cached_network_image` pour toutes les images réseau (jamais `Image.network`)
- `ListView.builder()` pour toutes les listes dynamiques (jamais `ListView` avec children)
- `auto_size_text` pour les textes pouvant déborder
- Skeleton screens préférés aux `CircularProgressIndicator` génériques
- Indicateur visuel offline si `state.isOffline == true`

---

## 📴 Mode offline-first

- Détection offline via **`SocketException`** (pas `ConnectivityService`)
- Fallback API → cache via `OfflineCacheService` / `CacheHelperService`
- Queue actions offline → sync automatique à la reconnexion via `SyncService`
- État BLoC : toujours inclure `isOffline` (et `pendingActions` si applicable)

---

## 🌐 Cross-platform non-négociable (évolution iOS/Web)

- ❌ Pas de `dart:io` direct dans `lib/` — utiliser `path_provider`, `cross_file`, abstractions
- ❌ Pas de `Platform.isAndroid` dispersé sans abstraction — tout passe par une interface dans `core/services/`
- ❌ Pas de package Android-only sans abstraction (workmanager, AndroidFlutterLocalNotificationsPlugin, android_intent_plus...)
- ✅ `MediaQuery.size` + `LayoutBuilder` pour responsive (mobile / tablette / desktop / web)
- ✅ `go_router` obligatoire pour toute nouvelle navigation (deep-linking web nécessite go_router)
- ✅ Cupertino fallbacks pour les widgets purement Material si UX iOS attendue
- ✅ Privilégier les packages `*_flutter` cross-platform plutôt que natifs

Voir skill `/cross-platform-audit` pour repérer les dépendances Android-only.

---

## 🛡️ RGPD / Données personnelles (non-négociable)

Toute fonctionnalité touchant aux données utilisateur doit respecter :

### Règles absolues
- ❌ **JAMAIS** de `print()` ou `debugPrint()` qui affiche un email, mot de passe, token, contenu sensible.
- ❌ **JAMAIS** d'envoi de données vers un service tiers (analytics, crash reporting) sans l'avoir déclaré dans la Politique de confidentialité côté API.
- ❌ **JAMAIS** stocker des secrets dans `shared_preferences` (utiliser `flutter_secure_storage`).
- ✅ **TOUJOURS** consommer les endpoints `/user/gdpr/*` pour exposer les droits utilisateur (accès, portabilité, consentement).
- ✅ **TOUJOURS** afficher la page **« Mes données »** ([profile/views/my_data_view.dart](lib/features/profile/views/my_data_view.dart)) accessible depuis le profil.

### Consentement obligatoire à l'inscription
Le flow d'inscription DOIT inclure :
1. Cases à cocher (non pré-cochées) « J'accepte les CGU » et « J'accepte la Politique de confidentialité »
2. Liens cliquables vers les documents complets
3. Soumission du formulaire interdite tant que les deux cases ne sont pas cochées
4. Après inscription, appel à `GdprService.recordConsent(tosVersion, privacyVersion)` avec les versions retournées par `/user/gdpr/legal-versions`

### Re-consentement après mise à jour
À chaque login, vérifier `GdprService.getConsentStatus()` :
- Si `needsAnyAcceptance == true` → afficher modal demandant l'acceptation des nouvelles versions avant d'autoriser l'accès au reste de l'app.

### Page « Mes données » dans le profil
Doit exposer :
- ✅ Voir mes données (article 15)
- ✅ Exporter mes données (article 20)
- ✅ Lien vers la suppression de compte (article 17 — déjà existant)
- ✅ Lien vers la Politique de confidentialité
- ✅ Lien vers les CGU

---

## 📱 Play Store quality non-négociable (évolution)

L'app doit passer la review Play Store sans souci :

- ✅ `key.properties` et `*.jks` dans `.gitignore` (jamais versionnés)
- ✅ `versionCode` et `versionName` cohérents avec `pubspec.yaml`
- ✅ Build **App Bundle** (`.aab`) pas APK pour release
- ✅ `targetSdkVersion` ≥ 34 (exigence Play Store 2024+)
- ✅ Permissions Android justifiées dans `AndroidManifest.xml` (chaque permission doit avoir une raison user-facing)
- ✅ Privacy policy URL renseignée
- ✅ Tests : minimum 1 widget test + 1 BLoC test par feature
- ✅ Accessibilité : labels TalkBack, contrast WCAG AA, font scaling
- ✅ Performance : cold start < 5s, pas de jank > 16ms

Voir skill `/playstore-readiness` pour la checklist complète.

---

## 🧰 Skills disponibles

Workflows et audits invocables via Skill tool :

- **feature-implementation** — Workflow 6 phases (analyse → planning → i18n FIRST → DTO/Service/BLoC/GetIt/Widget/View → validation → memory-bank update)
- **bug-fix** — Workflow 4 phases pour investiguer + corriger + documenter
- **refactor-large-file** — Découpage selon les seuils (150/200/300/400)
- **add-component** — Création design-system-first d'un composant réutilisable
- **cross-platform-audit** — Audit Android/iOS/Web compatibility (workmanager, dart:io, notifications, file storage, navigation)
- **playstore-readiness** — Checklist complète Play Store (signing, App Bundle, target SDK, privacy, accessibility, perf)
- **web-readiness** — Préparation build web (go_router, responsive, PWA, dart:io retiré)
- **ios-readiness** — Préparation iOS (Info.plist, Darwin notif, signing, Cupertino)
- **release** — Bump version + génère changelog + déclenche `release_workflow.yml` via `gh workflow run` (alternative au flow PR + label)

---

## 📚 Documentation technique

- [.claude/docs/architecture-feature.md](.claude/docs/architecture-feature.md) — Structure des features
- [.claude/docs/api-contracts.md](.claude/docs/api-contracts.md) — Endpoints API consommés
- [.claude/docs/offline-architecture.md](.claude/docs/offline-architecture.md) — Pattern offline-first complet
- [.claude/docs/design-system.md](.claude/docs/design-system.md) — Tokens + composants réutilisables
- [.claude/docs/cross-platform.md](.claude/docs/cross-platform.md) — Patterns d'abstraction plateforme + blockers actuels
- [.claude/docs/deployment.md](.claude/docs/deployment.md) — Android signing, web hosting, iOS provisioning

---

## 🪝 Hooks actifs

Voir [.claude/settings.json](.claude/settings.json). Selon le fichier édité, le hook injecte automatiquement les standards adaptés :

- `lib/.../bloc/**/*.dart` → standards BLoC
- `lib/.../views/**/*.dart`, `widgets/**/*.dart`, `components/**/*.dart` → standards widgets + Material 3 + tokens
- `lib/.../services/**/*.dart` → standards services + abstraction plateforme
- `lib/**/*.dart`, `lib/l10n/**/*.arb` → règles i18n (7 langues)
- `pubspec.yaml` → vérification compat iOS/Web/Android avant ajout d'un package
- `android/**`, `ios/**`, `web/**` → règles Play Store / App Store / web manifest, garde-fou `key.properties`

---

## 🎯 En cas d'ambiguïté

- **Si tu ne comprends pas un besoin → DEMANDE avant de coder**
- **Si pattern incertain → APPLIQUE le standard BLoC + offline-first + tokens design**
- **Si nouveau package → vérifier compat Android/iOS/Web AVANT ajout**
