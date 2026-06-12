# Spec Fonctionnelle — manga (detail) [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | manga               |
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
| [RETRO-009](../../adr/RETRO-009-detail-bloc-factory.md) | DetailBloc enregistré en factory (une instance par page) | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

La feature `manga (detail)` expose la fiche complète d'un manga identifié par son `muId`. Elle agrège des données provenant de l'API (`MangaService`), de la bibliothèque personnelle de l'utilisateur (`LibraryService`), de l'état local de lecture (`NewChapterService`, `NewChapterService`), et de la section commentaires (`CommentsSection`). C'est la page la plus riche de l'application en termes de mutations possibles.

---

## Règles métier (déduites du code)

1. **Stale-while-revalidate** : si un cache existe pour le manga, la fiche s'affiche immédiatement avec les données stale (`stale: true`) pendant que l'API est interrogée. Sans cache, un loader est affiché.

2. **Enrichissement bibliothèque** : après chaque chargement réseau ou cache, le BLoC interroge `LibraryService.getReadingStatusByUid` et `getReadChapterByUid` pour fusionner le statut et la progression de lecture dans le DTO. Cet enrichissement est transparent pour la vue.

3. **Ajout automatique à la bibliothèque lors de la progression** : si l'utilisateur coche un chapitre et que le manga n'est pas encore dans sa bibliothèque, il est ajouté automatiquement avec le statut `readLater`.

4. **Retrait automatique si 0 chapitre lu** : si l'utilisateur décoche tous les chapitres (progression ramenée à 0), le manga est retiré automatiquement de la bibliothèque.

5. **Détermination automatique du statut de lecture** :
   - `readChapters == 0` → `readLater` (ou statut courant si défini)
   - `readChapters > 0 && readChapters < totalChapters` → `reading`
   - `readChapters >= totalChapters` : vérification réseau du chapitre suivant via `ChapterCheckService` avant de conclure
     - Chapitre suivant détecté en ligne → `reading` (pas encore à jour)
     - Aucun chapitre suivant + manga terminé (`isCompleted == true`) → `completed`
     - Aucun chapitre suivant + manga en cours → `caughtUp`

6. **Vérification des nouveaux chapitres en arrière-plan** : 3 secondes après le chargement, si un lien personnalisé est défini et que le `muId` courant n'a pas changé, `ChapterCheckService` vérifie le chapitre suivant. Si détecté, une notification locale est envoyée (sous condition de préférence utilisateur).

7. **Notation optimiste** : la note utilisateur (0-10) est mise à jour immédiatement dans le DTO en mémoire avant l'appel API. En cas d'échec API, l'ancienne note est restaurée (rollback).

8. **Notation échelle 0-10, rendu 5 étoiles** : chaque étoile vaut 2 points. Taper une étoile déjà active la remet à 0 (suppression de la note). Seule une note de 0 à 10 est acceptée (hors-plage : ignorée).

9. **Lien personnalisé (custom link)** : le lien pointe vers un site de scan externe. Il doit contenir un numéro de chapitre dans un format reconnu par `ChapterLinkResolver` pour activer la sauvegarde automatique de progression. L'URL doit être valide (`https://` ou `http://`). Un avertissement est affiché si aucun format de chapitre n'est détecté, avec un lien vers la page de sélecteurs personnalisés.

10. **Mode offline** : les actions bibliothèque (ajout, retrait, mise à jour statut, sauvegarde progression) sont exécutées via `LibraryService` qui gère la queue offline. Si offline, `pendingActions` est incrémenté dans l'état et affiché dans la barre d'état. Les mutations custom link ne fonctionnent que si la connexion est disponible.

11. **Partage** : depuis la fiche, l'utilisateur peut partager le manga vers un ami (`ShareMangaSheet`) ou créer un groupe de lecture (`CreateReadingGroupSheet`).

12. **Recommandations en lazy loading** : les recommandations sont chargées à la demande (tap sur le bouton "sparkles"), non au chargement initial. Elles sont mises en cache dans l'état local de la vue (`_mangaRecommendationsCache`). L'API recommendations a un timeout de 18s avec 1 retry ; la liste vide est retournée silencieusement si tout échoue.

13. **Description traduite en arrière-plan** : la description du manga est traduite via `TranslationService` dans la langue de l'application, sans bloquer l'affichage initial. L'utilisateur peut forcer la retraduction via un bouton "refresh".

