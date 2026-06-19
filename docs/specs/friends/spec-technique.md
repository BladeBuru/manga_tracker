# Spec Technique — friends

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | friends             |
| Version       | 0.2.0               |
| Date          | 2026-06-19          |
| Source        | Rétro-ingénierie + Sprint responsive/social/stats-v2 |

---

## Architecture du module

Le module suit le pattern BLoC standard du projet avec les couches suivantes :

```
FriendsListPage
  └── BlocProvider<FriendsBloc>
        └── BlocConsumer<FriendsBloc>
              ├── _FriendsScaffold
              └── _FriendsContent (StatefulWidget — gère l'onglet sélectionné)
                    ├── UserSearchField (StatefulWidget — debounce 300ms)
                    ├── FriendsTabSegmented
                    ├── _AcceptedBody  → FriendsSectionCard > FriendListTile
                    └── _PendingBody   → FriendsSectionCard > FriendListTile
```

Le `FriendsBloc` est instancié via `BlocProvider.create` dans `FriendsListPage`
(pas un singleton GetIt). Il est donc recréé à chaque navigation vers la page.
Les instances `FriendsService` et `NotificationService` sont résolues
directement depuis `getIt` dans le constructeur du BLoC (accès statique au
ServiceLocator, pas via injection de constructeur).

