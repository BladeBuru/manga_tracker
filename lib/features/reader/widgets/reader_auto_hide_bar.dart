import 'package:flutter/material.dart';
import 'package:mangatracker/features/reader/widgets/reader_bar_controller.dart';
import 'package:mangatracker/features/reader/widgets/reader_bar_layout.dart';
import 'package:mangatracker/features/reader/widgets/reader_bar_snapper.dart';
import 'package:mangatracker/features/reader/widgets/reader_system_ui.dart';

/// Lecteur plein écran : la barre du haut suit le défilement, au prorata
/// (logique pure : `ReaderBarVisibility`, via [ReaderBarController]).
///
/// - Pendant le défilement, elle glisse avec le doigt ; quand il s'arrête
///   (doigt levé), elle se recale entière ou cachée ([ReaderBarSnapper]),
///   puis la page est redimensionnée UNE fois ([ReaderBarLayout]).
/// - **Cachée** : la page occupe TOUT l'écran ; les barres du système se
///   retirent aussi (mode immersif). Retour v0.18.0 : la barre cachée
///   laissait « 2 cm de blanc » en haut et une bande en bas.
/// - **Visible** : les barres du système reviennent dès que la barre
///   commence à revenir ; la barre **réserve sa place** au-dessus de la page.
///
/// En quittant le lecteur, les barres du système sont rétablies.
class ReaderAutoHideBar extends StatefulWidget {
  final ReaderBarController controller;
  final PreferredSizeWidget appBar;

  /// La page (WebView).
  final Widget page;

  /// Par-dessus la page, ancré à l'écran sous la barre (vérification
  /// anti-robot, bandeau « recherche de lien »).
  final Widget? overlay;

  const ReaderAutoHideBar({
    super.key,
    required this.controller,
    required this.appBar,
    required this.page,
    this.overlay,
  });

  @override
  State<ReaderAutoHideBar> createState() => _ReaderAutoHideBarState();
}

class _ReaderAutoHideBarState extends State<ReaderAutoHideBar>
    with SingleTickerProviderStateMixin {
  late final ReaderBarSnapper _snapper;
  bool _moving = false;
  bool _immersive = false;
  double? _statusInset;

  @override
  void initState() {
    super.initState();
    _snapper = ReaderBarSnapper(
      vsync: this,
      controller: widget.controller,
      onRest: _onRest,
    );
    widget.controller.addListener(_onBarChanged);
    ReaderSystemUi.setImmersive(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(covariant ReaderAutoHideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onBarChanged);
      widget.controller.addListener(_onBarChanged);
      _snapper.controller = widget.controller;
    }
    _configure();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onBarChanged);
    _snapper.dispose();
    ReaderSystemUi.setImmersive(false);
    super.dispose();
  }

  /// Hauteur de la barre d'état mémorisée hors mode immersif (elle y vaut 0) :
  /// la barre ne change pas de taille en revenant.
  void _configure() {
    final top = MediaQuery.paddingOf(context).top;
    if (_statusInset == null || (!_immersive && top > 0)) _statusInset = top;
    widget.controller.configure(
      extent: _statusInset! + widget.appBar.preferredSize.height,
      scrollUnitsPerLogicalPixel: ReaderSystemUi.scrollUnitsPerLogicalPixel(
        MediaQuery.devicePixelRatioOf(context),
      ),
    );
  }

  /// La page a défilé (les images du recalage exceptées).
  void _onBarChanged() {
    if (_snapper.isWriting) return;
    if (widget.controller.shown > 0) _setImmersive(false);
    if (!_moving) setState(() => _moving = true);
    _snapper.scrolled();
  }

  void _onRest(double target) {
    if (target <= 0) _setImmersive(true);
    if (mounted) setState(() => _moving = false);
  }

  void _setImmersive(bool immersive) {
    if (_immersive == immersive) return;
    _immersive = immersive;
    ReaderSystemUi.setImmersive(immersive);
  }

  @override
  Widget build(BuildContext context) {
    final bar = ReaderBarSurface(
      appBar: widget.appBar,
      statusInset: _statusInset ?? 0,
    );
    final page = Listener(
      onPointerDown: (_) => _snapper.pointerDown(),
      onPointerUp: (_) => _snapper.pointerUp(),
      onPointerCancel: (_) => _snapper.pointerUp(),
      child: widget.page,
    );
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => ReaderBarLayout(
        shown: widget.controller.shown,
        extent: widget.controller.extent,
        resting: !_moving,
        bar: bar,
        page: page,
        overlay: widget.overlay,
      ),
    );
  }
}
