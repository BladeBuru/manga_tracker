import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lecteur plein écran : la barre du haut se retire quand on lit (cf.
/// `ReaderBarVisibility`) et revient quand on remonte.
///
/// - **Cachée** : la page occupe TOUT l'écran. Les barres du système (heure,
///   batterie, boutons ou barre de geste) se retirent aussi — mode immersif ;
///   un glissement depuis le bord les fait réapparaître un instant.
///   Retour utilisateur v0.18.0 : la barre cachée laissait « 2 cm de blanc »
///   en haut (place de la barre d'état) et une bande en bas.
/// - **Visible** : barres du système et barre du haut reviennent ; la barre
///   **réserve sa place** au-dessus de la page (superposée, elle masquait le
///   haut de chaque chapitre et le bandeau de vérification).
///
/// En quittant le lecteur, les barres du système sont rétablies.
class ReaderAutoHideBar extends StatefulWidget {
  final bool visible;
  final PreferredSizeWidget appBar;
  final Widget child;

  const ReaderAutoHideBar({
    super.key,
    required this.visible,
    required this.appBar,
    required this.child,
  });

  @override
  State<ReaderAutoHideBar> createState() => _ReaderAutoHideBarState();
}

class _ReaderAutoHideBarState extends State<ReaderAutoHideBar> {
  static const Duration _duration = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _applySystemBars(widget.visible);
  }

  @override
  void didUpdateWidget(covariant ReaderAutoHideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _applySystemBars(widget.visible);
    }
  }

  @override
  void dispose() {
    _applySystemBars(true);
    super.dispose();
  }

  static void _applySystemBars(bool visible) {
    if (kIsWeb) return;
    SystemChrome.setEnabledSystemUIMode(
      visible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.visible;
    return Column(
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
                // L'AppBar couvre elle-même la barre d'état (son fond passe
                // dessous) : aucune bande vide au-dessus.
                child: Material(
                  elevation: 2,
                  color: Theme.of(context).colorScheme.surface,
                  child: widget.appBar,
                ),
              ),
            ),
          ),
        ),
        // La page commence sous la barre visible, ou tout en haut de l'écran
        // quand elle est cachée.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: visible,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
