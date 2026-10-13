import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Conteneur des onglets (`navigatorContainerBuilder` du `StatefulShellRoute`).
///
/// Un `PageView`, comme avant la migration : sur téléphone, on change
/// toujours d'onglet d'un glissement du doigt. Chaque onglet reste vivant
/// une fois ouvert (go_router enveloppe chaque branche dans un
/// `AutomaticKeepAlive`).
///
/// Ni la souris ni le pavé tactile ne font défiler les onglets : sur un
/// ordinateur portable, un geste horizontal destiné à un carrousel
/// changeait d'onglet par accident. Sur le web, le glissement est coupé
/// tout à fait (la molette horizontale y passe aussi par ce chemin).
class MainTabsPager extends StatefulWidget {
  final StatefulNavigationShell shell;
  final List<Widget> children;

  const MainTabsPager({super.key, required this.shell, required this.children});

  @override
  State<MainTabsPager> createState() => _MainTabsPagerState();
}

class _MainTabsPagerState extends State<MainTabsPager> {
  static const Set<PointerDeviceKind> _swipeDevices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };

  late final PageController _controller =
      PageController(initialPage: widget.shell.currentIndex);

  @override
  void didUpdateWidget(covariant MainTabsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Onglet changé par l'URL (bouton retour du navigateur, lien) ou par la
    // barre du bas : la page suit, sans animation (comme avant).
    final index = widget.shell.currentIndex;
    if (!_controller.hasClients) return;
    if ((_controller.page ?? index.toDouble()).round() != index) {
      _controller.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index != widget.shell.currentIndex) widget.shell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final pageBehavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      behavior: pageBehavior.copyWith(dragDevices: _swipeDevices),
      child: PageView(
        controller: _controller,
        physics: kIsWeb ? const NeverScrollableScrollPhysics() : null,
        onPageChanged: _onPageChanged,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            // Le contenu des onglets retrouve le comportement global
            // (carrousels déplaçables à la souris) ; animations coupées
            // hors de l'onglet affiché.
            ScrollConfiguration(
              behavior: pageBehavior,
              child: TickerMode(
                enabled: i == widget.shell.currentIndex,
                child: widget.children[i],
              ),
            ),
        ],
      ),
    );
  }
}
