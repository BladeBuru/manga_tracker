# RETRO-003 — Re-consentement RGPD vérifié à chaque login (article 7)

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | auth, home, profile |

> **Consolidation (2026-06-04)** : cet ADR fusionne l'ancien RETRO-006 (« Re-consentement RGPD bloquant au mount du shell de navigation », découvert côté `home`). RETRO-006 a été retiré. La fusion **lève la zone d'incertitude de RETRO-003** : le re-consentement post-login N'est PAS dans `StartupPage._onLoginSuccess`, il est appliqué au mount du shell `BottomNavbar` (voir « Décision identifiée » ci-dessous). Cet ADR est désormais l'ADR canonique du cycle de consentement RGPD (inscription + re-login). L'umbrella `GdprService` reste documenté séparément en RETRO-029.

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | SECURITY |
| Q1 — Coût de revert > 1j ? | OUI — supprimer ou modifier ce mécanisme implique de toucher `RegisterCubit` (consentement à l'inscription), `StartupPage` (re-consentement post-refresh), `GdprService` (appels `/user/gdpr/consent-status` et `/user/gdpr/consent`), et toute future flow de re-login ; plus d'une journée en comptant les tests de non-régression légaux. |
| Q2 — Non-déductible du code ? | OUI — la règle "vérifier le consentement après chaque refresh réussi, pas seulement à l'inscription" et la règle "erreur silencieuse = ne pas bloquer l'utilisateur" sont des choix architecturaux invisibles dans `pubspec.yaml` et dans les configs. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — auth (inscription + re-login), profile (page "Mes données" expose articles 15/20, lien vers suppression article 17), et tout futur flow d'authentification ajouté au projet doit appeler `getConsentStatus()` après login réussi. |
| Q4 — Casse un invariant si ignoré ? | OUI — un dev qui ajoute un nouveau flow de login (Apple, SSO entreprise) et oublie `getConsentStatus()` après authentification réussie contourne l'obligation légale de re-consentement (RGPD article 7) ; les utilisateurs utiliseraient l'app avec des CGU qu'ils n'ont pas acceptées, exposant l'éditeur à une non-conformité CNIL. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

Le RGPD article 7 impose que le consentement des utilisateurs soit éclairé, libre, et documenté. Lorsque les CGU ou la Politique de confidentialité évoluent, les utilisateurs existants doivent explicitement re-accepter les nouvelles versions avant de pouvoir continuer à utiliser le service. Ce mécanisme doit couvrir non seulement les nouveaux inscrits mais aussi les utilisateurs existants qui reviennent après une mise à jour des documents légaux.

## Décision identifiée

Le consentement est géré en deux points distincts :

**À l'inscription** (`RegisterCubit.submit`) :
1. Guard côté client : `state.canSubmit` (= `acceptedTos && acceptedPrivacy`) bloqué avant tout appel réseau.
2. Après `attemptSignUp()` + auto-login, appel à `GdprService.recordConsent(tosVersion, privacyVersion)` avec les versions courantes récupérées dynamiquement via `getConsentStatus()`.
3. L'échec de l'enregistrement du consentement est silencieux (le compte est créé ; un re-prompt sera fait au prochain login via `/user/gdpr/consent-status`).

**Au re-login / reprise de session** — point d'application réel (ex-RETRO-006) : le check n'est PAS dans `StartupPage._onLoginSuccess`, il est placé dans `BottomNavbar.initState` via `WidgetsBinding.instance.addPostFrameCallback`. Après le premier frame du shell de navigation :
1. `GdprService.getConsentStatus()` est appelé.
2. Si `status.needsAnyAcceptance == true`, un `AlertDialog` est présenté avec `barrierDismissible: false` (non fermable par tap extérieur).
3. Le dialog présente des `CheckboxListTile` non pré-cochés pour chaque document à re-accepter (CGU et/ou Privacy séparément, selon `needsTosAcceptance` / `needsPrivacyAcceptance`).
4. Le bouton « Accepter » n'est activé que quand toutes les cases requises sont cochées.
5. Acceptation → `GdprService.recordConsent(tosVersion, privacyVersion)`.
6. Refus → `AuthService.logout()` + `context.go('/login')` (article 7 RGPD : l'alternative au consentement est la déconnexion, pas la suppression de compte forcée).

`GdprService.getConsentStatus()` retourne `null` en cas d'erreur réseau, et la règle est « null = OK, ne pas bloquer » — l'utilisateur n'est pas pénalisé par un problème réseau temporaire.

**Composant dédié** : `ConsentCheckbox` — cases non pré-cochées (interdiction explicite de pré-cocher un consentement RGPD), avec lien cliquable vers le document légal.

**Alternatives écartées pour le point de contrôle re-login** : (1) au login dans `AuthService`/`LoginCubit` ; (2) dans un redirect guard `go_router` sur les routes protégées ; (3) au mount du shell `BottomNavbar` — **option 3 retenue**.

## Conséquences observées

### Positives
- Conformité RGPD article 7 dès l'inscription.
- Les versions CGU/Privacy sont récupérées dynamiquement depuis l'API (pas hardcodées côté client), permettant au backend de déclencher un re-consentement sans mise à jour de l'app.
- L'erreur silencieuse à l'inscription évite de bloquer la création de compte pour un problème réseau sur un endpoint non-critique.

### Négatives / Dette
- Le check re-login est placé dans `BottomNavbar` (couche UI), pas dans une couche service/middleware. Un futur refactoring `go_router` (ShellRoute) devra migrer cette logique vers un redirect guard pour rester cohérent avec l'architecture de navigation.
- Le check n'est effectué qu'au mount de `BottomNavbar` — pas re-vérifié si l'utilisateur laisse l'app ouverte plusieurs jours et que les CGU changent entre-temps.
- Si `GdprService.recordConsent()` échoue (erreur réseau), un `SnackBar` d'erreur est affiché mais l'utilisateur reste connecté et peut naviguer — le consentement n'a pas été persisté côté serveur (pas de retry / queue offline).
- `ConsentCheckbox` a des paddings et couleurs partiellement hardcodés (non-conformes aux tokens `AppSpacing`/`AppColors`).

## Recommandation

Garder le mécanisme (consentement à l'inscription + re-consentement bloquant au mount du shell). Points à adresser :
- Lors de la migration vers un `ShellRoute` go_router, migrer le check `BottomNavbar` vers un redirect guard au niveau du router plutôt que dans la couche widget.
- Rendre l'échec de `recordConsent` plus robuste (retry ou queue offline).
- Tout nouveau flow de login (Apple, SSO) doit garantir que le passage par le shell `BottomNavbar` (donc le check de consentement) reste obligatoire — ou répliquer le contrôle.

> **Note audit** : le constat C-1 (« `getConsentStatus()` absent de `StartupPage._onLoginSuccess` ») est requalifié par cette consolidation — le contrôle existe bien, mais au mount du shell `BottomNavbar`. Reste à confirmer qu'aucun chemin de navigation post-login ne contourne le shell.
