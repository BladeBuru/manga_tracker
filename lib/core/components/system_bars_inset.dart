import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Garde global contre la barre de navigation du système (boutons retour /
/// accueil, barre de geste, indicateur d'accueil iOS).
///
/// Android 15 impose l'affichage « bord à bord » aux applications qui le
/// ciblent : le contenu passe SOUS la barre de navigation. `Scaffold` ne
/// protège que sa barre du bas ; les boutons en bas de page, les derniers
/// éléments des listes et les bandeaux superposés se retrouvaient cachés
/// dessous (retour utilisateur : « des boutons cachés qui passent
/// par-dessous »). Placé dans `MaterialApp.builder`, ce garde remonte toute
/// l'application au-dessus de la barre et peint la bande libérée aux
/// couleurs du thème.
///
/// Le clavier : sa hauteur est mesurée depuis le bas de l'écran ; on en
/// retire la bande déjà réservée, sinon les champs remonteraient de trop.
class SystemBarsInset extends StatelessWidget {
  final Widget child;

  const SystemBarsInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.viewPadding.bottom;
    if (bottom <= 0) return child;

    final theme = Theme.of(context);
    final stripColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        theme.colorScheme.surface;

    return ColoredBox(
      color: stripColor,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: MediaQuery(
          data: media.copyWith(
            padding: media.padding.copyWith(bottom: 0),
            viewPadding: media.viewPadding.copyWith(bottom: 0),
            viewInsets: media.viewInsets.copyWith(
              bottom: math.max(0, media.viewInsets.bottom - bottom),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
