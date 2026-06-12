# RETRO-029 — GdprService : centralisation des droits RGPD comme invariant de sécurité

| Champ      | Valeur              |
|------------|---------------------|
| Statut     | Documenté (rétro)   |
| Date       | 2026-06-04          |
| Source     | Rétro-ingénierie    |
| Features   | profile             |

## Justification (politique ADR v2.3.0)

| Champ | Valeur |
|-------|--------|
| Catégorie | SECURITY |
| Q1 — Coût de revert > 1j ? | OUI — GdprService est consommé par auth (re-consentement au login via `getConsentStatus`), profile (page Mes données), et register (enregistrement du consentement via `recordConsent`). Supprimer ou restructurer ce service implique de modifier le flow d'inscription, la logique de login, et la page Mes données — bien au-delà d'un seul fichier. |
| Q2 — Non-déductible du code ? | OUI — Le choix de regrouper les trois articles RGPD (15/20/17) dans un seul service dédié avec un modèle `ConsentStatus` versioned (`tosVersion` / `privacyVersion` fournis par le serveur, jamais hardcodés côté client) ne se déduit pas de `pubspec.yaml` ni d'aucun fichier de config. |
| Q3 — Impact transverse (≥ 2 specs) ? | OUI — Specs concernées : `profile` (page Mes données, GdprService direct), `auth` (re-consentement au login, `ConsentStatus.needsAnyAcceptance`, flow inscription avec `recordConsent`). |
| Q4 — Casse un invariant si ignoré ? | OUI — Un dev implémentant une nouvelle page ou un nouveau flow d'inscription sans passer par GdprService pourrait contourner la vérification de consentement versioned, violant l'obligation légale RGPD d'enregistrement du consentement avec la version du document accepté. |

> Validé contre la politique `.claude/rules/06-adr-policy.md`.

## Contexte

L'application traite des données personnelles (email, pseudo, avatar, date de naissance, genre, bibliothèque, historique de lecture). Le RGPD impose des obligations concrètes : droit d'accès (article 15), droit à la portabilité (article 20), droit à l'effacement (article 17), et consentement éclairé à l'inscription avec re-consentement obligatoire lors des mises à jour des documents légaux.

Pour ne pas disperser ces obligations dans les différentes features, le projet a centralisé tout le droit des données dans un service dédié (`GdprService`) avec des endpoints API dédiés (`/user/gdpr/*`).

## Décision identifiée

`GdprService` est le point d'entrée unique pour toutes les opérations RGPD côté client :

- `getDataSummary()` — Article 15 : accès aux données détenues (`/user/gdpr/summary`)
- `exportData()` — Article 20 : export complet en JSON (`/user/gdpr/export`)
- `getConsentStatus()` — retourne `ConsentStatus` avec les versions actuelles des documents et les flags `needsTosAcceptance` / `needsPrivacyAcceptance`
- `recordConsent(tosVersion, privacyVersion)` — enregistre le consentement versioned côté serveur ; les versions sont celles retournées par `getConsentStatus()`, jamais hardcodées

Le flow de re-consentement est déclenché à chaque login si `ConsentStatus.needsAnyAcceptance == true`. En cas d'erreur réseau sur `getConsentStatus()`, le retour `null` est interprété comme "tout est OK" pour ne pas bloquer l'utilisateur.

La suppression de compte (article 17) est exposée via `UserService.deleteAccount()` et accessible depuis deux points d'entrée dans l'UI : la section Actions du profil principal et la section Suppression dans la page Mes données.

## Conséquences observées

### Positives
- Aucun appel direct aux endpoints RGPD en dehors de `GdprService` — la surface de risque de contournement est réduite.
- `ConsentStatus` est un modèle typé (non un `Map<String, dynamic>` brut), ce qui force la lecture explicite des champs `needsTosAcceptance` et `needsPrivacyAcceptance`.
- `GdprService` n'a aucune dépendance à `dart:io` — compatible Web sans adaptation.

### Négatives / Dette
- La suppression de compte (`deleteAccount`) est dans `UserService` et non dans `GdprService`, créant une légère incohérence : le droit à l'effacement est éparpillé entre deux services.
- L'export de données sur mobile utilise le presse-papier comme mécanisme de livraison (workaround cross-platform). Pour une conformité RGPD robuste, un téléchargement de fichier ou un partage via `share_plus` serait plus approprié.
- Pas de cache local du `ConsentStatus` : chaque login déclenche un appel réseau.

## Recommandation

Garder `GdprService` comme point d'entrée unique. À terme, migrer `deleteAccount` vers `GdprService` pour regrouper tous les droits article 17 au même endroit. Implémenter le téléchargement de fichier via `path_provider` + `share_plus` sur mobile pour l'export article 20.
