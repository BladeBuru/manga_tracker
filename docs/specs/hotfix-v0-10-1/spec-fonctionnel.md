# Spec Fonctionnelle — Hotfix v0.10.1 (Flutter)

| Champ      | Valeur                          |
|------------|---------------------------------|
| Module     | hotfix-v0-10-1                  |
| Version    | 0.1.0                           |
| Date       | 2026-06-11                      |
| Auteur     | Claude (audits vérifiés)        |
| Statut     | À valider                       |
| Source     | Bugs prod v0.10.0 + 3 audits Explore |

---

## ADRs

| ADR | Lien avec cette spec |
|-----|----------------------|
| RETRO-018-reading-progress-near-end-gate | Les seuils de détection « fin de chapitre » sont refondus (15/95 → constante unique 85) |
| RETRO-005-stale-while-revalidate | Le cache recos front suit le même pattern stale-while-revalidate avec TTL réel |

---

## Contexte et objectif

Sprint correctif **v0.10.1 côté Flutter**, pendant de `API-mangaTracker/docs/specs/hotfix-v0-10-1/`. Les bugs ont été vérifiés par 3 audits Explore avec preuves fichier:ligne. Deux découvertes clés : (1) le bug « tablette déconnectée » est **innocenté côté API** — l'investigation se poursuit côté client Huawei ; (2) le backend a déjà un cold start recos — le gap nouveaux-utilisateurs est purement UX front.

## Règles métier

1. **L'autofill des gestionnaires de mots de passe fonctionne** sur Android, iOS et Web (login + register).
2. **Aucune image cassée par CORS** sur la version web.
3. **Aucun texte au format email affiché comme nom d'auteur** (defense-in-depth, le fix racine est côté API).
4. **La position de lecture est sauvegardée jusqu'à 85 % de la page** ; au-delà, l'app considère le chapitre « en fin de lecture » et propose la validation.
5. **Les recommandations sont mises en cache 2 h côté client** ; revenir sur la page ne refetch pas systématiquement.
6. **Un nouvel utilisateur (biblio vide) voit les recos cold start** (populaires + pépites) avec un message d'accueil, pas un écran vide.

## User Stories

### US-1 — Autofill login/register
**En tant qu'** utilisateur avec un gestionnaire de mots de passe, **je veux** que mes identifiants se remplissent automatiquement, **afin de** me connecter en un tap.

