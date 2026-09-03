# VERSIONNING — auth

| Version | Date | Artefact/Composant | Changement | Auteur |
|---------|------|--------------------|------------|--------|
| 0.1.0 | 2026-06-04 | Module complet | Documentation initiale (rétro-ingénierie) | Rétro |
| 0.2.0 | 2026-09-04 | `session_expired.exception.dart`, `offline_cache_purge.dart`, `auth.service.dart` | Correctif mode hors ligne : `SessionExpiredException` (credentials absents sans verdict serveur), `purgeUserScopedCache()` appelé sur logout/changement de compte uniquement (pas sur `clearSessionTokens()`) | fix/offline-cache |
