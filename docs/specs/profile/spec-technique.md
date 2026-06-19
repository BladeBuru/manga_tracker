# Spec Technique — profile

| Champ         | Valeur              |
|---------------|---------------------|
| Module        | profile             |
| Version       | 0.2.0               |
| Date          | 2026-06-19          |
| Source        | Rétro-ingénierie + Sprint responsive/social/stats-v2 |

---

## Architecture du module

La feature `profile` ne suit pas le pattern BLoC classique utilisé dans le reste de l'application. La page principale (`Profile`) est un `StatefulWidget` qui orchestre directement les services via GetIt — pas de BLoC dédié. Ce choix est cohérent avec les features à état local simple (comme `auth` qui utilise des Cubits).

La page est décomposée en couches :

```
Profile (StatefulWidget)           ← orchestrateur, gère les loaders/actions
  └── ProfileBody (StatelessWidget) ← arbre visuel scrollable (CustomScrollView)
        ├── ProfileHeader           ← avatar + username + email
        ├── ProfileHighlightCard    ← carte de mise en avant (contenu à vérifier)
        ├── AccountSection          ← changement mot de passe
        ├── ProfileSocialSection    ← édition profil + liens vers stats/amis/inbox/groupes
        ├── SettingsSection         ← langue + notifications + thème + biométrie
        ├── ActionsSection          ← mes données + déconnexion + suppression
        ├── ContactSection          ← Discord
        ├── DownloadsSection        ← téléchargements
        ├── SelectorsSection        ← sélecteurs personnalisés
        └── ProfileFooter           ← version de l'app
```

`ProfileDialogs` est une façade statique qui délègue à 5 dialogs indépendants dans `widgets/dialogs/` :
- `change_password_dialog.dart`
- `delete_account_dialog.dart`
- `logout_dialog.dart`
- `theme_selector_dialog.dart`
- `biometric_reconnect_dialog.dart`

`MyDataView` est une page indépendante accessible via `/my-data`. Elle utilise directement `GdprService` et `UserService`, sans passer par `Profile`.

`ProfileEditView` est une page indépendante accessible via `/profile/edit`. Elle reçoit le `UserInformationDto` courant en `extra` via go_router et retourne un `bool` (true = profil mis à jour).

---

## Fichiers impactés

| Fichier | Rôle | Lignes |
|---------|------|--------|
| `lib/features/profile/views/profile.dart` | Orchestrateur principal — loaders + actions + build | ~284 |
| `lib/features/profile/views/my_data_view.dart` | Page RGPD "Mes données" | ~364 |
| `lib/features/profile/views/profile_edit.view.dart` | Formulaire d'édition du profil | ~376 |
| `lib/features/profile/views/custom_selectors_page.dart` | Sélecteurs personnalisés | N/A |
| `lib/features/profile/views/notifications_settings_page.dart` | Paramètres de notifications | N/A |
| `lib/features/profile/views/change_password.view.dart` | NEW — Page dédiée « Changer mon mot de passe » (formulaire 3 champs) | — |
| `lib/features/profile/services/change_password.service.dart` | NEW — Service dédié au changement de MDP (appel `PUT /user/password`, auto-persistance nouveaux tokens) | — |
| `lib/features/profile/presentation/cubit/change_password_cubit.dart` | NEW — Cubit pour la page change-password (validation, loading, success, error) | — |
| `lib/features/profile/services/user.service.dart` | Infos utilisateur, changement MDP, suppression compte, mise à jour profil | ~208 |
| `lib/features/profile/services/gdpr.service.dart` | Droits RGPD articles 15/20 + gestion consentement | ~127 |
| `lib/features/profile/widgets/profile_body.dart` | Corps scrollable + ProfileFooter | ~206 |
| `lib/features/profile/widgets/profile_header.dart` | Header avatar + username + email | ~127 |
| `lib/features/profile/widgets/profile_sections.dart` | 7 sections du profil + _BiometricRow | ~295 |
| `lib/features/profile/widgets/profile_dialogs.dart` | Façade statique pour les 5 dialogs | ~63 |
| `lib/features/profile/widgets/profile_edit_sections.dart` | Section card générique réutilisée dans edit + my_data | N/A |
| `lib/features/profile/widgets/profile_edit_rows.dart` | Rows champ texte, date, genre, privacy pour ProfileEditView | N/A |
| `lib/features/profile/widgets/profile_edit_widgets.dart` | Widgets éditables (hero avatar, save button) | N/A |
| `lib/features/profile/widgets/profile_menu_row.dart` | Tile de menu générique (icône + titre + sous-titre + trailing) | N/A |
| `lib/features/profile/widgets/profile_highlight_card.dart` | Carte de mise en avant du profil | N/A |
| `lib/features/profile/widgets/my_data_dialogs.dart` | Dialogs RGPD (résumé + documents légaux) | N/A |
| `lib/features/profile/widgets/my_data_info_banner.dart` | Bandeau informatif en haut de MyDataView | N/A |
| `lib/features/profile/widgets/dialogs/` | 5 dialogs indépendants (pwd, delete, logout, theme, biometric) | N/A |
| `lib/features/profile/dto/user_information.dto.dart` | DTO profil étendu (Phase 3) | ~134 |
| `lib/features/profile/dto/user.dto.dart` | DTO utilisateur simplifié (Equatable) | ~49 |
| `lib/features/profile/helpers/user.helper.dart` | Helper utilitaires profil | N/A |

