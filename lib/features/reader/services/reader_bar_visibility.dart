/// Barre du haut du lecteur : cachée quand on descend dans la page, de
/// retour dès qu'on remonte. **Pure** (ni Flutter ni GetIt) — testée seule
/// (`test/features/reader/reader_bar_visibility_test.dart`).
///
/// - Près du haut de la page : toujours visible.
/// - Il faut un mouvement franc ([threshold] pixels dans le même sens) pour
///   basculer : un léger tremblement du doigt ne la fait pas clignoter.
/// - Changement de chapitre ([reset]) : visible.
/// - Juste après une bascule ([settle]) : les mouvements sont ignorés. La
///   barre réserve sa place au-dessus de la page ; la retirer agrandit la
///   page, ce qui peut faire reculer le navigateur (bas de page) — sans ce
///   délai, ce recul la ferait revenir aussitôt.
class ReaderBarVisibility {
  /// Défilement cumulé dans un sens avant de basculer.
  final int threshold;

  /// Zone haute où la barre reste affichée.
  final int topZone;

  /// Durée, après une bascule, pendant laquelle le défilement est ignoré.
  final Duration settle;

  final DateTime Function() _now;

  ReaderBarVisibility({
    this.threshold = 24,
    this.topZone = 80,
    this.settle = const Duration(milliseconds: 400),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  bool _visible = true;
  int? _lastY;
  int _accumulated = 0;
  DateTime? _settleUntil;

  bool get visible => _visible;

  /// Nouvelle position verticale de la page ; renvoie la visibilité.
  bool onScroll(int y) {
    final now = _now();
    final until = _settleUntil;
    if (until != null && now.isBefore(until)) {
      // Mouvement provoqué par la bascule elle-même : nouvelle référence.
      _lastY = y;
      _accumulated = 0;
      return _visible;
    }
    final before = _visible;
    final result = _next(y);
    if (result != before) _settleUntil = now.add(settle);
    return result;
  }

  bool _next(int y) {
    final last = _lastY;
    _lastY = y;
    if (y <= topZone) {
      _accumulated = 0;
      return _visible = true;
    }
    if (last == null) return _visible;
    final delta = y - last;
    if (delta == 0) return _visible;
    // Changement de sens : on repart de zéro.
    if (_accumulated != 0 && (delta > 0) != (_accumulated > 0)) {
      _accumulated = 0;
    }
    _accumulated += delta;
    if (_accumulated >= threshold) {
      _visible = false;
    } else if (_accumulated <= -threshold) {
      _visible = true;
    }
    return _visible;
  }

  /// Nouvelle page : barre visible, mesure remise à zéro.
  void reset() {
    _visible = true;
    _lastY = null;
    _accumulated = 0;
    _settleUntil = null;
  }
}