14. **Chapitres saison/bonus** : si l'API retourne `seasonChapters` ou `bonusChapters`, les chapitres sont groupés en sections collapsibles via `ChapterSectionHelper`. Au-delà de 100 chapitres sans saisons définies, les chapitres sont également regroupés en tranches de 100. En dessous de 100, affichage linéaire dans une seule card.

15. **Téléchargement de chapitres** : accessible depuis le menu du lien personnalisé. Requiert qu'un lien soit défini. Délégué à `ChapterDownloadDialog`.

16. **Lecture offline** : si le chapitre suivant est téléchargé, le bouton "Lire en ligne" redirige vers le lecteur offline au lieu du lecteur WebView.

17. **Lecture partagée** : `SharedReadingSection` est affichée en tête du scroll si l'utilisateur appartient à un groupe de lecture pour ce manga (sinon invisible).

---

## Cas d'usage (déduits)

### CU-001 — Consulter la fiche d'un manga

**Acteur** : Utilisateur connecté  
**Flux** :
1. L'utilisateur navigue vers `/manga/:muId`.
2. Le cache est lu immédiatement s'il existe et affiché avec `stale: true`.
3. L'API `GET /mangas/:muId` est appelée en parallèle.
4. Le résultat est enrichi avec le statut bibliothèque de l'utilisateur.
5. La fiche s'affiche avec : couverture (340px header), genres chips, `DetailInfoCard` (chapitres / note / statut publication / année / auteur / artiste), synopsis pliable (traduit), chapitres groupés, section commentaires.
6. 3 secondes après le chargement, si un custom link est défini, une vérification de nouveaux chapitres est lancée en arrière-plan.

**Résultats alternatifs** :
- Sans connexion et sans cache → `DetailError` avec message "hors ligne".
- Authentification invalide → redirection vers `/login`.

### CU-002 — Ajouter à la bibliothèque

**Acteur** : Utilisateur connecté  
**Précondition** : manga non dans la bibliothèque  
**Flux** :
1. Tap sur le bouton "Ajouter à la bibliothèque" (CTA full-width en bas).
2. `DetailActionInProgress` émis avec le message d'action.
3. `LibraryService.addMangaToLibrary` appelé.
4. `DetailLoaded` émis avec `inLibrary: true`, statut `readLater`, `readChaptersCount: 0`.
5. L'action bar passe en mode "dans la bibliothèque" (status icon + bouton lire en ligne).

### CU-003 — Sauvegarder la progression de lecture

