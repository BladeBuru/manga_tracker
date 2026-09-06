/// Conversion entre défilement en pixels et position de lecture en pourcentage
/// — **classe pure** (ni Flutter, ni GetIt, ni WebView), donc testable telle
/// quelle (`test/features/reader/reading_position_calculator_test.dart`).
///
/// ## Pourquoi un pourcentage et pas des pixels
///
/// La position de lecture voyage désormais jusqu'au serveur pour être reprise
/// sur un autre appareil. Or un défilement en pixels n'a de sens que sur
/// l'appareil qui l'a mesuré : la même page fait 12 000 px sur un téléphone et
/// 5 000 px sur une tablette, et la hauteur change même d'une session à
/// l'autre (zoom, publicités bloquées, images non encore chargées). Un
/// pourcentage, lui, se transpose.
///
/// ## Échelle retenue : progression dans la course de défilement
///
/// `percent = scrollY / (documentHeight - viewportHeight) * 100` :
/// **0 % en haut de page, 100 % tout en bas**. C'est l'échelle qu'utilisait
/// déjà `ScrollPositionService` pour se comparer à
/// `kReadingEndThresholdPercent`, et la seule qui s'inverse proprement
/// (pourcentage → pixels) pour restaurer une position venue d'un autre écran.
///
/// ⚠️ Ne pas confondre avec l'échelle de `ReadingProgressHelper`
/// (`(scrollY + viewport) / total`, « quelle part du chapitre ai-je vue »),
/// qui décide de la question « avez-vous fini ce chapitre ? ». Les deux
/// mesures répondent à deux questions différentes et n'ont pas à coïncider.
class ReadingPositionCalculator {
  const ReadingPositionCalculator._();

  /// En deçà, la position n'est pas jugée digne d'être reprise : l'utilisateur
  /// n'a fait qu'effleurer le haut du chapitre, l'ouvrir en haut ne lui fait
  /// rien perdre.
  static const double minResumablePercent = 3;

  /// Position de lecture en pourcentage (0..100), ou `null` si la mesure n'est
  /// **pas exploitable**.
  ///
  /// Rendre `null` plutôt qu'une valeur par défaut est délibéré : une page en
  /// cours de chargement a `documentHeight ≈ viewportHeight`, ce qui donnerait
  /// « 100 % » et ferait croire à une fin de chapitre. On préfère ne rien
  /// savoir à savoir faux — le chapitre reste alors ouvert en haut, sans que
  /// rien ne soit écrasé.
  static double? percentFromScroll({
    required num? scrollY,
    required num? viewportHeight,
    required num? documentHeight,
  }) {
    if (scrollY == null || viewportHeight == null || documentHeight == null) {
      return null;
    }
    if (!scrollY.isFinite ||
        !viewportHeight.isFinite ||
        !documentHeight.isFinite) {
      return null;
    }
    if (documentHeight <= 0 || viewportHeight <= 0) return null;

    final maxScroll = documentHeight - viewportHeight;
    // Page plus courte que l'écran : rien à faire défiler, donc aucune
    // position à retenir (et surtout pas « 100 % »).
    if (maxScroll <= 0) return null;

    return _clampPercent(scrollY / maxScroll * 100);
  }

  /// Chemin inverse : combien de pixels faut-il faire défiler sur **cet**
  /// appareil pour retrouver [percent] ? `null` si le document n'est pas
  /// défilable ou si le pourcentage est inutilisable.
  static double? scrollOffsetFromPercent({
    required num? percent,
    required num? viewportHeight,
    required num? documentHeight,
  }) {
    if (percent == null || !percent.isFinite) return null;
    if (viewportHeight == null || documentHeight == null) return null;
    if (!viewportHeight.isFinite || !documentHeight.isFinite) return null;
    if (documentHeight <= 0 || viewportHeight <= 0) return null;

    final maxScroll = documentHeight - viewportHeight;
    if (maxScroll <= 0) return null;

    return maxScroll * _clampPercent(percent) / 100;
  }

  /// Arrondi d'envoi : le serveur n'a que faire de la 12e décimale, et deux
  /// mesures à 0,0001 % d'écart ne doivent pas compter comme un déplacement.
  static double round(double percent) =>
      (_clampPercent(percent) * 100).roundToDouble() / 100;

  static double _clampPercent(num value) {
    if (value.isNaN) return 0;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value.toDouble();
  }
}
