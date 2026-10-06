import 'package:flutter/material.dart';

/// Lecteur plein écran : la barre du haut se retire quand on lit (cf.
/// `ReaderBarVisibility`) et revient quand on remonte.
///
/// Visible, elle **réserve sa place** au-dessus de la page : superposée, elle
/// masquait en permanence le haut de chaque chapitre (elle est forcée en haut
/// de page) ainsi que le bandeau de vérification de sécurité. Cachée, la page
/// récupère toute la hauteur, et la barre n'intercepte ni les touchers ni le
/// lecteur d'écran.
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
    // Sous la barre d'état, jamais dessous.
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.bottomCenter,
              heightFactor: visible ? 1 : 0,
              duration: _duration,
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring: !visible,
                child: ExcludeSemantics(
                  excluding: !visible,
                  child: Material(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.surface,
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: appBar,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
