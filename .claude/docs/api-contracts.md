# Documentation : Contrats API — Manga Tracker Flutter

Liste des endpoints API consommés par l'application Flutter.

## Base URL

```
dev  : http://localhost:3000
prod : https://api.manga-tracker.com  (à confirmer)
```

Configurable via `flutter_dotenv` :
- `.env.development`
- `.env.production`

---

## Authentification

Toutes les requêtes protégées utilisent `HttpService` qui gère le JWT automatiquement.

```
Header : Authorization: Bearer <accessToken>
```

En cas d'expiration (401) → `HttpService` rafraîchit automatiquement via `POST /auth/refresh`.

### Endpoints Auth

| Méthode | Route | Auth | Corps | Réponse Flutter |
|---------|-------|------|-------|-----------------|
| `POST` | `/auth/register` | Public | `{ email, password, name }` | `{ accessToken, refreshToken }` |
| `POST` | `/auth/login` | Public | `{ email, password }` | `{ accessToken, refreshToken }` |
| `POST` | `/auth/refresh` | RefreshToken | — | `{ accessToken }` |

---

## Mangas

| Méthode | Route | Auth | Query | DTO Flutter |
|---------|-------|------|-------|-------------|
| `GET` | `/mangas/popular` | JWT | `?page=1&limit=20` | `List<MangaQuickViewDto>` |
| `GET` | `/mangas/trending` | JWT | `?page=1&limit=20` | `List<MangaQuickViewDto>` |
| `GET` | `/mangas/new` | JWT | `?page=1&limit=20` | `List<MangaQuickViewDto>` |
| `POST` | `/mangas/search` | JWT | body JSON `{search_pattern, page?, limit?}` | `SearchResultsPageDto` (enveloppe `{results, totalHits, page, perPage, hasMore}`) — tri par pertinence MangaUpdates ; tableau nu `List<MangaQuickViewDto>` si `page` absent (rétrocompat ≤ 0.11.0) |
| `GET` | `/mangas/:muId` | JWT | — | `MangaDetailsDto` |
| `GET` | `/mangas/home/sections` | JWT | `?limit=20` (5..40, items par section) | `HomeSectionsDto` — `{generatedAt, sections: [{id, kind, params, items}]}` |
| `GET` | `/mangas/home/sections/:id` | JWT | `?page=1&limit=40` (5..40) | `HomeSectionsPageDto` — `{id, kind, params, page, limit, total, items}` ; **404** si `id` inconnu → `HomeSectionNotFoundException` |

### Accueil catalogue (`/mangas/home/sections`) — 2026-09-05

Consommé par `HomeSectionsService` (`features/home/services/`), `HomeSectionsBloc`
(accueil) et `HomeSectionPageBloc` (page « Tout voir » `/home/section/:id`).

