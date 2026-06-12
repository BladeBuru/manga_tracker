# Spec Technique — Auth

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | auth                |
| Version       | 0.1.0               |
| Date          | 2026-06-04          |
| Source        | Rétro-ingénierie    |

---

## Architecture du module

Le module `auth` est organisé autour de quatre couches :

```
features/auth/
├── services/
│   ├── auth.service.dart          # Orchestrateur JWT + Google + biométrie
│   ├── biometric.service.dart     # Wrapper local_auth (détection + authenticate)
│   ├── email_auth.service.dart    # Flows email-driven (vérification, reset password)
│   └── validator.service.dart     # Validation email côté client
├── presentation/
│   └── cubit/
│       ├── login_cubit.dart        # Cubit login (état formulaire + biometric prompt)
│       ├── login_state.dart
│       ├── register_cubit.dart     # Cubit inscription + consentement RGPD
│       ├── register_state.dart
│       ├── forgot_password_cubit.dart  # État + logique forgot-password
│       ├── reset_password_cubit.dart   # État + logique reset-password confirm
│       └── auth_submission_status.dart # Enum { initial, loading, success, failure }
├── views/
│   ├── startup_page.dart           # Orchestrateur d'auto-login au démarrage
│   ├── login.view.dart             # Vue formulaire connexion
│   ├── register.view.dart          # Vue formulaire inscription
│   ├── forgot_password.view.dart   # Vue demande reset password
│   ├── reset_password.view.dart    # Vue confirmation nouveau mot de passe
│   ├── verify_email.view.dart      # Vue vérification email par deep link
│   ├── google_auth_webview.dart    # WebView OAuth Google (mobile + web)
│   ├── google_auth_js_helper_web.dart  # JS helpers web (window.open + postMessage)
│   └── google_auth_js_helper_stub.dart # Stub mobile (conditional export)
├── widgets/
│   ├── consent_checkbox.dart       # Case à cocher RGPD avec lien document légal
│   ├── social_login_buttons.dart   # Row Google + Apple outlined buttons
│   └── [autres widgets auth UI]    # auth_hero, auth_scaffold, auth_form_card, etc.
├── utils/
│   └── auth_error_mapper.dart      # Mapping exception → message l10n
└── exceptions/
    ├── auth_server.exception.dart
    ├── email_already_used.exception.dart
    └── invalid_credentials.exception.dart
```

Le module dépend également de `features/profile/services/gdpr.service.dart` pour l'enregistrement et la vérification du consentement RGPD.

---

## Fichiers impactés

| Fichier | Rôle | Lignes (approx.) |
|---------|------|-----------------|
| `lib/features/auth/services/auth.service.dart` | Orchestrateur principal : login email, Google, biométrie, refresh JWT, logout, persistance tokens | ~520 |
| `lib/features/auth/services/biometric.service.dart` | Wrapper `local_auth` avec compatibilité Huawei et gestion `PlatformException` | ~122 |
| `lib/features/auth/services/email_auth.service.dart` | Flows email-driven : vérification, reset password, throttling 429 | ~151 |
| `lib/features/auth/presentation/cubit/login_cubit.dart` | État formulaire login + biometric prompt post-login | ~96 |
| `lib/features/auth/presentation/cubit/register_cubit.dart` | État formulaire inscription + double consentement RGPD + auto-login | ~104 |
| `lib/features/auth/presentation/cubit/forgot_password_cubit.dart` | État + logique forgot-password (state + cubit dans un fichier) | ~72 |
| `lib/features/auth/presentation/cubit/reset_password_cubit.dart` | État + logique reset-password confirm + auto-login via persistTokens | ~94 |
| `lib/features/auth/presentation/cubit/login_state.dart` | State Equatable login avec `requiresBiometricPrompt` et `pendingEmail/Password` | ~55 |
| `lib/features/auth/presentation/cubit/register_state.dart` | State Equatable inscription avec `acceptedTos`, `acceptedPrivacy`, `canSubmit` | ~52 |
| `lib/features/auth/views/startup_page.dart` | Orchestrateur démarrage : vérif update → auto-login → routing conditionnel | ~287 |
| `lib/features/auth/views/login.view.dart` | Vue connexion : form + cubit + biométrie + Google + Apple stub | ~318 |
| `lib/features/auth/views/google_auth_webview.dart` | WebView OAuth Google multi-plateforme (InAppWebView mobile / popup web) | ~169 |
| `lib/features/auth/widgets/consent_checkbox.dart` | Case à cocher RGPD non pré-cochée avec lien légal cliquable | ~94 |
| `lib/features/auth/widgets/social_login_buttons.dart` | Row Google + Apple buttons outlined 52px | ~112 |
| `lib/features/profile/services/gdpr.service.dart` | Articles 15/20 + consentement (recordConsent, getConsentStatus) | ~127 |

