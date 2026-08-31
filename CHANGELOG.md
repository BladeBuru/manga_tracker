# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/) · Versioning : [SemVer](https://semver.org/lang/fr/).

---

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
