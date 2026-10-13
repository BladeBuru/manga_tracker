import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ce que le lecteur plein écran demande à la plateforme — en un seul
/// endroit (cf. CLAUDE.md : pas de test de plateforme dispersé).
class ReaderSystemUi {
  const ReaderSystemUi._();

  /// Barres du système masquées (mode immersif) ou rétablies (bord à bord).
  /// Sans effet sur le web.
  static void setImmersive(bool immersive) {
    if (kIsWeb) return;
    SystemChrome.setEnabledSystemUIMode(
      immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  /// Unités de `onScrollChanged` (flutter_inappwebview 6.1) par pixel
  /// logique. Android : pixels physiques (`View.getScrollY`). iOS :
  /// `contentOffset / contentScaleFactor`, des points divisés par l'échelle
  /// de l'écran (à vérifier sur appareil). Ailleurs : pixels logiques.
  static double scrollUnitsPerLogicalPixel(double devicePixelRatio) =>
      switch (defaultTargetPlatform) {
        TargetPlatform.android => devicePixelRatio,
        TargetPlatform.iOS => 1 / devicePixelRatio,
        _ => 1,
      };
}