---

## Schéma de données (côté client)

### UserInformationDto

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `int?` | Identifiant numérique (peut être null) |
| `email` | `String` | Email de l'utilisateur |
| `username` | `String` | Pseudo unique |
| `emailVerified` | `bool` | Vrai si email vérifié via magic link |
| `displayName` | `String?` | Nom public (fallback sur username si null) |
| `bio` | `String?` | Courte description (max 500 chars) |
| `avatarUrl` | `String?` | URL https:// ou data:image/[mime];base64,... |
| `dateOfBirth` | `String?` | Date ISO YYYY-MM-DD (RGPD opt-in) |
| `gender` | `UserGender?` | Enum : male, female, non_binary, prefer_not_to_say (RGPD opt-in) |
| `isProfilePublic` | `bool` | Visibilité du profil pour les amis (Phase 6) |

Méthode utilitaire : `effectiveDisplayName` retourne `displayName` si non vide, sinon `username`.

### UserDto

DTO simplifié (Equatable) utilisé dans d'autres contextes : `username`, `email`, `avatar`, `lastLogin`, `emailVerified`.

### ConsentStatus

| Champ | Type | Description |
|-------|------|-------------|
| `needsTosAcceptance` | `bool` | L'utilisateur doit accepter les nouvelles CGU |
| `needsPrivacyAcceptance` | `bool` | L'utilisateur doit accepter la nouvelle Politique |
| `currentTosVersion` | `String` | Version actuelle des CGU côté serveur |
| `currentPrivacyVersion` | `String` | Version actuelle de la Politique côté serveur |
| `needsAnyAcceptance` | `bool` (getter) | `true` si l'une ou l'autre acceptation est requise |

---

## API / Endpoints consommés

| Méthode | Route | Description | Auth |
|---------|-------|-------------|------|
| GET | `/user/information` | Informations profil complet | JWT |
| PUT | `/user/password` | Changement de mot de passe (retourne nouveaux tokens, persistés automatiquement) | JWT |
| DELETE | `/user/delete` | Suppression du compte | JWT |
| PATCH | `/user/profile` | Mise à jour des champs profil étendu | JWT |
| GET | `/user/gdpr/summary` | Résumé des données (article 15) | JWT |
| GET | `/user/gdpr/export` | Export JSON complet (article 20) | JWT |
| GET | `/user/gdpr/consent-status` | Statut du consentement versioned | JWT |
| POST | `/user/gdpr/consent` | Enregistrement du consentement | JWT |

Codes HTTP traités explicitement :
- `200 OK` — succès
- `403 Forbidden` — `InvalidCredentialsException` (delete, password)
- autres — `Exception` générique avec le status code

---

## Gestion du cache utilisateur

Le cache des informations utilisateur utilise `OfflineCacheService` avec la clé `cached_user_info` et un TTL de 7 jours (168h).

Stratégie stale-while-revalidate :
1. Si cache présent et non expiré : retourne immédiatement le cache, lance `_refreshUserInformationFromNetwork()` en arrière-plan (silencieuse en cas d'erreur).
2. Si cache présent mais expiré : appel réseau ; en cas d'échec, fallback sur le cache expiré.
3. Si aucun cache : appel réseau obligatoire ; echec → exception remontée.
4. `forceRefresh = true` : invalide d'abord le cache (`deleteSecureData('cached_user_info')`), puis appel réseau systématique.

Après `updateProfile()` : le cache est remplacé par le DTO retourné par l'API (pas d'invalidation puis re-fetch, mais remplacement direct).

---

## Gestion de la permission galerie (avatar)

Dans `ProfileEditView._ensureGalleryPermission()` :
- Sur web (`kIsWeb`) : pas de permission nécessaire.
- Sur Android/iOS : demande `Permission.photos`.
- Si `isPermanentlyDenied` : dialog d'information avec bouton "Paramètres" (`openAppSettings()`).
- Sur desktop : aucune permission requise.

L'avatar sélectionné est redimensionné à 512×512 px, qualité 75%, et encodé en base64 avec le MIME correct (jpeg par défaut, png si `.png`, webp si `.webp`).

---

