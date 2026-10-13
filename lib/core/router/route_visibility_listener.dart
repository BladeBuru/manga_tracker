import 'package:flutter/widgets.dart';

/// Prévient quand la page qui contient ce widget repasse au premier plan
/// ([onVisible] : retour depuis une page empilée par-dessus, fermeture d'une
/// fenêtre) ou le quitte ([onHidden]).
///
/// Sert aux pages qui affichent des données modifiables ailleurs : la page
/// de groupe et la carte « Lecture partagée » se rechargent au retour (avant :
/// chargées une fois, elles affichaient encore l'ancienne progression après
/// un enregistrement réussi — d'où l'impression d'un refus), et une page
/// recouverte suspend son rafraîchissement périodique.
///
/// Repose sur `ModalRoute.isCurrentOf` : fonctionne avec `go_router`, le
/// bouton retour du navigateur web et le geste retour. Rien n'est appelé au
/// premier affichage.
class RouteVisibilityListener extends StatefulWidget {
  final VoidCallback? onVisible;
  final VoidCallback? onHidden;
  final Widget child;

  const RouteVisibilityListener({
    super.key,
    this.onVisible,
    this.onHidden,
    required this.child,
  });

  @override
  State<RouteVisibilityListener> createState() =>
      _RouteVisibilityListenerState();
}

class _RouteVisibilityListenerState extends State<RouteVisibilityListener> {
  bool? _isCurrent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context);
    if (current == null) return;
    final previous = _isCurrent;
    _isCurrent = current;
    if (previous == null || previous == current) return;
    // Appelé pendant la construction de l'image : les rappels (évènements de
    // BLoC, setState) attendent qu'elle soit terminée. Un aller-retour dans
    // la même image ne déclenche rien.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isCurrent != current) return;
      (current ? widget.onVisible : widget.onHidden)?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
