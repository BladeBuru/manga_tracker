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
| `GET` | `/mangas/search` | JWT | `?q=...&page=1&limit=20` | `List<MangaQuickViewDto>` |
| `GET` | `/mangas/:muId` | JWT | — | `MangaDetailsDto` |

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
| `GET /library` | `cached_library` |
| `GET /mangas/:muId` | `cached_manga_detail_<muId>` |
| `GET /mangas/search?q=...` | `cached_search_<query>` |
| `GET /users/profile` | `cached_user_info` (TTL 7 jours) |

---

## Évolution multi-clients

Le front Flutter cible Android (actuel), iOS et Web (à venir). L'API doit avoir le domaine web futur dans son `CORS_ORIGINS` whitelist (côté `API-mangaTracker/`). Coordonner les déploiements.
