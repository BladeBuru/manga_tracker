import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

/// Retour visuel au survol de la souris (web, ordinateur) : curseur « main »
/// et réaction sobre — on voit ce qui est cliquable.
///
/// - cartes : la couverture zoome légèrement dans son cadre ([HoverZoom]),
///   sans rien déplacer (un soulèvement serait rogné par le carrousel) ;
/// - rangées ([HoverFeedback.highlight]) : voile très léger de la couleur du
///   texte, aux coins arrondis.
///
/// Au doigt, aucun survol n'existe : rendu strictement identique au
/// précédent sur téléphone. Animations coupées si le système le demande.
class HoverFeedback extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool _veil;

  /// Arrondi du voile.
  final double radius;

  /// Marge du voile (ex. l'espacement sous une rangée).
  final EdgeInsets inset;

  /// Carte : curseur + survol transmis aux [HoverZoom] descendants.
  const HoverFeedback({super.key, required this.child, this.enabled = true})
      : _veil = false,
        radius = AppRadius.xl,
        inset = EdgeInsets.zero;

  /// Rangée : curseur + voile léger.
  const HoverFeedback.highlight({
    super.key,
    required this.child,
    this.enabled = true,
    this.radius = AppRadius.xxxl,
    this.inset = EdgeInsets.zero,
  }) : _veil = true;

  /// La zone survolée englobant [context] l'est-elle ?
  static bool hoveredOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HoverScope>()?.hovered ??
      false;

  @override
  State<HoverFeedback> createState() => _HoverFeedbackState();
}

class _HoverFeedbackState extends State<HoverFeedback> {
  static const double _veilOpacity = 0.05;

  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final active = _hovered && !MediaQuery.disableAnimationsOf(context);
    Widget child = _HoverScope(hovered: active, child: widget.child);
    if (widget._veil) child = _withVeil(context, child, active);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: child,
    );
  }

  Widget _withVeil(BuildContext context, Widget child, bool active) {
    final veil = Theme.of(context).colorScheme.onSurface;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: widget.inset,
              child: AnimatedContainer(
                duration: hoverDuration,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  color: veil.withValues(alpha: active ? _veilOpacity : 0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Durée commune des réactions au survol.
const Duration hoverDuration = Duration(milliseconds: 160);

class _HoverScope extends InheritedWidget {
  final bool hovered;

  const _HoverScope({required this.hovered, required super.child});

  @override
  bool updateShouldNotify(_HoverScope oldWidget) =>
      oldWidget.hovered != hovered;
}

/// Image qui zoome très légèrement quand la carte est survolée — à placer
/// DANS le cadre arrondi (le zoom y reste contenu).
class HoverZoom extends StatelessWidget {
  static const double _zoom = 1.05;

  final Widget child;

  const HoverZoom({super.key, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: HoverFeedback.hoveredOf(context) ? _zoom : 1,
        duration: hoverDuration,
        curve: Curves.easeOut,
        child: child,
      );
}

/// Curseur « main » sur une zone cliquable faite d'un `GestureDetector`
/// (qui, contrairement à `InkWell`, n'en pose pas) — sans effet au doigt.
class ClickableCursor extends StatelessWidget {
  final Widget child;

  /// Zone inactive (pas de `onTap`) : curseur normal.
  final bool enabled;

  const ClickableCursor({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: child,
      );
}
