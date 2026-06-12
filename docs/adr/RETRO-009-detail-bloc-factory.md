# RETRO-009 — DetailBloc enregistré en factory (une instance par page)

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | manga               |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | DATA-MODEL |
| Q1 — Coût de revert > 1j ? | OUI — passer à un singleton nécessite de retirer `BlocProvider.create` de `DetailBlocView`, de gérer le reset d'état entre navigations successives, et de corriger tous les endroits qui supposent que le BLoC est frais à l'arrivée sur la page. Le champ `_currentMuId` stocké dans l'instance devient partagé entre toutes les pages, rendant les mutations bibliothèque non-déterministes. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml`, `get_it`, et `service_locator.dart` ne documentent pas pourquoi `DetailBloc` est le seul BLoC en factory alors que `HomePageBloc` et `LibraryBloc` sont des lazy singletons. L'intention (éviter les race conditions) est documentée uniquement dans les commentaires du code et le discovery.md. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — impacte `manga (detail)` (spec courante), `library` (mise à jour du statut bibliothèque au retour sur la fiche depuis LibraryView), et tout BLoC futur de type "détail d'entité" qui doit faire le même choix d'isolation. |
| Q4 — Casse un invariant si ignoré ? | OUI — si un dev enregistre `DetailBloc` en lazy singleton, naviguer rapidement de la fiche manga A vers la fiche manga B provoque une race condition : le handler `_onLoadMangaDetail` du manga B reçoit les résultats du cache du manga A (car `_currentMuId` n'a pas encore changé), et les mutations bibliothèque (AddToLibrary, SaveChapterProgress) ciblent potentiellement le mauvais manga. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

L'application permet à l'utilisateur de naviguer rapidement entre fiches manga (deep-link, recommandations, historique). Si le `DetailBloc` était un singleton partagé entre toutes les fiches, un changement de page avant la fin du chargement de la première fiche écraserait l'état de la deuxième avec les données de la première.

Le champ interne `_currentMuId: int?` (stocké dans l'instance BLoC) est utilisé par les handlers de mutation pour savoir quel manga est concerné par une action. En singleton, ce champ est partagé entre deux pages ouvertes simultanément, rendant les appels à `LibraryService` non-déterministes.

## Décision identifiée

`DetailBloc` est enregistré dans GetIt en `registerFactory` (commenté dans `service_locator.dart`). La vue `DetailBlocView` crée elle-même le `BlocProvider` avec `create: (context) => DetailBloc()` et dispatch `LoadMangaDetail(widget.muId)` immédiatement. Le BLoC est donc créé, utilisé, et détruit avec la page qui lui correspond.

Cette décision est explicitement documentée dans le codebase comme "non-négociable" (CLAUDE.md, section "Pattern BLoC").

## Conséquences observées

### Positives
- Isolation totale de l'état entre deux fiches de manga : aucun state leak possible.
- `_currentMuId` et `_chapterCheckTimer` sont propres à chaque instance, éliminant la race condition identifiée.
- Le `StreamSubscription` de connectivité est également propre à chaque instance et annulé à la fermeture via `close()`.

### Négatives / Dette
- Chaque ouverture d'une fiche manga recrée tous les services internes (bien que ceux-ci soient toujours des singletons dans GetIt — seul le BLoC est recréé).
- Contrairement aux singletons, l'état de chargement n'est pas préservé si l'utilisateur revient sur une fiche déjà consultée (rechargement à chaque visite sauf cache stale).
- Les services `ChapterCheckService`, `NewChapterService`, `NotificationService`, et `NotificationPreferencesService` sont instanciés directement dans le constructeur du BLoC (pas via GetIt), ce qui rend leur substitution pour les tests plus difficile.

## Recommandation

Garder — la factory est correcte pour un BLoC de détail qui doit être isolé par instance de page. La dette identifiée (instantiation directe des services sans GetIt) est un candidat pour un refactoring de testabilité, mais pas un motif de changement de stratégie d'enregistrement.