---

## Schéma BDD

Aucune table embarquée (pas de SQLite pour ce module). Stockage local via :

| Clé | Store | Contenu |
|-----|-------|---------|
| `accessToken` | `flutter_secure_storage` | JWT access token (Keystore Android / Keychain iOS / WebCrypto Web) |
| `refreshToken` | `flutter_secure_storage` | JWT refresh token |
| `secure_credentials` | `flutter_secure_storage` (biometric) | JSON `{email, password}` chiffré — déverrouillage biométrique requis |
| `biometric_auth_enabled` | `shared_preferences` | `bool` — préférence biométrique de l'utilisateur |

---

## API / Endpoints consommés

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| POST | `/auth/login` | Login email/mot de passe → `{accessToken, refreshToken}` | Non |
| POST | `/auth/register` | Inscription → 201 OK (auto-login immédiat côté client) | Non |
| POST | `/auth/refresh` | Refresh token → `{accessToken[, refreshToken]}` | Bearer refreshToken |
| POST | `/auth/google/mobile` | Login Google mobile → `{accessToken, refreshToken}` | Non (idToken body) |
| GET | `/auth/google` | Initiation OAuth Google web | Non |
| POST | `/auth/email/send-verification` | Renvoi mail de vérification (throttle 3/min) | JWT |
| POST | `/auth/email/verify` | Vérification email par token → `{accessToken, refreshToken}` | Non |
| POST | `/auth/email/password/reset/request` | Demande reset password (anti-énumération) | Non |
| POST | `/auth/email/password/reset/confirm` | Confirmation reset avec token → `{accessToken, refreshToken}` | Non |
| GET | `/user/gdpr/consent-status` | Statut consentement vs versions courantes CGU/Privacy | JWT |
| POST | `/user/gdpr/consent` | Enregistrement consentement avec versions | JWT |

---

## Patterns identifiés

### Cubits pour les formulaires (pas des BLoCs)
Les 4 formulaires auth (`LoginCubit`, `RegisterCubit`, `ForgotPasswordCubit`, `ResetPasswordCubit`) utilisent `Cubit<State>` sans events. C'est un choix pragmatique documenté dans `discovery.md` : les formulaires ont un état local simple (champs, statut, messages d'erreur) qui ne nécessite pas l'event-sourcing des BLoCs. Décision documentée dans `docs/retro/discovery.md` — non éligible en ADR (AP-3 : heuristique d'implémentation).

### État Equatable avec `copyWith` et flags sémantiques
`LoginState` inclut `requiresBiometricPrompt`, `pendingEmail`, `pendingPassword` — des champs temporaires qui permettent au cubit de passer des informations à la view (dialog biométrique) sans passer par le `BuildContext`. `clearPendingCredentials: true` dans `copyWith` est un flag booléen pour effacer ces champs sensibles après usage.

### Verrou `Completer` pour sérialisation des refreshes simultanés
`AuthService` contient `bool _isRefreshing` + `Completer<RefreshResult>? _refreshCompleter`. Si `refreshAccessToken()` est appelé pendant qu'un refresh est déjà en cours (ex: deux BLoCs qui lancent une requête en même temps au réveil), les appelants suivants attendent le `Future` du `Completer` au lieu de déclencher un deuxième appel HTTP. Mécanisme confiné à `auth.service.dart` — documenté ici car non visible dans les configs.

