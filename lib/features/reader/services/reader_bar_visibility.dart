/// Barre du haut du lecteur : elle suit le défilement **proportionnellement**
/// — remonter la fait apparaître progressivement jusqu'à sa taille fixe,
/// descendre la retire progressivement. **Pure** (ni Flutter ni GetIt) —
/// testée seule (`test/features/reader/reader_bar_visibility_test.dart`).
///
/// Retour utilisateur (2026-10) : la barre était « tout ou rien » — un
/// infime retour en arrière (relire une ligne) la faisait revenir entière.
///
/// - [shown] : hauteur révélée, en pixels logiques, de 0 (cachée) à [extent]
///   (entière, hauteur fournie par le widget).
/// - Défiler de Δ pixels logiques révèle ou retire Δ pixels de barre. Quand
///   le défilement s'arrête, le widget la recale sur la position la plus
///   proche ([snapTarget]) : moins de la moitié révélée → cachée. Un petit
///   retour en arrière n'en montre donc qu'un morceau, puis elle repart.
/// - Au repos (entière ou cachée), un mouvement doit dépasser [slack] avant
///   de la déplacer : un tremblement du doigt ne la fait pas bouger.
/// - Près du haut de la page, elle est « posée » sur le haut du contenu :
///   entière dans les [topZone] premiers pixels, puis elle s'en va avec lui.
/// - Après un recalage sur « entière » ([settleAt]) : les mouvements sont
///   ignorés pendant [settle]. La barre reprend alors sa place au-dessus de
///   la page, qui rétrécit, ce qui peut faire reculer le navigateur (bas de
///   page) — sans ce délai, ce recul la ferait bouger aussitôt.
/// - Unités : la WebView rapporte le défilement en unités natives (pixels
///   PHYSIQUES sur Android : 24 px n'y font que 8,7 dp à ×2,75, d'où une
///   barre qui revenait au moindre geste). [scrollUnitsPerLogicalPixel],
///   fourni par le widget, les convertit ; tous les seuils sont en pixels
///   logiques.
class ReaderBarVisibility {
  /// Zone haute (pixels logiques) où la barre reste entière.
  final double topZone;

  /// Mouvement (pixels logiques) à dépasser pour quitter une position de
  /// repos.
  final double slack;

  /// Durée, après un recalage sur « entière », pendant laquelle le défilement
  /// est ignoré.
  final Duration settle;

  final DateTime Function() _now;

  ReaderBarVisibility({
    this.topZone = 32,
    this.slack = 12,
    this.settle = const Duration(milliseconds: 400),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  double _extent = 0;
  double _shown = 0;
  double _scrollUnits = 1;
  int? _lastY;
  double _pending = 0;
  DateTime? _settleUntil;

  /// Hauteur totale de la barre (pixels logiques).
  double get extent => _extent;

  /// Une barre entière le reste quand sa hauteur change (barre d'état
  /// connue plus tard, rotation) ; une barre cachée reste cachée.
  set extent(double value) {
    final wasFull = _shown >= _extent;
    _extent = value < 0 ? 0 : value;
    _shown = wasFull ? _extent : _shown.clamp(0.0, _extent);
  }

  /// Unités de défilement de la WebView par pixel logique.
  double get scrollUnitsPerLogicalPixel => _scrollUnits;
  set scrollUnitsPerLogicalPixel(double value) {
    if (value > 0 && value.isFinite) _scrollUnits = value;
  }

  /// Hauteur révélée (pixels logiques), de 0 à [extent].
  double get shown => _shown;

  /// Nouvelle position verticale de la page ; renvoie la hauteur révélée.
  double onScroll(int y) {
    final last = _lastY;
    _lastY = y;
    final until = _settleUntil;
    if (until != null) {
      if (_now().isBefore(until)) {
        // Mouvement provoqué par le redimensionnement : nouvelle référence.
        _pending = 0;
        return _shown;
      }
      _settleUntil = null;
    }
    if (last != null) _shown = _follow((y - last) / _scrollUnits);
    // Près du haut : la barre est posée sur le haut du contenu.
    final floor = (topZone + _extent - y / _scrollUnits).clamp(0.0, _extent);
    if (_shown < floor) {
      _shown = floor;
      _pending = 0;
    }
    return _shown;
  }

  /// [delta] > 0 : on descend dans la page, la barre se retire.
  double _follow(double delta) {
    if (delta == 0 || _extent <= 0) return _shown;
    final hidden = _shown <= 0;
    final full = _shown >= _extent;
    if (hidden || full) {
      final leaving = (hidden && delta < 0) || (full && delta > 0);
      if (!leaving) {
        _pending = 0;
        return _shown;
      }
      _pending += delta;
      if (_pending.abs() <= slack) return _shown;
      delta = _pending - (delta > 0 ? slack : -slack);
      _pending = 0;
    }
    return (_shown - delta).clamp(0.0, _extent);
  }

  /// Position de repos la plus proche : entière si au moins la moitié est
  /// révélée, cachée sinon.
  double snapTarget() => _extent > 0 && _shown >= _extent / 2 ? _extent : 0;

  /// Image intermédiaire de l'animation de recalage.
  void jumpTo(double value) {
    _shown = value.clamp(0.0, _extent);
    _pending = 0;
  }

  /// Fin du recalage sur [target] (0 ou [extent]). Sur « entière », la page
  /// est redimensionnée sous la barre : le recul qui s'ensuit est ignoré.
  void settleAt(double target) {
    jumpTo(target);
    if (_extent > 0 && _shown >= _extent) {
      _settleUntil = _now().add(settle);
    }
  }

  /// Nouvelle page : barre entière, mesure remise à zéro.
  double reset() {
    _shown = _extent;
    _lastY = null;
    _pending = 0;
    _settleUntil = null;
    return _shown;
  }
}
