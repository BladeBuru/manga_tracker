# 📘 Product Requirements Document — Manga Tracker

## 🧭 Vision du produit
**Manga Tracker** est une application tout-en-un dédiée aux passionnés de mangas.  
Elle permet de **suivre ses lectures**, **découvrir de nouveaux titres**, **recevoir des alertes de sorties**, et **échanger avec la communauté**.  
L’objectif est d’offrir une expérience fluide, intelligente et personnalisée tout en redirigeant vers des plateformes de lecture légales.

---

## 🎯 Objectifs principaux
- Simplifier le **suivi de lecture** des mangas.
- Offrir des **recommandations personnalisées** basées sur les goûts et les habitudes de lecture.
- Permettre la **découverte communautaire** via un espace social et des mini-jeux.
- Garantir la **transparence** et la **conformité légale** (CNIL, API externes).
- Maintenir une **expérience performante et fluide** sur mobile et web.

---

## 🧩 Fonctionnalités principales

### 👤 Gestion utilisateur
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Connexion / Déconnexion | ✔️ | Authentification interne complète, avec persistance de session |
| Création / Suppression de compte | ✔️ | Gestion complète des comptes utilisateurs |
| Changement de mot de passe | ✔️ | Système sécurisé avec récupération d’identifiants |
| Photo de profil | 🔴 | À implémenter côté front |
| Onboarding (profil utilisateur) | 🔴 | Collecte d’informations : âge, langue, genres favoris, sexe |
| Authentification biométrique | ✔️ | Fonctionnelle |
| Authentification Google | 🔴 | À intégrer côté API |
| Confirmation e-mail | ❌ | Non implémentée |

---

### 📚 Gestion de la bibliothèque
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Ajout / Suppression / Consultation | ✔️ | Service complet de gestion de bibliothèque |
| Récupération d’un manga spécifique | ✔️ | Accessible via API |
| Filtrage du contenu mature | ✔️ | Actif côté front |
| Traduction des champs (titre, description) | 🔴 | En attente d’intégration |
| Favoris | ❌ | Fonctionnalité abandonnée |
| Historique de recherche | 🔴 | À ajouter (tracking et suggestions) |

---

### ⭐ Système de notation et avis
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Collecte et affichage des avis | 🔴 | En cours |
| Notes MangaUpdates | ✔️ | Synchronisées via API externe |
| Notes MangaTracker | 🔴 | À implémenter côté back |
| Interface de notation avancée | 🔴 | Prévue pour version ultérieure |

---

### 📖 Suivi de lecture
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Enregistrement de la progression | ✔️ | Enregistre l’état de lecture par manga |
| Statut de lecture (en cours, terminé, etc.) | ✔️ | Fonctionnel |
| Reprise automatique | 🔴 | À implémenter |
| Regroupement par tome ou arc | 🔴 | En étude |
| Mise à jour instantanée | 🔴 | Amélioration prévue via websocket ou polling |

---

### 📊 Statistiques
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Total de chapitres lus | 🔴 | En préparation |
| Estimation du temps de lecture | 🔴 | Calcul dynamique |
| Top genres les plus consultés | 🔴 | Basé sur historique de lecture |
| Streak de lecture | 🔴 | Fonctionnalité gamifiée |
| Progression vers objectif personnel | 🔴 | À concevoir |

---

### 🤖 Recommandations personnalisées
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Suggestions basées sur l’historique | 🔴 | Modèle LightFM en cours d’intégration |
| Modèle hybride (notes + tags + genres) | 🔴 | Côté ML |
| Ignorer un manga recommandé | 🔴 | À ajouter dans l’interface |

---

### 💬 Espace communautaire
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Forum et discussions | 🔴 | À implémenter |
| Partage de théories | 🔴 | Prévu |
| Mini-jeux communautaires | 🔴 | Exemple : “Manga du mois” |
| Chat en temps réel | 🔴 | Envisagé (Socket.io ou Firebase) |
| Voir la bibliothèque d’amis | 🔴 | À concevoir (requête API sociale) |

---

### 🔗 Redirection vers plateformes
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Liens vers sites légaux | 🔴 | En cours |
| Page WebView | 🔴 | Front partiellement prêt |
| Mise à jour automatique des liens | 🔴 | À automatiser côté backend |

---

### 🔔 Alertes de nouvelles sorties
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Notifications de nouveaux chapitres/volumes | 🔴 | Backend partiellement prêt |
| Filtres avancés de notifications | 🔴 | Planifié |
| Actualisation automatique | 🔴 | À implémenter (cron + cache) |

---

### 🧱 Sécurité et conformité
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Protection des endpoints | ✔️ | JWT / AuthGuard en place |
| Endpoint proxy pour images MangaUpdates | 🔴 | À implémenter |
| Audit CNIL et transparence API | 🔴 | Préparation en cours |

