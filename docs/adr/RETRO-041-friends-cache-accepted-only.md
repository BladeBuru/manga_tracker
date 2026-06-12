# RETRO-041 — Cache 24h limité aux amis acceptés, demandes pending toujours fresh

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | friends             |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DATA-MODEL |
| Q1 — Coût de revert > 1j ? | OUI — mettre en cache les pending ou supprimer le cache accepted touche FriendsService (logique TTL + invalidation), FriendsBloc (forceRefresh + fallback stale), NotificationCountsService (qui appelle getPendingRequests directement pour le badge) et la logique de notification locale dans FriendsBloc. Un refactor transverse sur au moins 3 fichiers clés du module et du core. |
| Q2 — Non-déductible du code ? | OUI — la distinction intentionnelle entre "accepted cacheable" et "pending non-cacheable" n'apparaît pas dans pubspec.yaml ni dans les configs. Elle nécessite de comprendre l'invariant métier : le badge de la BottomNavBar doit refléter l'état quasi-temps réel des demandes pending, ce qui exclut tout cache sur cette liste. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — concerne directement la spec friends (FriendsService + FriendsBloc) et la spec sharing/NotificationCountsService qui consomme getPendingRequests() dans son cycle de polling pour agréger le badge global. |
| Q4 — Casse un invariant si ignoré ? | OUI — si un dev applique naïvement un cache aux demandes pending (par analogie avec accepted), le badge de notifications de la BottomNavBar affiche un compteur décalé, et les notifications locales anti-doublon peuvent se déclencher pour des demandes déjà traitées par l'utilisateur. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

La feature friends gère deux types de données de relation asymétriques du
point de vue de la fraîcheur requise :

- **Amis acceptés** : liste stable, peu fréquemment modifiée, consultée en
  lecture pour affichage. Un retard de 24h est acceptable pour l'utilisateur
  (ses amis ne changent pas à la minute). Le cache sert aussi de fallback
  offline-first.

- **Demandes pending** : consommées par le badge BottomNavBar (via
  `NotificationCountsService`) qui poll toutes les 60s. Si les pending étaient
  cachés, le badge serait systématiquement en retard d'au moins 24h, ce qui
  détruirait l'utilité du compteur de notification.

## Décision identifiée

`FriendsService.getAcceptedFriends()` met en cache la liste dans
`flutter_secure_storage` (clés `cached_friends` + `cached_friends_at`) avec un
TTL de 24h. Le cache est retourné en fast-path si frais, et en fallback stale
si le réseau est indisponible.

`FriendsService.getPendingRequests()` ne cache jamais. Tout appel déclenche
une requête réseau. En cas d'erreur, il lève une exception (pas de fallback
stale).

Toute mutation (envoi, acceptation, refus, suppression) appelle
`invalidateCache()` qui supprime les deux clés, forçant un rechargement depuis
l'API au prochain `getAcceptedFriends()`.

## Conséquences observées

### Positives
- Le badge BottomNavBar reflète l'état réel des demandes pending (fraîcheur
  garantie à 60s près via le polling du NotificationCountsService).
- La liste des amis est disponible offline avec un contenu récent (24h max).
- Le coût réseau est réduit : la liste accepted n'est re-fetchée que toutes
  les 24h ou après une mutation.

### Negatives / Dette
- Les demandes pending ne sont jamais disponibles offline. Si le réseau est
  indisponible au chargement, l'onglet "Demandes" est inaccessible (FriendsError).
- Toute mutation invalide le cache accepted même quand la mutation ne modifie
  pas la liste (ex: envoi d'une demande sortante, qui n'ajoute pas encore un
  ami confirmé). Invalidation pessimiste.
- Le DTO ne déclare pas `toJson()` — la sérialisation manuelle dans
  `_writeCache()` doit être maintenue en sync avec l'évolution du DTO.

## Recommandation

Garder. La distinction cacheable/non-cacheable est justifiée par le couplage
avec le badge. Envisager à terme :
1. Ajouter `toJson()` sur `FriendshipDto` pour éliminer le mapping manuel dans
   `_writeCache()`.
2. Invalider le cache accepted uniquement lors des mutations qui modifient
   effectivement la liste accepted (acceptation, suppression), pas lors d'un
   simple envoi de demande.
