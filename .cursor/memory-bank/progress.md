# Progrès — Manga Tracker Flutter

**Version actuelle** : `0.3.0+11` — **Dernière mise à jour** : Mars 2026

---

## ✅ Complété

### Authentification
- ✅ Login / Logout avec persistance de session JWT
- ✅ Register + suppression de compte
- ✅ Changement de mot de passe
- ✅ Authentification biométrique (`BiometricService` + `local_auth`)
- ✅ Refresh automatique des tokens (via `HttpService`)

### Bibliothèque
- ✅ Ajout / Suppression / Consultation (CRUD complet)
- ✅ Filtrage du contenu mature
- ✅ Statuts de lecture (`ReadingStatus`)
- ✅ Progression par chapitres (`readChaptersCount`)
- ✅ Mode offline complet (cache + queue + sync)

### Mangas
- ✅ Page d'accueil (tendances, nouveautés, populaires) — `HomePageBloc`
- ✅ Page de détails — `DetailBloc` (factory)
- ✅ Affichage genres avec Chip Material 3 (Wrap)
- ✅ Recherche de mangas

### Profil
- ✅ Page Profile modernisée (Material 3, composants réutilisables)
- ✅ Changement de mot de passe
- ✅ Suppression de compte
- ✅ Cache infos utilisateur (7 jours, mise à jour en arrière-plan)
- ✅ Changelog intégré

### Infrastructure
- ✅ Architecture BLoC complète (HomePageBloc, LibraryBloc, DetailBloc, ConnectivityBloc)
- ✅ Mode offline-first (OfflineCacheService, CacheHelperService, SyncService)
- ✅ Internationalisation 7 langues (FR, EN, DE, JA, KO, PT, ES)
- ✅ Sélecteur de langue dans le profil
- ✅ Composants réutilisables dans `core/components/`
- ✅ `AppRadius` pour la cohérence des arrondis

---

## 🔴 À faire

### Court terme (v0.4.0)
- 🔴 Activer le thème sombre (code préparé dans `AppTheme`)
- 🔴 Migration vers `go_router`
- 🔴 Écrire les tests BLoC (structure prête)
- 🔴 GitHub Actions CI/CD (lint, build APK, release)
- 🔴 Photo de profil (backend prêt)
- 🔴 Proxy images MangaUpdates (endpoint CORS côté API)

### Moyen terme (v0.5.0)
- 🔴 Onboarding utilisateur (âge, langue, genres favoris)
- 🔴 Google OAuth2
- 🔴 Statistiques utilisateur (chapitres lus, streak, top genres)
- 🔴 Historique de recherche

### Long terme (v0.6.0+)
- 🔴 Recommandations LightFM
- 🔴 Alertes nouvelles sorties (Firebase Messaging)
- 🔴 Espace communautaire (forum, discussions)
- 🔴 Calendrier des sorties

---

## 🐛 Bugs résolus (résumé)

- ✅ Race conditions `DetailBloc` → factory dans GetIt
- ✅ Faux positifs offline → détection via `SocketException`
- ✅ Perte actions offline → gestion échecs `SyncService`
- ✅ `readChaptersCount` incorrect après suppression → reset explicite

> Voir `.cursor/memory-bank/known-issues.md` pour le détail complet.

---

## 📈 Progression globale

**≈ 58% du MVP** (23/40 fonctionnalités principales)

> Voir `memory-bank/product-requirements-document.md` pour le tableau complet.
