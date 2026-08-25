# Changelog

Toutes les modifications notables de ce projet sont documentées dans ce fichier.
Format : [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/) · Versioning : [SemVer](https://semver.org/lang/fr/).

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
- Recherche : titres de niche introuvables (« Shadow System… ») et pertinence cassée — l'écran consomme la nouvelle réponse paginée de l'API triée par pertinence MangaUpdates (`POST /mangas/search` + `page`/`limit`)
- Connexion Google : l'annulation du sélecteur de compte n'affiche plus « Échec de la connexion » ; erreurs de configuration OAuth distinguées (`GoogleLoginResult.configError`, message dédié ×7 langues) avec code d'erreur loggé pour diagnostic `adb logcat`
- Autofill des gestionnaires de mots de passe (cassé depuis la refonte V1)
- Emails affichés comme noms d'auteur dans les commentaires/amis/groupes (RGPD) + tap mailto involontaire
- La pagination des recos écrasait le cache de la première page
- Widget tests login/register obsolètes depuis la refonte V1

### Removed
- Stub legacy `isCacheExpired()` (retournait toujours `false`) et `clearExpiredCache()` mort

### BDD
