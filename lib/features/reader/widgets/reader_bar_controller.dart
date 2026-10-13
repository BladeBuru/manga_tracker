import 'package:flutter/foundation.dart';
import 'package:mangatracker/features/reader/services/reader_bar_visibility.dart';

/// Pont entre la logique pure [ReaderBarVisibility] et `ReaderAutoHideBar` :
/// la vue lui transmet le défilement, le widget l'écoute.
///
/// Seul le sous-arbre de la barre se reconstruit à chaque défilement — avant,
/// chaque bascule reconstruisait le lecteur entier. Purement visuel : rien
/// n'est mesuré, enregistré ni validé ici.
class ReaderBarController extends ChangeNotifier {
  ReaderBarController({ReaderBarVisibility? visibility})
      : visibility = visibility ?? ReaderBarVisibility();

  final ReaderBarVisibility visibility;

  /// Hauteur révélée (pixels logiques).
  double get shown => visibility.shown;

  /// Hauteur totale de la barre (pixels logiques).
  double get extent => visibility.extent;

  /// Défilement de la page, en unités natives de la WebView.
  void onScroll(int y) => _update(() => visibility.onScroll(y));

  /// Nouvelle page : barre entière.
  void reset() => _update(visibility.reset);

  /// Réservé au widget : dimensions et unités, sans notification (lues au
  /// rendu qui suit).
  void configure({
    required double extent,
    required double scrollUnitsPerLogicalPixel,
  }) {
    visibility
      ..extent = extent
      ..scrollUnitsPerLogicalPixel = scrollUnitsPerLogicalPixel;
  }

  /// Réservé au widget : image de l'animation de recalage.
  void animateTo(double value) => _update(() => visibility.jumpTo(value));

  /// Réservé au widget : fin du recalage.
  void settleAt(double target) {
    visibility.settleAt(target);
    notifyListeners();
  }

  void _update(void Function() change) {
    final before = visibility.shown;
    change();
    if (visibility.shown != before) notifyListeners();
  }
}