**Acteur** : Utilisateur connecté  
**Précondition** : manga dans la bibliothèque (ou pas, l'ajout est automatique)  
**Flux** :
1. Tap sur un chapitre dans la liste.
2. Si tap sur un chapitre déjà lu → `readChapters = chapterNumber - 1`.
3. Si tap sur un chapitre non lu → `readChapters = chapterNumber`.
4. Si `readChapters == 0` → retrait automatique de la bibliothèque.
5. Si manga pas en bibliothèque → ajout automatique avant la sauvegarde.
6. Le statut de lecture est recalculé automatiquement (cf. règle 5).
7. `DetailLoaded` émis avec les nouvelles valeurs.

### CU-004 — Changer le statut de lecture

**Acteur** : Utilisateur connecté  
**Précondition** : manga dans la bibliothèque  
**Flux** :
1. Tap sur l'icône de statut (action bar, gauche).
2. Sheet avec les 4 statuts : En cours / À lire plus tard / À jour / Terminé.
3. Sélection d'un statut → `UpdateReadingStatus` dispatché.
4. Confirmation snackbar.
5. Bouton "Retirer de la bibliothèque" (action destructive en bas de la sheet).

### CU-005 — Associer un lien de lecture personnalisé

**Acteur** : Utilisateur connecté  
**Précondition** : manga dans la bibliothèque  
**Flux** :
1. Tap sur "Ajouter un lien" (bouton lecture en ligne, sans lien défini).
2. Dialog avec champ URL.
3. `ChapterLinkResolver` analyse l'URL en temps réel pour détecter le format de chapitre.
4. Avertissement si pas de format détecté + lien vers les sélecteurs personnalisés.
5. Validation : URL doit avoir un scheme valide (`http://` ou `https://`).
6. `UpdateCustomLink` dispatché → `LibraryService.updateCustomLink` appelé.

### CU-006 — Noter un manga

**Acteur** : Utilisateur connecté  
**Précondition** : manga dans la bibliothèque (section notation visible uniquement si `inLibrary`)  
**Flux** :
1. Tap sur une étoile (1 à 5, chaque étoile = 2 points sur 10).
2. Mise à jour optimiste immédiate de l'UI.
3. `LibraryService.updateRating` appelé.
4. En cas d'échec : rollback vers l'ancienne note.
5. Retapper la même étoile → remise à 0 (suppression de la note).

### CU-007 — Consulter les recommandations

**Acteur** : Utilisateur connecté  
**Flux** :
1. Tap sur le bouton "sparkles" (icône en bas à droite).
2. Si pas encore chargées : `MangaService.getMangaRecommendations` (timeout 18s, 1 retry).
3. Bottom sheet avec les mangas recommandés (70% hauteur écran).
4. Navigation vers la fiche d'un manga recommandé possible.

### CU-008 — Partager un manga avec un ami

**Acteur** : Utilisateur connecté  
**Flux** :
1. Tap sur l'icône de partage (app bar, droite).
2. Bottom sheet `ShareMangaSheet` (sélection d'un ami).
3. Le manga est ajouté à l'inbox de l'ami.

### CU-009 — Lire en ligne

**Acteur** : Utilisateur connecté  
**Précondition** : lien personnalisé défini  
**Flux** :
1. Tap sur "Lire en ligne".
2. `ChapterLinkResolver.buildUrlForChapter` construit l'URL du chapitre suivant (`lastRead + 1`).
3. Si chapitre téléchargé → lecteur offline (`/manga/:muId/read-offline?chapter=N`).
4. Sinon → lecteur WebView (`/manga/:muId/read`).
5. Au retour sur la fiche, `RefreshMangaDetail` est dispatché.

---

## Dépendances

- `LibraryService` — CRUD bibliothèque, statut, progression, custom link, notation
- `MangaService` — détail manga, recommandations
- `CacheHelperService` — cache des données détail manga (clé `cached_manga_detail_<muId>`, 24h)
- `ConnectivityService` — détection online/offline
- `ChapterCheckService` — vérification HTTP de l'existence d'un chapitre (HEAD + GET fallback)
- `NewChapterService` — persistance locale des nouveaux chapitres (SharedPreferences)
- `NotificationService` — notification locale "nouveau chapitre"
- `NotificationPreferencesService` — préférence activation notifications nouveaux chapitres
- `TranslationService` — traduction de la description
- `LanguageService` — langue courante de l'app
- `DownloadManagerService` — vérification si un chapitre est téléchargé
- `CustomSelectorsService` — patterns URL personnalisés pour `ChapterLinkResolver`
- `CommentsSection` (feature `comments`) — chargée en bas du scroll
- `SharedReadingSection` (feature `sharing`) — en tête du scroll si groupe actif
- `ShareMangaSheet`, `CreateReadingGroupSheet` (feature `sharing`) — depuis l'app bar

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Critère d'affichage des sections saison** : `ChapterSectionHelper.calculateSections` détermine le découpage, mais la logique métier exacte (seuils, règles de nommage des saisons) n'a pas été lue. La section "bonus" semble distincte de la section "saison" mais le critère de séparation n'est pas documenté dans le code lu.
- **Contenu de `userRating` dans la réponse API** : le DTO mappe `userRating` depuis la réponse API, mais il n'est pas clair si l'API renvoie toujours ce champ ou seulement quand le manga est dans la bibliothèque de l'utilisateur courant.
- **Visibilité de la section notation** : visible uniquement si `inLibrary == true`. Mais ce flag est enrichi côté client via `LibraryService` et non renvoyé par l'API détail — nécessite validation.
- **`aggregatedRating` Bayesian** : le DTO contient un champ `aggregatedRating` qui combine note MU globale et note communautaire locale, mais ce champ n'est pas affiché dans les widgets lus. Son usage réel est à confirmer.
- **Timer 3 secondes** : le délai de 3s avant vérification des nouveaux chapitres est un choix opérationnel. Il n'est pas configuré par l'utilisateur. La valeur est-elle adéquate sur réseau lent ?
- **Comportement offline du custom link** : `_onUpdateCustomLink` et `_onDeleteCustomLink` n'ont pas de gestion explicite du mode offline (pas de queue). Si appelé hors ligne, l'erreur est remontée à l'UI. Ce comportement est-il voulu ?
