# Spec Fonctionnelle — Auth [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | auth                |
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

## ADRs

| ADR | Titre | Statut |
|-----|-------|--------|
| [RETRO-001](../../adr/RETRO-001-jwt-refresh-result-tristate.md) | Stratégie JWT stateless avec `RefreshResult` tristate | Documenté (rétro) |
| [RETRO-002](../../adr/RETRO-002-google-signin-dual-strategy.md) | Google Sign-In : idToken natif sur mobile, OAuth WebView sur web | Documenté (rétro) |
| [RETRO-003](../../adr/RETRO-003-gdpr-consent-check-at-every-login.md) | Re-consentement RGPD vérifié à chaque login (article 7) | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

Le module `auth` gère l'intégralité du cycle de vie d'authentification de l'utilisateur dans Manga Tracker. Son objectif est de permettre à l'utilisateur d'accéder à l'application de manière sécurisée via plusieurs mécanismes (email/mot de passe, Google, biométrie) tout en garantissant la persistance transparente de sa session (JWT avec refresh automatique), la conformité RGPD à l'inscription et au re-login, et une expérience fluide au démarrage de l'app (auto-login ou redirection vers login).

---

## Règles métier (déduites du code)

1. **Inscription bloquée sans double consentement** : le formulaire d'inscription ne peut pas être soumis si l'utilisateur n'a pas coché explicitement les deux cases "J'accepte les CGU" et "J'accepte la Politique de confidentialité" (cases non pré-cochées). Le consentement est enregistré en base via l'API après l'auto-login post-inscription.

2. **Consentement enregistré avec versions dynamiques** : les versions des documents légaux (CGU, Privacy) sont récupérées depuis l'API au moment de l'enregistrement — jamais hardcodées côté client. Cela permet au backend de déclencher un re-consentement sans mise à jour de l'app.

3. **Session JWT stateless avec distinction réseau/rejet** : le refresh de token distingue trois cas — succès (nouveau token reçu), erreur réseau temporaire (l'utilisateur peut accéder au cache en mode offline), rejet explicite du serveur (la session est morte, l'utilisateur DOIT être renvoyé vers le login).

4. **Auto-login au démarrage selon la validité du token** : au démarrage, si l'access token est encore valide, l'utilisateur est connecté directement. Si expiré mais refresh token valide, un refresh est tenté. Si le refresh échoue avec rejet serveur, les tokens sont purgés et l'utilisateur est redirigé vers `/login`.

5. **Vérification des mises à jour avant l'auth** : sur mobile, la vérification de mise à jour GitHub Releases s'exécute avant toute tentative d'authentification — pour permettre à l'utilisateur de mettre à jour l'app même si l'auth est cassée.

6. **Biométrie opt-in avec prompt une seule fois** : après un premier login email réussi, si l'appareil supporte la biométrie et que l'utilisateur n'a jamais défini de préférence, un dialog propose l'activation. La biométrie n'est jamais activée automatiquement. La désactivation conserve les identifiants chiffrés pour une réactivation ultérieure sans re-saisie.

7. **Connexion biométrique via re-login email** : la biométrie déverrouille les identifiants email/mot de passe chiffrés dans `flutter_secure_storage` et appelle `attemptLogIn()` avec ces identifiants — ce n'est pas un token biométrique envoyé au serveur, c'est une re-connexion email transparente.

8. **Rotation du refresh token supportée** : si le backend renvoie un nouveau `refreshToken` dans la réponse de refresh, il est persisté automatiquement (rotation silencieuse).

9. **Récupération de mot de passe anti-énumération** : la demande de reset password renvoie toujours un succès au client, que l'email existe ou non — pour ne pas révéler quels emails sont inscrits.

10. **Auto-login après reset de mot de passe** : après confirmation du nouveau mot de passe via le token reçu par email, l'API renvoie des JWT qui sont persistés directement — l'utilisateur est connecté sans avoir à saisir ses identifiants.

11. **Biométrie désactivée automatiquement si hardware indisponible** : si la biométrie n'est plus disponible sur l'appareil au moment d'une tentative de connexion biométrique, elle est désactivée automatiquement.

12. **Google OAuth : stratégies différentes mobile/web** : sur mobile, le SDK natif `google_sign_in` est utilisé (popup compte Google intégré, idToken envoyé à `POST /auth/google/mobile`). Sur web, une WebView OAuth ouvre le flow standard du backend avec interception du redirect et récupération des tokens via postMessage.

---

## Cas d'usage (déduits)

### CU-001 — Connexion email/mot de passe
L'utilisateur saisit son email et son mot de passe sur la page `/login`, valide le formulaire. `LoginCubit` appelle `AuthService.attemptLogIn()`. En cas de succès, les JWT sont persistés dans `flutter_secure_storage` et l'utilisateur est redirigé vers `/home`. Si c'est le premier login réussi sur cet appareil avec un support biométrique, un dialog propose l'activation.

### CU-002 — Inscription avec consentement RGPD
L'utilisateur remplit le formulaire d'inscription (pseudo, email, mot de passe) et coche les deux cases de consentement. `RegisterCubit` vérifie `state.canSubmit` côté client avant tout appel réseau, appelle `AuthService.attemptSignUp()` puis `attemptLogIn()` (auto-login), puis enregistre le consentement via `GdprService.recordConsent()` avec les versions dynamiques.

