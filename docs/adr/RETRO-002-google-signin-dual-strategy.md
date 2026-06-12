# RETRO-002 — Google Sign-In : idToken natif sur mobile, OAuth WebView sur web

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | auth                |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | AUTH |
| Q1 — Coût de revert > 1j ? | OUI — unifier les deux stratégies nécessite de changer `google_sign_in` (SDK natif), `GoogleAuthWebView` (popup + postMessage), les deux endpoints backend `/auth/google/mobile` et `/auth/google`, et le `serverClientId` hardcodé ; plus d'une journée de refactoring et de tests sur les deux plateformes. |
| Q2 — Non-déductible du code ? | OUI — `pubspec.yaml` liste `google_sign_in ^7.2.0` et `flutter_inappwebview ^6.0.0` mais ne révèle pas que le SDK natif est utilisé pour le mobile (idToken) tandis que la WebView OAuth est utilisée pour le web (postMessage), ni pourquoi ; la distinction et la raison (le SDK natif ne fonctionne pas dans le contexte web Flutter) ne se déduisent pas des dépendances. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — auth (login Google) et tout futur flow nécessitant une re-auth Google (ex: liaison de compte, scope étendu) ; la stratégie web implique aussi le router (`GoogleAuthWebView` pousse une route `MaterialPageRoute` en dehors du `go_router`, ce qui est une exception à la règle de navigation). |
| Q4 — Casse un invariant si ignoré ? | OUI — un dev qui essaie d'utiliser `GoogleSignIn.instance.authenticate()` sur le web obtiendra une erreur silencieuse ou un crash à l'exécution ; inversement, utiliser le flow WebView sur mobile produit une UX dégradée (WebView plein écran au lieu du popup natif Google). |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

Google Sign-In nécessite deux stratégies différentes selon la plateforme d'exécution. Sur mobile, le SDK `google_sign_in` fournit une popup native (compte Android intégré) et retourne un `idToken` signé par Google que le backend valide via `POST /auth/google/mobile`. Sur le web Flutter, le SDK natif n'est pas disponible ; le flow OAuth standard du backend est utilisé via une WebView qui intercept le redirect `mangatracker://auth` (mobile) ou via une popup navigateur + `postMessage` (web).

## Décision identifiée

`AuthService.loginWithGoogle(BuildContext context)` dispatch sur `kIsWeb` :

- **Mobile** (`kIsWeb == false`) : `_loginWithGoogleMobile()` — initialise `GoogleSignIn.instance` avec le `serverClientId`, force un `signOut()` pour afficher le sélecteur de compte, puis envoie l'`idToken` à `POST /auth/google/mobile`.
- **Web** (`kIsWeb == true`) : `_loginWithGoogleWeb(context)` — pousse `GoogleAuthWebView` comme `MaterialPageRoute` fullscreenDialog ; sur web, ouvre une popup via `window.open()` et poll le résultat via `postMessage` ; sur mobile dans la WebView, intercepte le deep link `mangatracker://auth?accessToken=...&refreshToken=...` via `shouldOverrideUrlLoading`.

Les JWT résultants sont persistés dans `flutter_secure_storage` dans les deux cas via `storageService.writeSecureData`.

Note : `GoogleAuthWebView` est utilisée en `MaterialPageRoute` directement (pas via `go_router`), ce qui est une exception documentée — go_router ne supporte pas les routes temporaires push sans URL stable.

## Conséquences observées

### Positives
- L'UX mobile est optimale (popup native Google Account Manager).
- Le web fonctionne sans dépendance au SDK natif indisponible dans le contexte Flutter Web.
- Le `serverClientId` est unique (même Client ID pour mobile et web), simplifiant la configuration backend.

### Négatives / Dette
- Le `serverClientId` Google (`43781664315-4qruuj7eek7j71meh9ccl398r9k20a6k.apps.googleusercontent.com`) est hardcodé dans `auth.service.dart` — devrait aller dans les fichiers `.env`.
- `GoogleAuthWebView` utilise `MaterialPageRoute` au lieu de `go_router`, créant une exception à la règle de navigation du projet.
- Le polling `Timer.periodic(500ms)` côté web pour détecter le `postMessage` est fragile (la popup peut être bloquée par le navigateur).
- Apple Sign-In est présent dans l'UI (`SocialLoginButtons`) mais non implémenté (stub `l10n?.comingSoon`).

## Recommandation

Garder la stratégie duale (elle est correcte). Déplacer le `serverClientId` vers les fichiers `.env`. Investiguer le remplacement du polling postMessage par un `EventListener` natif JS (moins fragile).