Critères :
- Formulaire login et register wrappés dans `AutofillGroup`
- `TextInput.finishAutofillContext(shouldSave: true)` appelé après login/register réussi (le gestionnaire propose d'enregistrer)
- Vérifié sur Chrome (Google Password Manager) + Android (service autofill système)

### US-2 — Images visibles sur le web
**En tant qu'** utilisateur web, **je veux** voir les couvertures, **afin de** naviguer normalement.

Critères :
- Toutes les images mangas passent par le proxy backend (`useProxy: true` partout)
- Sur web (`kIsWeb`), l'URL proxy inclut `mode=stream` (cf. spec API US-2)
- 0 erreur CORS dans la console Chrome sur `https://app.bladeburu.com` après navigation Home → Bibliothèque → Détail → Recos

### US-3 — Masquage email (defense-in-depth)
**En tant qu'** utilisateur, **je veux** ne jamais voir d'adresse email comme nom d'auteur, **afin que** les données personnelles restent privées même en cas de donnée legacy.

Critères :
- Tout nom d'affichage matchant le format email est remplacé par la clé ARB `anonymousUser` (7 langues)
- Appliqué dans : commentaires, amis, partages, profils publics

### US-4 — Suivi de lecture fiable
**En tant que** lecteur, **je veux** que ma position soit retenue et que la validation de fin de chapitre se déclenche au bon moment, **afin de** reprendre ma lecture sans friction.

Critères :
- Constante unique `kReadingEndThresholdPercent = 85` remplace les seuils 15 %/95 %
- Position < 85 % → sauvegardée et restaurée à ±5 % (5 essais consécutifs OK)
- Position ≥ 85 % → popup « Avez-vous fini ce chapitre ? » au retour
- Timeout d'attente des images : 10 s (au lieu de 5 s)
- Fallback de lecture du scroll pour les lecteurs en iframe (`window.parent.scrollY`)

### US-5 — Recos : cache front + accueil cold start
**En tant qu'** utilisateur, **je veux** une page Recommandations rapide et accueillante même avec une bibliothèque vide, **afin de** découvrir des mangas dès l'inscription.

Critères :
- TTL réel 2 h via `isCacheExpiredFor('recommendations', maxHours: 2)` ; retour sur la page < 300 ms si cache chaud
- Cache in-memory par page dans la vue paginée (pas de double fetch en scroll)
- Biblio vide → bandeau d'accueil (« Découvre les titres populaires en attendant tes premières lectures ») au-dessus des recos cold start, clés ARB 7 langues
- Stub legacy `isCacheExpired()` supprimé

## Cas d'usage

### CU-001 — Connexion avec gestionnaire de mots de passe
L'utilisateur ouvre le login sur Chrome. Le navigateur propose ses identifiants enregistrés. Il les sélectionne, les champs se remplissent, il se connecte. Après succès, le navigateur propose de mettre à jour l'enregistrement.

### CU-002 — Lecture d'un chapitre en deux fois
L'utilisateur lit jusqu'à 60 % et quitte. À la réouverture, la page se positionne à ~60 %. Il lit jusqu'à 92 % et quitte : la popup « Avez-vous fini ? » s'affiche. « Oui » → chapitre marqué lu.

### CU-003 — Nouvel inscrit découvre les recos
Compte créé, biblio vide. La page Recommandations affiche le bandeau d'accueil + le top communauté et des pépites (cold start backend déjà en place).

## Cas limites

- **Tablette Huawei (investigation D6)** : le bug « déconnexion » est infirmé côté API. Tâche : instrumenter `flutter_secure_storage` (log diagnostique anonymisé lecture/écriture des tokens au boot et au refresh) et tester sur la tablette. Hypothèse : keystore EMUI/HarmonyOS instable sans Google Services → si confirmé, fallback chiffré à concevoir (hors scope de ce sprint, décision après diagnostic).
- **Lecteur dans une iframe** : `window.scrollY` = 0 → fallback `window.parent.scrollY`, sinon désactiver la popup plutôt que produire un faux « fin de chapitre ».
- **Images très lentes (> 10 s)** : restauration du scroll au meilleur effort, position conservée pour la prochaine ouverture.
- **Donnée legacy email malgré la migration API** : le masque front (US-3) garantit l'affichage anonymisé.

## Contraintes

- i18n FIRST : toutes les nouvelles clés ARB dans les 7 langues avant les widgets.
- Tokens design V1 (AppColors/AppSpacing/AppRadius) pour le bandeau cold start.
- Vérification light + dark + Android + Web avant clôture (règle projet).
- Widgets ≤ 150 lignes, services ≤ 300.

## Dépendances

- `docs/specs/auth/` — login/register
- `docs/specs/comments/` — affichage auteur
- `docs/specs/manga/` — images covers
- `docs/specs/recommendations/` — page recos
- `docs/specs/reader/` — suivi de lecture
- **Spec API jumelle** : `API-mangaTracker/docs/specs/hotfix-v0-10-1/` (US-2 dépend du mode stream API)

## Hors scope

- Refonte de la page d'accueil
- Bouton « Lire » direct dans la bibliothèque
- Profil ami enrichi
- Onboarding par choix de genres
- Tracking de lecture web complet (le stub `web_view_web.dart` reste un stub ce sprint)

## Critères d'acceptation globaux

1. Autofill fonctionnel Chrome + Android (test manuel documenté)
2. 0 erreur CORS console après parcours complet sur app.bladeburu.com
3. Restauration scroll ±5 % sur 5 essais, popup fin à ≥ 85 %
4. Retour page recos < 300 ms cache chaud ; bandeau cold start visible sur compte neuf
5. `flutter analyze` 0 erreur ; ARB 7 langues synchronisés (`flutter gen-l10n` OK)