## Responsive

- Page profil principale : `LayoutBuilder` avec contrainte `maxWidth: 700`. Padding horizontal `24` si largeur >= 700px, `0` sinon.
- `MyDataView` et `ProfileEditView` : `LayoutBuilder` avec padding horizontal `32` si >= 600px, `16` sinon.
- `ChangePasswordView` : utilise `AppBreakpoints` (`lib/core/theme/app_breakpoints.dart`) pour le centrage du formulaire (max-width via `AppContentWidth` 1100px).

## Page « Changer mon mot de passe »

Route go_router : `/change-password`. Accessible depuis le menu profil (entrée « Compte » / `AccountSection`).

Architecture : Cubit (`ChangePasswordCubit`) + `ChangePasswordView` (StatelessWidget). Trois champs : mot de passe actuel, nouveau mot de passe, confirmation. Le Cubit gère les états `ChangePasswordInitial`, `ChangePasswordLoading`, `ChangePasswordSuccess`, `ChangePasswordError`.

`ChangePasswordService.changePassword()` appelle `PUT /user/password`. L'API retourne de nouveaux tokens (access + refresh) après un changement réussi — ils sont persistés automatiquement dans `flutter_secure_storage` via `StorageService` sans nécessiter de re-login.

---

## Patterns identifiés

- **StatefulWidget direct** (pas de BLoC) — choix assumé pour une page à état local (chargements, toggles) sans logique métier complexe côté état. Cohérent avec le pattern Cubit utilisé dans `auth` pour les formulaires.
- **Façade statique pour les dialogs** — `ProfileDialogs` expose une API uniforme et délègue à des implémentations dans des fichiers séparés pour respecter la limite 400 lignes/fichier.
- **Séparation orchestrateur/vue** — `Profile` porte les `async` actions, `ProfileBody` est `StatelessWidget` pur recevant uniquement des callbacks.
- **Sections comme widgets autonomes** — chaque section (AccountSection, SettingsSection, etc.) est un `StatelessWidget` indépendant dans `profile_sections.dart`, recevant uniquement les callbacks nécessaires.
- **Design System V1 "Refined Classic"** — utilisation systématique de `AppColors.dsBgDark/Light`, `AppColors.dsHairline`, `AppColors.dsText2/3`, `PastelTile`, `ProfileMenuRow`, `ProfileEditSection`.
- **Image resolution polymorphe** — `ProfileHeader._resolveImage()` supporte data URLs (décodage base64 → `MemoryImage`) et URLs http(s) (`NetworkImage`). Logique dupliquée dans `AppAvatar._resolveImage` (composant core).

---

## Décisions documentées en spec (non-ADR)

**Cache 7 jours pour les infos utilisateur** : `UserService.getUserInformation()` utilise un TTL de 168h. Ce délai est un compromis entre fraîcheur des données et économie d'appels réseau. La mise à jour en arrière-plan assure que les données restent à jour pour les sessions actives. Ce choix est confiné à `UserService` et ne contraint pas d'autres modules.

**Pas d'endpoint pour vider un champ de profil** : le PATCH `/user/profile` avec une chaîne vide retourne 400 (validation `@Length(1, N)` côté serveur NestJS). Pour effacer un champ, un endpoint dédié serait nécessaire côté API — non implémenté en MVP. Les chaînes vides sont donc filtrées côté client avant l'appel.

**Export RGPD via presse-papier** : mécanisme cross-platform actuel (Android, iOS, Web). Le JSON brut retourné par `/user/gdpr/export` est copié dans `Clipboard`. Une implémentation via `path_provider` + `share_plus` (mobile) ou `Blob download` (web) est envisageable pour une meilleure UX.

**`deleteAccount` dans UserService plutôt que GdprService** : légère incohérence par rapport à la centralisation RGPD. La suppression de compte (article 17) est dans `UserService` pour des raisons d'organisation historique. Elle est accessible depuis deux points d'entrée UI (profil principal et page Mes données).

---

## Tests existants

| Fichier | Ce qu'il teste | Statut |
|---------|---------------|--------|
| Aucun test dans `test/features/profile/` | — | Absent |

La feature `profile` n'a pas de tests dédiés dans `test/`. Les tests existants couvrent `auth` (cubit + widget), `manga` (DTO), et les composants core.

---

## Notes cross-platform

- `profile_edit.view.dart` importe `dart:io show Platform` directement (détection Android/iOS pour la permission galerie). Ce n'est pas une abstraction complète — blocker potentiel si `dart:io` est retiré pour le web. Contournement : `kIsWeb` est vérifié en premier, donc le code `dart:io` n'est jamais atteint sur web.
- `GdprService` n'a aucune dépendance à `dart:io` — compatible Web nativement.
- `UserService` n'a aucune dépendance à `dart:io`.
