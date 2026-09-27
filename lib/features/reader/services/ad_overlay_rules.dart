/// Seuils de reconnaissance des publicités **en surimpression** — pur.
///
/// Ces publicités se posent PAR-DESSUS la page (interstitiels, fausses
/// boîtes de dialogue, calques transparents qui captent le premier appui) et
/// n'ont souvent ni id, ni classe, ni adresse : les sélecteurs et
/// l'heuristique par nom du bloqueur ne peuvent pas les voir. Elles se
/// reconnaissent à leur géométrie : fixées à l'écran, au-dessus de tout,
/// couvrant une large part de l'écran.
///
/// Cas fondateur, mesuré sur appareil le 2026-09-27 (manga-scantrad.io,
/// pop-up « VPN activé recommandé ») : un `<iframe>` SANS `src` (contenu
/// écrit par script), enfant direct de `<html>` — hors `<body>` —,
/// `position: fixed`, `z-index: 2147483647`, 100 % de l'écran. Le bloqueur
/// tournait, mais aucune de ses règles ne pouvait le reconnaître.
///
/// Les valeurs sont injectées telles quelles dans le script du bloqueur
/// (`AdBlockerService.buildAdBlockScript`).
class AdOverlayRules {
  const AdOverlayRules._();

  /// Iframe en surimpression : z-index au moins égal à…
  static const int iframeMinZIndex = 1000;

  /// … couvrant au moins cette part de l'écran (0 à 1), et sans adresse,
  /// vide, `javascript:` ou d'un autre site (jamais un iframe du site lu).
  static const double iframeMinCoverage = 0.3;

  /// Autre élément en surimpression : exigences plus strictes, car un site
  /// a ses propres calques légitimes. Mesurés sur manga-scantrad.io : menu
  /// mobile `z-index: 10000`, visionneuse d'images colorbox `9999`.
  static const int elementMinZIndex = 100000;

  /// Part de l'écran couverte (0 à 1) par un élément en surimpression.
  static const double elementMinCoverage = 0.5;

  /// Côté minimal (px CSS) d'une image de chapitre : un calque qui en
  /// contient une n'est JAMAIS retiré (lecteurs « plein écran » des sites).
  static const int chapterImageMinSide = 200;
}