### CU-003 — Auto-login au démarrage
`StartupPage` se charge et tente l'auto-login de manière séquentielle : (1) access token encore valide → `/home` direct ; (2) refresh token valide + connecté → tentative refresh → routing selon `RefreshResult` ; (3) refresh token valide + hors ligne → `/home` en cache ; (4) aucun token valide → tentative biométrique → `/login`.

### CU-004 — Connexion biométrique
L'utilisateur clique sur le bouton biométrique. `AuthService.tryBiometricLogin()` vérifie que la biométrie est activée, que des identifiants sont stockés, que le hardware est disponible, puis lance `BiometricService.authenticateWithBiometrics()`. En cas de succès, les identifiants chiffrés sont déchiffrés et `attemptLogIn()` est appelé.

### CU-005 — Connexion Google (mobile)
L'utilisateur clique sur "Se connecter avec Google". `GoogleSignIn.instance.authenticate()` affiche le sélecteur de compte natif. L'idToken est envoyé à `POST /auth/google/mobile`. Les JWT reçus sont persistés et l'utilisateur est redirigé vers `/home`.

### CU-006 — Connexion Google (web)
L'utilisateur clique sur "Se connecter avec Google" depuis le web. Une WebView s'ouvre avec l'URL OAuth du backend. Une popup navigateur s'ouvre ; quand l'utilisateur s'authentifie, la popup envoie les tokens via `postMessage`. Un timer poll le résultat côté Dart toutes les 500ms jusqu'à réception.

### CU-007 — Récupération de mot de passe
L'utilisateur clique sur "Mot de passe oublié ?", saisit son email sur `/forgot-password`. `EmailAuthService.requestPasswordReset()` est appelé. L'interface affiche toujours un message de succès (anti-énumération). L'utilisateur reçoit un email avec un lien deep link contenant un token. Il clique, est redirigé vers `/reset-password?token=...`. Il saisit son nouveau mot de passe. `ResetPasswordCubit` appelle `EmailAuthService.confirmPasswordReset()`. Les JWT auto-login sont persistés.

### CU-008 — Vérification email
Après inscription, un email de vérification peut être envoyé. L'utilisateur clique sur le lien deep link, qui ouvre `/auth/verify?token=...`. `EmailAuthService.verifyEmail()` est appelé avec le token de l'URL. Les JWT auto-login sont persistés si la vérification réussit.

### CU-009 — Re-consentement RGPD au login
Après un login ou refresh réussi, si les CGU ou la Politique de confidentialité ont évolué, `GdprService.getConsentStatus()` retourne `needsAnyAcceptance == true`. Une modal bloquante doit s'afficher demandant re-acceptation avant d'accéder au reste de l'app.

### CU-010 — Déconnexion
Depuis le profil, l'utilisateur se déconnecte. `AuthService.logout()` supprime `accessToken` et `refreshToken` du secure storage (sans supprimer les identifiants biométriques, pour permettre une réactivation ultérieure).

---

## Dépendances

- `StorageService` — persistance sécurisée des tokens JWT (Keystore Android / Keychain iOS / WebCrypto Web)
- `BiometricService` — détection hardware biométrique + authentification `local_auth`
- `GdprService` — enregistrement et vérification du consentement RGPD
- `ConnectivityService` — vérification de la connectivité avant le refresh token
- `AppUpdateService` — vérification des mises à jour avant le flow d'auth au démarrage
- `EmailAuthService` — flow email-driven (vérification email, reset password)
- `HttpService` — appels API authentifiés (hors login/register/refresh qui utilisent `http` direct)
- `go_router` — navigation vers `/home`, `/login`, `/register`, `/forgot-password`, `/auth/verify`

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Re-consentement post-login effectivement implémenté ?** : Les commentaires dans le code (CLAUDE.md et RETRO-003) décrivent que `getConsentStatus()` doit être appelé après chaque login. Le code de `StartupPage._onLoginSuccess()` ne contient pas cet appel explicitement — soit il est effectué ailleurs (dans un BLoC), soit il est manquant. À vérifier par le dev.
- **Apple Sign-In** : `SocialLoginButtons` affiche un bouton Apple mais son handler appelle `l10n?.comingSoon`. Statut de développement non documenté (roadmap, priorité ?).
- **Vérification email obligatoire ou optionnelle ?** : Le code de `StartupPage` et de `LoginView` laisse passer un utilisateur non-vérifié. Un `VerifyEmailBanner` existe dans le design system mais son emplacement d'affichage n'est pas visible dans les fichiers lus. À confirmer.
- **Throttling côté serveur sur le refresh** : `EmailAuthService.resendVerificationEmail()` documente un rate limit côté serveur (3 req/min, 429). Aucun rate limit similaire n'est documenté pour `/auth/refresh` ou `/auth/login` dans les fichiers lus.
- **Comportement en cas d'échec de `recordConsent()` à l'inscription** : le code marque l'erreur comme silencieuse et précise "re-prompt au prochain login". La mécanique de ce re-prompt n'est pas visible dans les fichiers lus (voir zone d'incertitude 1 ci-dessus).
