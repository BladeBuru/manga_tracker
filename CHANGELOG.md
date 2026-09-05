# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/) · Versioning : [SemVer](https://semver.org/lang/fr/).

---

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
