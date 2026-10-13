import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Défilement global de l'application (`MaterialApp.scrollBehavior`).
///
/// - **Mobile** (Android / iOS) : inchangé — rebond partout
///   (`BouncingScrollPhysics`), toujours défilable (tirer pour rafraîchir
///   sur une liste courte).
/// - **Web / ordinateur** : physique de la plateforme (pas de rebond forcé
///   sous Windows) et carrousels déplaçables **à la souris** et au pavé
///   tactile — sans ça, un carrousel horizontal ne se faisait défiler
///   qu'au clavier ou à la molette maintenue avec Maj.
abstract final class AppScrollBehavior {
  static ScrollBehavior forPlatform() =>
      _usesPointer ? const _PointerScrollBehavior() : _mobile;

  static bool get _usesPointer =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.windows ||
        TargetPlatform.macOS ||
        TargetPlatform.linux =>
          true,
        _ => false,
      };

  static final ScrollBehavior _mobile = const ScrollBehavior().copyWith(
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
  );
}

class _PointerScrollBehavior extends ScrollBehavior {
  const _PointerScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      AlwaysScrollableScrollPhysics(parent: super.getScrollPhysics(context));
}
