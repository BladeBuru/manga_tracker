# Spec Fonctionnelle — reader [DRAFT — à valider par le dev]

| Champ      | Valeur              |
|------------|---------------------|
| Module     | reader              |
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
| [RETRO-017](../../adr/RETRO-017-platform-split-conditional-exports.md) | Platform-split lecteur via conditional exports Dart | Documenté (rétro) |
| [RETRO-018](../../adr/RETRO-018-reading-progress-near-end-gate.md) | Validation de la progression de lecture conditionnée à la fin du chapitre (seuil 15%) | Documenté (rétro) |

> *Table auto-générée par adr-linker. Ne pas éditer manuellement.*

---

## Contexte et objectif

Le module `reader` fournit à l'utilisateur la capacité de lire des chapitres de manga depuis l'application. Le contenu manga étant hébergé sur des sites tiers (MangaScan, SushiScan, Webtoons, etc.), la lecture en ligne s'effectue via une WebView embarquée (`flutter_inappwebview`) qui charge directement le site tiers. Sur plateforme web (navigateur), la WebView embarquée n'est pas applicable (restrictions CSP / X-Frame-Options) : l'application ouvre le lien dans un nouvel onglet via `url_launcher`.

Le module gère également la lecture hors-ligne des chapitres préalablement téléchargés (feature `download`) via un lecteur HTML dédié.

---

## Règles métier (déduites du code)

1. **Lecture en ligne — mobile uniquement** : la WebView embarquée (`flutter_inappwebview`) n'est instanciée que sur mobile (iOS/Android). Sur plateforme web Flutter, `ReaderWebView` est remplacé par un stub qui propose d'ouvrir l'URL dans le navigateur externe.

2. **Lecture hors-ligne — mobile uniquement** : `OfflineReaderView` affiche le HTML téléchargé uniquement sur mobile. Sur plateforme web Flutter, un stub "non disponible sur web" est rendu à la place.

3. **Redirection automatique vers le lecteur hors-ligne** : au démarrage de la WebView en ligne, si le prochain chapitre (numéro `initialLastRead + 1`) est déjà téléchargé, l'application redirige automatiquement vers `OfflineReaderView` sans afficher la WebView en ligne.

4. **Détection du chapitre courant** : le numéro de chapitre en cours de lecture est déduit de l'URL chargée dans la WebView, selon un ordre de priorité : (1) patterns regex personnalisés par domaine, (2) paramètres de requête (`chapter`, `ch`, `ep`, `episode_no`, etc.), (3) patterns dans le chemin de l'URL (ex. `/chapter-120/`, `/c120`, `/ep-10/`).

5. **Sauvegarde de progression — seuil de fin** : la progression de lecture (numéro de chapitre lu) n'est sauvegardée en bibliothèque que si l'utilisateur se trouve dans les 15 derniers pourcents du chapitre (`isNearEnd = percentageFromEnd <= 15`). Si l'utilisateur ferme le lecteur avant ce seuil, la progression n'est pas enregistrée.

6. **Validation de progression au retour** :
   - Passage naturel au chapitre suivant (+1) : le chapitre précédent ET le nouveau sont automatiquement marqués comme lus.
   - Saut de chapitres (avance de +2 ou plus) : une boîte de dialogue demande à l'utilisateur s'il veut marquer les chapitres précédents comme lus.
   - Retour en arrière : aucun commit de progression.
   - Fermeture du lecteur (bouton retour) : un dialogue "Avez-vous fini le chapitre X ?" n'est affiché que si l'utilisateur est proche de la fin (≤15%).

7. **Sauvegarde de position de scroll** : la position verticale de scroll dans la WebView est sauvegardée périodiquement (toutes les 5 secondes) et à la fermeture, dans `SharedPreferences` avec la clé `scroll_position_{muId}_{chapter}`. Une seule position est conservée par manga (les positions des autres chapitres sont supprimées). Les positions à ≥95% de la hauteur totale ne sont pas sauvegardées (le chapitre est considéré comme terminé).

8. **Restauration de position de scroll** : à l'ouverture d'un chapitre déjà partiellement lu, la position sauvegardée est restaurée après chargement de la page, sauf si l'utilisateur a déjà scrollé manuellement (position > 100px).

