# Next Session — Bugs & améliorations à traiter

> Document de session compilé le 2026-05-19 après la release v0.10.0. **Mis à jour le 2026-06-11** après vérification approfondie (3 agents Explore) et rédaction des specs Zelian.
> À traiter en suivant la méthodologie : comprendre → analyser → bons skills/agents → implémentation → audit → cross-platform (Android/Web) + dark/light → memory-bank.

---

## ⭐ SPECS ZELIAN RÉDIGÉES (2026-06-11) — POINT D'ENTRÉE DU SPRINT v0.10.1

Les bugs ci-dessous ont été **vérifiés en profondeur** (preuves fichier:ligne) et les specs du sprint correctif sont prêtes :

- **Spec Flutter** : `docs/specs/hotfix-v0-10-1/` (spec-fonctionnel, spec-technique, tech-design, VERSIONNING)
- **Spec API** : `API-mangaTracker/docs/specs/hotfix-v0-10-1/` (idem)

Workflow Zelian : lire la spec → `/superpowers:brainstorm` → `/superpowers:write-plan` → `/superpowers:execute-plan`, session dédiée par repo.

**Verdicts de vérification importants (corrigent des hypothèses de ce document)** :
- ✅ RGPD email dans commentaires : CONFIRMÉ — cause = `username` rempli avec l'email (register sans validation + fallback OAuth Google), `displayName` jamais rempli
- ❌ **Multi-device tablette : INFIRMÉ côté API** — sessions indépendantes, rotation propre. Investigation côté Flutter/Huawei (instrumentation d'abord, voir tech-design D6)
- ✅ CORS images web : CONFIRMÉ avec nuance — le proxy fait un **302 vers le CDN MU** donc bloqué même via proxy en CanvasKit → mode `stream` à ajouter côté API (tech-design D1)
- ✅ Autofill : `autofillHints` déjà présents — il manque `AutofillGroup` + `finishAutofillContext`
- ⚠️ Recos nouveaux users : le backend a DÉJÀ un cold start (`buildColdStartRecommendations`) — gap purement UX front
- ⚠️ Cache front : le stub `isCacheExpired()` retourne toujours false mais la vraie méthode `isCacheExpiredFor()` existe — il faut juste l'utiliser

---

## 🆕 Bugs remontés en fin de session (2026-05-19)

### Auth — Durée session trop courte + multi-device cassé

**Symptôme user** :
> « Sur ma tablette ça me déconnecte tout le temps au bout de la session. La tablette est une Huawei (Android modifié). Est-ce normal pour une app de tracking ? »

**Config actuelle confirmée** :
- AccessToken (JWT) : **1h**
- RefreshToken : **7 jours** ← TROP COURT
- `UserSession` entity supporte théoriquement multi-device (champ `deviceInfo`)

**Benchmarks par catégorie d'app** :

| App | Access | Refresh |
|---|---|---|
| Banking | 5-15min | 1-24h |
| SaaS | 15min-1h | 7-30j |
| **Media tracking** (Goodreads, Letterboxd, MAL) | **1-2h** | **30-180j** |
| Streaming (Netflix) | 1h+ | ~365j |

**Recommandation** :
- Bumper `JWT_REFRESH_SECRET_EXPIRES_IN` de `7d` à `30d` (minimum), idéalement `90d`
- Ajouter option "Rester connecté 1 an" à cocher au login (refresh 365j si oui)
- Fichiers à modifier :
  - `API-mangaTracker/.github/workflows/ci-cd.yml` (env var prod)
  - `API-mangaTracker/deploy/compose.production.yml`

**Sur le multi-device cassé (tablette Huawei) — à auditer** :
1. Audit `auth.service.ts` : est-ce que `createSession()` révoque les anciennes sessions du même user ?
2. Vérifier le flow refresh : si la tablette refresh avec un token périmé, est-ce que ça invalide aussi le token du téléphone ?
3. Spécifique Huawei (EMUI 13+ / HarmonyOS) :
   - `flutter_secure_storage` peut être instable sans Google Services
   - Le keystore Android d'Huawei a parfois des bugs sur EMUI
   - Tester avec `shared_preferences` en fallback pour le refresh token (moins sécurisé mais plus stable)

**Skills concernés** : `bug-fix`, `secure-deployment`

---

### Images CORS sur Web — fix simple

**Symptôme user** + logs console :
```
Access to image at 'https://cdn.mangaupdates.com/image/i483215.jpg' from origin 'https://app.bladeburu.com'
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

**Cause** : Sur Flutter Web, le navigateur bloque les images chargées en cross-origin depuis `cdn.mangaupdates.com` qui ne renvoie pas le header `Access-Control-Allow-Origin: *`.

**Solution déjà disponible** : on a un proxy backend `GET /mangas/:muId/cover?size=medium` qui sert les images depuis notre API (même origine que le front → pas de CORS).

**Action** :
1. Auditer où dans Flutter on charge encore les URLs MU directes :
   - `lib/core/components/refreshable_manga_image.dart`
   - `MangaQuickViewDto.coverUrl` retourne quoi exactement ?
2. Forcer l'usage du proxy partout via Flutter Web (kIsWeb) :
   ```dart
   final coverUrl = kIsWeb
     ? '${env.apiUrl}/mangas/$muId/cover?size=medium'
     : originalMuUrl;
   ```
3. Optionnel : appliquer le proxy aussi sur mobile pour ne pas avoir à gérer 2 cas (et profiter du cache disque côté API)
4. Vérifier que le `Dockerfile`/Nginx du back ajoute bien `Access-Control-Allow-Origin: https://app.bladeburu.com` sur la route `/mangas/*/cover` (CORS configuré côté API mais on doit valider)

**Skills concernés** : `bug-fix`, `web-readiness`

---

### Autofill mot de passe perdu (web + mobile)

**Symptôme user** :
> « Avant mon authentificateur arrivait à mettre automatiquement les données, mais là il y arrive plus. »

**Cause probable** : Lors d'une refonte récente du formulaire login, les attributs `autocomplete` ont sauté.

**Côté Flutter Web** : le `TextField` doit avoir :
```dart
TextField(
  autofillHints: const [AutofillHints.username, AutofillHints.email],
  ...
)
TextField(
  autofillHints: const [AutofillHints.password],
  obscureText: true,
  ...
)
```

Et le formulaire doit être wrappé dans `AutofillGroup` :
```dart
AutofillGroup(
  child: Column(children: [emailField, passwordField, loginButton]),
)
```

**Action** :
1. Audit `lib/features/auth/views/login.view.dart` et `register.view.dart`
2. Ajouter `autofillHints` + `AutofillGroup`
3. Tester sur Chrome (1Password / Google PW Manager) + Android (autofill système)
4. Sur Android, vérifier `AndroidManifest.xml` n'a pas désactivé l'autofill au niveau de l'activity

**Skills concernés** : `bug-fix`, `web-readiness`, `add-component`

---

## 🔴 P1 — Bugs critiques fonctionnels

### 1. Suivi automatique de lecture cassé

**Symptôme user** :
> « Sur la page de lecture du manga (le lien qu'on a mis), il y avait quelque chose qui détectait si on était en bas de page ou pas. Si on n'était pas en bas → ça sauvegardait la position en hauteur pour revenir au même endroit. Si en bas → ça affichait "Avez-vous fini de lire ?" Oui → chapitre marqué lu + ouvre suivant. Aujourd'hui ça ne fonctionne plus. Sur la version PC, il y a juste le lien sans popup. »

**Plateformes concernées** :
- Android (release v0.10.0) : popup absente / scroll non détecté
- Web (Flutter Web) : pas du tout implémenté

**Actions** :
1. Auditer le code WebView / launchUrl actuel (agent lancé en background — voir résultat)
2. Restaurer le mécanisme côté mobile (WebView interne + JS bridge scroll)
3. Sur Web : alternative possible = popup au retour de l'onglet "As-tu fini ce chapitre ?" basée sur Page Visibility API
4. Tests manuels Android + Chrome avant fermeture

**Skills concernés** : `bug-fix`, `cross-platform-audit`

---

### 2. Bug commentaires — emails au lieu d'usernames

**Symptôme user** :
> « Sur les commentaires, j'ai uniquement les adresses mail qui apparaissent et quand je clique dessus ça check direct [ouvre app mail]. »

**Gravité** : 🚨 **POTENTIELLEMENT RGPD** — email = donnée personnelle exposée publiquement.

**Hypothèses** :
- DTO côté API expose `user.email` au lieu de `user.username` ou `user.displayName`
- Côté front, un `Linkify` auto-détecte les emails dans le contenu et active le tap mailto:

**Actions** :
1. Audit en background (résultat attendu)
2. **Si confirmé RGPD** → hotfix prioritaire (avant prochaine release)
3. Corriger CommentDto API : `username` + `displayName` + `avatarUrl`, **jamais** `email`
4. Côté Flutter : afficher `displayName ?? username`, désactiver mailto auto sur le texte commentaire

**Skills concernés** : `bug-fix`, `secure-deployment` (audit RGPD)

---

## 🟠 P2 — UX/fonctionnel important

### 3. Nouveaux utilisateurs — Recommandations vides

**Symptôme** : Compte fraîchement créé → page Recommandations vide (rien à afficher car bibliothèque vide → pas de sources).

**Solutions possibles** :
- **A. Fallback "Mangas populaires"** : si user a 0 mangas en biblio → afficher Top 20 toutes catégories (déjà l'endpoint Home / Trending)
- **B. Onboarding par choix de genres** : modal post-inscription "Quels genres tu aimes ?" (3-5 choix) → recommandations basées sur popularité dans ces genres
- **C. Combinaison A + B** : populaires en attendant les choix, puis filtrés selon genres choisis

**Recommandé** : **C** (UX la plus douce).

**Skills concernés** : `feature-implementation`

---

### 4. Recommandations — quantité insuffisante + pas de cache

**Symptôme user** :
> « Même avec 60 mangas dans la liste, pas énormément de recommandations. Pas de cache : à chaque retour sur la page ça recalcule, requête lente. Pas de sauvegarde côté front ni côté back. »

**Audit en background** — résultat attendu.

**Pistes confirmées** :
- Backend : `recommendation.service.ts` cap actuel `MAX_RECOS_PER_SOURCE=30` (récemment bumpé de 10). Pas de cache de résultat final côté Postgres ni Redis.
- Front : `OfflineCacheService` n'a pas de clé `cached_recommendations` (à vérifier).

**Actions probables** :
1. Côté front : cache Flutter 1-2 h sur la liste de recos (`cached_recommendations` clé existante du pattern offline-first)
2. Côté back : cache Redis 30 min sur `GET /api/recommendations?userId=X` OU pré-calcul nocturne par cron (`reco_cache` table avec colonne `user_id, recos_json, computed_at`)
3. Audit pourquoi peu de recos même avec 60 mangas — possibles causes :
   - `getCachedRecommendations` retourne peu pour les mangas niche
   - Exclusion library `libraryMuIds.has()` enlève trop
   - Fallback `ADAPTIVE_FALLBACK_CAP=60` mal déclenché
4. Doc dans `.claude/memory-bank/decisions.md` la stratégie de cache retenue

**Skills concernés** : `feature-implementation`, `bug-fix`, `refactor-large-file` (si reco.service.ts gros)

---

### 5. Bouton lecture rapide dans la bibliothèque

**Demande user** :
> « Déplacer le bouton étoile [note] à la fin à la place de la note. Mais pour lire directement, ça nous évite un clic pour l'utilisateur. Comme ça il voit directement ceux avec lien et ceux sans lien. »

**Reformulation** : dans la vue Bibliothèque (list + grid), ajouter à chaque ligne un bouton "▶️ Lire" qui ouvre directement le lien du dernier chapitre lu + 1 (ou le prochain non lu). Le bouton étoile peut être supprimé ou déplacé.

**Actions** :
1. Ajouter `read_url` ou `next_chapter_url` au DTO Library (si pas déjà présent)
2. Bouton "Lire" visible uniquement si lien dispo, gris/désactivé sinon
3. Disposition : pour la version `list_tile`, à droite (trailing). Pour grid, en overlay bottom-right de la cover
4. i18n 7 langues
5. Brancher sur le même flow que le suivi auto (P1.1)

**Skills concernés** : `add-component`, `feature-implementation`

---

### 6. Profil ami — affichage limité

**Demande user** :
> « Pour l'instant on voit pas grand chose. Pouvoir voir le profil de nos amis. »

**État actuel** : Page friend profile probablement minimaliste (juste username + avatar).

**À ajouter (RGPD-aware)** :
- Bibliothèque publique de l'ami (si `is_profile_public = true`)
- Stats publiques (nombre de mangas lus, genre préféré, total chapitres)
- Liste des recos qu'il a partagées
- Bouton "Lire ensemble" (reading group avec lui)
- Bouton "Voir ses commentaires"

**Pré-requis RGPD** :
- Flag `is_profile_public` doit exister sur User (à vérifier : Phase 3 du plan global)
- Endpoint `/user/profile/:id` retourne 404 si `is_profile_public = false`

**Skills concernés** : `feature-implementation`

---

## 🟡 P3 — UX cosmétique / refonte

### 7. Page d'accueil un peu fade

**Demande user** :
> « Repenser un peu la page d'accueil qui est un peu fade à mon goût. Avec les endpoints qu'on a vu sur MangaUpdates, on peut justement améliorer tout ça. »

**Idées concrètes (alimentées par la veille MU)** :
1. **Hero rotatif** : carrousel top 5 mangas (cover large, titre, note, action "Voir")
2. **Section "Pépites des nouvelles sorties"** : combine `releases/days/{yesterday}` + scoring sleeper-hit + match genres user
3. **Section "À découvrir dans tes genres préférés"** : utilise top stats user (genre le plus lu)
4. **Section "Tes amis ont aimé"** : feed des recos partagées par friends
5. **Section "Reprise de lecture"** : 5 derniers mangas avec progression < 100% (cards avec progress bar)
6. **Section "Nouveaux dans la communauté"** : mangas ajoutés récemment dans les biblios MU (signal d'émergence)

**Approche graduelle** : commencer par 5 (reprise) + 2 (pépites des sorties) = grosses victoires. Compléter avec le reste après.

**Skills concernés** : `add-component`, `feature-implementation`, `cross-platform-audit` (responsive web)

---

### 8. Langues page redesign V1

**État** : queued depuis la session précédente, pas urgent mais cohérence design.

---

## 🟢 P4 — Veille technique / structuration

### 9. Veille MangaUpdates API

**Document existant** : `C:\Users\User\.claude\plans\https-api-mangaupdates-com-est-ce-que-tu-tranquil-brook.md`

**Highlights** (à consulter au début de session) :
- ~150 endpoints sur 17 groupes. On en utilise 2 actuellement.
- 3 endpoints à fort potentiel : `rating/rainbow`, `lists/similar-users/by-series/{id}`, `releases/days/{day}`
- Crawl progressif faisable sans ban : 30 req/min, jitter, UA identifiable, caching 30-60j
- 5 features roadmap considérablement enrichies par cette ingestion
- 3 features inédites low-hanging (recherche avancée, comparaison user/communauté, pages auteur)

**Décisions à prendre next session** :
- Démarrer le crawler progressif (BullMQ) ? → impact long terme sur reco
- Implémenter d'abord les features low-effort (recherche avancée, pages auteur/éditeur) ?
- Notifications nouveau chapitre via `releases/days` ?

---

### 10. Amélioration skills + rules + architecture

**Demande user** : « Lance quelques skills en parallèle pour améliorer un peu les skills existants ou les rules ou l'architecture ou tout ça. »

**Actions next session** :
- Audit `.claude/skills/` et `.claude/rules/` côté Flutter et API
- Identifier les skills manquants : reco peut bénéficier d'un skill dédié `cache-strategy` ?
- Mettre à jour `architecture.md` avec les composants récents (BLoC amis, reading groups, etc.)
- Re-générer `roadmap.md` avec mindmap mermaid à jour

---

## 📋 Méthodologie à appliquer (rappel user)

Pour chaque tâche ci-dessus, le workflow est :

1. **Comprendre le besoin** (questions à l'user si ambigü)
2. **Analyser** (lecture memory-bank, fichiers concernés)
3. **Appeler les bons skills/agents** (parallèle quand possible)
4. **Implémenter** (i18n FIRST si UI, tokens design)
5. **Audit qualité auto-déclenché** (code-reviewer ou Explore)
6. **Cross-platform check** : Android + Web
7. **Theming check** : light + dark
8. **Memory-bank update** : `progress.md` + `roadmap.md` + `known-issues.md`

---

## 🤖 Résultats des 3 audits pré-lancés (session 2026-05-19 fin)

### 🔴 Audit 1 — Suivi auto lecture

**État actuel** :
- ✅ **Marche partiellement** sur mobile (Android/iOS) via `flutter_inappwebview`
- ❌ **Stub vide** sur Flutter Web (`web_view_web.dart` → juste un `launchUrl()`)

**Fichiers clés** :
- `lib/features/reader/services/scroll_position_service.dart` (319 lignes — limite frôlée)
- `lib/features/reader/utils/reading_progress_helper.dart` (seuil 15% pour popup "fin")
- `lib/features/reader/services/webview_navigation_service.dart`
- `lib/features/manga/views/web_view_io.dart` (popup `_onWillPop` ligne 686-750)
- `lib/features/manga/views/web_view_web.dart` (stub à refondre)
- `lib/features/reader/views/offline_reader_view_io.dart`

**Diagnostic** :
1. **Seuils incohérents** : 15% pour popup, 95% pour rejet sauvegarde → signal mixte
2. **Timeout images court** : 5s (`maxAttempts=25`) → certains lecteurs lents échouent
3. **Restauration scroll fragile** : DOM pas prêt quand `window.scrollTo()` est appelé
4. **iframe** : `window.scrollY` retourne 0 si lecteur en `<iframe>` → faux négatif
5. **Auto-passage chapitre N+1** : détecte le changement d'URL mais ne navigue pas auto

**Fix court terme** :
- Unifier seuils à 90% (`reading_progress_helper.dart` lignes 89, 254, 35)
- Augmenter `maxAttempts` à 50 (10s timeout images)
- Fallback `window.parent.scrollY` pour iframes
- Bloquer affichage tant que `restoreScrollPosition()` non confirmé

**Fix long terme** :
- Service Worker au lieu de JS bridge (timing robuste)
- `go_router` + deep-linking
- PWA mode avec IndexedDB pour le web
- Unifier offline/online readers

---

### 🟠 Audit 2 — Cache recommandations

**État actuel** :
- ❌ **Aucun cache user-level** côté backend (recalcul O(N) à chaque request)
- ❌ Cache front Flutter **cassé** : `isCacheExpired()` retourne toujours `false` → refetch systématique
- ❌ Pagination sans dedup → requêtes multiples sans cache par page

**Fichiers à modifier (par priorité)** :

| Fichier | Action | Priorité |
|---|---|---|
| `API-mangaTracker/src/api/recommendations/recommendation.service.ts` | Cache user-level (clé `recos:${userId}:${genre}`, TTL 1h) | 🔴 |
| `API-mangaTracker/src/api/recommendations/recommendation.controller.ts` | Invalider cache au POST/PATCH `/library` | 🔴 |
| `API-mangaTracker/package.json` | Add `@nestjs/cache-manager` (mémoire) ou `cache-manager-redis-store` | 🔴 |
| `manga_tracker/lib/core/services/offline_cache_service.dart` ligne 317-319 | Corriger `isCacheExpiredFor(maxHours)` | 🟠 |
| `manga_tracker/lib/features/manga/services/recommendation.service.dart` | Check TTL avant fetch | 🟠 |
| `manga_tracker/lib/features/recommendations/views/paginated_recommendations_view.dart` | Cache in-memory `Map<pageKey, items>` | 🟡 |

**Pourquoi peu de recos même avec 60 mangas** :
- `MAX_RECOS_PER_SOURCE=30` × 60 mangas = 1800 candidats théoriques
- Mais : exclusion library (-20-40%) + filtrage genre (top 5 × 10) + `MAX_LIMIT=500` → pool final modeste
- **Recommandé** : bumper à `MAX_RECOS_PER_SOURCE=40` (test A/B avant 50)

**Gains attendus** :
- Cold start : 500-3000ms → 1s (avec pré-calcul nocturne cron)
- Re-fetch (retour page) : refetch 0 → cache hit 200ms
- UX recos stables entre sessions = confiance utilisateur

---

### 🚨 Audit 3 — Bug commentaires email (RGPD CRITIQUE)

**Cause racine** :
Le `username` ou `displayName` de certains utilisateurs **contient leur email** en BDD. iOS et Android auto-linkifient les chaînes au format `xx@yy.zz` → tap = `mailto:` natif. Le code Flutter n'a aucun contrôle, c'est l'OS.

**Pourquoi des emails dans username** :
1. Inscription Google OAuth → email sauvegardé comme username au lieu de displayName
2. OU migration/script qui a inversé email/username
3. OU sérialisation API qui retourne email à la place du username

**⚠️ Risque RGPD article 5 (minimisation) + article 32 (sécurité)** : exposition de donnée personnelle sans consentement explicite. À hotfixer **avant le prochain push prod**.

**Fichiers concernés** :
- `API-mangaTracker/src/api/comments/dto/comment.dto.ts` (lignes 125-141)
- `manga_tracker/lib/features/comments/dto/comment.dto.dart` (lignes 40-43)
- `manga_tracker/lib/features/comments/widgets/comment_tile.dart` (lignes 49-50)

**Plan de fix immédiat** :

1. **Audit BDD prod** (à exécuter dès la prochaine session) :
   ```sql
   SELECT id, username, displayName, email FROM "user" WHERE username LIKE '%@%' OR displayName LIKE '%@%';
   ```

2. **Migration corrective** :
   - Pour chaque user concerné : générer un username sain depuis email (ex: `john.doe@gmail.com` → `john.doe` + suffix random si collision)
   - Le `displayName` peut rester l'email côté User entity (donnée privée) MAIS jamais exposé via DTO public

3. **Validation API stricte** sur `User.username` + `User.displayName` :
   ```typescript
   @Matches(/^[a-zA-Z0-9_.-]{3,32}$/, { message: 'Format invalide' })
   ```

4. **Fallback front Flutter** (`comment_tile.dart`) — defense-in-depth :
   ```dart
   String get _safeDisplayName {
     final n = comment.displayName;
     if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(n)) {
       return l10n.anonymousUser; // clé ARB à créer
     }
     return n;
   }
   ```

5. **Audit `gdpr.service.ts`** pour vérifier que l'export RGPD n'expose pas non plus d'emails dans des champs publics par erreur.

**Skills à invoquer next session** :
- `bug-fix` (4 phases)
- `secure-deployment` (audit RGPD complet)

---

## 🎯 Ordre de priorité suggéré pour la prochaine session

**Sprint 1 — Hotfixes** (release v0.10.1) :
1. **🚨 Bug commentaires email** (P1.2) — RGPD, à fixer en priorité absolue
2. **Refresh token 7d → 30d/90d** — fix critique UX, env var à bump
3. **Multi-device + Huawei** — audit + fix de la révocation prématurée
4. **CORS images Web** — switch front sur le proxy backend
5. **Autofill login** — ajouter `autofillHints` + `AutofillGroup`

→ Release v0.10.1 quick patch après ce sprint

**Sprint 2 — UX core** :
6. **Suivi auto lecture** (P1.1) — restaurer + cross-platform
7. **Cache recos** (P2.4) — `@nestjs/cache-manager` + corriger `isCacheExpiredFor`
8. **Bouton lecture rapide bibliothèque** (P2.5)
9. **Onboarding nouveaux users** (P2.3)

**Sprint 3 — Features + refonte** :
10. **Refonte home** (P3.7) avec endpoints MU
11. **Profil ami enrichi** (P2.6)
12. **Pages auteur/éditeur** (MU veille feature 3)
13. **Recherche avancée** (MU veille feature 4)

**Sprint 4 — Long terme** :
14. **Démarrage crawl MU** (P4.9 + LightFM préparation)
15. **Audit skills/rules/architecture** (P4.10)
16. **Notifications nouveau chapitre** (MU `releases/days`)

Estimation totale : ~5-7 sessions de 3-4h chacune.
