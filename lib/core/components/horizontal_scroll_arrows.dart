import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Flèches gauche / droite par-dessus un carrousel horizontal, sur grand
/// écran ([AppBreakpoints.carouselArrows]) : à la souris, faire défiler un
/// carrousel sans glisser ni molette horizontale. Une flèche n'apparaît que
/// s'il reste quelque chose à voir de son côté. Sous le seuil (téléphone),
/// rendu inchangé : [child] seul.
class HorizontalScrollArrows extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  /// Hauteur (depuis le haut) à laquelle centrer les flèches — en général
  /// le milieu des couvertures. `null` : milieu du carrousel.
  final double? centerY;

  const HorizontalScrollArrows({
    super.key,
    required this.controller,
    required this.child,
    this.centerY,
  });

  @override
  State<HorizontalScrollArrows> createState() => _HorizontalScrollArrowsState();
}

class _HorizontalScrollArrowsState extends State<HorizontalScrollArrows> {
  static const Duration _duration = Duration(milliseconds: 320);

  /// Part de la largeur visible parcourue par un clic.
  static const double _pageFraction = 0.8;

  /// Dimensions du contenu connues / changées (premier rendu, page
  /// suivante chargée) : le contrôleur, lui, ne notifie qu'au défilement.
  final ValueNotifier<int> _metrics = ValueNotifier<int>(0);

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  void _scrollBy(int direction) {
    final controller = widget.controller;
    if (!controller.hasClients) return;
    final position = controller.position;
    final target = (position.pixels +
            direction * position.viewportDimension * _pageFraction)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    controller.animateTo(target, duration: _duration, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.carouselArrows) {
          return widget.child;
        }
        final l10n = AppLocalizations.of(context);
        final controller = widget.controller;
        return Stack(
          children: [
            NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                _metrics.value++;
                return false;
              },
              child: widget.child,
            ),
            Positioned.fill(
              child: ListenableBuilder(
                listenable: Listenable.merge([controller, _metrics]),
                builder: (context, _) {
                  final position = controller.hasClients &&
                          controller.position.hasContentDimensions
                      ? controller.position
                      : null;
                  final canBack = position != null &&
                      position.pixels > position.minScrollExtent;
                  final canForward = position != null &&
                      position.pixels < position.maxScrollExtent;
                  return _ArrowsRow(
                    centerY: widget.centerY,
                    previous: canBack ? () => _scrollBy(-1) : null,
                    next: canForward ? () => _scrollBy(1) : null,
                    previousTooltip: l10n?.carouselPrevious,
                    nextTooltip: l10n?.carouselNext,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArrowsRow extends StatelessWidget {
  final double? centerY;
  final VoidCallback? previous;
  final VoidCallback? next;
  final String? previousTooltip;
  final String? nextTooltip;

  const _ArrowsRow({
    required this.centerY,
    required this.previous,
    required this.next,
    required this.previousTooltip,
    required this.nextTooltip,
  });

  /// Diamètre approximatif d'un `IconButton` (zone tactile Material).
  static const double _buttonSize = 48;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, VoidCallback? onPressed, String? tooltip) {
      if (onPressed == null) return const SizedBox(width: _buttonSize);
      return IconButton.filledTonal(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          arrow(Icons.chevron_left_outlined, previous, previousTooltip),
          const Spacer(),
          arrow(Icons.chevron_right_outlined, next, nextTooltip),
        ],
      ),
    );
    final y = centerY;
    if (y == null) return Center(child: row);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: (y - _buttonSize / 2).clamp(0, double.infinity),
          child: row,
        ),
      ],
    );
  }
}
