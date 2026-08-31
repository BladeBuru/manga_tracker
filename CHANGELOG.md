# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/) · Versioning : [SemVer](https://semver.org/lang/fr/).

---

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
