# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/) · Versioning : [SemVer](https://semver.org/lang/fr/).

---

## [Unreleased] — feat/reco-order-dismiss

### ⚡ Améliorations

- **Vos recommandations ne changent plus d'ordre.** Les titres proposés sur l'accueil se retrouvaient rangés autrement dès que vous ouvriez la liste complète : impossible de remettre la main sur celui que vous veniez de repérer. L'accueil montre désormais exactement le début de la liste dépliée.
- **La liste complète des recommandations s'ouvre du tac au tac.** Elle repartait de zéro à chaque ouverture ; elle réutilise maintenant ce que l'accueil a déjà chargé. Un geste de bas en haut la rafraîchit toujours quand vous le demandez.

### ✨ Nouveautés

- **Dire « celui-là ne m'intéresse pas » se voit enfin.** Vous pouviez déjà écarter un titre de vos recommandations, mais rien ne le laissait deviner : il fallait connaître l'appui long. À votre première visite de la page des recommandations, un rappel vous l'explique — une seule fois, puis il disparaît pour de bon. Et chaque titre de cette page porte maintenant un bouton dédié, qui vous demande toujours pourquoi avant d'écarter quoi que ce soit. L'appui long, lui, continue de fonctionner partout où il fonctionnait déjà.

### Notes d'implémentation

