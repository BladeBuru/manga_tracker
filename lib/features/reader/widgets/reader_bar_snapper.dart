import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:mangatracker/features/reader/widgets/reader_bar_controller.dart';

/// Recalage de la barre du lecteur quand le défilement s'arrête : aucun
/// événement pendant [delay] ET doigt levé, puis animation vers la position
/// de repos la plus proche (`ReaderBarVisibility.snapTarget`).
///
/// Pas de `scrollend` JavaScript : rien n'est injecté dans la page pour ça.
class ReaderBarSnapper {
  ReaderBarSnapper({
    required TickerProvider vsync,
    required this.controller,
    required this.onRest,
    this.delay = const Duration(milliseconds: 150),
    Duration duration = const Duration(milliseconds: 200),
  }) : _animation = AnimationController(vsync: vsync, duration: duration) {
    _animation
      ..addListener(_onFrame)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  ReaderBarController controller;

  /// Fin du recalage, barre au repos sur `target` (0 ou entière).
  final void Function(double target) onRest;
  final Duration delay;

  final AnimationController _animation;
  Timer? _timer;
  double _from = 0;
  double _to = 0;
  int _pointers = 0;
  bool _writing = false;

  /// `true` pendant que le recalage écrit lui-même dans [controller] : ces
  /// notifications ne sont pas du défilement.
  bool get isWriting => _writing;

  void pointerDown() => _pointers++;
  void pointerUp() => _pointers = math.max(0, _pointers - 1);

  /// La page vient de défiler : le recalage en cours s'interrompt, le délai
  /// repart.
  void scrolled() {
    _animation.stop();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(delay, _start);
  }

  void _start() {
    // Doigt encore posé (relecture d'une ligne, pause) : on attend.
    if (_pointers > 0) {
      _arm();
      return;
    }
    _from = controller.shown;
    _to = controller.visibility.snapTarget();
    if (_from == _to) {
      _finish();
    } else {
      _animation.forward(from: 0);
    }
  }

  void _onFrame() {
    final t = Curves.easeOutCubic.transform(_animation.value);
    _write(() => controller.animateTo(lerpDouble(_from, _to, t)!));
  }

  void _finish() {
    _write(() => controller.settleAt(_to));
    onRest(_to);
  }

  void _write(void Function() change) {
    _writing = true;
    try {
      change();
    } finally {
      _writing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _animation.dispose();
  }
}
