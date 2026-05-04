# Décisions Architecturales — Manga Tracker Flutter

**Dernière mise à jour :** Mai 2026

---

## Décisions Prises

### State management : BLoC (flutter_bloc)
**Décision** : BLoC pattern avec `flutter_bloc` et `Equatable`.
**Raison** : Architecture réactive et testable, séparation claire UI/logique métier, flux unidirectionnel prévisible (Event → BLoC → State).
**Impact** : Un BLoC par feature, events et states avec `Equatable`, BLoCs exposés via `BlocProvider`.
**Date** : Conception initiale

---

### Injection de dépendances : GetIt (Service Locator)
**Décision** : GetIt comme service locator central.
**Raison** : Simple, performant, supporte singletons, lazy singletons, factories et init asynchrone.
**Impact** : `service_locator.dart` centralise tout, ordre d'init documenté, pas de `BuildContext` nécessaire pour accéder aux services.
**Date** : Conception initiale

---

### DetailBloc en Factory (CRITIQUE)
**Décision** : `DetailBloc` enregistré en **factory** dans GetIt.
**Raison** : Chaque page de détails doit avoir sa propre instance pour éviter les race conditions (navigation rapide entre pages).
**Impact** : `getIt<DetailBloc>()` crée une nouvelle instance — toujours wrapper dans un `BlocProvider` lors de la navigation.
**Date** : 2025-11 (correction de bug)

---

### Cache offline : SharedPreferences + JSON (pas Hive)
**Décision** : `flutter_secure_storage` + `shared_preferences` pour le cache offline.
**Raison** : Simplicité, pas de dépendance supplémentaire, données en JSON.
**Impact** : `OfflineCacheService` sérialise/désérialise en JSON.
**Date** : Conception initiale

---

### Détection offline : `SocketException` (pas ConnectivityService)
**Décision** : Détecter le mode offline via les `SocketException` sur les appels HTTP.
**Raison** : `ConnectivityService` peut indiquer "connecté" (WiFi) sans accès internet → faux négatifs.
**Impact** : Les BLoCs catchent `SocketException`. `ConnectivityService` utilisé uniquement pour la reconnexion (sync).
**Date** : 2025-11 (correction de bug)

---

### Internationalisation : ARB natif (7 langues)
**Décision** : i18n native Flutter avec ARB, 7 langues (FR, EN, DE, JA, KO, PT, ES).
**Raison** : Standard Flutter officiel, intégration native, génération auto.
**Impact** : Tous les textes visibles dans les ARB, `LanguageService` pour la persistance.
**Date** : Conception initiale

---

### Navigation : MaterialPageRoute (migration go_router prévue)
**Décision** : Navigation impérative avec `Navigator` + `MaterialPageRoute`.
**Raison** : Simplicité initiale, go_router non nécessaire pour le MVP Android.
**Impact** : Migration vers `go_router` **obligatoire avant le build web** (deep-linking). Prévu v0.4.
**Date** : Conception initiale

---

### Thème : Material 3 (sombre prévu)
**Décision** : Material 3 avec thème clair actif, sombre commenté.
**Raison** : Standard moderne, design tokens cohérents.
**Impact** : Utiliser `Theme.of(context).colorScheme.*` et `AppRadius` exclusivement.
**Date** : Conception initiale

---

### HTTP client : `http` package (pas Dio)
**Décision** : Package `http` standard, encapsulé dans `HttpService`.
**Raison** : Simplicité, moins de dépendances.
**Impact** : Tout accès réseau via `HttpService`.
**Date** : Conception initiale

---

### 🆕 Platform-agnostic par défaut (évolution)
**Décision** : Tout nouveau code doit fonctionner sur Android, iOS et Web sauf justification documentée.
**Raison** : L'app cible Android (actuel), iOS et Web (à venir). Ajouter des dépendances Android-only sans abstraction crée une dette techniquement coûteuse à rembourser plus tard.
**Impact** :
- Toute API native (notif, background task, file pick) doit être derrière une interface dans `core/services/` avec impl conditionnelle.
- `dart:io` direct interdit dans `lib/` — utiliser `path_provider` ou abstraire.
- `Platform.isAndroid` jamais dispersé — encapsulé dans le service_locator ou un service abstrait.
- Nouveaux packages : vérifier compat iOS/Web AVANT ajout à `pubspec.yaml`.
**Date** : 2026-05 (évolution multi-plateformes)

---

### 🆕 Play Store quality non-négociable (évolution)
**Décision** : L'app doit passer la review Play Store sans ajustement de dernière minute.
**Raison** : Qualité requise pour la distribution publique. Évite les rejections en cascade.
**Impact** :
- `key.properties` et `*.jks` toujours dans `.gitignore`.
- Build App Bundle (`.aab`) pour les releases Play Store.
- `targetSdkVersion` ≥ 34, ProGuard/R8 actif en release.
- Permissions Android justifiées dans le manifest.
- Privacy policy URL renseignée.
- Tests : minimum 1 widget test + 1 BLoC test par feature.
- Accessibilité : labels TalkBack, contraste WCAG AA, font scaling.
**Date** : 2026-05 (évolution qualité)

---

### 🆕 Design system mature (évolution)
**Décision** : Étendre les tokens du design system + promouvoir les composants réutilisables.
**Raison** : Aujourd'hui les paddings sont hardcodés, certains composants sont dupliqués entre features. Pour iOS/Web et la qualité Play Store, le design system doit être robuste.
**Impact** :
- Créer `lib/core/theme/app_spacing.dart` (tokens xs/s/m/l/xl/jumbo).
- Promouvoir `MangaCard`, `MangaRow`, `OfflineBanner`, `LoadingSkeleton`, `EmptyState`, `ErrorState` vers `core/components/`.
- Skill `/add-component` à utiliser pour la création.
**Date** : 2026-05 (évolution design)

---

## Décisions Futures à Prendre

| Sujet | Contexte | Deadline | Options |
|-------|----------|----------|---------|
| Navigation go_router | Deep linking, navigation déclarative — bloque le web | v0.4 | go_router uniquement |
| Thème sombre | Code déjà préparé | v0.4 | Activer + tester sur toutes les vues |
| Tests | Structure prête | v0.4 | Commencer par les BLoCs critiques |
| Notifications push | Alertes nouvelles sorties | v0.5 | `firebase_messaging` (multi-plateformes) |
| Stockage offline avancé | Si cache JSON insuffisant | v0.5 | Hive vs Isar vs Drift |
| iOS adaptive UI | Material vs Cupertino adaptive | Avant App Store | A : Material partout (simple) / B : Adaptive (UX iOS native) |
| Background tasks iOS | Remplacer workmanager | Avant App Store | BGTaskScheduler via plugin custom ou plugin existant |

---

## Alternatives Considérées

| Décision | Alternative rejetée | Raison du rejet |
|----------|-------------------|-----------------|
| BLoC | Provider / Riverpod / GetX | BLoC plus structuré, meilleure séparation, plus testable |
| GetIt | Injectable / Riverpod DI | GetIt plus simple, pas de code generation |
| SharedPreferences | Hive / Isar | Complexité inutile pour le cache JSON actuel |
| `http` | Dio | Simplicité ; Dio dispo si besoin de fonctionnalités avancées |
| ARB natif | `easy_localization` / `get` i18n | Standard officiel Flutter |
