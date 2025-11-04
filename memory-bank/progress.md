# 📊 Progrès du projet — Manga Tracker

> Suivi de l'avancement du projet basé sur le PRD et l'état actuel du code.

---

## 🎯 Vue d'ensemble

**Version actuelle** : `0.3.0+11`  
**Dernière mise à jour** : 2024

---

## ✅ Fonctionnalités complétées

### 👤 Gestion utilisateur (70% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Connexion / Déconnexion | ✔️ **Complété** | Authentification complète avec persistance de session via JWT |
| Création / Suppression de compte | ✔️ **Complété** | Interface complète dans Profile avec confirmations |
| Changement de mot de passe | ✔️ **Complété** | Service UserService avec validation |
| Photo de profil | 🔴 **À implémenter** | Backend prêt, UI à développer |
| Onboarding (profil utilisateur) | 🔴 **À implémenter** | Collecte d'infos : âge, langue, genres favoris |
| Authentification biométrique | ✔️ **Complété** | `BiometricService` avec `local_auth` |
| Authentification Google | 🔴 **À intégrer** | Backend à configurer |
| Confirmation e-mail | ❌ **Non prévu** | Non implémenté |

**Détails techniques** :
- ✅ `AuthService` avec login/register/refresh token
- ✅ `BiometricService` pour l'authentification rapide
- ✅ `UserService` pour la gestion du profil
- ✅ Interface Profile modernisée avec Material 3
- ✅ Gestion sécurisée des tokens dans `flutter_secure_storage`

---

### 📚 Gestion de la bibliothèque (90% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Ajout / Suppression / Consultation | ✔️ **Complété** | Service complet avec UI réactive (BLoC) |
| Récupération d'un manga spécifique | ✔️ **Complété** | Via `MangaService` et `DetailBloc` |
| Filtrage du contenu mature | ✔️ **Complété** | Actif côté front |
| Traduction des champs | 🔴 **À implémenter** | Backend à configurer |
| Favoris | ❌ **Abandonné** | Fonctionnalité retirée du scope |
| Historique de recherche | 🔴 **À ajouter** | Tracking et suggestions à implémenter |

**Détails techniques** :
- ✅ `LibraryService` avec toutes les opérations CRUD
- ✅ `LibraryBloc` pour la gestion d'état réactive
- ✅ Interface `LibraryBlocView` avec indicateurs offline
- ✅ Gestion des statuts de lecture (reading, completed, on_hold, etc.)
- ✅ Sauvegarde de la progression de lecture (chapitres lus)

---

### ⭐ Système de notation et avis (20% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Collecte et affichage des avis | 🔴 **En cours** | Backend en développement |
| Notes MangaUpdates | ✔️ **Complété** | Synchronisées via API externe |
| Notes MangaTracker | 🔴 **À implémenter** | Backend à développer |
| Interface de notation avancée | 🔴 **Prévu** | Version ultérieure |

**Détails techniques** :
- ✅ Affichage des notes MangaUpdates dans les détails
- 🔴 Interface de notation à développer
- 🔴 Backend pour les notes MangaTracker à créer

---

### 📖 Suivi de lecture (85% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Enregistrement de la progression | ✔️ **Complété** | Sauvegarde du nombre de chapitres lus |
| Statut de lecture (en cours, terminé, etc.) | ✔️ **Complété** | Enum `ReadingStatus` avec tous les statuts |
| Reprise automatique | ✔️ **Complété**  | Dernier chapitre lu à afficher |
| Regroupement par tome ou arc | 🔴 **En étude** | Complexité de l'API MangaUpdates |
| Mise à jour instantanée | 🔴 **Prévu** | WebSocket ou polling à implémenter |

**Détails techniques** :
- ✅ `DetailBloc` avec gestion de la progression
- ✅ Sauvegarde automatique lors de la lecture
- ✅ Mise à jour du statut automatique (reading → completed)
- ✅ Interface de sélection de chapitres dans `DetailBlocView`
- 🔴 Indicateur "Dernier chapitre lu" à ajouter

---

