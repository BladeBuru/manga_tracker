# Spec Technique — sharing

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | sharing             |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Retro-ingenierie    |

## Architecture du module

Le module `sharing` suit le pattern BLoC standard du projet avec deux particularites notables :

**Deux BLoCs dans un seul fichier** (`reading_groups_bloc.dart`) : `ReadingGroupsBloc` (liste des groupes) et `ReadingGroupDetailBloc` (detail avec polling). Ce choix de co-localisation est justifie par le couplage fort entre les deux BLoCs (meme DTO, meme service) et par le fait que les events/states sont declares dans les fichiers `part of` correspondants.

**Pas de BLoC pour l'inbox** : la page `InboxPage` est un `StatefulWidget` qui appelle `SharingService` directement sans couche BLoC intermediaire. Ce choix est coherent avec la simplicite de la page (un seul chargement, filtrage local, pas d'etat complexe).

**Enregistrement GetIt** : les deux services sont enregistres comme singletons asynchrones via `init()`. `ReadingGroupsBloc` instancie `getIt<ReadingGroupsService>()` directement dans le constructeur (pas d'injection par parametre).

**Interaction cross-feature** : `NotificationCountsService` (dans `core/services/`) agrege les donnees de `FriendsService` et `SharingService` pour alimenter le badge BottomNavBar — c'est le seul point d'agregation transversale du module.

## Fichiers impactes

| Fichier | Role | Lignes |
|---------|------|--------|
| `lib/features/sharing/bloc/reading_groups_bloc.dart` | 2 BLoCs : liste (ReadingGroupsBloc) + detail avec polling 30s (ReadingGroupDetailBloc) | ~138 |
| `lib/features/sharing/bloc/reading_groups_event.dart` | Events des 2 BLoCs (part of) | ~41 |
| `lib/features/sharing/bloc/reading_groups_state.dart` | States des 2 BLoCs (part of) | ~92 |
| `lib/features/sharing/services/sharing.service.dart` | CRUD shares : envoi, inbox, mark-seen, unseen-count | ~79 |
| `lib/features/sharing/services/reading_groups.service.dart` | CRUD groupes : creer, lister, detail, inviter, quitter, supprimer, findGroupForManga | ~113 |
| `lib/features/sharing/views/inbox_page.dart` | Page inbox (StatefulWidget, grouping date local, filtres locaux) | ~296 |
| `lib/features/sharing/views/reading_groups_list_page.dart` | Page liste des groupes (BlocProvider + BlocBuilder) | ~277 |
| `lib/features/sharing/views/reading_group_detail_page.dart` | Page detail groupe (BlocConsumer, polling, navigation retour signale) | ~177 |
| `lib/features/sharing/dto/share.dto.dart` | DTO MangaShareDto (id, sender, mangaMuId, message, createdAt, seenAt, isNew getter) | ~43 |
| `lib/features/sharing/dto/reading_group.dto.dart` | DTOs ReadingGroupDto + ReadingGroupMemberDto (members, readChapters, customLink) | ~86 |
| `lib/features/sharing/widgets/share_manga_sheet.dart` | Bottom sheet selection amis + message optionnel (StatefulWidget) | ~392 |
| `lib/features/sharing/widgets/create_reading_group_sheet.dart` | Bottom sheet creation groupe + nom + selection amis (StatefulWidget) | ~452 |
| `lib/features/sharing/widgets/shared_reading_section.dart` | Section integree fiche manga : groupe lie au manga courant (FutureBuilder, silencieux si erreur) | ~204 |
| `lib/features/sharing/widgets/inbox_filter_chips.dart` | Chips filtre Toutes/Non lues/Lues avec compteurs | ~(inspecte indirectement) |
| `lib/features/sharing/widgets/inbox_share_tile.dart` | Row de share avec avatar/sender/titre/date/pill NOUVEAU | ~(inspecte indirectement) |
| `lib/features/sharing/widgets/reading_group_list_row.dart` | Row de groupe avec avatars superposes + manga + progression | ~(inspecte indirectement) |
| `lib/features/sharing/widgets/reading_group_hero_card.dart` | Card hero "you vs friend" avec progress bars | ~(inspecte indirectement) |
| `lib/features/sharing/widgets/reading_group_detail_sections.dart` | Sections Progression + Actions de la page detail | ~(inspecte indirectement) |
| `lib/features/sharing/widgets/reading_group_action_row.dart` | Row d'action unitaire (Inviter / Quitter / Supprimer) | ~(inspecte indirectement) |
| `lib/features/sharing/widgets/reading_group_progress_row.dart` | Row de progression par membre | ~(inspecte indirectement) |
| `lib/core/services/notification_counts_service.dart` | Agregateur badge BottomNavBar : polling 60s, anti-doublon notifs locales | ~129 |

## Schemas BDD

Pas de stockage local pour ce module. Toutes les donnees sont fetched depuis l'API REST. Aucun cache local (`OfflineCacheService`) n'est utilise pour les donnees de sharing.

## API / Endpoints

| Methode | Route | Description | Auth |
|---------|-------|-------------|------|
| `POST` | `/sharing/manga/:muId` | Partage un manga avec des amis (`friendIds[]`, `message?`) | JWT |
| `GET` | `/sharing/inbox` | Inbox des shares recus (limit 100, plus recents en premier) | JWT |
| `POST` | `/sharing/inbox/mark-seen` | Marque tous les shares non-vus comme vus, retourne `{updated: int}` | JWT |
| `GET` | `/sharing/inbox/unseen-count` | Compteur shares non-vus, retourne `{count: int}` | JWT |
| `POST` | `/reading-groups` | Cree un groupe (`muId`, `name?`, `inviteFriendIds?`) | JWT |
| `GET` | `/reading-groups` | Liste mes groupes (owner ou membre) | JWT |
| `GET` | `/reading-groups/:id` | Detail d'un groupe + progression membres | JWT |
| `POST` | `/reading-groups/:id/invite` | Invite un ami (`friendId`) — owner uniquement | JWT |
| `DELETE` | `/reading-groups/:id/leave` | Quitter le groupe (transfert ownership si owner avec membres) | JWT |
| `DELETE` | `/reading-groups/:id` | Supprimer le groupe — owner uniquement | JWT |

## Patterns identifies

- **BLoC event-driven** : `ReadingGroupsBloc` et `ReadingGroupDetailBloc` suivent le pattern standard `Bloc<Event, State>` avec `Equatable`.
- **StatefulWidget direct-service** : `InboxPage`, `ShareMangaSheet`, `CreateReadingGroupSheet` acces `SharingService`/`FriendsService` directement sans couche BLoC — choix justifie par la simplicite des flux (pas de cache, pas d'etat partage).
- **Polling via `Timer.periodic`** : `ReadingGroupDetailBloc` demarre un `Timer.periodic(30s)` apres le premier chargement reussi. Il annule le timer dans `close()` et lors d'une suppression reussie. Les erreurs de poll sont silencieuses (etat precedent conserve).
- **FutureBuilder pour le scope utilisateur** : `ReadingGroupsListPage` charge l'ID de l'utilisateur courant via `UserService` dans un `FutureBuilder` pour identifier "soi" dans les listes de membres.
- **Retour de valeur par navigation** : `ReadingGroupDetailPage` fait `context.pop(true)` lors d'une suppression ; le caller (`reading_groups_list_page.dart`) recupere cette valeur via `context.push<bool>(...)` et recharge la liste en consequence.
- **Signal de suppression via state terminal** : `ReadingGroupDetailDeleted` est un state terminal capte par le `BlocConsumer` listener ; il declenche la navigation et le `ScaffoldMessenger` sans que la vue n'ait besoin de logique supplementaire.
- **Anti-doublon notifications en memoire** : `NotificationCountsService` maintient un `Set<int>` d'IDs de shares deja notifies. Ce set est perdu au redemarrage de l'app, ce qui peut provoquer des notifications dupliquees apres un crash ou un redemarrage rapide.
- **findGroupForManga — filtrage client** : `ReadingGroupsService.findGroupForManga(muId)` appelle `getMyGroups()` puis filtre cote client. Pas d'endpoint dedie `/reading-groups?muId=X`.

## Patterns d'integration cross-feature

### SharedReadingSection dans la fiche manga
`SharedReadingSection` est integree dans `late_detail.view.dart` (feature `manga`). Elle appelle `ReadingGroupsService.findGroupForManga()` de maniere silencieuse (erreurs ignorees, widget invisible si pas de groupe). Elle est "legere" : un seul appel au mount, pas de polling.

### ShareMangaSheet et CreateReadingGroupSheet depuis la fiche manga
Les deux sheets sont ouverts via `showModalBottomSheet` depuis des widgets de la feature `manga`. Ils dependent de `FriendsService` (pour la liste d'amis) et de `SharingService`/`ReadingGroupsService` pour les actions.

### NotificationCountsService — agregateur transversal
`NotificationCountsService` est dans `core/services/` car il depend a la fois de `FriendsService` (feature `friends`) et de `SharingService` (feature `sharing`). Il emet un `Stream<int>` consomme par la BottomNavBar pour le badge.

## Configuration du polling

| Composant | Intervalle | Declencheur start | Declencheur stop |
|-----------|-----------|-------------------|-----------------|
| `ReadingGroupDetailBloc` | 30 secondes | Apres `_onLoad` reussi | `close()` du BLoC / suppression reussie |
| `NotificationCountsService` | 60 secondes | `start()` (a l'initialisation de l'app) | `stop()` (au logout) |

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| _(aucun)_ | Les BLoCs sharing, les services, les DTOs et les vues ne sont pas couverts par des tests automatises | Absent |

## Dette technique identifiee

- **Absence totale de tests** : `ReadingGroupsBloc`, `ReadingGroupDetailBloc`, `SharingService`, `ReadingGroupsService` et `NotificationCountsService` n'ont aucun test. Le comportement du polling (demarrage/arret, erreurs silencieuses) et le filtrage local de l'inbox sont non-testes.
- **Anti-doublon non persiste** : le `Set<int> _notifiedShareIds` de `NotificationCountsService` est en memoire uniquement. Apres un redemarrage, les shares deja existants peuvent re-declencher des notifications locales (le premier poll "silencieux" ne protege que le demarrage, pas un redemarrage avec des shares recents non vus).
- **Pas de cache offline** : la feature sharing n'a aucun fallback offline. Si le reseau est indisponible, l'inbox et les groupes affichent une erreur sans contenu cache.
- **findGroupForManga charge tous les groupes** : `ReadingGroupsService.findGroupForManga()` recupere `GET /reading-groups` (tous les groupes) pour filtrer cote client. Si l'utilisateur a de nombreux groupes, cette approche est inefficace. A surveiller si usage intensif.
- **Deux BLoCs dans un fichier** : depassement potentiel des seuils de taille si les deux BLoCs grossissent. Actuellement acceptable (138 lignes) mais a surveiller.
- **`InboxPage` — pas de BLoC** : la page inbox utilise `setState` directement. Si la complexite augmente (pagination, sync temps reel), une migration vers un BLoC sera necessaire.
