# Spec Fonctionnelle — home [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | home                |
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
| [RETRO-005](../../adr/RETRO-005-stale-while-revalidate.md) | Stratégie cache stale-while-revalidate sur la HomePage | Documenté (rétro) |
| [RETRO-003](../../adr/RETRO-003-gdpr-consent-check-at-every-login.md) | Re-consentement RGPD vérifié à chaque login (point d'application : mount du shell BottomNavbar) | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

La feature `home` est le point d'entrée principal de l'application après authentification. Elle remplit deux rôles distincts :

1. **Shell de navigation** : `BottomNavbar` héberge un `PageView` à 4 onglets (Accueil, Bibliothèque, Recherche, Mon compte) et gère les responsabilités transverses au démarrage (vérification RGPD, démarrage du polling de notifications).

2. **Page d'accueil** : `HomePageBlocView` affiche les sections de découverte de mangas (tendances, populaires, nouveautés), un carrousel de recommandations personnalisées, et les infos utilisateur (pseudo, statut de vérification email).

## Règles métier (déduites du code)

1. **Affichage immédiat depuis le cache** : si des données en cache existent au chargement, elles sont affichées immédiatement avec le drapeau `isStale = true`, avant même que les requêtes réseau ne se terminent.

2. **Chargement parallèle des 4 sections** : populaires, nouveaux, tendances et infos utilisateur sont chargés en parallèle via `Future.wait`. Les recommandations sont chargées séparément après (graceful degradation si erreur).

3. **Fallback offline-first** : si toutes les requêtes réseau échouent, le BLoC émet le cache existant avec `isOffline = true` et `isStale = true`. Si le cache est vide ET le réseau injoignable, un état d'erreur avec `isOffline = true` est émis.

4. **Reconnexion automatique** : `ConnectivityService` est écouté — un retour en ligne déclenche un rechargement automatique (via `home_page.dart`).

5. **Détection `InvalidCredentialsException`** : si une requête retourne une erreur d'authentification, l'utilisateur est redirigé vers `/login` (via `BlocConsumer.listener` dans `HomePageBlocView`).

6. **Vérification email différée** : si `userInfo.emailVerified == false` au chargement, un second fetch forcé (`forceRefresh: true`) est effectué pour détecter une vérification externe (lien cliqué depuis un autre navigateur). Le banner "Vérifiez votre email" disparaît dès que le statut devient `true`.

7. **Recommandations avec graceful degradation** : les recommandations sont limitées à 5 dans le carrousel de la home. En cas d'erreur, la liste reste vide sans bloquer le reste du chargement. En mode offline, si la liste est vide, la section recommandations est masquée.

8. **Re-consentement RGPD bloquant** : au mount du shell (`BottomNavbar.initState`), `GdprService.getConsentStatus()` est vérifié. Si `needsAnyAcceptance == true`, un dialog modal non-fermable est présenté. L'utilisateur peut accepter (les versions sont enregistrées via `GdprService.recordConsent`) ou refuser (déconnexion forcée via `AuthService.logout` + redirection `/login`).

9. **Badge de notifications** : `NotificationCountsService` démarre un polling lors du mount de `BottomNavbar` et expose un `Stream<int>` qui alimente le badge sur l'onglet "Mon compte" (pending friend requests + unread shares).

10. **Filtre de liste** : trois onglets de filtre (Tendances / Populaires / Nouveautés) permutent la liste affichée. Le filtre par défaut est Tendances (index 0).

11. **Pull-to-refresh** : un `RefreshIndicator` sur `HomePageBlocView` déclenche l'event `RefreshHomePage` (alias de `LoadHomePage`).

12. **Deux implémentations coexistantes** : `home_page.dart` (`StatefulWidget` + `FutureBuilder` via `CacheHelperService` direct) et `homepage_bloc_view.dart` (BLoC event-driven) coexistent dans le code. La version BLoC est celle utilisée dans le `PageView` via `BottomNavbar`.

## Cas d'usage (déduits)

### CU-001 — Chargement initial avec cache disponible
L'utilisateur ouvre l'app avec un cache existant. L'état `HomePageLoaded(isStale: true)` est émis immédiatement avec les données du cache, puis remplacé par `HomePageLoaded(isStale: false)` une fois les requêtes réseau terminées. L'utilisateur perçoit un affichage instantané.

### CU-002 — Chargement initial sans cache (premier lancement)
Aucun cache disponible. L'état `HomePageLoading` est émis, un `CircularProgressIndicator` s'affiche, puis `HomePageLoaded` est émis à la fin du `Future.wait`.

### CU-003 — Perte de connexion pendant la navigation
L'API est injoignable. Le BLoC émet le cache avec `isOffline: true` — le `OfflineBanner` s'affiche en haut de la page. Si le cache est vide, `HomePageError(isOffline: true)` est émis avec un bouton "Réessayer".

### CU-004 — Retour en ligne
`ConnectivityService` émet `true`. `loadResources()` est rappelé dans `home_page.dart`. (Dans `HomePageBlocView`, l'écoute connectivité n'est pas directement câblée — voir Zones d'incertitude.)

### CU-005 — Session expirée
Une requête retourne `InvalidCredentialsException`. Le `listener` du `BlocConsumer` intercepte `HomePageError(message: 'InvalidCredentials...')` et redirige vers `/login`.

### CU-006 — Re-consentement RGPD requis
Au mount de `BottomNavbar`, `GdprService.getConsentStatus()` retourne `needsAnyAcceptance: true`. Un dialog bloquant s'affiche avec des cases à cocher non pré-cochées. Si l'utilisateur accepte, `GdprService.recordConsent(tosVersion, privacyVersion)` est appelé. Si l'utilisateur refuse, `AuthService.logout()` est appelé et l'app redirige vers `/login`.

### CU-007 — Email non vérifié
`UserDto.emailVerified == false` dans l'état chargé. `VerifyEmailBanner` est rendu visible. Lors du chargement, un second fetch forcé est tenté silencieusement pour détecter une vérification externe.

## Dépendances

- `MangaService` — endpoints `/trending`, `/popular`, `/new`
- `RecommendationService` — endpoint recommandations personnalisées (limite 5)
- `UserService` — informations et statut de vérification email de l'utilisateur connecté
- `CacheHelperService` — wrapper stale-while-revalidate autour des requêtes API
- `ConnectivityService` — stream de connectivité réseau
- `GdprService` — statut de consentement et enregistrement côté backend
- `AuthService` — logout en cas de session expirée ou refus RGPD
- `NotificationCountsService` — polling du badge notifications (pending friends + unread shares)
- `LibraryBloc` — fourni via `BlocProvider` dans le `PageView` pour l'onglet Bibliothèque
- `HomePageBloc` — singleton lazy (GetIt)

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Double implémentation `home_page.dart` / `homepage_bloc_view.dart`** : `home_page.dart` est un `StatefulWidget` avec `FutureBuilder` qui gère lui-même la connectivité et le cache. `homepage_bloc_view.dart` est la version BLoC utilisée dans `BottomNavbar`. La première semble être une version antérieure non supprimée. Valider si `home_page.dart` est encore utilisé quelque part ou peut être retiré.

- **Reconnexion automatique dans `HomePageBlocView`** : `home_page.dart` écoute `connectivityStream` pour relancer `loadResources()` au retour en ligne. `HomePageBlocView` ne comporte pas cette écoute directement — le rechargement auto en ligne passe-t-il par un autre mécanisme (ex. `ConnectivityBloc`) ou est-il absent de la version BLoC ?

- **Recommandations en mode offline** : le cache des recommandations n'est pas explicitement sauvegardé dans `CacheHelperService` (ni dans `HomeCacheSnapshot`). Valider si les recommandations sont disponibles offline ou simplement masquées.

- **`HomePageActionInProgress`** : ce state est émis lors du rechargement d'une section isolée (via `LoadPopularMangas` etc.) mais les handlers correspondants semblent peu utilisés dans la vue — valider l'usage réel de ces events granulaires.