9. **Bloqueur de publicités** :
   - Activé par défaut (préférence `ad_blocker_enabled` dans `SharedPreferences`).
   - Fonctionne à deux niveaux : blocage réseau via `ContentBlocker` (liste de domaines publicitaires), et injection JavaScript post-chargement (suppression CSS + MutationObserver).
   - Un mode interactif permet à l'utilisateur de cliquer sur une publicité non détectée pour la bloquer, en ajoutant un sélecteur CSS personnalisé persisté dans `CustomSelectorsService`.
   - Les sélecteurs personnalisés (par domaine ou globaux `*`) sont intégrés aux ContentBlockers et au script JS.

10. **Détection et gestion des captchas** : si un captcha (Cloudflare, reCAPTCHA, hCaptcha) est détecté (par URL ou inspection DOM), le bloqueur de pub est automatiquement et temporairement désactivé pour permettre la résolution du challenge. Le bloqueur est réactivé automatiquement après résolution (détection du cookie `cf_clearance`).

11. **Filtrage de domaine** : la WebView n'autorise les navigations principales qu'au sein du même "provider" (domaine de base partagé, ex. `sushiscan.net` et `cdn.sushiscan.net` sont considérés comme le même provider). Toute navigation vers un domaine externe non publicitaire est bloquée.

12. **Mise à jour du lien personnalisé** : après détection d'un nouveau chapitre, le lien personnalisé de l'utilisateur en bibliothèque est automatiquement mis à jour vers l'URL du chapitre suivant (calculée par `ChapterLinkResolver.buildNextUrl`).

13. **Téléchargement depuis la WebView** : la WebView embarquée propose un bouton "Télécharger" qui extrait le HTML de la page via JavaScript (résolution des URLs relatives, forçage de chargement des images lazy), télécharge les images localement via `ChapterDownloadService`, et enregistre le chapitre dans `DownloadManagerService`.

