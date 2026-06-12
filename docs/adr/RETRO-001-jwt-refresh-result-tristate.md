# RETRO-001 — Stratégie JWT stateless avec `RefreshResult` tristate

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | auth                |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | AUTH |
| Q1 — Coût de revert > 1j ? | OUI — migrer vers des sessions serveur ou un schéma à token unique nécessite de modifier `AuthService`, `HttpService`, `StorageService`, `StartupPage`, et l'interface backend `/auth/refresh` ; changement transverse à plusieurs couches. |
| Q2 — Non-déductible du code ? | OUI — la distinction intentionnelle `networkError ≠ rejected` (mode offline toléré vs force-login obligatoire) et la règle "5xx = networkError, 401/403 = rejected" sont des décisions architecturales qui ne se voient pas dans `pubspec.yaml` ni dans les configs ; seul le commentaire Dart dans `auth.service.dart` les explicite. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — `StartupPage` (routing conditionnel sur le résultat), `HttpService` (retry 401 avec refresh), et tous les BLoCs authentifiés (home, library, detail) dépendent de ce contrat. |
| Q4 — Casse un invariant si ignoré ? | OUI — un dev qui simplifie `refreshAccessToken()` en retournant un `bool` perd la distinction `networkError/rejected`, laissant des utilisateurs naviguer dans le cache avec une session expirée côté serveur (bug "je vois mes données mais je ne suis plus authentifié"). |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

L'application doit gérer le cas où le token JWT d'accès expire entre deux sessions. La stratégie naïve (refresh = OUI ou NON) ne suffit pas : il faut distinguer l'échec réseau transitoire (l'utilisateur est probablement encore authentifié, le serveur était juste injoignable) du rejet explicite par le serveur (la session est morte, continuer en cache serait tromper l'utilisateur sur son état d'authentification).

## Décision identifiée

`AuthService.refreshAccessToken()` retourne un `enum RefreshResult { success, networkError, rejected }` plutôt qu'un `bool`. Les règles de mapping sont :

- HTTP 201 → `success` (nouveau token reçu, rotation optionnelle du refreshToken)
- HTTP 401 / 403 → `rejected` (session explicitement invalidée côté serveur)
- HTTP 5xx, `SocketException`, `TimeoutException`, token null ou expiré localement → `networkError` (erreur transitoire, l'auth reste plausible)

Un verrou `bool _isRefreshing` + `Completer<RefreshResult>?` sérialise les appels simultanés : si un refresh est déjà en cours, les appelants suivants attendent son résultat plutôt que de déclencher un deuxième appel HTTP.

`StartupPage._attemptAutoLogin()` applique la logique suivante :
- `success` → navigation vers `/home`
- `networkError` → navigation vers `/home` (cache toléré)
- `rejected` → `logout()` + tentative biométrique → `/login`

## Conséquences observées

### Positives
- Le bug "je vois mes données de cache mais je ne suis plus connecté" est explicitement traité : `rejected` force le logout.
- Les utilisateurs en mode avion au démarrage ne sont pas expulsés inutilement (`networkError` → accès cache).
- La rotation de refreshToken côté serveur est supportée silencieusement (le nouveau token est persisté si présent dans la réponse).
- La sérialisation via `Completer` évite les race conditions quand plusieurs BLoCs déclenche un refresh simultanément au réveil de l'app.

### Négatives / Dette
- `AuthService` contient de la logique de connectivité (`getIt<ConnectivityService>()`) ce qui introduit un couplage service-à-service qui contourne l'injection par constructeur.
- Le wrapper `refreshOk()` qui mappe `networkError → true` pourrait induire en erreur un appelant qui ne lit pas les commentaires ; son usage devrait être restreint aux call sites non-auth-critiques.
- De nombreux `debugPrint` avec emoji en production (pas de flag `kDebugMode` systématique).

## Recommandation

Garder. La logique tristate est un invariant de sécurité documenté. Le couplage `AuthService → ConnectivityService` via `getIt` pourrait être atténué en injectant `ConnectivityService` dans le constructeur, mais n'est pas urgent.
