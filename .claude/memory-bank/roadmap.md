# Roadmap Manga Tracker

> **Source initiale** : carte mentale exportée le 04/05/2026 puis convertie en markdown versionnable.
> Ce fichier remplace le format `.mind` (binaire, non-diff-able). Il est édité au fil de l'eau.
>
> **Convention** : à la fin de chaque feature livrée, mettre à jour le marqueur correspondant
> (`⏳` → `🔵` quand le back est OK, puis `🔵` → `✅` quand le front consomme + tests OK).

## Légende

| Marqueur | Signification |
|---|---|
| ✅ | Feature **prête front + back** (livrée et testée) |
| 🔵 | Feature **prête côté back** (API OK, front à faire) |
| ❌ | Feature **abandonnée** (volontairement écartée) |
| ⏳ | Feature **à faire** (pas commencée ou en cours) |
| 🔴 | **Cassé en prod / bloquant** (priorité absolue) |
| 🔥 P0-P3 | Marqueur de **priorité** (voir section Priorités) |

---

## 🔥 Priorités (mise à jour 2026-07-03)

> Ordre de traitement recommandé. Détail et justification en bas de fichier
> (section « Ordre de priorité — justification »).

| # | Priorité | Item | Effort | État |
|---|---|---|---|---|
| 1 | **P0** 🔴 | Google Sign-In : créer l'OAuth client **Android** dans la console GCP (runbook `known-issues.md`) | ~5 min, zéro code | ✅ **Fait le 2026-07-07** (2 clients Android créés + testeur `fabien1.…` ajouté + app OAuth publiée) — à confirmer sur téléphone |
| 2 | **P0** 🔴 | Recherche : merger [PR API #71](https://github.com/BladeBuru/API-mangaTracker/pull/71) → vérifier prod → merger [PR Flutter #48](https://github.com/BladeBuru/manga_tracker/pull/48) + release | 2 merges + 1 release | ✅ **Déployé le 2026-07-07** (API en prod, APK v0.12.0, web) |
| 3 | **P1** 🔥 | Secrets : `.env.development` **embarqué dans l'APK distribué** (contient `GOOGLE_CLIENT_SECRET`) → retirer des assets + **rotation** | ~1 h + rotation | À faire |
| 4 | **P1** 🔥 | Secrets : `key.properties`/keystore versionnés (Flutter) + `development.env` versionné (API : JWT_KEY, secrets) → gitignore + rotation | ~2 h + rotation | Known-issues critiques |
| 5 | **P2** | Notifications de nouveaux chapitres (pipeline complet — le check background Android existe déjà) | sprint | ⏳ |
| 6 | **P2** | Play Store readiness (dépend de #3/#4 pour le signing propre) — `.aab`, permissions, listing | sprint | ⏳ |
| 7 | **P2** | Web : 1er déploiement `app.bladeburu.com` (infra prête) + responsive | sprint court | 🔵 |
| 8 | **P3** | Catalogue local + recherche `pg_trgm` + modèle `work`/multi-sources (lève le verrou `mu_id`, MangaDex pivot — doc veille 2026-06) | chantier | ⏳ |
| 9 | **P3** | Reco ML (LightFM) — après le catalogue local | chantier | ⏳ |
| 10 | **P3** | iOS App Store (après Play Store + abstractions cross-platform) | chantier | ⏳ |

---

## Gestion utilisateur

### ✅ Connexion à son compte utilisateur
### ✅ Déconnexion du compte utilisateur
### ✅ Création de compte utilisateur
### ✅ Suppression de compte utilisateur
### ✅ Changement de mot de passe du compte utilisateur *(livré v0.11.x — page profil + currentPassword requis + révocation des autres sessions)*
### ✅ Récupération du nom d'utilisateur
### 🔵 Photo de profil *(URL externe OK ; upload multipart à câbler Phase 3.1)*
### 🔵 Onboarding pour collecter des stats utilisateur *(champs profil étendus prêts ; modal post-inscription à câbler — choix de genres pour alimenter les recos + démographie optionnelle)*

- 🔵 Tranche d'âge *(dateOfBirth en base + UI)*
- ⏳ Pays / Langue
- ⏳ Genre (sélection 3 genres environ)
- 🔵 Sexe *(champ gender en base + UI ChoiceChips)*

### ✅ Profil étendu (Phase 3) — displayName, bio, avatarUrl, isProfilePublic

---

## Authentification

### Interne

- ✅ Rester connecté après login (refresh token)
- ✅ Confirmation par mail (verify-email)
- ✅ Protection des endpoints (JWT guard)
- ✅ API Authentification
- ✅ Authentification biométrique
- ✅ Reset password via mail (magic link)

### Externe

- ✅ Authentification Google (mobile via `idToken` + web via OAuth WebView) *(réparée le 2026-07-07 : clients OAuth Android release + dev créés dans la console GCP, testeur corrigé (`fabien1.…`), app OAuth publiée en production. Feedback d'erreurs différencié livré en v0.12.0 — confirmation finale sur téléphone en attente)*
- ⏳ Authentification Apple (App Store requirement)

---

## Gestion de bibliothèque utilisateur

### Service bibliothèque

- ✅ Ajout
- ✅ Suppression
- ✅ Consultation
- ✅ Gestion de l'état de lecture
- ✅ Note personnelle (rating 0-10)
- ✅ Lien personnalisé (custom link)

### ✅ Recherche sur tous les noms des mangas

- ✅ Pertinence alignée sur le classement MangaUpdates *(livré v0.12.0 — cause racine `orderby: rating` corrigée ; « Shadow System » et « Naruto » vérifiés en #1 en local ET la correction profite aussi aux vieux APK)*
- ✅ Pagination scroll infini + compteur de résultats + fin de liste propre *(livré v0.12.0 — enveloppe `{results, totalHits, page, perPage, hasMore}` rétrocompatible)*

### ✅ Récupération d'un manga spécifique

- ✅ Traduire les champs (description)

### ✅ Affichage des tendances/nouveautés/populaires
### ✅ Filtrer les contenus mature
### ❌ Favoris *(remplacé par les statuts de lecture)*

- ❌ Voir tous les mangas favoris
- ❌ Ajout
- ❌ Suppression

### ✅ Historique de recherche

---

## Système de notation et avis

### ✅ Collecte des avis (commentaires utilisateurs) *(Phase 7 + 7.1 — livré : threading, soft delete, rating optionnel, pagination)*
### Affichage des notes

- ✅ Affichage des notes MangaUpdates
- ✅ Affichage des notes MangaTracker (agrégées — note Bayésienne sur la fiche détail)

### ⏳ Interface de notation avancée

---

## Suivi de lecture

### ✅ Mise à jour instantanée de l'état (reading/completed/caughtUp/readLater)
### ⏳ Filtres avancés de notifications

### Lecture

- ✅ Enregistrement de la progression
  - ✅ Journal de lecture par chapitre *(API + table chapter_log ; readers branchés — sprint stats v2, v0.11.x)*
  - ⏳ Regrouper les chapitres par tome ou arc
- ✅ Téléchargement de chapitre (Android/iOS uniquement)
- ✅ Bloqueur de pub dans le webview

### Statistiques

- ✅ Nombre total de chapitres lus *(Phase 2)*
- ✅ Estimation du temps de lecture (chapitres × durée moyenne) *(Phase 2)*
- ✅ Top genres les plus consultés *(Phase 2)*
- ✅ Taux de complétion + dernière lecture + ancienneté du compte *(Phase 2)*
- ✅ Stats v2 : graphique d'activité hebdo + historique des dernières lectures + genres *(livré sprint social/stats, v0.11.x)*
- ⏳ Streak de lecture
- ⏳ Progression vers un objectif personnel

### ✅ Status de lectures (reading / readLater / completed / caughtUp / dropped)

---

## Recommandations personnalisées

### ✅ Suggestions basées sur l'historique de lecture *(API + front livrés ; cache user-level 1h back + 2h front — v0.10.x)*
### ✅ Recommandations par genre (`/recommendations/by-genre` + vue sections front)
### ✅ Sleeper hits (pépites cachées) — `/recommendations/sleepers` *(intégrés au cold start)*
### ✅ Cold start nouveaux utilisateurs *(biblio vide → top communauté + pépites + bandeau d'accueil — v0.10.x)*
### ⏳ Page « Explorer » par catégories personnalisées *(bouton « Voir plus » sur la home — en cours)*
### ⏳ Modèle hybride LightFM (interactions explicites + features)

- ⏳ Ignorer un manga des recommandations (déjà en cours / déjà lu)

---

## Espace communautaire

### ✅ Système d'amis *(Phase 6 + 6.1 — backend + UI livrés)*

- ✅ Demande / accept / refuser / bloquer / supprimer
- ✅ Recherche d'utilisateurs (autocomplete)
- ✅ Page Amis (onglets + recherche + cache 24h)
- ✅ Badge BottomNavBar (compteur global polling — NotificationCountsService)

### ⏳ Forum et discussions
### ⏳ Partage de théories
### ⏳ Mini-jeux communautaires
### ⏳ Chat en temps réel
### ✅ Voir la bibliothèque de ses amis *(livré v0.11.x — profil ami, réservé aux amitiés acceptées)*
### ✅ Partage de manga entre amis *(Phase 8 + 8.1 — modal partage + inbox + badge nouveau)*

---

## Redirection vers plateformes

### ✅ Liens directs vers des sites légaux de lecture
### ✅ Lien personnalisé de l'utilisateur

- ✅ Affichage de la page avec WebView (mobile)
- ✅ Ouverture dans un nouvel onglet (web — `url_launcher`)

### ✅ Mise à jour automatique des liens

---

## Alertes de nouvelles sorties

### ⏳ Notification des nouveaux chapitres/volumes
### ⏳ Mise à jour automatique des alertes (liens, filtres)
### ✅ Vérification background des nouveaux chapitres (workmanager Android)
### ⏳ Background fetch iOS (BGTaskScheduler)
### ⏳ Service worker Web pour notifications push

---

## Sécurité et Conformité

### 🔴 Secrets exposés — 🔥 **P1** *(découverts/reconfirmés lors de l'audit du 2026-07-03)*

- ⏳ `assets/env/.env.development` est **déclaré comme asset Flutter → embarqué dans chaque APK release distribué** (contient `GOOGLE_CLIENT_SECRET`) → le retirer des assets du `pubspec.yaml` + **rotation du secret Google**
- ⏳ `android/key.properties` + `upload-keystore.jks` présents dans le repo (mot de passe keystore lisible) → vérifier gitignore/historique + rotation si exposé
- ⏳ API : `src/common/envs/development.env` versionné (JWT_KEY, JWT_REFRESH_SECRET, GOOGLE_CLIENT_SECRET en clair) → retrait de git + rotation

### ✅ Conformité RGPD (article 15 / 17 / 20 / 7)

- ✅ Endpoints `/user/gdpr/summary`, `/export`, `/consent`, `/consent-status`
- ✅ Page « Mes données » dans le profil
- ✅ Cascade DELETE sur user (user_manga + user_session)
- ✅ Consentement obligatoire à l'inscription (CGU + Privacy)
- ✅ Re-consentement après mise à jour des versions
- ⏳ Audit complet vis-à-vis des recommandations CNIL

### ✅ Endpoint transparent renvoyant les images de MangaUpdates *(Phase 4 — proxy + auto-refresh)*

---

## Optimisation et Performances

### Cache

- ✅ Cache local SharedPreferences (24h sur library/manga/homepage/search, 7j sur user)
- ✅ Cache mémoire LRU dans BLoCs
- ⏳ Pré-calcul + mise en cache périodique des scores de recommandation (Redis)
- ⏳ Génération nocturne des recommandations pour tous les utilisateurs

### Base de données

- ⏳ Indexer la colonne `mu_id` pour optimiser les requêtes de lecture
- ✅ Utiliser les données en base si dernière actualisation < 6h
  - ⏳ Pour les manga non updaté depuis 24h, actualiser 1 fois

### Backups

- ✅ Backup PostgreSQL prod quotidien (3h UTC) via SSH NAS + rotation 30 jours

---

## Fonctionnalités complémentaires

### ⏳ Ajouter les noms des mangas dans les différentes langues
### ⏳ Trier la liste des mangas (date modification, alphabétique)
### ⏳ Ajouter l'autocomplétion lors de la recherche
### ⏳ Ajouter traduction anglais/français (faisabilité à étudier)
### ❌ Lire un manga directement dans l'application *(scraping = zone grise légale)*

---

## CI/CD et Qualité du code

### ✅ Formateur + linter dans le pipeline CI/CD pour les PR
### ✅ Automatisation linter + formatter
### ✅ Déploiement de l'image d'intégration (Docker Hub + TrueNAS)
### ✅ Skill `/release` (workflow_dispatch + bump version + changelog automatique)
### ✅ Trigger pipeline release sur `main` (au lieu de `dev`)
### ⏳ Automatisation training → test → publication du modèle LightFM

---

## Infrastructure et Environnement

### ✅ Mise en place de Swagger pour documenter les endpoints de l'API
### ✅ Création du repository de l'API
### ✅ Connexion à la base de données de prod (TrueNAS PostgreSQL)
### ✅ Déploiement de l'image d'intégration
### ✅ Construction de l'image `latest` à partir de `master`
### ✅ Reverse proxy NPMplus + HTTPS Let's Encrypt
### ✅ Endpoint pour récupérer l'image de couverture d'un manga (proxy CORS — mode `stream` v0.10.x, fix images web)
### ⏳ Mention « données provenant de l'API MangaUpdates »

### Environnement ML dédié

- ⏳ Serveur ou container Docker pour entraînement LightFM (GPU/CPU)
- ⏳ Stockage et versioning des modèles (MLflow ou DVC)

---

## Frontend et Expérience utilisateur

### ✅ Page de connexion
### ✅ Maquette tendances/nouveautés/populaires
### ✅ Bottom navbar (4 tabs : Home / Library / Search / Profile)
### ✅ Page gestion de compte
### ✅ Thème sombre *(light/dark/système — ThemeToggleButton, refonte V1 Refined Classic)*
### ⏳ Calendrier mensuel/semaine des dates de parution pour les séries suivies
### ⏳ Score de compatibilité LightFM (affichage)
### ✅ Page Detail Manga
### ✅ Recherche manga

- ✅ Améliorer la pertinence des résultats *(livré v0.12.0)*
- ✅ Pagination scroll infini *(livré v0.12.0)*

### ✅ i18n complète 7 langues (fr, en, de, ja, ko, pt, es)

---

## Web (PWA)

### ✅ Build Flutter Web fonctionnel (auth + biblio + recherche + détails + recommendations)
### ✅ Migration `MaterialPageRoute` → `go_router` (deep-linking)
### ✅ Stubs propres pour features web-incompatibles (download, offline reader, workmanager)
### ✅ Pipeline CI/CD web → Nginx Docker → NAS via NPMplus
### 🔵 Domaine `app.bladeburu.com` *(infra prête, attente lancement 1er deploy)*
### ⏳ Layouts responsive (LayoutBuilder mobile/tablette/desktop)
### ⏳ PWA installable (manifest + service worker activés)
### ⏳ Adaptation des largeurs hardcodées au format desktop

---

## iOS (App Store) — non démarré

### ⏳ Configuration `Info.plist` (NSCameraUsage, NSPhotoLibraryUsage, NSFaceIDUsage)
### ⏳ Bundle Identifier + Team ID + Provisioning Profile
### ⏳ Cupertino fallbacks pour widgets purement Material
### ⏳ Notifications via `DarwinInitializationSettings`
### ⏳ Background fetch iOS (BGTaskScheduler) au lieu de workmanager
### ⏳ Build `.ipa` signé via Fastlane

---

## Visualisation Mermaid

```mermaid
mindmap
  root((Manga Tracker))
    🔥 P0 — Débloquer ✅ fait 2026-07-07
      ✅ Google Sign-In — clients Android créés + app publiée
      ✅ Recherche — v0.12.0 déployée API + APK + web
    🔥 P1 — Sécurité secrets
      🔴 .env.development embarqué dans APK — rotation GOOGLE_CLIENT_SECRET
      🔴 keystore et env versionnés — gitignore + rotation
    Auth
      ✅ Login/Register/Logout
      ✅ JWT + Refresh
      ✅ Biométrique
      ✅ Google OAuth mobile — réparé
      ✅ Magic links email
      ⏳ Apple Sign-In — avec iOS
    Bibliothèque
      ✅ CRUD complet
      ✅ Statuts lecture
      ✅ Note + custom link
      ✅ Recherche pertinence + pagination — v0.12.0
      ✅ Tendances/populaires
    Recommandations
      ✅ API user
      ✅ Par genre
      ✅ Sleeper hits + cold start
      ⏳ LightFM — P3, après catalogue
    Lecture
      ✅ Progression + journal par chapitre
      ✅ Téléchargement chapitres
      ✅ Bloqueur pub
      ✅ Stats v2 — activité hebdo, historique, genres
      ⏳ Streak
    Notifications — P2
      ✅ Check background Android
      ⏳ Notifs nouveaux chapitres bout en bout
      ⏳ iOS BGTask
      ⏳ Web Push
    Données — P3
      ⏳ Catalogue local + recherche pg_trgm
      ⏳ Modèle work multi-sources — lever verrou mu_id
      ⏳ MangaDex pivot — webtoons occidentaux
    Plateformes
      ✅ Android prod hors store
      ⏳ Play Store — P2, après P1 secrets
      🔵 Web déployable — P2, infra prête
      ⏳ iOS App Store — P3
    Infrastructure
      ✅ NestJS API + Postgres
      ✅ Docker NAS
      ✅ Backup quotidien
      ✅ HTTPS NPMplus
      ✅ CI/CD release skill
    Frontend
      ✅ Material 3 + i18n 7 langues
      ✅ go_router
      ✅ Dark mode
      ⏳ Responsive — P2 avec le web
      ⏳ PWA
    Communauté
      ✅ Amis + partage + biblio ami
      ⏳ Forum
      ⏳ Chat
      ⏳ Mini-jeux
```

---

## Ordre de priorité — justification (2026-07-03)

**P0 — Débloquer l'existant (heures).** Deux features déjà payées sont
inutilisables : la connexion Google (panne totale, fix = 5 min de console
GCP, aucun code, agit sur l'APK déjà installé) et la recherche (PRs #71/#48
testées de bout en bout, il ne reste que 2 merges + 1 release — **ordre
impératif : API d'abord**). Meilleur ratio valeur/effort de toute la carte.

**P1 — Secrets (avant toute croissance).** Le `GOOGLE_CLIENT_SECRET` est
distribué publiquement dans chaque APK (asset `.env.development`) et des
secrets JWT/keystore sont versionnés. Tant que l'app est confidentielle le
risque est contenu, mais c'est un préalable absolu au Play Store (review +
exposition) et chaque jour augmente le coût d'une rotation. À faire AVANT P2.

**P2 — Vague produit courte (semaines).** (a) Notifications de nouveaux
chapitres : c'est LE cœur d'une app de suivi, le check background existe
déjà, il manque le pipeline de bout en bout ; (b) Play Store (dépend de P1
pour le signing/secrets) : distribution et mises à jour sans friction ;
(c) 1er déploiement web `app.bladeburu.com` : infra prête, gros gain de
visibilité pour un effort résiduel (responsive en parallèle).

**P3 — Fond structurant (mois).** Catalogue local + `pg_trgm` + modèle
`work` multi-sources (doc veille 2026-06) : recherche instantanée, lève le
verrou `mu_id`, couvre les webtoons occidentaux via MangaDex. À faire AVANT
LightFM (le ML a besoin d'un catalogue propre) et avant iOS (qui a ses
propres prérequis d'abstraction). Apple Sign-In s'aligne sur iOS.

**Non prioritaire.** Forum/chat/mini-jeux (communauté embryonnaire),
calendrier de sorties, streak — valeur réelle mais aucune dépendance ne les
bloque, à piocher en fond de sprint.

---

## Avancement global *(à régénérer après chaque release)*

| État | Compte | Description |
|---|---:|---|
| ✅ Prêt (front + back) | ~62 | Livré et testé *(+7 : stats v2, journal lecture, biblio ami, change password, dark mode…)* |
| 🔵 Prêt, en attente merge/release | ~5 | Dont recherche pertinence + pagination (PRs #71/#48) |
| 🔴 Cassé / bloquant | 2 | Google Sign-In mobile (console GCP) + secrets exposés |
| ⏳ À faire | ~60 | Backlog priorisé (P2/P3 + fond de sprint) |
| ❌ Abandonné | 3 | Volontairement écartés |

---

## Comment maintenir ce fichier

1. Quand une feature passe en prod (front + back validés) → changer `⏳` ou `🔵` en `✅`
2. Quand le back est OK mais que le front est encore à faire → mettre `🔵`
3. Quand on décide d'abandonner une feature → mettre `❌` avec une justification entre `*( )*`
4. Pour ajouter une nouvelle catégorie → respecter le pattern `## Catégorie` puis `### feature` puis `- sous-feature`
5. Mettre à jour le bloc Mermaid à la fin pour qu'il reste représentatif (vue d'ensemble)
6. Mettre à jour le tableau d'avancement global après chaque release
