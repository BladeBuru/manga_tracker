import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Disposition du lecteur plein écran pour une barre révélée de [shown]
/// pixels sur [extent] (voir `ReaderAutoHideBar`).
///
/// La barre est TOUJOURS au-dessus de la page, jamais par-dessus : elle
/// masquait le haut de chaque chapitre et le bandeau de vérification.
///
/// - **Au repos, barre entière** : la page commence sous la barre et en est
///   raccourcie — la place est réellement réservée.
/// - **Au repos, barre cachée** : la page occupe tout l'écran.
/// - **Pendant un mouvement** : la page garde la hauteur de l'écran et est
///   simplement décalée de [shown] (son bas sort un instant de l'écran,
///   comme dans Chrome sur Android). La WebView n'est donc PAS redimensionnée
///   à chaque image : elle l'est une fois, au recalage.
/// - [overlay] (vérification anti-robot, bandeau « recherche de lien ») :
///   ancré à l'écran, sous la barre — il ne suit pas le décalage de la page.
class ReaderBarLayout extends StatelessWidget {
  const ReaderBarLayout({
    super.key,
    required this.shown,
    required this.extent,
    required this.resting,
    required this.bar,
    required this.page,
    this.overlay,
  });

  final double shown;
  final double extent;

  /// `false` pendant un mouvement (défilement ou recalage en cours).
  final bool resting;
  final Widget bar;
  final Widget page;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final hidden = shown <= 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final reserved = resting && extent > 0 && shown >= extent;
        final pageTop = reserved ? extent : shown;
        final pageHeight =
            reserved ? math.max(0.0, height - extent) : height;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: pageTop,
              left: 0,
              right: 0,
              height: pageHeight,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: pageTop > 0,
                child: page,
              ),
            ),
            Positioned(
              top: shown - extent,
              left: 0,
              right: 0,
              height: extent,
              child: IgnorePointer(
                ignoring: hidden,
                child: ExcludeSemantics(excluding: hidden, child: bar),
              ),
            ),
            if (overlay != null)
              Positioned(
                top: shown,
                left: 0,
                right: 0,
                bottom: 0,
                child: overlay!,
              ),
          ],
        );
      },
    );
  }
}

/// Fond de la barre : l'AppBar couvre elle-même la barre d'état (son fond
/// passe dessous), avec une hauteur de barre d'état FIXE ([statusInset]) —
/// en mode immersif elle vaut 0 et la barre aurait changé de taille en
/// revenant.
class ReaderBarSurface extends StatelessWidget {
  const ReaderBarSurface({
    super.key,
    required this.appBar,
    required this.statusInset,
  });

  final PreferredSizeWidget appBar;
  final double statusInset;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(top: statusInset),
          viewPadding: media.viewPadding.copyWith(top: statusInset),
        ),
        child: appBar,
      ),
    );
  }
}
