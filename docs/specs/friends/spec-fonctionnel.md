# Spec Fonctionnelle — friends [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | friends             |
| Version    | 0.1.0               |
| Date       | 2026-06-04          |
| Auteur     | retro-documenter    |
| Statut     | DRAFT               |
| Source     | Rétro-ingénierie    |

> **[DRAFT — à valider par le dev]** Cette spec a été générée par rétro-ingénierie
> à partir du code existant. Elle doit être relue et validée par un développeur
> qui connaît le contexte métier.

---

## ADRs

| ADR | Titre | Statut |
|-----|-------|--------|
| [RETRO-041](../../adr/RETRO-041-friends-cache-accepted-only.md) | Cache 24h limité aux amis acceptés, demandes pending toujours fresh | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

Le module `friends` implémente le réseau social de Manga Tracker. Il permet à
un utilisateur authentifié de gérer ses relations d'amitié : trouver d'autres
utilisateurs par pseudo, leur envoyer une demande, accepter ou refuser les
demandes reçues, supprimer une amitié existante. Le module alimente également
le badge de notifications de la barre de navigation inférieure, et déclenche
des notifications locales à chaque nouvelle demande reçue.

---

## Règles métier (déduites du code)

1. **Seuil de recherche** : la recherche d'utilisateurs ne se déclenche que si
   la requête comporte au moins 2 caractères après trim. En dessous de ce
   seuil, la liste de résultats est vidée localement sans appel serveur.

2. **Cache des amis acceptés (24h)** : la liste des amis confirmés est mise en
   cache dans `flutter_secure_storage` pendant 24 heures. Lors d'un
   chargement sans `forceRefresh`, le cache est retourné s'il est encore
   frais. En cas d'erreur réseau, le cache expiré (stale) est retourné en
   fallback plutôt qu'une erreur.

3. **Pas de cache pour les demandes pending** : les demandes reçues
   (`/friends/pending`) sont toujours chargées depuis le serveur pour
   refléter l'état en quasi-temps réel (impact direct sur le badge).

4. **Invalidation du cache après toute mutation** : chaque opération qui
   modifie l'état d'une relation (envoi, acceptation, refus, suppression)
   invalide le cache des amis acceptés.

5. **Auto-acceptation côté serveur** : si un utilisateur A envoie une demande
   à l'utilisateur B qui avait déjà une demande en attente vers A, le serveur
   peut retourner un statut `accepted` directement. Dans ce cas, le BLoC
   ajoute l'ami directement dans la liste `accepted` sans attendre un rechargement.

6. **Direction de la relation** : chaque `FriendshipDto` porte une direction
   (`sent` ou `received`) du point de vue de l'utilisateur courant. Seules
   les demandes `received + pending` sont affichées dans l'onglet "Demandes"
   et potentiellement notifiées.

7. **Notifications locales anti-doublon (premier load silencieux)** : au
   premier chargement des demandes pending après démarrage, tous les IDs
   existants sont enregistrés dans un `Set` en mémoire sans déclencher de
   notification. Les notifications ne sont déclenchées qu'à partir du
   second load, uniquement pour les IDs absents du Set — évitant d'inonder
   l'utilisateur à chaque démarrage.

8. **Badge BottomNavBar décrementé sans attendre le poll** : quand
   l'utilisateur accepte ou refuse une demande, le BLoC appelle
   `NotificationCountsService.refresh()` immédiatement pour mettre à jour
   le badge sans attendre le prochain cycle de polling (60s).

9. **Rejet modélisé comme suppression** : dans la vue, le rejet d'une
   demande en attente déclenche l'event `RemoveFriend` (suppression de la
   relation), pas `RespondToRequest(blocked)`. Il n'y a pas d'appel
   `PATCH /friends/:id` avec statut `rejected` — c'est un `DELETE` direct.

10. **Affichage du nom** : le nom affiché (`displayName`) est le
    `otherDisplayName` s'il est non nul et non vide, sinon l'`otherUsername`
    (fallback). Même logique pour `UserSearchResultDto.effectiveDisplayName`.

---

## Cas d'usage (déduits)

