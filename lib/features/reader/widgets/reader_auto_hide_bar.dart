import 'package:flutter/material.dart';

/// Lecteur plein écran : la barre du haut glisse PAR-DESSUS la page et se
/// retire quand on lit (cf. `ReaderBarVisibility`).
///
/// Superposée plutôt que redimensionnant la page : changer la hauteur de la
/// page web à chaque bascule ferait sauter le contenu de toute la hauteur de
/// la barre. Cachée, elle n'intercepte ni les touchers ni le lecteur
/// d'écran.
class ReaderAutoHideBar extends StatelessWidget {
  final bool visible;
  final PreferredSizeWidget appBar;
  final Widget child;

  const ReaderAutoHideBar({
    super.key,
    required this.visible,
    required this.appBar,
    required this.child,
  });

  static const Duration _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sous la barre d'état, jamais dessous ; la page occupe le reste.
        Positioned.fill(child: SafeArea(bottom: false, child: child)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: ExcludeSemantics(
              excluding: !visible,
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, -1),
                duration: _duration,
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: _duration,
                  child: Material(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.surface,
                    child: appBar,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
