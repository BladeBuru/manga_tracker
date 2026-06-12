# Spec Fonctionnelle — search [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | search              |
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

Aucun ADR RETRO n'a été créé pour cette feature. L'analyse de la politique ADR v2.3.0 a conclu que toutes les décisions techniques identifiées (debounce, historique local, StatefulWidget, genres hardcodés) ne passent pas la checklist obligatoire (principalement Q3 — impact confiné au seul module search). Ces décisions sont documentées en `spec-technique.md`.

---

## Contexte et objectif

Le module `search` expose une page de recherche permettant à l'utilisateur de trouver des mangas par titre ou par genre. Il combine trois modes d'interaction :
- saisie libre avec appel différé à l'API,
- réutilisation de termes depuis un historique local persisté,
- exploration par genres populaires prédéfinis.

La page est accessible depuis la barre de navigation inférieure de l'application.

## Règles métier (déduites du code)

1. La recherche n'est déclenchée qu'après une inactivité de 800 ms suivant la dernière frappe (debounce). Pendant ce délai, aucun appel réseau n'est effectué.
2. Toute requête soumise est automatiquement ajoutée en tête de l'historique local avant l'affichage des résultats.
3. Si un terme est déjà présent dans l'historique, il est déplacé en tête (pas de doublons).
4. L'historique est limité à 10 entrées. L'entrée la plus ancienne est supprimée dès que la limite est dépassée.
5. L'historique est chargé au montage de la page et sauvegardé à la fermeture (dispose).
6. Une query vide annule le debounce en cours et efface les résultats affichés, retournant au mode "browse".
7. Les genres populaires sont affichés uniquement en mode "browse" (pas de résultats actifs). Cliquer sur un genre déclenche une recherche sur son libellé.
8. L'utilisateur peut supprimer une entrée de l'historique individuellement ou effacer l'intégralité de l'historique.
9. Le bouton "Effacer" de l'historique n'est visible que si l'historique est non vide.

## Cas d'usage (déduits)

### CU-001 — Recherche par saisie libre

L'utilisateur saisit un terme dans la barre de recherche. Après 800 ms d'inactivité, l'application appelle l'API, ajoute la query à l'historique et affiche la liste de résultats via `HomepageMangaList`. La barre de recherche adopte une bordure colorée (couleur primaire du thème) dès qu'un caractère est saisi.

### CU-002 — Recherche via l'historique

L'utilisateur tape sur un terme de l'historique. La barre de recherche est peuplée avec ce terme, le curseur placé en fin de texte, et la recherche est immédiatement déclenchée (sans attendre le debounce).

### CU-003 — Recherche via un genre populaire

L'utilisateur tape sur un chip de genre dans la section "Genres populaires". Le comportement est identique à CU-002 : la barre est peuplée et la recherche déclenchée immédiatement.

### CU-004 — Suppression d'un terme de l'historique

L'utilisateur tape sur l'icône "×" à droite d'un terme. Le terme disparaît de la liste localement (setState immédiat) et la suppression est persistée en arrière-plan dans `SharedPreferences`.

### CU-005 — Effacement complet de l'historique

L'utilisateur tape sur "Effacer" dans l'en-tête de la section historique. Tous les termes disparaissent de la liste localement et la clé `search_history` est supprimée de `SharedPreferences`.

### CU-006 — Retour au mode browse

L'utilisateur tape sur l'icône "×" de la barre de recherche (bouton clear). La query est effacée, le debounce annulé, et la page revient en mode "browse" (historique + genres populaires).

## Dépendances

- `MangaService.searchForMangas(query)` — appel POST `/mangas/search` (module `manga`), retourne `Future<List<MangaQuickViewDto>>`
- `SearchHistoryService` — persistance de l'historique via `SharedPreferences`
- `HomepageMangaList` — widget de rendu des résultats (module `home`)
- `AppLocalizations` — clés i18n : `searchTitle`, `searchPlaceholder`, `searchHistoryTitle`, `searchEmptyHistory`, `searchPopularGenres`, `clear`
- Tokens du design system : `AppColors`, `AppSpacing`, `AppRadius`

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- La discovery mentionne un debounce de 500 ms mais le code implémente 800 ms. La valeur de référence à documenter et la raison de l'écart ne sont pas claires.
- Les 8 genres populaires (`Shounen`, `Seinen`, `Romance`, `Action`, `Aventure`, `Drama`, `Fantasy`, `Sci-Fi`) sont hardcodés dans le StatefulWidget. Il n'est pas établi si cette liste est figée par conception ou provisoire en attendant un endpoint API dédié.
- La gestion d'erreur lors de la recherche API n'est pas explicite dans ce module : `HomepageMangaList` reçoit un `Future` qui peut rejeter — le traitement d'erreur dépend de l'implémentation interne de `HomepageMangaList`.
- Il n'est pas clair si l'historique doit être partagé entre sessions utilisateur (actuellement lié au device, pas au compte).
- Le comportement offline n'est pas géré dans ce module (pas de cache réseau pour les résultats de recherche).
