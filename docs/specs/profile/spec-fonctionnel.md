# Spec Fonctionnelle — profile [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | profile             |
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
| [RETRO-029](../../adr/RETRO-029-gdpr-service-centralized.md) | GdprService : centralisation des droits RGPD comme invariant de sécurité | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

La feature `profile` constitue la page "Mon compte" de l'application. Elle centralise toutes les actions relatives à l'identité de l'utilisateur, à ses préférences applicatives, et à ses droits sur ses données personnelles. C'est aussi le hub de navigation vers les features sociales (amis, inbox, groupes de lecture) et les statistiques.

L'objectif est de donner à l'utilisateur un contrôle complet sur son compte sans quitter l'application.

---

## Règles métier (déduites du code)

1. **Affichage du profil** : le username et l'email sont toujours affichés dans l'en-tête. Si un `displayName` est défini, il est utilisé à la place du username dans les contextes publics (commentaires, profil visible). En l'absence d'avatar, une icône de substitution est affichée.

2. **Avatar** : l'avatar peut être une URL `https://` ou une image encodée en base64 au format `data:image/[mime];base64,...`. Les autres formats sont silencieusement ignorés. L'envoi vers l'API est conditionné à la validité du format. La colonne de stockage côté API est de type `text` (capacité ~200 000 caractères), ce qui permet les data URLs.

3. **Édition du profil** : les champs éditables sont `displayName` (max 80 chars), `bio` (max 500 chars), `avatarUrl`, `dateOfBirth` (ISO YYYY-MM-DD), `gender` (enum : male, female, non_binary, prefer_not_to_say), et `isProfilePublic`. Les champs `username` et `email` sont en lecture seule dans le formulaire d'édition.

4. **Champs vides non envoyés** : les chaînes vides ne sont pas envoyées à l'API (le serveur valide `@Length(1, N)` et retournerait une erreur 400). Pour effacer un champ, un endpoint dédié serait nécessaire — non implémenté.

5. **Changement de mot de passe** : le nouveau mot de passe est soumis via un dialog dédié. Un succès HTTP 200 est attendu. La modification ne nécessite pas d'invalider le cache des informations utilisateur (les données de profil ne changent pas).

6. **Suppression de compte** : une confirmation explicite via dialog est requise. Après suppression, l'utilisateur est redirigé vers `/login`.

7. **Déconnexion** : une confirmation explicite via dialog est requise. Après déconnexion, l'utilisateur est redirigé vers `/login`.

8. **Biométrie** :
   - La biométrie n'est affichée que si le device la supporte (vérifié via `BiometricService.hasBiometricSupport()`).
   - Pour activer la biométrie, des credentials doivent être stockés dans le secure storage (`hasBiometricCredentials()`). Si ce n'est pas le cas, l'utilisateur est invité à se reconnecter.
   - La désactivation de la biométrie est immédiate sans confirmation supplémentaire.

9. **Thème** : l'utilisateur peut choisir entre Clair, Sombre, et Système. Le changement est persisté par `ThemeService` et appliqué en temps réel.

10. **Langue** : 7 langues disponibles (FR, EN, DE, JA, KO, PT, ES). Le changement est persisté par `LanguageService` via `shared_preferences` et appliqué sans redémarrage.

11. **Cache des informations utilisateur** : les données de profil sont mises en cache localement pour 7 jours. Si le cache n'est pas expiré, les données sont servies immédiatement et une mise à jour en arrière-plan est lancée silencieusement. Après expiration, le réseau est requis ; en cas d'échec réseau, le cache expiré est servi en fallback.

12. **Invalidation du cache** : le cache est invalidé explicitement lors d'un `forceRefresh` (ex : après mise à jour du profil) ou d'une suppression explicite via `invalidateUserInfoCache()`.

13. **RGPD — droits utilisateur** (voir RETRO-029) :
    - Article 15 (accès) : l'utilisateur peut visualiser un résumé de ses données via `GdprService.getDataSummary()`.
    - Article 20 (portabilité) : l'utilisateur peut exporter l'intégralité de ses données au format JSON. L'export est copié dans le presse-papier (mécanisme cross-platform actuel).
    - Article 17 (effacement) : l'utilisateur peut supprimer son compte depuis la page Mes données et depuis la page principale du profil.
    - La Politique de confidentialité et les CGU sont consultables in-app via des dialogs dédiés.

14. **Re-consentement** : à chaque login, `GdprService.getConsentStatus()` est interrogé. Si `needsAnyAcceptance == true`, un modal bloque l'accès au reste de l'application jusqu'à acceptation des nouvelles versions des documents légaux.

15. **Discord** : un lien externe vers le serveur Discord est ouvert via `url_launcher` en mode `externalApplication`. En cas d'impossibilité d'ouvrir l'URL, une notification d'erreur est affichée.

---

## Cas d'usage (déduits)