14. **Lecteur hors-ligne — nettoyage HTML** : le HTML téléchargé est nettoyé avant affichage (suppression des `<link>` CSS externes, `<script>` externes et trackers, `<iframe>` externes, imports CSS distants) et rendu responsive (injection d'un `<style>` pour `img { max-width: 100% }`).

15. **Lecteur hors-ligne — isolation réseau** : toutes les requêtes réseau (HTTP/HTTPS) sont bloquées dans la WebView du lecteur hors-ligne. Seules les URLs `file://` sont autorisées.

16. **Navigation inter-chapitres (hors-ligne)** : dans le lecteur hors-ligne, des boutons "Chapitre précédent" et "Chapitre suivant" permettent de naviguer entre chapitres téléchargés disponibles localement.

17. **Mode autoDownload** : la WebView peut être ouverte en mode `autoDownload = true`, auquel cas le téléchargement est déclenché automatiquement au chargement de la page (si les cookies Cloudflare clearance sont présents) et la WebView se ferme après succès.

---

## Cas d'usage (déduits)

### CU-001 — Lecture en ligne d'un chapitre (mobile)
L'utilisateur ouvre un chapitre depuis la fiche manga. La WebView charge l'URL fournie. Le bloqueur de pub s'active. Le chapitre courant est détecté depuis l'URL. L'utilisateur lit. La position de scroll est sauvegardée périodiquement. En fermant, si l'utilisateur est proche de la fin, un dialogue lui propose de valider la lecture. La progression est sauvegardée en bibliothèque si confirmé.

### CU-002 — Passage au chapitre suivant en ligne
L'utilisateur navigue vers la page du chapitre suivant dans la WebView. La WebView détecte le changement de numéro, marque automatiquement le chapitre précédent comme lu, et commence à sauvegarder la position du nouveau chapitre.

### CU-003 — Captcha détecté en cours de lecture
Le site tiers présente un challenge Cloudflare. L'application détecte le captcha (URL ou DOM). Le bloqueur de pub est désactivé. Une notification informe l'utilisateur. Après résolution (cookie `cf_clearance` détecté), le bloqueur est réactivé.

### CU-004 — Lecture hors-ligne d'un chapitre téléchargé
L'utilisateur ouvre un chapitre précédemment téléchargé. Le HTML stocké localement est chargé dans la WebView (base URL `file://`). Les ressources externes sont toutes bloquées. La position de scroll précédente est restaurée. En fermant, si proche de la fin, la progression est enregistrée.

### CU-005 — Lecture sur plateforme web (navigateur)
L'utilisateur tente de lire un chapitre depuis la version web de l'application. La WebView embarquée n'est pas disponible. Un bouton "Ouvrir le chapitre" lance `url_launcher` pour ouvrir l'URL dans un nouvel onglet du navigateur. Aucune progression automatique n'est sauvegardée (limitation plateforme web).

### CU-006 — Blocage d'une publicité non détectée (mode interactif)
L'utilisateur active le mode interactif depuis l'AppBar. Un script JS est injecté. L'utilisateur clique sur un élément publicitaire. Un sélecteur CSS est généré et persisté dans `CustomSelectorsService`. L'élément est immédiatement masqué. Le sélecteur sera intégré aux blocages futurs pour ce domaine.

---

## Dépendances

- **`LibraryService`** — commit de la progression de lecture (`saveChapterProgress`), mise à jour du lien personnalisé (`updateCustomLink`)
- **`DownloadManagerService`** — vérification et enregistrement des chapitres téléchargés
- **`ChapterDownloadService`** — traitement HTML + téléchargement des images pour mise en cache offline
- **`AdBlockerService`** — gestion des ContentBlockers et scripts JS de blocage publicitaire
- **`CaptchaDetectionService`** — détection DOM/URL des challenges CAPTCHA
- **`ScrollPositionService`** — persistance/restauration de la position de scroll (SharedPreferences)
- **`WebViewNavigationService`** — classification des changements de chapitre (firstDetected/nextChapter/jumpForward/jumpBackward/noChange)
- **`ChapterLinkResolver`** — extraction du numéro de chapitre depuis une URL, construction de l'URL du chapitre suivant
- **`ReadingProgressHelper`** — calcul de la position relative dans le chapitre (near end ≤ 15%)
- **`CustomSelectorsService`** — chargement et persistance des patterns URL et sélecteurs CSS personnalisés par domaine
- **`SharedPreferences`** — préférence `ad_blocker_enabled`, positions de scroll `scroll_position_{muId}_{chapter}`, cookies par domaine `cookies_{domain}`
- **`go_router`** — routes `/manga/:muId/read` et `/manga/:muId/read-offline`
- **`flutter_inappwebview`** (mobile uniquement) — moteur WebView, ContentBlockers, JavaScript bridge

---

## Zones d'incertitude

> Les points suivants n'ont pas pu être déterminés par le code seul :

- **Cohérence `initialLastRead` vs chapitre réellement ouvert** : la WebView reçoit `initialLastRead` (dernier chapitre validé) et `initialUrl` (URL à ouvrir), qui peuvent correspondre à des chapitres différents. La logique de détection suppose que l'URL ouverte correspond à `initialLastRead + 1`, mais ce n'est pas garanti si l'utilisateur a un lien personnalisé non incrémental.
- **Comportement iOS du lecteur hors-ligne** : le code utilise `shouldOverrideUrlLoading` pour bloquer les requêtes réseau, mais mentionne en commentaire que `androidShouldInterceptRequest` est Android-only. Le comportement réel sur iOS pour le blocage des ressources hors-ligne n'a pas pu être vérifié à partir du code.
- **Téléchargement depuis la WebView en mode non-autoDownload** : le bouton "Télécharger" dans l'AppBar déclenche `_downloadCurrentPage()`. Il n'est pas clair si ce flow est distinct du flow de téléchargement géré par la feature `download`, ou s'il y a des cas de doublon.
- **Cookie saving pour les domaines** : les cookies sont sauvegardés dans `SharedPreferences` (clé `cookies_{domain}`) après chargement de chaque page, mais leur utilisation ultérieure (pour les téléchargements automatiques) n'est pas clairement consommée dans le code lu.
- **Persistance de la sélection de langue du lecteur** : aucun sélecteur de langue ni préférence de format de lecture (LTR/RTL, scroll/page) n'a été identifié dans le code du reader.