- Cause de l'incohérence d'ordre : **côté serveur**, `limit` et `offset` font partie de la clé de cache de `GET /recommendations` (`recommendation.service.ts:178-180`). L'accueil (`limit=10`) et la page « Tout voir » (`limit=50`) déclenchaient donc deux calculs complets et **indépendants** du classement — et ce calcul n'est pas déterministe : tris par score sans départage secondaire (`recommendation-dto-builder.service.ts:69`), ordre d'insertion produit par un `Promise.all` (`recommendation.service.ts:205-221`), troncature `slice(0, 12)` sur un `getRawMany()` sans `ORDER BY` (`reco-graph-candidate.service.ts:129-138`), et surtout des écritures en base lancées en tâche de fond par la requête précédente, dont la colonne `type` qui pilote l'entrelacement par type d'œuvre (`recommendation-dto-builder.service.ts:155-159`). Ce n'était **pas** le cache client.
- L'entrelacement lui-même est innocent : il s'applique à la liste entière **avant** `slice(offset, offset + limit)` (`recommendation-dto-builder.service.ts:94-102`), il est donc stable par préfixe à `limit` variable. Le vivier de candidats du chemin principal ne dépend pas non plus de `limit` (`recommendation.service.ts:389-396`). Exception : le chemin **cold start** (bibliothèque vide) dimensionne son vivier en `offset + limit + 50` puis re-trie sur une autre clé (`sleeper-hits.service.ts:187-190, 242-243, 271`) — violation directe et déterministe, à corriger côté serveur.
- Correction côté application : une seule **page canonique** (`kRecommendationsPageSize`, `lib/features/recommendations/recommendations_paging.dart`) demandée par les deux écrans, l'accueil n'affichant que ses premiers éléments (`homeRecommendationsPreview`). Le parcours passe de deux classements serveur à un seul ; le surcoût de l'accueil se limite à 40 objets sérialisés en plus, le calcul serveur ne dépendant pas de la taille de page demandée. Une grande première page est un choix délibéré : chaque page supplémentaire est un calcul indépendant, donc une occasion de doublon ou de trou.
- `getPersonalizedRecommendations` gagne `forceRefresh` : le cache de la première page étant désormais presque toujours frais, « tirer pour rafraîchir » n'aurait plus rien fait. Le drapeau d'exhaustivité et la pagination `offset > 0` sont inchangés.
- Découvrabilité : `RecommendationTipStore` (préférence d'appareil, **hors GetIt** — l'ordre du service locator n'est pas touché) + `DismissRecommendationTip`, qui gère lui-même son « une seule fois ». Le drapeau est posé **dès l'affichage** et non sur « Compris » : une astuce lue puis quittée par le bouton retour a rempli son rôle.
- `DismissibleRecommendationCard` reçoit `showDismissAction`, **faux par défaut** : seule la page « Tout voir » l'active. L'accueil et la page par genre gardent des cartes strictement inchangées, conformément au raisonnement de `feat/pas-interesse` (une croix sur les trois écrans encombrerait et provoquerait des rejets accidentels). Le bouton n'écarte rien par lui-même — il ouvre la feuille qui demande la raison, avec sa sortie « Annuler ».
- La page « Tout voir » n'a plus qu'un seul chemin de rendu : bandeau d'accueil et astuce en en-têtes optionnels au-dessus de la grille, au lieu de deux branches dupliquées.

### Reste à faire côté serveur

- Sortir `limit` / `offset` de la clé de cache et paginer **après** le cache (`recommendation.service.ts:178-180` et `244-251`) : une seule liste canonique par `(utilisateur, genre)`, tranchée à la lecture. Sans changer l'algorithme, cela garantit l'invariant à l'intérieur de la fenêtre de cache et divise par N le nombre de classements calculés.
- Départages secondaires sur tous les tris par score, `ORDER BY` total avant les troncatures, et vivier cold start indépendant de `limit` — détail dans `.claude/memory-bank/known-issues.md`.

### Tests

- `flutter test` : **482 tests verts** (460 avant). `flutter analyze` : **40 informations, 0 erreur, 0 avertissement** (identique à la branche parente).
- `recommendations_order_test.dart` (+9) : l'aperçu de l'accueil est le préfixe strict de la page canonique pour toutes les tailles rencontrées, l'accueil demande bien la page canonique, et un fil de détente relit les sources pour interdire le retour d'une taille de page en dur.
- `recommendation_service_cache_test.dart` (+4) : accueil puis « Tout voir » ne déclenchent **qu'une** requête et renvoient la même liste ; `forceRefresh` ignore le cache en lecture mais l'alimente, retombe dessus hors ligne, et ne touche ni à la pagination `offset > 0` ni au drapeau d'exhaustivité.
- `dismiss_discoverability_test.dart` (+9) : l'astuce s'affiche une fois, est mémorisée dès l'affichage, ne revient pas après remontage (persistance réelle), et ne clignote pas avant lecture de la préférence ; le bouton explicite n'existe que là où il est demandé, ouvre bien la feuille de rejet, et le geste d'appui long reste branché.

### Nouvelles clés i18n (7 langues)

- `recommendationsTipTitle`, `recommendationsTipBody`, `recommendationsTipAction` — astuce d'usage montrée une seule fois.
- `dismissRecommendationAction` — libellé du bouton explicite (aussi utilisé comme étiquette pour les lecteurs d'écran).
## [Unreleased] — feat/home-carousel-ux

### ✨ Nouveautés

- **Les carrousels de l'accueil se prolongent quand vous faites défiler.** Chaque rangée de titres s'arrêtait après un nombre fixe d'éléments et il fallait passer par « Tout voir » pour continuer. Maintenant, en approchant de la fin d'une rangée, la suite se charge toute seule. « Tout voir » reste là quand vous préférez la vue en grille.
- **Vous voyez d'un coup d'œil les titres que vous avez déjà.** Sur l'accueil et sur les pages « Tout voir », une petite pastille sur la couverture signale les titres déjà présents dans votre bibliothèque. Elle apparaît dès que vous ajoutez un titre depuis sa fiche, et reste juste même sans connexion.

### ⚡ Améliorations

- **La source des données est désormais créditée.** Les fiches, le catalogue et les suggestions viennent de MangaUpdates : la mention figure en bas de l'accueil, en bas des pages « Tout voir » et sur votre profil.

### Notes d'implémentation

- **Une seule pagination pour deux surfaces.** Le carrousel réutilise `HomeSectionPageBloc`, celui de la page « Tout voir », plutôt que d'en écrire une seconde. Le BLoC gagne une taille de page configurable (`limit`) et un évènement `SeedSectionPage` qui déclare l'aperçu déjà affiché comme page 1, sans requête : `GET /mangas/home/sections?limit=20` fournit la page 1, le défilement enchaîne sur `GET /mangas/home/sections/:id?page=N&limit=20`. Append, déduplication par `muId`, garde hors ligne et gestion d'échec restent écrits une seule fois.
- Une page **vide** ferme la pagination quel que soit le `total` annoncé par le serveur — sans ça, un carrousel arrivé au bout redemandait la même page à chaque geste. Correction qui profite aussi à la grille « Tout voir ».
- Hors ligne (`HomeSectionsState.isOffline` propagé jusqu'au carrousel), aucune requête n'est tentée. Les éléments arrivent en fin de liste : la position de défilement n'est jamais déplacée (test dédié).
- `LibraryIndexService` (core/services, 113 lignes) : index mémoire des `muId` possédés, dérivé du cache local `cached_library` — **zéro appel réseau**, donc juste hors ligne. `ValueListenable` consommé par `LibraryOwnedIdsBuilder`, pas de BLoC supplémentaire. Trois sources de vérité, par ordre de fiabilité : réécriture du cache (`OfflineCacheService.libraryCacheObserver`, branché dans `setupServiceLocator`), marquage optimiste sur ajout / retrait dans `LibraryService`, lecture paresseuse au premier affichage.
- Purge : l'index vit en mémoire, `purgeUserScopedCache()` ne l'atteindrait pas — il reçoit `null` à la purge, sinon un appareil partagé signalerait la bibliothèque du compte précédent. Le mécanisme existant d'invalidation du cache des recommandations est inchangé.
- GetIt : `LibraryIndexService` ajouté **en fin** de `setupServiceLocator`, `registerLazySingleton` sans `dependsOn`. La factory `HomeSectionPageBloc` (page « Tout voir ») n'est pas touchée : le carrousel construit son BLoC lui-même, avec sa propre taille de page.
- Choix visuel de l'indicateur : la pastille de type (Manga / Manhwa / Manhua) occupe déjà le haut **gauche** de la couverture. Un second badge texte serait illisible sur une vignette de 120 px, donc l'appartenance prend le haut **droit**, en icône seule (`bookmark_added_outlined`) — aucun recouvrement possible, aucun texte ajouté à la carte. L'information n'est pas portée par la seule couleur : icône signifiante + annonce d'accessibilité traduite. `CoverBadge` gagne une variante `.icon` au lieu d'un troisième motif de pastille dans le projet.
- `HomeSectionCard` : la configuration de carte partagée par le carrousel et la grille vit à un seul endroit.
- `manga_card.dart` repasse sous la limite de 400 lignes (407 → 328) par extraction des deux widgets de progression dans `manga_card_progress.dart`, sans changement visuel. `AppRadius.full` remplace le `BorderRadius.circular(999)` en dur.
- Crédit MangaUpdates posé en bas de défilement (accueil, page « Tout voir ») plutôt que sous chaque carrousel, plus une mention permanente au pied du profil : l'application n'a pas d'écran « À propos », et « Mes données » ne traite que les données personnelles.
- Dette connue, **non aggravée volontairement** : `library.service.dart` dépassait déjà la limite de 400 lignes (422) et passe à 439 (+ 1 helper d'index de 11 lignes). Découpage à traiter dans une session dédiée.

### Tests

- `flutter test` : **481 tests verts** (460 sur la base `a4e055d`). `flutter analyze` : **40 informations, 0 erreur, 0 avertissement** — identique à la base.
- `library_index_service_test.dart` (+7) : appartenance depuis le cache, `muId` décimal ⇄ entier, cache vide / illisible, lecture unique et `refresh()`, ajout / retrait + notification, remplacement à la réécriture du cache, purge puis relecture pour le compte suivant.
- `home_section_page_bloc_test.dart` (+5) : amorce d'un aperçu plein / incomplet / hors ligne, append avec déduplication, page vide qui ne reboucle jamais.
- `home_section_carousel_test.dart` (+7) : chargement déclenché près de la fin, doublon serveur ignoré, page vide (un seul appel malgré trois gestes), inertie hors ligne, indicateur discret + position de défilement conservée, pastille bibliothèque présente / absente, absence d'index tolérée.
- `home_section_page_test.dart` (+1) et `homepage_bloc_view_test.dart` (+1) : pastille dans la grille et crédit MangaUpdates, libellés vérifiés en français.

### Nouvelles clés i18n (7 langues)

- `homeSectionLoadingMore` — annonce d'accessibilité de l'indicateur de chargement en fin de carrousel.
- `libraryOwnedBadge` — annonce de la pastille « Déjà dans ma bibliothèque ».
- `dataSourceCredit` — crédit MangaUpdates.

## [Unreleased] — feat/reading-position-client

### ✨ Nouveautés

- **Reprenez votre lecture là où vous vous êtes arrêté.** Quand vous quittez un chapitre en plein milieu, l'application retient l'endroit exact et vous y ramène à la réouverture, au lieu de vous reposer en haut de la page.
- **Votre lecture vous suit d'un appareil à l'autre.** Vous vous arrêtez au milieu d'un chapitre sur votre tablette, vous reprenez sur votre téléphone au même endroit — et inversement. Si la lecture en cours porte sur un autre chapitre que celui qui allait s'ouvrir, l'application vous demande simplement lequel vous voulez : vous ne sautez jamais un chapitre sans le vouloir, et vous ne relisez jamais ce que vous avez déjà lu.

### ⚡ Améliorations

- **La fin d'un chapitre est enfin retenue.** Si vous lisiez jusqu'aux dernières images et que vous répondiez « Non » à la question « Avez-vous fini ce chapitre ? », l'application vous ramenait bien plus haut à la réouverture, sur un endroit que vous aviez dépassé depuis longtemps.
- **La page ne saute plus sous vos doigts.** Si vous commenciez à faire défiler pendant le chargement, l'application vous replaçait quand même à votre ancienne position et vous perdiez le fil. Elle respecte maintenant l'endroit où vous êtes.
- **Le bon endroit, même quand les images arrivent en retard.** Sur les chapitres lourds, la page s'allongeait après coup et vous étiez replacé trop haut : l'application vérifie désormais et corrige.

### 🐛 Corrections

- **Vos lectures ne se mélangent plus entre comptes.** Sur un appareil partagé, la personne qui se connectait après vous rouvrait un manga au milieu d'un chapitre qu'elle n'avait jamais ouvert. Vos positions de lecture sont maintenant effacées quand vous vous déconnectez.

### Notes d'implémentation

- Contrat consommé (API PR #83) : `PUT /library/reading-position` (`{ muId, chapter, positionPercent }`), `GET /library/:muId/reading-position` (200 / 204), plus les champs optionnels `currentChapter` / `currentPositionPercent` / `currentPositionUpdatedAt` de `GET /library/all`. **Déployer l'API avant l'application.** Le serveur remet ces champs à `null` quand le chapitre en cours devient terminé — règle non réimplémentée côté client.
- `ReadingPositionService` (< 300 lignes, `registerLazySingleton` en fin de `service_locator.dart`, sans `dependsOn`) : throttle d'un envoi / 10 s / manga, `flush()` immédiat à la sortie du lecteur, au passage en arrière-plan et dans `dispose()`. Jamais bloquant : 400 et 404 abandonnent, 429 / 5xx / réseau coupé conservent la position. Hors ligne, **une seule** position en attente par manga (pas de file façon `SyncService` : seule la dernière compte).
- Position exprimée en **pourcentage** (`ReadingPositionCalculator`, pure) et non en pixels : la même page fait 12 000 px sur une tablette et 5 000 sur un téléphone. `null` quand la mesure n'est pas exploitable, pour ne jamais lire une page en cours de chargement comme « 100 %, chapitre fini ».
- Décision de reprise dans `ReadingResumePolicy` (pure, modèle `ChapterCommitPolicy`) : silencieuse si la position porte sur `dernier lu + 1`, confirmée (modale traduite, sans émoji) si elle porte sur un autre chapitre. Position retenue entre 3 % et `kReadingEndThresholdPercent`. Garde-fou : un chapitre `<= dernier lu` n'est **jamais** rouvert au milieu.
- Défaut 1 corrigé : `saveScrollPosition` ne fait plus `return` au-delà de 85 %. La garantie « on ne rouvre pas un chapitre terminé au milieu » repose désormais sur la **suppression** de la position à la validation du chapitre, plus un verrou pur dans la politique de reprise.
- Défaut 2 corrigé : les garde-fous de restauration parsaient le retour de `evaluateJavascript` comme une chaîne alors qu'Android rend une `Map` — ils ne s'exécutaient jamais. Tout passe par `ReaderViewportProbe` / `WebViewResultParser` (Map **et** String), comme `reading_progress_helper.dart` le faisait déjà.
- Défaut 3 corrigé : les écritures sont suspendues pendant une restauration, qui vérifie et **retente** jusqu'à 3 passes (le document s'allonge après `onLoadStop`).
- Défaut 4 corrigé : `scroll_position_*` / `reading_position_*` sont purgées par `purgeUserScopedCache()` (déconnexion + changement de compte uniquement) ; `AuthService._purgeCache()` vide aussi l'état mémoire du service.
- `scroll_position_service.dart` : 425 → 296 lignes (persistance dans `ReadingPositionStore`, mesure dans `ReaderViewportProbe`) malgré les fonctionnalités ajoutées.

### Tests

- `flutter test` : **460 tests verts** (362 avant). `flutter analyze` : **40 informations, 0 erreur, 0 avertissement** (identique à la branche parente).
- `reading_position_calculator_test.dart` (+13), `webview_result_parser_test.dart` (+9), `reading_position_service_test.dart` (+19), `reading_resume_policy_test.dart` (+16), `scroll_position_service_test.dart` (+19), `resume_reading_dialog_test.dart` (+5), `manga_quick_view_reading_position_test.dart` (+8), `offline_cache_purge_test.dart` (+4), `reader_invariants_test.dart` (+7).
- Fixtures du contrat dans `test/fixtures/` : `reading_position.json`, `reading_position_saved.json`, `library_all_with_position.json`, `library_all_without_position.json`.

### Nouvelles clés i18n (7 langues)

- `resumeReadingTitle`, `resumeReadingMessage`, `resumeReadingConfirm`, `resumeReadingDecline` — modale de reprise inter-appareils.

## [Unreleased] — fix/reader-progress-semantics

### 🐛 Corrections

- **Vos chapitres lus ne sont plus décalés d'un cran.** Quand vous arriviez à la fin du chapitre 133 et que le site enchaînait sur le 134, l'application enregistrait aussitôt le 134 comme lu — alors que vous veniez tout juste de l'ouvrir. Votre progression avait donc systématiquement un chapitre d'avance sur votre lecture réelle. Désormais, un chapitre n'est compté comme lu que lorsque vous l'avez terminé.
- **La question « Avez-vous fini le chapitre ? » revient — et elle marche.** Elle ne s'affichait plus du tout après un passage au chapitre suivant, et le geste de retour sur les téléphones récents la contournait complètement. Quand vous quittez le lecteur près de la fin d'un chapitre, l'application vous demande de nouveau si vous l'avez terminé, quel que soit la façon dont vous sortez : geste de retour, flèche en haut à gauche ou bouton du téléphone.
- **Sauter des chapitres n'enregistre plus n'importe quoi.** Si vous passiez du chapitre 134 au 140 et que vous répondiez « oui » à la question, l'application enregistrait 139 chapitres lus. Elle enregistre maintenant le 134, celui que vous venez réellement de finir — exactement ce que la question propose.
- **Les chapitres téléchargés vous demandent aussi votre avis.** En lecture hors connexion, l'application marquait le chapitre comme lu toute seule dès que vous approchiez de la fin, sans rien demander. Elle pose désormais la même question que la lecture en ligne, et passer au chapitre suivant depuis la flèche enregistre celui que vous quittez.
- **Plus de notifications « Chapitre enregistré » en double.** Un même changement de chapitre pouvait déclencher plusieurs enregistrements et plusieurs messages d'affilée.
- **Votre page de lecture est retenue quand vous quittez l'application.** Si vous basculiez vers une autre application ou que le téléphone fermait Manga Tracker, vous pouviez perdre jusqu'à quelques secondes de lecture au retour.

### Notes d'implémentation

- Cause racine dans `web_view_io.dart` : la branche `nextChapter` de `_handleDetected` appelait `_commitIfNeeded(prev)` **puis** `_commitIfNeeded(newCh)` (« car on est dessus »). Introduit par `cc586a0` (v0.8.0), amplifié par `59ab81e` (v0.12.1). Effet en cascade : `_lastCommitted == _currentChapter` rendait la garde de la modale de fin (`_lastCommitted < c`) structurellement toujours fausse.
- Sémantique extraite dans `ChapterCommitPolicy` (pure, sans Flutter ni GetIt) : `nextChapter` → N seul ; `jumpForward` → N sur « oui » ; `jumpBackward` / `firstDetected` / `noChange` → rien ; sortie près de la fin avec C non enregistré → question, « oui » → C (`confirmedByUser: true`).
- `WillPopScope` → `PopScope(canPop: false, onPopInvokedWithResult:)` sur les deux lecteurs : `android:enableOnBackInvokedCallback="true"` fait ignorer `WillPopScope` par le retour prédictif d'Android 13+. Garde de réentrance (`_exitFlowRunning`) et borne de temps (`kNearEndMeasureTimeout`, 3 s) sur la mesure « proche de la fin ».
- `_handleDetected` sérialisé et idempotent (garde + mémorisation de la dernière URL + file d'attente de profondeur 1) : les trois callbacks de la WebView signalaient la même navigation.
- `WidgetsBindingObserver` sur les deux lecteurs : sauvegarde de la position sur `paused` / `inactive`, **aucun** enregistrement silencieux de chapitre.
- Modales extraites en widgets testables (`ChapterCompletionDialog`, `ChapterSkipDialog`), passées aux tokens (`AppColors`, `AppRadius`, `AppSpacing`, `textTheme`) — les `Colors.blue` / `Colors.green` / `Colors.orange` / `Colors.red` en dur ont disparu du lecteur.
- Nettoyage HTML du lecteur hors ligne extrait dans `OfflineHtmlSanitizer` (pur) : le fichier repassait sous la limite de 400 lignes.
- Chemins de sortie qui contournent volontairement la modale, documentés dans le code : redirection vers le lecteur hors ligne à l'ouverture (aucune lecture encore), fermeture automatique après téléchargement, navigation entre chapitres téléchargés.

### Tests

- `test/features/reader/chapter_commit_policy_test.dart` (+17) — dont le test de non-régression nommé « arriver sur un chapitre ne le marque JAMAIS comme lu », qui balaie les 5 transitions.
- `test/features/reader/chapter_completion_dialog_test.dart` (+6) — les deux modales, leurs réponses, et le fait que la question de fin ne se ferme pas d'un appui hors modale.
- `test/features/reader/reader_invariants_test.dart` (+10) — fil de détente sur le source : `_commitIfNeeded(newCh)`, retour de `WillPopScope`, disparition de la garde, de la garde de réentrance, de la borne de temps, de l'observateur de cycle de vie, ou de la sérialisation des détections.
- Suite complète : 362 tests verts (329 avant). `flutter analyze` : 40 informations, 0 erreur, 0 avertissement (45 avant).

### Nouvelle clé i18n (7 langues)

- `readerNoContentAvailable` — le chapitre téléchargé ne contient ni page ni images (texte auparavant en dur, en français).

## [Unreleased] — fix/l10n-cles-manquantes

### Fixed
- **L’application parle enfin votre langue partout.** En allemand, espagnol, japonais, coréen et portugais, l’écran des sélecteurs personnalisés et la section « Téléchargements » du profil s’affichaient en français. Ces textes sont maintenant traduits dans les 7 langues.
- 66 clés n’existaient que dans `app_fr.arb` (3 manquaient aussi en anglais) : `flutter gen-l10n` comblait alors silencieusement les getters générés avec le texte du template, donc du français, sans erreur bloquante. Les placeholders ICU (`{count}`) sont conservés ; les marqueurs émojis du texte FR/EN ne sont pas repris dans les nouvelles traductions (cf. `chore/emojis-vers-icones`).

### Tests
- `test/l10n/arb_keys_sync_test.dart` : les 6 ARB traduits doivent exposer exactement le jeu de clés de `app_fr.arb` (hors métadonnées `@`). Le test échouait avant correction (EN : 3 clés, DE/ES/JA/KO/PT : 66 clés) et passe désormais.

## [Unreleased] — fix/i18n-changelog-dialog

### 🐛 Corrections
- **L'écran « Quoi de neuf ? » parle enfin votre langue.** À chaque mise à jour, son titre et le bouton pour le refermer restaient en français, quelle que soit la langue choisie dans l'application. Ils sont désormais traduits dans les 7 langues, comme le reste de l'interface.

### Notes d'implémentation
- `ChangelogDialog` : les deux libellés en dur passent par `AppLocalizations` via les clés `whatsNew` et `great`, déjà présentes dans les 7 ARB mais jamais utilisées — aucune clé ajoutée, fichiers générés inchangés (`flutter gen-l10n` sans diff).
- +3 widget tests (`test/core/components/changelog_dialog_test.dart`) : rendu en anglais, rendu en français, fermeture + callback `onClose`.
- Reste en dur dans ce dialog : le préfixe « Version » (clé ARB `version` disponible) et le mot « build » — hors périmètre de ce correctif.

## [Unreleased] — feat/home-catalog-sections

### ✨ Nouveautés

- **Découvrez de nouvelles sections sur l'accueil.** L'accueil ne se limite plus à trois listes : il vous propose désormais de nombreuses rangées à faire défiler, comme un catalogue — les dernières sorties, ce qui marche le mieux, les mieux notés, le choix de la communauté, des pépites cachées, mais aussi des sélections par type (manga, manhwa, manhua), par genre (action, fantasy, romance…) et par année (« Les sorties de 2014 »…). De nouvelles sections pourront apparaître au fil du temps sans mise à jour de l'application.
- **Un bouton « Tout voir » sur chaque section** ouvre la sélection complète dans une grille qui se remplit au fur et à mesure que vous faites défiler, avec le nombre total de titres.
- **Le type de chaque œuvre est indiqué sur sa couverture** (manga, manhwa, manhua), pour repérer d'un coup d'œil ce qui vous plaît.
- Les titres des sections et des genres les plus courants s'affichent dans votre langue.

### ⚡ Améliorations

- L'accueil s'affiche avec des aperçus de chargement plutôt qu'une roue qui tourne, et s'adapte aux tablettes et aux grands écrans (cartes plus grandes, davantage visibles).
- Sans connexion, l'accueil et les sections déjà consultées restent disponibles, avec le bandeau habituel.
- Tirez vers le bas pour actualiser l'ensemble de l'accueil, recommandations comprises.

## [Unreleased] — statut « En cours » automatique

### ⚡ Améliorations

- **Un manga « À jour » repasse tout seul « En cours » dès qu'un nouveau chapitre sort.** Vous aviez lu jusqu'au chapitre 39 et le 40 vient de paraître ? Vous n'êtes plus à jour : le statut change automatiquement, sans rien avoir à faire. Cela vaut que le nouveau chapitre soit repéré par l'application (vérification de votre lien de lecture en arrière-plan ou à l'ouverture de la fiche) ou par le serveur, même application fermée. Le manga remonte en tête de votre bibliothèque pour que vous le voyiez tout de suite.
- **Le changement est visible immédiatement** dans la bibliothèque et sur la fiche du manga, et il est conservé si vous consultez votre bibliothèque hors connexion.
- **Rien d'autre ne bouge.** Les statuts « À lire plus tard » et « Terminé » ne sont jamais modifiés. Marquer un manga « À jour » vous-même reste possible : seule la sortie d'un nouveau chapitre le remet « En cours ». Et quand vous atteignez le dernier chapitre, le passage à « À jour » ou « Terminé » fonctionne comme avant.

> Fonctionne pleinement avec la version du serveur publiée en même temps (à mettre en ligne en premier).

## [Unreleased] — chore/emojis-vers-icones

### Changed
- L'interface utilise désormais de vraies icônes à la place des émojis (section « Pépites cachées » des recommandations, encarts d'aide du réglage des sélecteurs personnalisés, écran « Quoi de neuf »).

## [Unreleased] — lecteur : protection anti-redirection et bloqueur

### 🐛 Corrections

- **Fini les redirections vers des pages de publicité pendant la lecture.** Depuis la version 0.13.0, un clic ou un script pouvait vous envoyer sur une page publicitaire d'où il était impossible de revenir au chapitre. La protection qui bloque toute sortie du site de lecture est rétablie, et elle est désormais couverte par des tests automatiques pour qu'elle ne puisse plus disparaître.
- **L'interrupteur du bloqueur de publicités est de retour.** Vous voyez à nouveau d'un coup d'œil s'il est activé ou non ; il est actif par défaut, se coupe de lui-même le temps d'une vérification « êtes-vous un robot ? » et se rallume ensuite.
- **Vérification anti-robot : l'application se présente à nouveau comme un navigateur normal.** La tentative de la version 0.13.0 de maquiller l'identité du navigateur intégré n'aidait pas — et pouvait même rendre la vérification plus méfiante. Elle est retirée, et une information technique inutile qui identifiait l'application auprès des sites n'est plus envoyée. Si une vérification tourne en boucle malgré tout, l'application vous propose toujours d'ouvrir la page dans votre navigateur.
## [Unreleased] — feat/pas-interesse

### Added
- **« Pas intéressé / déjà vu » sur les recommandations** : un appui long sur une carte de recommandation propose d'écarter le titre, en demandant pourquoi — « déjà lu », « pas intéressé » ou « vu ailleurs » (animé, drama, film). Le titre disparaît alors de toutes les recommandations. Besoin d'origine : *« On me recommande One Piece et Naruto. Les deux, c'est les meilleurs, les plus connus. Sauf que moi je les ai — j'adore, mais je les ai vus en animé et je n'ai pas forcément envie de les relire. »* Aucun algorithme ne peut deviner ça, l'information n'existe nulle part ailleurs
- **Annulation immédiate** : un SnackBar de 6 s propose « Annuler » juste après le rejet. Un rejet accidentel est réversible sur-le-champ, sans aller fouiller dans les réglages — ce qui compte d'autant plus que le titre écarté ne remonte plus nulle part et serait autrement introuvable
- `RecommendationDismissalService` (`POST` / `DELETE /recommendations/dismissals/:muId`) + `DismissalReason` (valeurs de fil alignées sur l'API) + `DismissRecommendation` (event `HomePageBloc`)
- i18n ×7 langues (14 clés `dismiss*`)

### Changed
- **Geste choisi : appui long, pas de bouton.** Une croix sur chaque carte encombrerait les trois écrans de recommandations et provoquerait des rejets accidentels. L'appui long ne coûte rien visuellement, n'entre pas en conflit avec l'appui simple (ouverture de la fiche) et reste annoncé aux lecteurs d'écran via un hint `Semantics`
- `MangaCard` reçoit un `onLongPress` **optionnel**, nul partout ailleurs : bibliothèque, accueil (tendances / nouveautés / populaires), profil ami et fiche détail gardent exactement leur comportement
- `DismissibleRecommendationCard` centralise le mapping `MangaQuickViewDto` → `MangaCard`, jusqu'ici dupliqué à l'identique dans les trois écrans (dont la règle « note `N/A` → aucune note »)
- Retrait du titre adapté à chaque écran : liste paginée → retrait de `_items` **et décrément de `_offset`** (le serveur exclut désormais ce titre, sans ça la page suivante sauterait un élément) ; par genre → filtrage au rendu via un `Set` en state, les listes venant de `Future`s immuables (couvre aussi la section « Pépites », et une section vidée disparaît) ; accueil → event BLoC filtrant `recommendations` et `recommendationsByGenre`
- Le cache local des recommandations (TTL 2 h sur la première page) est invalidé à chaque rejet et à chaque annulation. Sans ça le titre écarté réapparaîtrait pendant 2 h et le geste paraîtrait sans effet

### Fixed
- La feuille modale débordait de 35 px sur un petit écran : elle est désormais scrollable et `isScrollControlled`. Sans ce correctif, le bouton « Annuler » passe sous le pli dès que la police est agrandie — la sortie de secours devenait inatteignable

### Notes d'implémentation
- `RecommendationDismissalService` est enregistré en `registerLazySingleton` **sans `dependsOn`** : il résout `HttpService` et `OfflineCacheService` à l'appel et non à la construction. L'ordre du service locator n'est donc pas modifié — cf. l'écran blanc au lancement de la v0.12.1, causé par un `dependsOn` sur un type pas encore enregistré
- Contrairement aux lectures de recommandations (qui avalent les erreurs pour ne pas casser l'écran), les erreurs de rejet sont remontées : un échec silencieux laisserait croire à l'utilisateur que c'est fait. Un 404 à l'annulation (rejet déjà supprimé) est en revanche traité comme un succès — le résultat voulu est atteint
- Dépend de l'API `feat/pas-interesse` : **déployer l'API avant l'app**

### Tests
- +19 tests (76 → 95) : service (URL, body, valeurs de fil, invalidation du cache et son absence sur échec, 429/404/500, annulation), feuille modale (3 raisons, titre rappelé, valeur retournée par raison, fermeture sans choix), geste (appui long déclencheur, branchement sur `MangaCard`, hint d'accessibilité, `N/A` non affiché, carte sans callback inchangée)
## [Unreleased] — mode hors ligne

### 🐛 Corrections

- **Vos mangas restent consultables sans connexion.** Jusqu'ici, dès que votre session avait expiré, l'application refusait d'afficher quoi que ce soit hors connexion — même une fiche que vous veniez de consulter. Vous pouvez maintenant rouvrir le détail d'un manga déjà vu, votre bibliothèque et la page d'accueil dans le métro ou l'avion, sans réseau.
- **Vous retrouvez votre progression hors connexion.** Le nombre de chapitres lus et le statut de lecture s'affichaient comme si le manga n'était pas dans votre bibliothèque quand vous étiez hors ligne. Ils sont désormais conservés et affichés.
- **Le bandeau « hors ligne » ne joue plus à cache-cache.** Il apparaissait puis disparaissait sans raison apparente, notamment pendant une mise à jour de statut ou sur la recherche depuis un navigateur. Il s'affiche maintenant de façon fiable, et dès l'ouverture de l'écran quand l'appareil se sait déconnecté.
- **Plus de chargement sans fin.** Ajouter un manga à sa bibliothèque sans connexion pouvait laisser la fiche bloquée sur une roue de chargement qu'il fallait quitter de force. L'action est mise en attente et l'écran vous rend la main.
- **Un écran vide plutôt qu'un message d'erreur** quand vous ouvrez sans connexion un contenu jamais consulté auparavant.
- Les statistiques affichent enfin leur bandeau hors ligne quand elles proviennent de données enregistrées.
- **Une session expirée ne vous prive plus de vos données.** Quand le serveur ne reconnaissait plus votre session, l'application vidait l'écran et vous renvoyait à la connexion — y compris pour des fiches que vous veniez de consulter. Désormais votre bibliothèque, vos fiches, l'accueil, vos recherches et vos statistiques restent affichés, avec un bandeau discret qui vous propose de vous reconnecter quand vous le souhaitez. Rien ne vous bloque.

### 🔒 Sécurité

- Consulter hors connexion ne contourne pas la connexion : seule la **lecture** de ce que vous aviez déjà vu est autorisée. Toute modification (marquer un chapitre, modifier votre bibliothèque, noter) exige toujours une session valide et attend le retour du réseau — elle n'est jamais appliquée « pour de faux » sur votre appareil.
- **La déconnexion efface maintenant les données enregistrées sur l'appareil.** C'est la contrepartie du point ci-dessus : puisque le contenu enregistré reste visible même quand la session est refusée, il ne doit plus rien rester une fois que vous vous déconnectez. Bibliothèque, fiches manga, accueil, recherches, profil, statistiques et amis sont supprimés à la déconnexion et à la suppression de compte. Vos identifiants biométriques, eux, sont conservés pour vous éviter de retaper votre mot de passe.
- **Changement de compte sur un appareil partagé** : se connecter avec un autre compte efface d'abord les données enregistrées du précédent. En cas de doute sur le propriétaire des données, elles sont effacées.
## [Unreleased] — lecteur intégré face aux vérifications Cloudflare

### Fixed
- **La vérification anti-robot ne boucle plus indéfiniment.** Sur les sites protégés par Cloudflare, la page « Un instant… » se rechargeait sans fin sans jamais aboutir. La cause n'était pas le réseau mais le **nettoyage du DOM** effectué par le bloqueur de publicités : toutes les 2 secondes, il supprimait les éléments de la vérification elle-même. Trois règles étaient en cause — `iframe[sandbox]` (or le widget Turnstile de Cloudflare *est* un iframe sandboxé, donc la case à cocher disparaissait avant que l'utilisateur puisse la cliquer) ; `[data-cfasync]` (attribut de Cloudflare lui-même, pris pour un marqueur publicitaire) ; et surtout `className.includes('ad')`, une correspondance par sous-chaîne qui faisait passer « lo**ad**ing », « he**ad**er », « sh**ad**ow » ou « downlo**ad** » pour des publicités — alors que la page de vérification est précisément un écran de chargement. Le nettoyage suspend désormais toute action tant qu'une vérification est affichée, épargne systématiquement ses éléments, et ne reconnaît plus « ad » que comme mot entier.
- **Le bloqueur de publicités pouvait rester actif pendant la vérification.** Le script injecté tournait sur un `setInterval` de 2 secondes et ne pouvait pas être arrêté : le désactiver côté application ne l'arrêtait pas dans la page. Il est maintenant explicitement arrêté dès qu'une vérification est détectée, et il ne s'empile plus à chaque chargement.
- **Liste blanche stricte de l'infrastructure de vérification** (domaines Cloudflare, hCaptcha, reCAPTCHA, et endpoints `/cdn-cgi/` servis par le site lui-même) : ces requêtes ne peuvent plus être bloquées, et un défi servi depuis un domaine tiers reste navigable. La correspondance se fait par suffixe de domaine, de sorte qu'un hôte imitant `challenges.cloudflare.com` n'est pas autorisé.
- **User-agent cohérent avec le moteur réel.** La WebView annonçait les jetons `; wv` et `Version/4.0`, qui décrivent un moteur ancien et bridé alors que le moteur exécuté est Chromium. Ils sont retirés, ainsi que l'identifiant de modèle `Build/…` ; les versions réelles de Chrome et d'Android sont conservées. L'URL initiale est chargée après application du user-agent, afin que la première requête le porte déjà.
- **Persistance du cookie d'autorisation** rendue explicite (stockage DOM, base de données, cookies tiers, cache, hors navigation privée) et magasin de cookies partagé activé sur iOS, où il est désactivé par défaut.

### Added
- **Porte de sortie quand la vérification ne passe pas.** Après 3 présentations du même défi en moins de 90 secondes, l'application cesse d'insister et propose d'ouvrir la page dans le navigateur du système, de réessayer, ou de fermer. Textes disponibles dans les 7 langues.
- **Bouton « rafraîchir » dans le lecteur**, en action rapide. Il recharge la page sans vous faire perdre votre lecture : le chapitre reste celui que vous lisiez, et vous êtes ramené où vous en étiez. La position est enregistrée juste avant le rechargement — sans quoi tout ce que vous aviez lu depuis la dernière sauvegarde automatique aurait été perdu. Un rafraîchissement demandé par vous ne compte pas non plus comme un tour de la boucle de vérification anti-robot.

### Changed
- **La barre du lecteur est réorganisée en deux niveaux.** Elle affichait six commandes de front, dont un interrupteur et deux petites icônes collées l'une à l'autre. Ne restent visibles que les deux gestes qu'on fait *pendant* la lecture, sur la page en cours : **rafraîchir** et **le bloqueur de publicités**. Le reste — télécharger la page, copier l'URL, mode de désignation des pubs, explication du bloqueur — passe derrière un menu **trois points**.
- **Le bouton du bloqueur de publicités agit maintenant vraiment sur la page affichée.** L'activer applique le blocage immédiatement, sans recharger, donc sans vous déplacer dans le chapitre. Le désactiver recharge la page : c'est nécessaire pour faire réapparaître ce qui avait déjà été retiré, et l'application vous le dit. Là encore, votre position de lecture est préservée.
- **Accessibilité de la barre** : chaque action visible annonce son nom aux lecteurs d'écran, en plus de son infobulle. Le libellé du bloqueur décrit ce que le bouton va faire (« Activer » / « Désactiver »), son état étant annoncé séparément. Quatre textes du lecteur qui n'existaient qu'en français sont désormais traduits dans les 7 langues.

### Note
Aucun mécanisme de résolution ou de contournement automatique d'une vérification anti-robot n'a été ajouté, et aucun n'est envisagé : l'objectif est uniquement de laisser une vérification légitime s'afficher et aboutir entre les mains de l'utilisateur.

---

## [Unreleased] — correctifs navigation + progression de lecture

### Fixed
- Si vous lisez un chapitre au-delà du dernier connu, votre progression est désormais enregistrée et le manga mis à jour automatiquement. Avant, confirmer « Vous avez bien lu jusqu'au 90 » ne gardait rien : l'avancement était perdu sans le moindre message. Le signalement communautaire n'est déclenché que sur les chemins de confirmation explicite (dialogue de fin de chapitre, saut de chapitres, tap sur un chapitre depuis la fiche) — jamais sur la simple navigation, dont le numéro déduit de l'URL peut être erroné.
- **Retour arrière impossible depuis les recommandations** : `RecommendationsSegmentedToggle` naviguait via `context.go`. Les routes `/recommendations` et `/recommendations/by-genre` étant déclarées à la racine du routeur, `go` reconstruisait la pile depuis zéro — plus aucune page à dépiler, bouton retour système inopérant, l'utilisateur devait tuer l'application. Remplacé par `context.pushReplacement` (échange la page courante, conserve l'accueil en dessous, n'empile pas à chaque bascule). 2 tests de régression ajoutés (vérifiés en échec sur l'ancien code).

---

## [Unreleased] — hotfix démarrage v0.12.1

### Fixed
- **Écran blanc au lancement (v0.12.1)** : `HttpService` déclarait `dependsOn: [LanguageService]` alors que `LanguageService` était enregistré plus bas dans `service_locator.dart` — GetIt exige que les types de `dependsOn` soient déjà enregistrés (throw synchrone `ArgumentError` → `setupServiceLocator` interrompu → cascade `BiometricService not registered` dans AuthService → `runApp` jamais appelé). Fix : LanguageService enregistré tôt et retiré des `dependsOn` (le header `Accept-Language` de HttpService est déjà défensif).

---

## [Unreleased] — feat/recos-chapitres-traductions-polish

### Added
- Signalement « plus de chapitres » : `ChapterReportService` + event `ReportMoreChapters` (DetailBloc) + `ReportChaptersDialog` + CTA drapeau sur la fiche — débloque le compteur immédiatement, consolidation communautaire côté API ; i18n ×7 (10 clés `reportMoreChapters*`)
- Descriptions traduites côté serveur : header `Accept-Language` global (HttpService) + `MangaDetailDto.translatedDescription` — suppression de la traduction client sur la fiche détail (`_translateDescription`, ~-120 l.), `TranslationService` conservé pour changelog/profil

### Changed
- Recos : carrousel home 5 → 10 ; fix du bug de cache qui plafonnait la page « Tout » à 5 résultats (cache servi seulement si `cached.length >= limit`) ; `statsNoHistory` reformulé ×7
- `_copyMangaDetail` préserve `userRating`/`communityRating`/`aggregatedRating` (bug préexistant : réinitialisés à chaque action biblio)

### Fixed
- i18n : textes hardcodés branchés sur les ARB (HomepageMangaList états vide/erreur, DetailBottomBar ×5, reader offline ×4 + 3 nouvelles clés ×7 langues)
- Modernisation : `WidgetStatePropertyAll`, `dart:js` → `dart:js_interop`, `onPopInvokedWithResult`, guards `context.mounted` ×6, imports inutiles, stories renommées (espace/typos dans les noms de fichiers)
- Code mort : `getNextPopularMangas`/`getNextLatestManga` + offsets bugués, stub `chapters.helper.dart` + paramètre `mangaChapters` jamais lu

---

## [Unreleased] — sprint hotfix-v0-10-1

### Added
- Recherche : pagination par scroll infini (`SearchBloc` + `SearchResultsList`), compteur de résultats (`totalHits`), états vide/erreur du design system, fallback cache offline page 1, clés ARB ×7 langues
- Profil ami : tap sur un ami → sa bibliothèque (réservé aux amitiés acceptées)
- Page « Changer mon mot de passe » (mot de passe actuel requis, déconnexion des autres appareils)
- Stats v2 : graphique d'activité hebdomadaire + historique des dernières lectures (journal de lecture branché dans les readers)
- Section « 💎 Pépites cachées » dans les recommandations par genre (note Bayésienne)
- AppBreakpoints + AppContentWidth : responsive unifié desktop/mobile sur 10+ pages
- Bandeau d'accueil cold start sur la page Recommandations (bibliothèque vide → explication du top communauté affiché), clés ARB ×7 langues
- `safeDisplayName`/`stripEmailFormat` (`lib/core/utils/safe_display_name.dart`) — defense-in-depth RGPD
- `kReadingEndThresholdPercent` (`lib/features/reader/utils/reading_constants.dart`) — seuil unique de fin de chapitre
- Instrumentation diagnostique secure storage (debug only, D6 Huawei)

### Changed
- Toutes les covers passent par le proxy API (`useProxy: true`), avec `mode=stream` sur le web (fix CORS CanvasKit)
- Cache recos front : TTL réel 2h (page 0), seule la première page est mise en cache
- Seuils lecture unifiés à 85 % (popup « fini ? » + sauvegarde/restauration scroll) ; timeout images 5s → 10s ; fallback conteneur scrollable
- Formulaires login/register wrappés dans `AutofillGroup` + `finishAutofillContext()` après succès

### Fixed
- Suivi de lecture : le chapitre en cours est maintenant reconnu sur les sites où son numéro apparaît seul dans l'adresse de la page (ex. Raijin Scans), et le passage au chapitre suivant fonctionne sur ces sites ; les nombres présents dans le titre de l'œuvre (ex. « 4000 years ») ne sont jamais confondus avec un numéro de chapitre
- Recherche : titres de niche introuvables (« Shadow System… ») et pertinence cassée — l'écran consomme la nouvelle réponse paginée de l'API triée par pertinence MangaUpdates (`POST /mangas/search` + `page`/`limit`)
- Connexion Google : l'annulation du sélecteur de compte n'affiche plus « Échec de la connexion » ; erreurs de configuration OAuth distinguées (`GoogleLoginResult.configError`, message dédié ×7 langues) avec code d'erreur loggé pour diagnostic `adb logcat`
- Autofill des gestionnaires de mots de passe (cassé depuis la refonte V1)
- Emails affichés comme noms d'auteur dans les commentaires/amis/groupes (RGPD) + tap mailto involontaire
- La pagination des recos écrasait le cache de la première page
- Widget tests login/register obsolètes depuis la refonte V1

### Removed
- Stub legacy `isCacheExpired()` (retournait toujours `false`) et `clearExpiredCache()` mort

### BDD