- `items[]` = même JSON que `/mangas/popular` (`muId, title, year,
  mediumCoverUrl, largeCoverUrl, rating`) **+ champs optionnels** `type`
  (string : `Manga`, `Manhwa`, `Manhua`…) et `genres` (string[]). Parsés par
  `MangaQuickViewDto.fromJson` (`type` / `genres` nullables, `toJson`
  rétrocompatible avec l'ancien cache).
- **Les sections ne portent pas de titre** : le client le déduit de `kind` +
  `params` via `HomeSectionL10n.title()` (ARB `homeSection*`, placeholders
  `genre` / `type` / `year`). L'**ordre des sections est celui du serveur**.
- `kind` connus (`HomeSectionKind`) : `latest`, `popular`, `top_rated`,
  `type` (`params.type`), `genre` (`params.genre`), `year` (`params.year`,
  entier), `community`, `hidden_gems`. Un `kind` **inconnu est ignoré sans
  planter** (`HomeSectionKind.tryParse` → `null` → section écartée) ; sur la
  page `/:id`, un `kind` inconnu conserve la page, le titre retombe sur l'`id`.
- Sections `type:*` possiblement absentes au début : rien n'est supposé, la
  liste affichée est exactement celle du serveur, sections vides masquées.
- `id` peut contenir `:` et des espaces (`genre:Slice of Life`) → encodé
  avec `Uri.encodeComponent` dans le chemin.
- Pagination « Tout voir » : `hasMore = page * limit < total` (repli : page
  pleine ⇒ suite) ; les doublons entre pages (insertion serveur entre deux
  appels) sont dédoublonnés côté client sur `muId`.
- Fixtures du contrat : `test/fixtures/home_sections.json`,
  `test/fixtures/home_section_page.json`.

---

## Recommandations

| Méthode | Route | Auth | Query / Corps | DTO Flutter |
|---------|-------|------|---------------|-------------|
| `GET` | `/recommendations` | JWT | `?limit=50&offset=0&genre=` | `List<MangaQuickViewDto>` |
| `GET` | `/recommendations/by-genre` | JWT | `?topGenres=5&perGenre=10` | `Map<String, List<MangaQuickViewDto>>` |
| `GET` | `/recommendations/sleepers` | JWT | `?limit=20` | `List<MangaQuickViewDto>` |
| `POST` | `/recommendations/dismissals/:muId` | JWT | `{ reason }` | `DismissalDto` (201) |
| `DELETE` | `/recommendations/dismissals/:muId` | JWT | — | — (204) |
| `GET` | `/recommendations/dismissals` | JWT | — | `List<DismissalDto>` |

### Rejets « pas intéressé / déjà vu »

`reason` est **obligatoire** et vaut `already_read`, `not_interested` ou
`seen_elsewhere` (cf. `DismissalReason.wireValue` — à garder aligné sur l'enum
de l'API). Un titre écarté est retiré de **tous** les chemins de
recommandation côté serveur : liste paginée, sections par genre, pépites,
cold start, et recommandations de la fiche détail.

Codes de retour utiles : `429` quota atteint (60 rejets/heure et par
utilisateur), `404` manga inconnu au rejet ou rejet déjà annulé au retrait.
Un `404` sur le `DELETE` est traité côté app comme un succès — le résultat
voulu est atteint.

⚠️ Après un rejet ou une annulation, **invalider le cache local des
recommandations** (`OfflineCacheService.invalidateRecommendationsCache`) :
la première page est mise en cache 2 h, sinon le titre écarté réapparaît.

---

## Bibliothèque

| Méthode | Route | Auth | Corps | DTO Flutter |
|---------|-------|------|-------|-------------|
| `GET` | `/library` | JWT | — | `List<MangaQuickViewDto>` |
| `GET` | `/library/:muId` | JWT | — | `MangaQuickViewDto` |
| `POST` | `/library` | JWT | `{ muId }` | — |
| `DELETE` | `/library/:muId` | JWT | — | — |
| `PATCH` | `/library/:muId/status` | JWT | `{ readingStatus }` | — |
| `PATCH` | `/library/:muId/chapter` | JWT | `{ readChaptersCount }` | — |
| `PATCH` | `/library/:muId/custom-link` | JWT | `{ customLink }` | — |

---

## Utilisateur

| Méthode | Route | Auth | Corps | DTO Flutter |
|---------|-------|------|-------|-------------|
| `GET` | `/users/profile` | JWT | — | `UserInformationDto` |
| `PATCH` | `/users/name` | JWT | `{ name }` | — |
| `PATCH` | `/users/password` | JWT | `{ currentPassword, newPassword }` | — |
| `DELETE` | `/users` | JWT | — | — |

---

## DTOs Flutter

### `MangaQuickViewDto`
```dart
class MangaQuickViewDto {
  final String muId;
  final String title;
  final String? coverUrl;
  final double? score;
  final ReadingStatus? readingStatus;
  final int? readChaptersCount;
  final String? customLink;

  factory MangaQuickViewDto.fromJson(Map<String, dynamic> json) { ... }
}
```

### `MangaDetailsDto`
```dart
class MangaDetailsDto {
  final String muId;
  final String title;
  final String? description;
  final String? coverUrl;
  final double? score;
  final List<String> genres;
  final List<AuthorDto> authors;
  final List<SeasonChapterDto> chapters;
  final String? releaseStatus;
  final String? customLink;
  final ReadingStatus? readingStatus;
  final int? readChaptersCount;

  factory MangaDetailsDto.fromJson(Map<String, dynamic> json) { ... }
}
```

### `UserInformationDto`
```dart
class UserInformationDto {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;

  factory UserInformationDto.fromJson(Map<String, dynamic> json) { ... }
}
```

### `ReadingStatus` (enum)
```dart
enum ReadingStatus {
  reading,
  completed,
  onHold,
  dropped,
  planToRead;

  String get apiValue => switch (this) {
    reading => 'reading',
    completed => 'completed',
    onHold => 'on_hold',
    dropped => 'dropped',
    planToRead => 'plan_to_read',
  };
}
```

---

## Gestion des erreurs dans HttpService

```dart
try {
  final data = await _httpService.getWithAuthTokens('/api/mangas/trending');
} on SocketException {
  // Mode offline → cache
} on InvalidTokenException {
  // RefreshToken expiré → déconnecter
} catch (e) {
  // Autre erreur → afficher message
}
```

HttpService gère :
- 401 → refresh auto → retry
- Timeout → SocketException
- 4xx/5xx → Exception avec message
- 429 (Throttle) → afficher rate-limit message à l'utilisateur

---

## Clés de cache offline

| Endpoint | Clé cache |
|----------|-----------|
| `GET /mangas/popular + trending + new` | `cached_homepage` |
| `GET /mangas/home/sections` (réponse complète, enveloppe `{cachedAt, data}`) | `cached_home_sections` (préfixe `cached_` → purgé à la déconnexion) |
| `GET /mangas/home/sections/:id` | — (pas de cache par page ; hors ligne, la page 1 retombe sur l'aperçu de `cached_home_sections`) |
| `GET /library` | `cached_library` |
| `GET /mangas/:muId` | `cached_manga_detail_<muId>` |
| `POST /mangas/search` (page 1) | `cached_search_<query>` |
| `GET /users/profile` | `cached_user_info` (TTL 7 jours) |

---

## Évolution multi-clients

Le front Flutter cible Android (actuel), iOS et Web (à venir). L'API doit avoir le domaine web futur dans son `CORS_ORIGINS` whitelist (côté `API-mangaTracker/`). Coordonner les déploiements.