Le `NotificationCountsService` est un singleton partagé avec la feature
`sharing`. Il s'occupe du badge global (amis + partages). Le `FriendsBloc`
l'appelle en mode fire-and-forget via `_refreshNotificationsBadge()` pour
décrémenter le badge immédiatement après acceptation/refus.

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/friends/bloc/friends_bloc.dart` | BLoC principal — logique de chargement, recherche, envoi, réponse, suppression, notification locale | ~195 |
| `lib/features/friends/bloc/friends_event.dart` | 5 events : LoadFriends, SearchUsers, SendFriendRequest, RespondToRequest, RemoveFriend | ~46 |
| `lib/features/friends/bloc/friends_state.dart` | 4 états : Initial, Loading, Loaded (avec copyWith), Error | ~71 |
| `lib/features/friends/services/friends.service.dart` | Cache 24h amis acceptés, CRUD amis, recherche utilisateurs | ~183 |
| `lib/features/friends/dto/friend.dto.dart` | FriendshipDto, UserSearchResultDto, FriendshipStatus enum, FriendshipDirection enum | ~94 |
| `lib/features/friends/views/friends_list_page.dart` | Scaffold + BlocConsumer + corps responsive | ~232 |
| `lib/features/friends/widgets/friend_list_tile.dart` | Row d'ami ou demande — variante accept/reject ou menu contextuel | ~172 |
| `lib/features/friends/widgets/user_search_field.dart` | Champ autocomplete + carte résultats | ~331 |
| `lib/features/friends/widgets/friends_tab_segmented.dart` | Sélecteur d'onglets chip-style avec compteur | ~150 |
| `lib/features/friends/widgets/friends_section_card.dart` | Carte section avec label uppercase et dividers | ~79 |
| `lib/core/services/notification_counts_service.dart` | Badge BottomNavBar (partagé friends + sharing) — polling 60s | ~128 |
| `lib/features/friends/views/friend_profile_view.dart` | NEW — Page profil d'un ami : bibliothèque + stats + extras (`FriendProfileExtras`) | — |

---

## Schéma BDD

Pas de base de données embarquée dans le module. Stockage via
`flutter_secure_storage` :

| Clé | Contenu | TTL |
|-----|---------|-----|
| `cached_friends` | JSON de la liste `List<FriendshipDto>` sérialisée manuellement | 24h |
| `cached_friends_at` | ISO8601 timestamp de la dernière écriture | (utilisé pour calculer TTL) |

Le DTO ne déclare pas de `toJson()`. La sérialisation pour le cache est
effectuée inline dans `FriendsService._writeCache()` avec un mapping manuel
des champs.

---

## API / Endpoints

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| `GET` | `/friends` | Liste des amis acceptés | JWT |
| `GET` | `/friends/pending` | Demandes en attente (reçues et envoyées) | JWT |
| `POST` | `/friends/request` | Envoyer une demande (`addresseeId` ou `addresseeUsername`) | JWT |
| `PATCH` | `/friends/:id` | Mettre à jour le statut d'une relation (`{status: "accepted"\|"blocked"}`) | JWT |
| `DELETE` | `/friends/:id` | Supprimer une relation (amitié ou demande) | JWT |
| `GET` | `/friends/search?q=` | Recherche d'utilisateurs (min 2 chars) | JWT |
| `GET` | `/friends/:userId/library` | NEW — Bibliothèque de l'ami (via `FriendsService.getFriendLibrary`) | JWT |

Convention HTTP attendue : `200 OK` ou `201 Created` pour les mutations
réussies. Toute autre réponse est traitée comme une erreur avec throw.

---

## Patterns identifiés

- **BLoC pattern standard** — events/states/bloc en 3 fichiers `part of`.
  Un seul BLoC pour les 3 listes (acceptés + pending + recherche) car elles
  sont couplées (accepter une demande la déplace de pending vers accepté).

- **Stale-while-revalidate unilatéral** — uniquement sur les amis acceptés.
  Le cache expiré est retourné en fallback si le réseau est indisponible,
  mais il n'est pas émis en avance pendant le rechargement réseau (pas de
  double émission "stale puis fresh" contrairement à HomePageBloc).

- **Anti-doublon notification via Set en mémoire** — `_notifiedPendingIds`
  dans FriendsBloc. Initialisation silencieuse au premier load
  (`_lastPendingCount == -1`). Réinitialisé à chaque création du BLoC
  (donc à chaque navigation vers la page Amis).

- **Debounce côté widget** — Le debounce de 300 ms pour la recherche est géré
  dans `_UserSearchFieldState` avec un `Timer`, pas dans le BLoC. La règle
  "min 2 chars" est vérifiée deux fois : une fois dans le widget (pour ne pas
  envoyer l'event) et une fois dans le service (garde-fou).

- **Accès GetIt statique dans le BLoC** — `FriendsBloc` résout ses dépendances
  via `getIt<T>()` directement dans son corps, pas via injection de constructeur.
  Même pattern pour `NotificationService` (instanciation directe `NotificationService()`
  sans ServiceLocator).

- **Invalidation cache pessimiste** — Toute mutation (envoi, acceptation, refus,
  suppression) invalide le cache même si la mutation ne modifie pas la liste
  des amis acceptés (ex: envoi d'une demande sortante).

- **Responsive layout** — `_FriendsScaffold` et `_FriendsContentState` mixent
  `ResponsiveLayoutMixin` pour adapter le padding horizontal et la largeur
  maximale selon les breakpoints (`AppBreakpoints` — `lib/core/theme/app_breakpoints.dart`, 600/800/1200 px, `AppContentWidth` centré à 1100px).
- **Profil ami** — Tap sur un `FriendListTile` (amitié acceptée) navigue vers la route `/friends/:userId`. La page `FriendProfileView` charge la bibliothèque de l'ami via `FriendsService.getFriendLibrary(userId)` et affiche un ensemble d'extras (`FriendProfileExtras`) : stats publiques, mangas en commun, etc.

---

## Décisions techniques documentées ici (non-ADR)

### Rejet modélisé comme suppression

Le refus d'une demande dans la vue utilise `RemoveFriend(f.id)` qui appelle
`DELETE /friends/:id` — pas `PATCH` avec `status: rejected`. Le DTO déclare
`FriendshipStatus.blocked` mais ce statut n'est pas utilisé dans le flux de
rejet visible. Documenter côté API si ce comportement est intentionnel.

### FriendsBloc non enregistré dans GetIt

Contrairement à `HomePageBloc` (lazy singleton) et `DetailBloc` (factory),
`FriendsBloc` est instancié directement dans `BlocProvider.create` au niveau
de la vue. Il est donc recréé à chaque navigation vers la page, ce qui
réinitialise le `Set<int>` anti-doublon et le compteur `_lastPendingCount`.

### Sérialisation cache sans toJson()

`FriendshipDto` n'implémente pas `toJson()`. Le cache est sérialisé via un
mapping manuel dans `_writeCache()`. Si le DTO évolue (ajout de champ),
le cache peut désérialiser silencieusement des valeurs incomplètes.

### NotificationService instancié directement (pas via GetIt)

`FriendsBloc` crée `NotificationService()` directement sans passer par le
ServiceLocator. Idem dans `NotificationCountsService`. Ce pattern brise la
testabilité par mocking et l'isolation plateforme.

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| Aucun fichier de test identifié pour ce module | — | Absent |

La feature `friends` ne dispose d'aucun test unitaire, widget test ou BLoC test
au moment de la rétro-ingénierie. C'est cohérent avec le rapport discovery qui
note que les features récentes (stats, friends, sharing, comments) ne sont pas
couvertes.
