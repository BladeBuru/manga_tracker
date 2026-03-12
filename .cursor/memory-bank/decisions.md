# Décisions Architecturales — Manga Tracker Flutter

**Dernière mise à jour :** Mars 2026

---

## Décisions Prises

### State management : BLoC (flutter_bloc)
**Décision** : BLoC pattern avec `flutter_bloc` et `Equatable`
**Raison** : Architecture réactive et testable, séparation claire UI/logique métier, flux unidirectionnel prévisible (Event → BLoC → State)
**Impact** : Un BLoC par feature, events et states avec `Equatable`, BLoCs exposés via `BlocProvider`
**Date** : Conception initiale

---

### Injection de dépendances : GetIt (Service Locator)
**Décision** : GetIt comme service locator central
**Raison** : Simple, performant, supporte les singletons, lazy singletons, factories et l'initialisation asynchrone avec dépendances
**Impact** : `service_locator.dart` centralise tout, ordre d'initialisation documenté, pas de `BuildContext` nécessaire pour accéder aux services
**Date** : Conception initiale

---

### DetailBloc en Factory (CRITIQUE)
**Décision** : `DetailBloc` enregistré en **factory** dans GetIt, pas en lazy singleton
**Raison** : Chaque page de détails doit avoir sa propre instance pour éviter les race conditions (navigation rapide entre pages)
**Impact** : `getIt<DetailBloc>()` crée une nouvelle instance à chaque appel — toujours wrapper dans un `BlocProvider` lors de la navigation
**Date** : 2025-11 (correction de bug)

---

### Cache offline : SharedPreferences + JSON (pas Hive)
**Décision** : Utiliser `flutter_secure_storage` et `shared_preferences` pour le cache offline, pas Hive
**Raison** : Simplicité, pas de dépendance supplémentaire, les données cachées sont en JSON et ne nécessitent pas une vraie BDD locale
**Impact** : `OfflineCacheService` sérialise/désérialise en JSON, clés de cache nommées explicitement
**Date** : Conception initiale

---

### Détection offline : erreurs réseau (pas ConnectivityService)
**Décision** : Détecter le mode offline via les `SocketException` sur les appels HTTP, pas via `ConnectivityService`
**Raison** : `ConnectivityService` peut indiquer "connecté" (WiFi) sans accès internet réel → faux négatifs fréquents
**Impact** : Les BLoCs catchent `SocketException` et passent en mode offline, `ConnectivityService` est utilisé uniquement pour détecter la reconnexion (pour déclencher la synchronisation)
**Date** : 2025-11 (correction de bug)

---

### Internationalisation : flutter_localizations + ARB (7 langues)
**Décision** : i18n native Flutter avec fichiers ARB, 7 langues supportées (FR, EN, DE, JA, KO, PT, ES)
**Raison** : Standard Flutter officiel, intégration native, génération de code automatique, pas de dépendance externe
**Impact** : Tous les textes visibles dans les fichiers ARB, `LanguageService` pour la persistance, changement de langue sans redémarrage
**Date** : Conception initiale

---

### Navigation : MaterialPageRoute (migration go_router prévue)
**Décision** : Navigation impérative avec `Navigator` et `MaterialPageRoute` actuellement
**Raison** : Simplicité initiale, go_router non nécessaire pour le MVP
**Impact** : Migration vers `go_router` prévue en v0.4 — ne pas implémenter de deep linking ou navigation complexe sans go_router
**Date** : Conception initiale

---

### Thème : Material 3 (sombre prévu)
**Décision** : Material 3 avec thème clair actif, sombre commenté
**Raison** : Standard moderne Flutter, composants natifs, système de design tokens cohérent
**Impact** : Utiliser exclusivement `Theme.of(context).colorScheme.*` et `AppRadius` — jamais hardcoder couleurs ou dimensions
**Date** : Conception initiale

---

### HTTP client : `http` package (pas Dio)
**Décision** : Package `http` standard, encapsulé dans `HttpService`
**Raison** : Simplicité, moins de dépendances, `Dio` disponible mais non utilisé
**Impact** : Tout accès réseau passe par `HttpService` — jamais `http.Client` directement dans les services ou BLoCs
**Date** : Conception initiale

---

## Décisions Futures à Prendre

| Sujet | Contexte | Deadline | Options |
|-------|----------|----------|---------|
| Navigation go_router | Deep linking, navigation déclarative | v0.4 | go_router uniquement |
| Thème sombre | Code déjà préparé dans AppTheme | v0.4 | Activer + tester sur toutes les vues |
| Tests | Structure prête, tests à écrire | v0.4 | Commencer par les BLoCs critiques |
| Notifications push | Alertes nouvelles sorties | v0.5 | `firebase_messaging` déjà en dépendance |
| Stockage offline avancé | Si cache JSON insuffisant | v0.5 | Hive vs Isar vs SQLite via Drift |

---

## Alternatives Considérées

| Décision | Alternative rejetée | Raison du rejet |
|----------|-------------------|-----------------|
| BLoC | Provider / Riverpod / GetX | BLoC plus structuré, meilleure séparation UI/logique, plus testable |
| GetIt | Injectable / Riverpod DI | GetIt plus simple, pas de code generation, suffisant pour ce projet |
| SharedPreferences | Hive / Isar | Complexité inutile pour le cache JSON actuel |
| `http` | Dio | Simplicité, Dio disponible si besoin de fonctionnalités avancées |
| ARB natif | `easy_localization` / `get` i18n | Standard officiel Flutter, pas de dépendance supplémentaire |
