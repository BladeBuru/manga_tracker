# Spec Fonctionnelle — sharing [DRAFT — a valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | sharing             |
| Version    | 0.1.0               |
| Date       | 2026-06-04          |
| Auteur     | retro-documenter    |
| Statut     | DRAFT               |
| Source     | Retro-ingenierie    |

> **[DRAFT — a valider par le dev]** Cette spec a ete generee par retro-ingenierie
> a partir du code existant. Elle doit etre relue et validee par un developpeur
> qui connait le contexte metier.

---

## ADRs

*Aucun ADR lié.*

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

Le module `sharing` ajoute une couche sociale au-dessus du suivi de manga. Il regroupe deux sous-fonctionnalites distinctes :

1. **Partage puntuel** : un utilisateur peut recommander un manga a un ou plusieurs amis depuis la fiche manga. L'ami recoit le share dans une "inbox" dediee.
2. **Groupes de lecture** : des utilisateurs peuvent former un groupe autour d'un manga specifique pour suivre leur progression respective en quasi-reel.

Ces deux sous-fonctionnalites partagent un badge de notification unifie dans la BottomNavBar (via `NotificationCountsService`).

## Regles metier (deduites du code)

1. On ne peut partager un manga qu'avec des amis confirmes (la liste des destinataires est chargee depuis `FriendsService.getAcceptedFriends()`).
2. Un message optionnel peut accompagner le share (max 280 caracteres, donne par le champ texte du `ShareMangaSheet`).
3. L'inbox affiche les shares recus, limit a 100 entrees, ordonnes du plus recent au plus ancien.
4. Un share est marque "non-vu" (`isNew == seenAt == null`) jusqu'a ce que `markAllSeen()` soit appele.
5. `markAllSeen()` est appele automatiquement a chaque ouverture de la page inbox, puis le badge `NotificationCountsService` est rafraichi en consequence.
6. La page inbox propose trois filtres locaux (cote client) : Toutes, Non lues, Lues. Le filtrage ne declenche pas de requete reseau supplementaire.
7. Les items de l'inbox sont regroupes visuellement par bucket de date relatif : Aujourd'hui, Hier, Cette semaine, Plus tot.
8. Un tap sur un item de l'inbox navigue vers la fiche manga correspondante (`/manga/:muId`).
9. Un groupe de lecture est lie a un manga unique (`mangaMuId`). Il peut avoir un nom optionnel ; si absent, le titre du manga est utilise comme nom d'affichage.
10. La creation d'un groupe requiert l'invitation d'au moins un ami (le bouton "Creer" est desactive tant qu'aucun ami n'est selectionne).
11. La taille maximale d'un groupe est de 10 membres (validation cote serveur, mentionnee dans le commentaire du service).
12. Quitter un groupe alors qu'on en est le proprietaire et qu'il reste d'autres membres transfere l'ownership au membre present depuis le plus longtemps (logique cote serveur).
13. Si le proprietaire est seul dans le groupe et qu'il quitte, le groupe est supprime (logique cote serveur).
14. Seul le proprietaire peut supprimer definitivement un groupe (endpoint `DELETE /reading-groups/:id`, controle cote serveur).
15. Seul le proprietaire peut inviter de nouveaux membres dans un groupe existant (endpoint `POST /reading-groups/:id/invite`, controle cote serveur).
16. La progression de chaque membre dans le groupe correspond au nombre de chapitres lus (`readChapters`). Si `null`, le membre n'a pas encore commence ou le manga n'est pas dans sa bibliotheque.
17. La progression est rafraichie en quasi-reel par un polling automatique toutes les 30 secondes sur la page detail d'un groupe. Les erreurs de poll sont silencieuses (la derniere vue valide est conservee).
18. Le polling s'arrete automatiquement quand la page detail est fermee (via `close()` du BLoC qui annule le `Timer`).
19. La page detail du groupe emet un signal de retour `true` au caller (la liste) si le groupe est supprime, declenchant un rechargement de la liste.
20. La section "Lecture partagee" sur la fiche manga (`SharedReadingSection`) s'affiche uniquement si l'utilisateur appartient a un groupe lie a ce manga. Elle ne fait pas de polling (un seul appel au mount).
21. Le badge de notification BottomNavBar agrege : demandes d'amis en attente + shares non-vus. Il est poll toutes les 60 secondes par `NotificationCountsService`.
22. Le premier poll de `NotificationCountsService` est "silencieux" : les shares existants sont enregistres dans l'anti-doublon sans declencher de notification locale (evite l'inondation au demarrage de l'app).
23. Pour chaque nouveau share detecte entre deux polls, une notification locale est declenchee via `NotificationService.showShareReceivedNotification`.
24. L'anti-doublon des notifications locales est un `Set<int>` d'IDs stocke en memoire (non persiste au redemarrage de l'app).
25. La recherche d'un groupe lie a un manga depuis la fiche manga (`findGroupForManga`) est un filtrage cote client sur la liste de tous les groupes de l'utilisateur — aucun endpoint dedie n'est expose par l'API.

## Cas d'usage (deduits)

### CU-001 — Partager un manga avec des amis
L'utilisateur, sur la fiche d'un manga, ouvre le sheet "Partager ce manga". Il voit la liste de ses amis confirmes. Il en selectionne un ou plusieurs (pastilles de selection visuelles), ajoute un message optionnel, puis appuie sur "Envoyer". Le share est envoye a chaque ami selectionne. Un SnackBar confirme l'envoi.

### CU-002 — Consulter et filtrer l'inbox
L'utilisateur ouvre la page Inbox. Les shares sont charges et tous les shares non-vus sont immediatement marques comme vus cote serveur (badge remis a zero). L'utilisateur peut filtrer par "Non lues / Lues / Toutes" sans appel reseau. Il peut taper sur un share pour naviguer vers la fiche du manga concerne.

### CU-003 — Creer un groupe de lecture
Depuis la fiche d'un manga, l'utilisateur ouvre le sheet "Lire a deux". Il peut saisir un nom de groupe (optionnel), selectionne au moins un ami a inviter, puis appuie sur "Creer". Le groupe est cree et l'utilisateur est dirige vers la page detail du groupe.

### CU-004 — Suivre la progression du groupe
Sur la page detail d'un groupe, l'utilisateur voit la progression de chaque membre (nombre de chapitres lus). Cette vue se met a jour automatiquement toutes les 30 secondes sans action utilisateur.

### CU-005 — Inviter un membre dans un groupe (owner)
Depuis la page detail d'un groupe, le proprietaire peut inviter un nouvel ami via l'action "Inviter". L'ami rejoint le groupe.

### CU-006 — Quitter ou supprimer un groupe
Un membre peut quitter un groupe depuis la page detail (action "Quitter"). Le proprietaire a en plus l'option "Supprimer le groupe". Les deux actions demandent une confirmation.

### CU-007 — Badge notifications fusionnes
L'utilisateur voit dans la BottomNavBar un badge numerique representant le total de ses demandes d'amis en attente et de ses shares non-vus. Ce badge se met a jour toutes les 60 secondes.

## Dependencies

- `features/friends` — `FriendsService.getAcceptedFriends()` et `getPendingRequests()` pour alimenter les pickers et le badge
- `features/manga` (DetailBloc) — surface de declenchement du partage et de la creation de groupe (ShareMangaSheet, CreateReadingGroupSheet, SharedReadingSection integres dans la fiche)
- `core/services/NotificationCountsService` — badge BottomNavBar partage avec `friends`
- `features/manga/services/NotificationService` — notifications locales pour les nouveaux shares
- `core/network/HttpService` — tous les appels API authentifies
- `features/profile/services/UserService` — identification de "soi" parmi les membres d'un groupe

## Zones d'incertitude

> Les points suivants n'ont pas pu etre determines par le code seul :

- La logique de transfert d'ownership (membre present depuis le plus longtemps) est documentee dans un commentaire de `reading_groups.service.dart` mais implementee cote serveur — la semantique exacte (par `joinedAt` ? par ID croissant ?) n'est pas verifiable depuis le code Flutter.
- La limite de 100 entrees pour l'inbox (`limit 100`) est documentee dans un commentaire du service mais non configurable depuis l'app ; verifier si le serveur supporte la pagination pour un futur infinite scroll.
- La limite de 10 membres par groupe est mentionnee dans un commentaire (`max 10 total`) mais la validation n'est pas visible cote Flutter — le serveur rejette la creation si depassee, mais l'UI ne prealerte pas l'utilisateur.
- Il n'y a pas de gestion offline pour cette feature (pas de cache local, pas de queue offline) : comportement attendu lors d'une perte de connexion non specifie dans le code.
- Le `customLink` d'un membre (`ReadingGroupMemberDto.customLink`) est reference dans les DTOs avec une note sur `ChapterLinkResolver.buildUrlForChapter`, mais son utilisation UI dans la page detail n'est pas visible dans les widgets documentes — a valider si cette feature est completement implemented.
