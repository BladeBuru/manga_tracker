# Spec Technique — Hotfix v0.10.1 (Flutter)

| Champ      | Valeur                          |
|------------|---------------------------------|
| Module     | hotfix-v0-10-1                  |
| Version    | 0.1.0                           |
| Date       | 2026-06-11                      |
| Auteur     | Claude (audits vérifiés)        |
| Statut     | À valider                       |

---

## Architecture

Cinq chantiers dans les features existantes — aucun nouveau BLoC, aucun nouveau service. Un helper partagé (`safe_display_name.dart`) et une constante de lecture (`reading_constants.dart`) sont les seules additions.

## Fichiers impactés (preuves d'audit fichier:ligne)

### US-1 — Autofill

| Fichier | Ligne | Changement |
|---|---|---|
| `lib/features/auth/views/login.view.dart` | 164-178 | Wrapper le contenu du `Form` dans `AutofillGroup` |
| `lib/features/auth/views/login.view.dart` | ~158 | Avant `context.go('/home')` : `TextInput.finishAutofillContext(shouldSave: true);` |
| `lib/features/auth/views/register.view.dart` | équiv. | Mêmes deux changements |

Note : `autofillHints` déjà en place (`auth_form_field.dart:19,123`, `auth_password_field.dart:16-27`, `login.view.dart:235`) — ne pas dupliquer.

### US-2 — Images via proxy stream

| Fichier | Ligne | Changement |
|---|---|---|
| `lib/features/manga/widgets/manga_card.dart` | 150-156 | `useProxy: false` → `true` |
| `lib/core/components/refreshable_manga_image.dart` | 54-57 | Construction URL proxy : ajouter `if (kIsWeb) 'mode': 'stream'` aux query params |
| Tous les usages d'images covers | — | Grep `useProxy: false` + URLs MU directes restantes → tout basculer sur le proxy |

### US-3 — Masque email (defense-in-depth)

| Fichier | Changement |
|---|---|
| `lib/core/utils/safe_display_name.dart` | NEW — `String safeDisplayName(String raw, AppLocalizations l10n)` : si `RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')` match → `l10n.anonymousUser`, sinon `raw` |
| `lib/features/comments/widgets/comment_tile.dart` | :49-50 — passer le nom par `safeDisplayName` |
| Widgets amis / partages / profil public | Grep des affichages de `username`/`displayName` → appliquer le helper |
| `lib/l10n/app_*.arb` ×7 | + clé `anonymousUser` (fr : « Utilisateur anonyme ») |

### US-4 — Suivi de lecture

| Fichier | Ligne | Changement |
|---|---|---|
| `lib/features/reader/utils/reading_constants.dart` | NEW | `const int kReadingEndThresholdPercent = 85;` |
| `lib/features/reader/utils/reading_progress_helper.dart` | 35 | `percentageFromEnd <= 15` → `position >= kReadingEndThresholdPercent` (adapter le JS injecté : raisonner en % de position, plus en % restant) |
| `lib/features/reader/services/scroll_position_service.dart` | 89, 254-257 | `percentage > 95` → `percentage >= kReadingEndThresholdPercent` |
| `lib/features/reader/services/scroll_position_service.dart` | ~314-330 | `maxAttempts = 25` → `50` (timeout images 5 s → 10 s) |
| `lib/features/reader/utils/reading_progress_helper.dart` | 8-69 | JS : si `window.scrollY === 0` et `document.body.scrollHeight <= window.innerHeight`, tenter `window.parent.scrollY` (try/catch cross-origin) ; échec → retourner « unknown » (pas de popup) |

### US-5 — Cache recos front + cold start UX

| Fichier | Ligne | Changement |
|---|---|---|
| `lib/core/services/offline_cache_service.dart` | 317-319 | Supprimer le stub legacy `isCacheExpired()` (grep usages d'abord) |
| `lib/features/manga/services/recommendation.service.dart` | — | Avant fetch : `if (!await cache.isCacheExpiredFor('recommendations', maxHours: 2)) return cached;` |
| `lib/features/recommendations/views/paginated_recommendations_view.dart` | 122-141 | + `Map<int, List<MangaQuickViewDto>> _pageCache` (dedup pagination) ; + bandeau cold start si l'API signale biblio vide (ou heuristique : 0 manga en biblio locale) |
| `lib/l10n/app_*.arb` ×7 | + clés `recommendationsColdStartTitle`, `recommendationsColdStartSubtitle` |

### Investigation D6 — Huawei (pas de fix, diagnostic)

| Fichier | Changement |
|---|---|
| `lib/features/auth/services/auth.service.dart` | Logs diagnostiques temporaires (debugPrint conditionnel, **jamais le contenu des tokens** — uniquement présence/absence/longueur) autour des lectures/écritures secure storage au boot et au refresh |

## Schéma BDD

Aucun (client). Le cache local reste `shared_preferences` via `OfflineCacheService`.

## API consommée

- `GET /mangas/:muId/cover?size=…&mode=stream` (nouveau param, spec API jumelle US-2)
- Aucun autre changement de contrat.

## Tests

1. **Widget test login** : `AutofillGroup` présent dans l'arbre ; hints email/password posés.
2. **Unit test `safeDisplayName`** : `"jean@mail.com"` → « Utilisateur anonyme » ; `"jean.dupont"` → inchangé ; `"j@b"` (pas un email valide) → inchangé.
3. **Unit test seuils** : positions 84/85/86 → sauvegarde/popup conformes à la constante.
4. **Unit test `isCacheExpiredFor`** : metadata vieille de 3 h avec `maxHours: 2` → expiré ; 1 h → valide.
5. **Vérif manuelle croisée** : Android + Chrome, light + dark (règle projet).