### 🌐 Mode hors ligne (95% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Cache des données | ✔️ **Complété** | Bibliothèque, détails, page d'accueil, recherche |
| Queue d'actions offline | ✔️ **Complété** | Toutes les actions sont mises en file d'attente |
| Synchronisation automatique | ✔️ **Complété** | `SyncService` avec retry automatique |
| Indicateurs visuels | ✔️ **Complété** | Badges orange avec nombre d'actions en attente |
| Cache d'images | ✔️ **Complété** | `cached_network_image` avec `sqflite` |

**Détails techniques** :
- ✅ `OfflineCacheService` pour le cache des données
- ✅ `CacheHelperService` avec fallback automatique
- ✅ `SyncService` pour la synchronisation à la reconnexion
- ✅ Détection du mode offline basée sur les erreurs réseau
- ✅ Gestion des échecs avec retry automatique
- ✅ Cache d'images avec `cached_network_image`

---

### 🎨 Frontend et UX (80% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Vue de connexion | ✔️ **Complété** | `LoginView` avec validation |
| Page compte utilisateur | ✔️ **Complété** | `Profile` modernisée avec Material 3 |
| Page détail manga | ✔️ **Complété** | `DetailBlocView` avec toutes les fonctionnalités |
| Page tendances/nouveautés | ✔️ **Complété** | `HomePageBlocView` avec filtres |
| Barre de navigation | ✔️ **Complété** | `BottomNavbar` avec PageView |
| Thème sombre | 🔴 **À finaliser** | Code préparé, à activer |
| Recherche de mangas | ✔️ **Complété** | `Search` avec résultats |
| Calendrier des sorties | 🔴 **À concevoir** | Backend à développer |
| Affichage des scores LightFM | 🔴 **En attente** | Intégration modèle ML |

**Détails techniques** :
- ✅ Architecture BLoC pour toutes les pages principales
- ✅ Composants réutilisables (ProfileOptionTile, ProfileSection, etc.)
- ✅ Thème Material 3 partiellement implémenté
- ✅ Storybook (Dashbook) pour la documentation des composants
- 🔴 Thème sombre à activer
- 🔴 Internationalisation à finaliser

---

### 🧰 CI/CD et qualité (60% complété)

| Fonctionnalité | Statut | Détails |
|----------------|--------|---------|
| Linter + Formatter automatique | 🔴 **À configurer** | GitHub Actions à créer |
| Déploiement APK automatisé | 🔴 **À configurer** | GitHub Actions à créer |
| Gestion des versions auto | 🔴 **À configurer** | Scripts à créer |
| Publication GitHub Release + changelog | 🔴 **À configurer** | GitHub Actions à créer |
| Tests automatisés | 🔴 **En cours** | Structure prête, tests à écrire |

**Détails techniques** :
- ✅ `flutter_lints` configuré
- ✅ `analysis_options.yaml` avec règles de linting
- ✅ Structure de tests prête (`test/`)
- 🔴 GitHub Actions workflows à créer
- 🔴 Scripts de versioning automatique à développer

---

## 🔴 Fonctionnalités en cours / à venir

### 🔔 Alertes de nouvelles sorties
- **Statut** : 🔴 Backend partiellement prêt
- **À faire** : 
  - Intégration des notifications push (`firebase_messaging`)
  - Filtres avancés de notifications
  - Actualisation automatique (cron + cache)

### 🤖 Recommandations personnalisées
- **Statut** : 🔴 Modèle LightFM en cours d'intégration
- **À faire** :
  - Intégration du service ML
  - Affichage des recommandations dans l'UI
  - Cache des scores de recommandation
  - Option "Ignorer un manga recommandé"

### 💬 Espace communautaire
- **Statut** : 🔴 À concevoir
- **À faire** :
  - Forum et discussions
  - Partage de théories
  - Mini-jeux communautaires
  - Chat en temps réel (Socket.io ou Firebase)
  - Voir la bibliothèque d'amis

### 📊 Statistiques
- **Statut** : 🔴 En préparation
- **À faire** :
  - Total de chapitres lus
  - Estimation du temps de lecture
  - Top genres les plus consultés
  - Streak de lecture (gamification)
  - Progression vers objectif personnel