### CU-001 — Charger la page Amis
L'utilisateur ouvre la page Amis. Le BLoC émet `FriendsLoading`, charge en
parallèle la liste des amis acceptés (cache ou API) et les demandes pending
(API toujours). L'état passe à `FriendsLoaded`. Le badge et les notifications
sont mis à jour si de nouvelles demandes sont détectées.

### CU-002 — Rechercher un utilisateur pour l'ajouter
L'utilisateur saisit au moins 2 caractères dans le champ de recherche. Après
un debounce de 300 ms, l'event `SearchUsers` est envoyé. Les résultats
s'affichent dans une carte en dessous du champ. Si le champ est vidé ou
contient moins de 2 caractères, la liste de résultats est effacée.

### CU-003 — Envoyer une demande d'amitié
L'utilisateur tape sur un résultat de recherche. L'event `SendFriendRequest`
est envoyé. L'utilisateur disparaît des résultats de recherche. Si le serveur
confirme une amitié (auto-acceptée), l'ami est ajouté directement à la liste
`accepted`. Un snackbar confirme l'envoi.

### CU-004 — Accepter une demande reçue
L'utilisateur voit la demande dans l'onglet "Demandes" et appuie sur
"Accepter". L'event `RespondToRequest(accepted)` est envoyé. La demande
quitte la liste `pending` et l'ami est ajouté à `accepted`. Le badge est
rafraîchi immédiatement.

### CU-005 — Refuser une demande reçue
L'utilisateur appuie sur "Refuser". L'event `RemoveFriend` est envoyé,
supprimant la relation côté serveur. La demande disparaît de la liste
`pending`. Le badge est rafraîchi.

### CU-006 — Supprimer un ami
L'utilisateur appuie sur le menu `more_horiz` d'un ami confirmé et choisit
"Supprimer". L'event `RemoveFriend` est envoyé. L'ami disparaît de la liste
`accepted`.

### CU-007 — Pull-to-refresh
L'utilisateur tire la liste vers le bas. L'event `LoadFriends(forceRefresh: true)`
est envoyé, court-circuitant le cache pour recharger depuis l'API.

### CU-008 — Recevoir une nouvelle demande en arrière-plan
Le `NotificationCountsService` (poll 60s) détecte un nouveau `pending` dans
l'inbox. Le `FriendsBloc` déclenche une notification locale (via
`NotificationService.showFriendRequestNotification`) si l'ID n'a pas déjà
été notifié. Le badge de la BottomNavBar est mis à jour.

---

## Dépendances

- `FriendsService` — cache + endpoints `/friends/*`
- `NotificationCountsService` (core) — badge BottomNavBar, polling 60s
- `NotificationService` (manga/services) — notifications locales
- `HttpService` (core) — transport HTTP authentifié
- `StorageService` (core) — cache sécurisé (`flutter_secure_storage`)
- `AppEmptyState`, `AppErrorState` (core/components) — états vides/erreur
- `AppAvatar` (core/components) — avatar utilisateur
- `AppColors`, `AppBreakpoints`, `ResponsiveLayoutMixin` (core/theme) — design system

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :
- Le serveur supporte-t-il un statut `rejected` distinct de la suppression ?
  Le code utilise `DELETE` pour les refus mais le DTO déclare `FriendshipStatus.blocked`.
  La sémantique exacte de `blocked` côté API n'est pas visible dans le client.
- Les demandes envoyées (`sent`) sont-elles visibles quelque part dans l'UI ?
  Le DTO porte `direction: sent` mais l'onglet "Demandes" ne filtre que les
  `received`. Les demandes sortantes semblent absentes de l'UI.
- La limite de résultats pour la recherche (`/friends/search?q=`) est fixée
  côté serveur ; la borne max n'est pas visible dans le client.
- Le `Set<int> _notifiedPendingIds` est en mémoire seulement : toute
  notification non vue avant un redémarrage de l'app sera re-déclenchée au
  prochain démarrage sauf si elle est présente dans le premier poll silencieux.
  Cette fenêtre de temps entre démarrage et premier poll est une zone
  d'ambiguïté.
