/// Détecte qu'une page de vérification anti-robot « boucle » : elle se
/// represente encore et encore sans jamais aboutir.
///
/// Le service ne tente rien contre le défi lui-même. Il compte simplement les
/// présentations successives pour la même page afin que l'interface puisse
/// **cesser de boucler** et proposer une porte de sortie explicite
/// (ouverture dans le navigateur externe).
///
/// Pur et sans dépendance Flutter/GetIt : l'horloge est injectable, donc
/// entièrement testable.
class ChallengeLoopDetector {
  ChallengeLoopDetector({
    this.threshold = 3,
    this.window = const Duration(seconds: 90),
    DateTime Function()? clock,
  })  : assert(threshold > 0, 'threshold doit être strictement positif'),
        _clock = clock ?? DateTime.now;

  /// Nombre de présentations consécutives à partir duquel on considère que la
  /// vérification est bloquée et qu'il faut proposer une sortie.
  final int threshold;

  /// Au-delà de ce délai entre deux présentations, on repart de zéro : il
  /// s'agit d'un nouveau défi et non d'une boucle.
  final Duration window;

  final DateTime Function() _clock;

  String? _currentKey;
  int _count = 0;
  DateTime? _lastSeen;
  bool _escapeOffered = false;

  /// Nombre de présentations consécutives du défi pour la page courante.
  int get failureCount => _count;

  /// La page courante suivie, ou `null` si aucune séquence en cours.
  String? get currentKey => _currentKey;

  /// `true` dès que le seuil est atteint : l'appelant doit arrêter de
  /// recharger et proposer la porte de sortie.
  bool get shouldOfferEscape => _count >= threshold;

  /// La proposition de sortie a-t-elle déjà été montrée pour cette boucle ?
  bool get escapeAlreadyOffered => _escapeOffered;

  /// Enregistre l'affichage d'un défi pour [url].
  ///
  /// Retourne `true` si cet enregistrement vient de faire franchir le seuil,
  /// c'est-à-dire s'il faut proposer la sortie **maintenant** (une seule fois
  /// par boucle).
  bool recordChallenge(String url) {
    final key = _normalize(url);
    final now = _clock();
    final last = _lastSeen;

    final isNewSequence = _currentKey != key ||
        last == null ||
        now.difference(last) > window;

    if (isNewSequence) {
      _currentKey = key;
      _count = 1;
      _escapeOffered = false;
    } else {
      _count++;
    }
    _lastSeen = now;

    if (shouldOfferEscape && !_escapeOffered) {
      _escapeOffered = true;
      return true;
    }
    return false;
  }

  /// La page s'est affichée normalement (ou le cookie d'autorisation est
  /// présent) : la séquence en cours est close.
  void recordSuccess() => reset();

  /// Remet le compteur à zéro.
  void reset() {
    _currentKey = null;
    _count = 0;
    _lastSeen = null;
    _escapeOffered = false;
  }

  /// Clé de regroupement : schéma + hôte + chemin.
  ///
  /// La query est ignorée volontairement — Cloudflare ajoute un identifiant
  /// (`__cf_chl_rt_tk`, `ray`…) différent à chaque tentative ; sans cette
  /// normalisation, chaque itération de la boucle paraîtrait être une page
  /// nouvelle et la boucle ne serait jamais détectée.
  String _normalize(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path.isEmpty ? '/' : uri.path;
    return '${uri.scheme}://${uri.host}$path';
  }
}
