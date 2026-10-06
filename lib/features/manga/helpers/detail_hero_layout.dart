import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Disposition de l'en-tête (image + titre) de la fiche manga selon l'écran.
///
/// - Petit écran : l'image ne prend pas plus de 42 % de la hauteur (340 px
///   au plus, comme avant).
/// - Clavier ouvert (saisie d'un commentaire) : ni image ni barre d'actions —
///   sinon la zone défilante tombait à 0 px et le champ saisi n'était plus
///   visible.
/// - Titre sous la barre d'état ET la barre d'application transparente
///   (retour, groupe, partage) : un retrait fixe de 70 px les chevauchait sur
///   les barres d'état hautes.
///
/// [media] doit venir d'un contexte situé AU-DESSUS du Scaffold : le Scaffold
/// retire le clavier du MediaQuery de son corps.
class DetailHeroLayout {
  static const double maxHeight = 340;
  static const double maxScreenShare = 0.42;

  final bool keyboardOpen;
  final double height;
  final double titleTop;

  const DetailHeroLayout._({
    required this.keyboardOpen,
    required this.height,
    required this.titleTop,
  });

  factory DetailHeroLayout.of(MediaQueryData media) => DetailHeroLayout._(
    keyboardOpen: media.viewInsets.bottom > 0,
    height: math.min(maxHeight, media.size.height * maxScreenShare),
    titleTop: media.padding.top + kToolbarHeight + 4,
  );

  /// Image d'en-tête et barre d'actions affichées.
  bool get showChrome => !keyboardOpen;
}
