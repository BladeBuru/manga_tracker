# Progrès — Manga Tracker Flutter

**Version actuelle** : `0.8.0+17` — **Dernière mise à jour** : Mai 2026

---

## ✅ Complété

### Authentification
- ✅ Login / Logout avec persistance JWT
- ✅ Register + suppression de compte
- ✅ Changement de mot de passe
- ✅ Authentification biométrique (`BiometricService` + `local_auth`)
- ✅ Refresh automatique des tokens (via `HttpService`)

### Bibliothèque
- ✅ Add / Remove / Get (CRUD complet)
- ✅ Filtrage du contenu mature
- ✅ Statuts de lecture (`ReadingStatus`)
- ✅ Progression par chapitres (`readChaptersCount`)
- ✅ Mode offline complet (cache + queue + sync)

### Mangas
- ✅ Page d'accueil — `HomePageBloc`
- ✅ Page de détails — `DetailBloc` (factory)
- ✅ Affichage genres avec Chip Material 3 (Wrap)
- ✅ Recherche

### Profil
- ✅ Page Profile modernisée (Material 3, composants réutilisables)
- ✅ Changement de mot de passe
- ✅ Suppression de compte
- ✅ Cache infos utilisateur (7 jours, mise à jour en arrière-plan)
- ✅ Changelog intégré

### Infrastructure
- ✅ Architecture BLoC complète
- ✅ Mode offline-first (OfflineCacheService, CacheHelperService, SyncService)
- ✅ i18n 7 langues (FR, EN, DE, JA, KO, PT, ES)
- ✅ Sélecteur de langue dans le profil
- ✅ Composants réutilisables dans `core/components/` (8 composants)
- ✅ `AppRadius` pour la cohérence des arrondis
- ✅ CI/CD GitHub Actions (`release_workflow.yml`) — APK Android + GitHub Releases

---

## 🔴 À faire

### 🔒 Sécurité (PRIORITÉ HAUTE — voir known-issues.md)
- 🔴 **Retirer `key.properties` du repo** + rotation du mot de passe keystore
- 🔴 Ajouter `android/key.properties`, `*.jks` au `.gitignore`

### 🌐 Cross-platform (évolution iOS/Web — PRIORITÉ HAUTE)
- 🔴 Audit complet via skill `/cross-platform-audit`
- 🔴 Abstraire `workmanager` derrière `BackgroundTaskService` (impl Android/iOS/Web)
- 🔴 Abstraire `notification_service.dart` avec Darwin fallback iOS
- 🔴 Retirer / abstraire `dart:io` direct dans `lib/`
- 🔴 Migration vers `go_router` (obligatoire avant build web)

### 📱 Play Store quality (évolution)
- 🔴 Build **App Bundle** (`.aab`) en plus de l'APK dans la CI
- 🔴 Upload Play Console automatisé (alpha / beta / prod)
- 🔴 Vérifier `targetSdkVersion` ≥ 34
- 🔴 ProGuard / R8 activés en release
- 🔴 Privacy policy URL
- 🔴 Tests : 1 widget + 1 BLoC test par feature minimum
- 🔴 Audit accessibilité (`Semantics`, contraste, TalkBack)

### 🎨 Design system (évolution)
- 🔴 Créer `lib/core/theme/app_spacing.dart`
- 🔴 Promouvoir `MangaCard`, `MangaRow`, `OfflineBanner`, `LoadingSkeleton`, `EmptyState`, `ErrorState` vers `core/components/`
- 🔴 Migration progressive `EdgeInsets.all(16)` → `AppSpacing.m`

### Court terme (v0.4.0)
- 🔴 Activer le thème sombre (code préparé dans `AppTheme`)
- 🔴 Migration vers `go_router`
- 🔴 Écrire les tests BLoC
- 🔴 GitHub Actions : lint + tests + build App Bundle
- 🔴 Photo de profil (backend prêt)
- 🔴 Proxy images MangaUpdates (endpoint CORS côté API)

### Moyen terme (v0.5.0)
- 🔴 Onboarding utilisateur (âge, langue, genres favoris)
- 🔴 Google OAuth2
- 🔴 Statistiques utilisateur (chapitres lus, streak, top genres)
- 🔴 Historique de recherche
- 🔴 **iOS readiness** (skill `/ios-readiness`)
- 🔴 **Web readiness** (skill `/web-readiness`)

### Long terme (v0.6.0+)
- 🔴 Recommandations LightFM
- 🔴 Alertes nouvelles sorties (Firebase Messaging multi-plateforme)
- 🔴 Espace communautaire
- 🔴 Calendrier des sorties
- 🔴 Privacy Manifest iOS (exigence iOS 17+)

---

## 🐛 Bugs résolus (résumé)

- ✅ Race conditions `DetailBloc` → factory dans GetIt
- ✅ Faux positifs offline → détection via `SocketException`
- ✅ Perte actions offline → gestion échecs `SyncService`
- ✅ `readChaptersCount` incorrect après suppression → reset explicite

> Voir `.claude/memory-bank/known-issues.md` pour le détail (et 7 problèmes actifs détectés à l'audit cross-platform de mai 2026).

---

## 📈 Progression globale

**≈ 58% du MVP** (23/40 fonctionnalités principales).

Prochaines priorités :
1. Sécurité (retirer `key.properties`)
2. Cross-platform (abstractions pour iOS/Web)
3. Design system (AppSpacing + composants promus)
4. Tests (couverture BLoC + widget)
5. Play Store quality (App Bundle + accessibilité)