### Stockage sécurisé via `flutter_secure_storage`
Tokens JWT stockés dans Keystore Android / Keychain iOS / WebCrypto Web. Les identifiants biométriques (`secure_credentials`) sont stockés avec `writeSecureDataBiometric` — interface différente qui nécessite une authentification biométrique pour la lecture (`readSecureDataBiometric`). Ce choix est visible dans `pubspec.yaml`.

### Platform-split Google OAuth via `kIsWeb`
`AuthService.loginWithGoogle()` dispatch sur `kIsWeb` pour sélectionner la stratégie : SDK natif `google_sign_in` sur mobile, `GoogleAuthWebView` sur web. La WebView utilise le pattern conditional export pour les helpers JS (`google_auth_js_helper_web.dart` / `google_auth_js_helper_stub.dart`).

### Anti-énumération email sur forgot-password
`EmailAuthService.requestPasswordReset()` retourne toujours `true` au client (succès, email trouvé ou non). La distinction est documentée par commentaire dans le code — décision de sécurité standard qui n'a pas de signalement dans les configs.

### Decode JWT client-side
`AuthService.isTokenExpired()` parse le JWT localement (base64 decode du payload, champ `exp`) pour éviter un appel réseau inutile au démarrage. Pas de vérification de signature côté client (normal — la signature est vérifiée par le serveur).

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| `test/features/auth/login_cubit_test.dart` | `LoginCubit.submit()` — succès, erreur credentials, état biometric prompt | Existant |
| `test/features/auth/register_cubit_test.dart` | `RegisterCubit.submit()` — succès, canSubmit guard, email déjà utilisé | Existant |
| `test/features/auth/login_view_test.dart` | Widget test `LoginView` — rendu form, actions boutons | Existant |
| `test/features/auth/register_view_test.dart` | Widget test `RegisterView` — cases consentement, soumission | Existant |
| `AuthService` (refreshAccessToken, logout, biometric) | Non couvert | Absent |
| `BiometricService` | Non couvert | Absent |
| `EmailAuthService` | Non couvert | Absent |
| `GdprService` | Non couvert | Absent |
| `StartupPage` (machine d'état auto-login) | Non couvert | Absent |

---

## Enregistrement GetIt

Les cubits auth (`LoginCubit`, `RegisterCubit`, `ForgotPasswordCubit`, `ResetPasswordCubit`) sont instanciés directement dans les views (`_loginCubit = LoginCubit(authService: _authService)`) et fermés dans `dispose()` — ils ne sont pas enregistrés dans GetIt. Ce pattern est approprié pour les cubits de formulaire à vie courte.

`AuthService`, `BiometricService`, `EmailAuthService`, `GdprService`, `ValidatorService` sont enregistrés dans `service_locator.dart` (enregistrements exacts à vérifier dans ce fichier).

---

## Dette technique identifiée (non-ADR)

- Le `serverClientId` Google (`43781664315-...`) est hardcodé dans `auth.service.dart` — devrait être dans `assets/env/.env.*`.
- `GoogleAuthWebView` utilise `MaterialPageRoute` au lieu de `go_router` (exception à la règle de navigation du projet).
- De nombreux `debugPrint` avec emoji dans `AuthService` et `BiometricService` ne sont pas gardés par `kDebugMode` — ils s'exécutent en production.
- `ConsentCheckbox` utilise des paddings (`EdgeInsets.symmetric(horizontal: 4, vertical: 2)`) non conformes aux tokens `AppSpacing`.
- `BiometricService` contient une heuristique de compatibilité Huawei (retour `true` même si `getAvailableBiometrics()` est vide) qui pourrait produire des erreurs silencieuses sur des appareils non-Huawei sans biométrie.