---

### ⚡ Optimisation et performances
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Système de cache (Redis) | 🔴 | En développement |
| Cache des scores de recommandation | 🔴 | Planifié |
| Indexation BDD (muID) | 🔴 | À mettre en place |
| Actualisation périodique | 🔴 | Tous les 6–24h selon source |

---

### 🧩 Fonctionnalités complémentaires
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Noms de mangas dans plusieurs langues | 🔴 | À ajouter |
| Tri de la liste (date, alphabétique) | 🔴 | À implémenter |
| Autocomplétion de recherche | 🔴 | À ajouter |
| Traduction anglais/français | 🔴 | Étude de faisabilité |
| Lecture directe du manga | ❌ | Fonctionnalité abandonnée |

---

### 🧰 CI/CD et qualité
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Linter + Formatter automatique | 🔴 | `flutter_lints` configuré, GitHub Actions à créer |
| Déploiement APK automatisé | 🔴 | GitHub Actions à configurer |
| Gestion des versions auto (`pubspec.yaml`) | 🔴 | Scripts à développer |
| Publication GitHub Release + changelog | 🔴 | GitHub Actions à créer |
| Tests automatisés | 🔴 | Structure prête, tests à écrire |

---

### ☁️ Infrastructure et environnement
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Swagger API | ✔️ | Documente tous les endpoints |
| Base de données dev | ✔️ | Connectée et fonctionnelle |
| Environnement d’intégration Docker | ✔️ | Déployé |
| Environnement ML (LightFM) | 🔴 | À héberger (Docker GPU/CPU) |
| Stockage et versioning modèles | 🔴 | À gérer via MLflow ou DVC |

---

### 🎨 Frontend et UX
| Fonctionnalité | Statut | Description |
|----------------|---------|-------------|
| Vue de connexion | ✔️ | Terminée avec validation |
| Page compte utilisateur | ✔️ | Modernisée avec Material 3, composants réutilisables, changelog intégré |
| Page détail manga | ✔️ | Terminée avec BLoC, mode offline, gestion complète |
| Page tendances/nouveautés | ✔️ | Implémentée avec HomePageBloc, filtres, cache offline |
| Barre de navigation | ✔️ | Stable avec BottomNavigationBar et PageView |
| Thème sombre | 🔴 | Code préparé, à activer |
| Recherche de mangas | ✔️ | Fonctionnelle avec cache offline |
| Calendrier des sorties | 🔴 | À concevoir |
| Affichage des scores LightFM | 🔴 | En attente d'intégration modèle |

---

## 🧱 Architecture générale (résumé)
- **Frontend Flutter**
    - Architecture : Feature-based avec pattern BLoC
    - Pages : Auth, Bibliothèque, Détails, Tendances, Profil, Recherche
    - Thème : Material 3 (clair actif, sombre prévu)
    - Mode offline : Cache automatique, queue d'actions, synchronisation
    - Navigation : BottomNavigationBar avec PageView
- **Backend Node/Express ou NestJS**
    - Authentification JWT, Bibliothèque, Statistiques, Recommandations
    - API REST avec Swagger
- **Base de données**
    - PostgreSQL (backend)
    - SQLite via sqflite (cache d'images Flutter)
- **Machine Learning**
    - LightFM (modèle de recommandation hybride) - prévu
    - Service Python/FastAPI - prévu
- **CI/CD**
    - GitHub Actions : À configurer (linter, build, versioning, release)
    - Structure prête, workflows à créer
- **Infra**
    - Docker (services backend et ML) - prévu
    - Swagger pour documentation API

---

## 🗺️ MVP actuel
Fonctionnalités prêtes (✔️) :
- Authentification complète (JWT, biométrie)
- Gestion de bibliothèque (CRUD complet, mode offline)
- Suivi de lecture (progression, statuts)
- Pages principales du front (Auth, Home, Library, Detail, Profile, Search)
- Mode offline complet (cache, queue, synchronisation)
- Architecture BLoC réactive et testable

Fonctionnalités en cours / à venir :
- Onboarding avancé
- Recommandations personnalisées (LightFM)
- Espace communautaire
- Alertes de nouvelles sorties
- CI/CD automatisé (GitHub Actions à créer)

---

## 🧭 Priorités prochaines versions
1. Intégrer Google Auth et onboarding complet
2. Activer les recommandations LightFM avec cache
3. Ajouter statistiques utilisateur et calendrier de parution
4. Implémenter alertes de nouveaux chapitres
5. Créer les premières briques de l’espace communautaire

---

## 🏁 Conclusion
**Manga Tracker** progresse rapidement : le socle technique est robuste (auth, CI/CD, infra, API), et la phase suivante vise à enrichir la personnalisation et la dimension communautaire.

---