### CU-001 — Consulter son profil
L'utilisateur ouvre la page "Mon compte". L'avatar, le username et l'email s'affichent dans l'en-tête. Si les informations sont disponibles en cache (< 7 jours), elles s'affichent immédiatement, et une mise à jour en arrière-plan est lancée. En cas de chargement en cours, un spinner central est affiché.

### CU-002 — Éditer son profil
L'utilisateur tape sur "Modifier le profil". Il arrive sur `ProfileEditView`. Il peut modifier son `displayName`, sa `bio`, son avatar (sélection depuis la galerie, encodé en base64), sa date de naissance, son genre, et la visibilité publique de son profil. Il valide via "Enregistrer". Si succès, le cache est invalidé et la page profil recharge les données à jour.

### CU-003 — Changer son mot de passe
L'utilisateur tape sur "Changer le mot de passe". Un dialog s'affiche avec un champ de saisie du nouveau mot de passe. Il valide. Une notification de succès ou d'erreur est affichée.

### CU-004 — Activer / désactiver la biométrie
La ligne biométrique n'est visible que si le device la supporte. L'utilisateur bascule le switch. Si désactivation : immédiate. Si activation : vérifie les credentials stockés, demande une reconnexion si absents.

### CU-005 — Changer le thème
L'utilisateur tape sur "Thème". Un dialog affiche les 3 options (Clair, Sombre, Système). Le choix est appliqué immédiatement et persisté.

### CU-006 — Changer la langue
L'utilisateur tape sur "Langue". Un sélecteur affiche les 7 langues disponibles. Le changement est appliqué sans redémarrage.

### CU-007 — Consulter et exercer ses droits RGPD
L'utilisateur tape sur "Mes données". Il accède à la page `MyDataView` qui expose :
- Un résumé de ses données (article 15).
- Un bouton d'export JSON (article 20) — le JSON est copié dans le presse-papier.
- La Politique de confidentialité et les CGU (via dialogs).
- La suppression de compte (article 17).

### CU-008 — Supprimer son compte
Depuis la page profil ou depuis "Mes données", l'utilisateur déclenche la suppression. Un dialog de confirmation s'affiche. Après confirmation, `UserService.deleteAccount()` est appelé, puis l'utilisateur est redirigé vers `/login`.

### CU-009 — Se déconnecter
L'utilisateur tape sur "Déconnexion". Un dialog de confirmation s'affiche. Après confirmation, `AuthService.logout()` est appelé et l'utilisateur est redirigé vers `/login`.

### CU-010 — Naviguer vers les features sociales et statistiques
Depuis le profil, l'utilisateur peut accéder directement à ses statistiques (`/stats`), ses amis (`/friends`), sa messagerie (`/inbox`), ses groupes de lecture (`/reading-groups`), ses téléchargements (`/downloads`), ses sélecteurs personnalisés (`/custom-selectors`), et les paramètres de notifications (`/notifications-settings`).

---

## Dépendances

- `UserService` — lecture et mise à jour des informations utilisateur, suppression de compte, changement de mot de passe
- `GdprService` — droits RGPD (articles 15, 20) et gestion du consentement versioned
- `AuthService` — déconnexion, gestion biométrique
- `BiometricService` — détection du support biométrique, authentification
- `ThemeService` — lecture et persistance du thème
- `LanguageService` — lecture et persistance de la langue
- `OfflineCacheService` — cache local des informations utilisateur
- `Notifier` — notifications snackbar
- `go_router` — navigation vers les sous-pages et retour vers `/login`
- `image_picker` — sélection d'avatar depuis la galerie
- `url_launcher` — ouverture du lien Discord externe

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Avatar "coming soon"** : le tap sur l'avatar dans `profile.dart` affiche un message `comingSoonAvatar`, mais `ProfileEditView` implémente déjà la sélection d'image. La relation entre les deux points d'entrée (avatar dans le header vs avatar dans la page d'édition) n'est pas clairement délimitée.
- **Vider un champ de profil** : le code indique explicitement qu'il n'est pas possible de vider un champ (ex : effacer le `displayName`) via l'API actuelle. Est-ce une limitation temporaire ou un choix permanent ?
- **Export RGPD via presse-papier** : l'utilisation du presse-papier comme mécanisme de livraison de l'export est mentionnée comme un workaround cross-platform. Est-ce acceptable en production ou une implémentation `share_plus` / fichier téléchargeable est-elle prévue ?
- **Re-consentement dans le flow auth** : le re-consentement est décrit dans `GdprService` mais son point d'intégration exact dans le flow de login n'est pas visible depuis `profile.dart` seul — il serait à vérifier dans `auth`.
- **`UserDto` vs `UserInformationDto`** : deux DTOs coexistent pour les données utilisateur. `UserDto` est plus simple (username, email, avatar, lastLogin, emailVerified) et étend `Equatable`. `UserInformationDto` est plus riche (profil étendu Phase 3). L'usage de `UserDto` n'est pas visible dans les fichiers profile actuels — son périmètre d'usage est à clarifier.