### 🔗 Redirection vers plateformes
- **Statut** : 🔴 En cours
- **À faire** :
  - Liens vers sites légaux (partiellement fait)
  - Page WebView (partiellement fait)
  - Mise à jour automatique des liens (backend)

---

## 📈 Statistiques de progression

### Par catégorie

| Catégorie | Complété | En cours | À faire | Total |
|-----------|----------|----------|---------|-------|
| **Gestion utilisateur** | 4 | 0 | 3 | 7 |
| **Gestion bibliothèque** | 4 | 0 | 1 | 5 |
| **Notation et avis** | 1 | 1 | 2 | 4 |
| **Suivi de lecture** | 2 | 0 | 3 | 5 |
| **Mode hors ligne** | 5 | 0 | 0 | 5 |
| **Frontend/UX** | 7 | 0 | 2 | 9 |
| **CI/CD** | 0 | 1 | 4 | 5 |
| **Total** | **23** | **2** | **15** | **40** |

### Progression globale

**≈ 58% complété** (23/40 fonctionnalités principales)

---

## 🎯 Prochaines étapes prioritaires

### Version 0.4.0 (Court terme)

1. **Finaliser le mode offline**
   - ✅ Cache des données (fait)
   - ✅ Synchronisation (fait)
   - 🔴 Tests d'intégration offline

2. **Moderniser l'UI**
   - ✅ Page Profile (fait)
   - 🔴 Activer le thème sombre
   - 🔴 Améliorer les animations

3. **CI/CD**
   - 🔴 Créer les workflows GitHub Actions
   - 🔴 Automatiser le build APK
   - 🔴 Automatiser le versioning

### Version 0.5.0 (Moyen terme)

1. **Onboarding utilisateur**
   - Collecte d'informations (âge, langue, genres)
   - Personnalisation des recommandations

2. **Intégration Google Auth**
   - Configuration backend
   - Intégration frontend

3. **Statistiques utilisateur**
   - Dashboard de statistiques
   - Top genres, temps de lecture, etc.

### Version 0.6.0+ (Long terme)

1. **Recommandations LightFM**
   - Intégration du service ML
   - Affichage dans l'UI
   - Cache des scores

2. **Alertes de nouvelles sorties**
   - Notifications push
   - Filtres personnalisés

3. **Espace communautaire**
   - Forum et discussions
   - Partage de théories
   - Mini-jeux

---

## 🐛 Bugs connus et améliorations

### Bugs résolus récemment

- ✅ Correction de la gestion du `readChaptersCount` lors de la suppression de la bibliothèque
- ✅ Correction de la détection du mode offline (basée sur les erreurs réseau)
- ✅ Correction des race conditions avec `DetailBloc` (factory au lieu de singleton)
- ✅ Correction de la perte silencieuse des actions offline (gestion des échecs)

### Améliorations techniques récentes

- ✅ Refactorisation du mode offline avec détection intelligente
- ✅ Modernisation de la page Profile avec composants réutilisables
- ✅ Intégration du changelog dans le profil
- ✅ Optimisation du cache avec `cached_network_image`

---

## 📝 Notes importantes

### Architecture

- **BLoC Pattern** : Bien implémenté avec séparation claire des responsabilités
- **Offline-First** : Architecture robuste avec queue d'actions et synchronisation automatique
- **Service Locator** : GetIt bien configuré avec gestion des dépendances asynchrones

### Performance

- **Cache intelligent** : Expiration après 24h, nettoyage automatique
- **Lazy loading** : BLoCs en lazy singleton pour économiser la mémoire
- **Images** : Cache automatique avec `cached_network_image`

### Sécurité

- **Tokens JWT** : Stockage sécurisé dans `flutter_secure_storage`
- **Refresh automatique** : Gestion transparente des tokens expirés
- **Biométrie** : Authentification rapide sécurisée

---

## 🚀 Objectifs à long terme

1. **MVP complet** : Toutes les fonctionnalités de base opérationnelles
2. **Recommandations ML** : Système de recommandations personnalisées fonctionnel
3. **Communauté** : Espace social et échanges entre utilisateurs
4. **Performance** : Optimisation pour supporter des milliers de mangas
5. **Internationalisation** : Support multi-langues (FR/EN au minimum)

---

**Dernière mise à jour** : 04/11/2025

