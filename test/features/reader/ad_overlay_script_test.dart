import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';
import 'package:mangatracker/features/reader/services/ad_overlay_rules.dart';

/// Publicités en surimpression : cas fondateur mesuré sur appareil le
/// 2026-09-27 (manga-scantrad.io) — `<iframe>` sans `src`, enfant direct de
/// `<html>`, `position: fixed`, `z-index: 2147483647`, plein écran, que le
/// bloqueur ne savait pas reconnaître.
void main() {
  late String script;

  setUpAll(() async {
    if (!getIt.isRegistered<Notifier>()) {
      getIt.registerSingleton<Notifier>(Notifier());
    }
    script = await AdBlockerService().buildAdBlockScript(null);
  });

  /// Corps d'une fonction JavaScript du script, jusqu'à la suivante.
  String functionBody(String name) {
    final start = script.indexOf('function $name(');
    expect(start, isNot(-1), reason: 'fonction $name absente du script');
    final next = script.indexOf('\n      function ', start + 1);
    return script.substring(start, next == -1 ? script.length : next);
  }

  group('seuils (AdOverlayRules)', () {
    test('les calques légitimes mesurés restent sous les seuils', () {
      // Menu mobile du site : z-index 10000 ; colorbox : 9999.
      expect(AdOverlayRules.elementMinZIndex, greaterThan(10000));
      expect(AdOverlayRules.iframeMinZIndex, lessThanOrEqualTo(2147483647));
    });

    test('le cas fondateur (z max, 100 % de l\'écran) dépasse les seuils', () {
      expect(2147483647, greaterThanOrEqualTo(AdOverlayRules.iframeMinZIndex));
      expect(1.0, greaterThanOrEqualTo(AdOverlayRules.iframeMinCoverage));
    });

    test('les proportions sont des parts d\'écran valides', () {
      for (final cover in [
        AdOverlayRules.iframeMinCoverage,
        AdOverlayRules.elementMinCoverage,
      ]) {
        expect(cover, greaterThan(0));
        expect(cover, lessThanOrEqualTo(1));
      }
    });

    test('les seuils sont injectés tels quels dans le script', () {
      expect(script,
          contains('OVERLAY_IFRAME_MIN_Z = ${AdOverlayRules.iframeMinZIndex}'));
      expect(script,
          contains('OVERLAY_MIN_Z = ${AdOverlayRules.elementMinZIndex}'));
      expect(
          script,
          contains(
              'CHAPTER_IMAGE_MIN_SIDE = ${AdOverlayRules.chapterImageMinSide}'));
    });
  });

  group('détection des surimpressions', () {
    test('le nettoyage retire les surimpressions, après la garde de défi', () {
      final body = functionBody('removeAds');
      final guard = body.indexOf('if (pageHasChallenge()) return;');
      final overlays = body.indexOf('removeOverlays()');
      expect(guard, isNot(-1));
      expect(overlays, greaterThan(guard),
          reason: 'Aucun retrait tant qu\'une vérification est affichée.');
    });

    test('un élément de défi n\'est jamais une surimpression', () {
      final body = functionBody('isAdOverlay');
      expect(body.indexOf('isChallengeElement(el)'),
          lessThan(body.indexOf('getComputedStyle')),
          reason: 'La garde de défi passe avant toute autre règle.');
    });

    test('seuls les éléments fixés à l\'écran sont candidats', () {
      expect(functionBody('isAdOverlay'),
          contains("cs.position !== 'fixed'"));
    });

    test('un iframe du site lu n\'est jamais retiré', () {
      final body = functionBody('isBlankOrForeignFrame');
      expect(body, contains("src === 'about:blank'"));
      expect(body, contains('!== location.host'));
    });

    test('un calque qui contient une image de chapitre est conservé', () {
      expect(functionBody('isAdOverlay'),
          contains('!containsChapterImage(el)'));
    });

    test('les calques accrochés à <html> (hors <body>) sont examinés', () {
      expect(functionBody('overlayCandidates'),
          contains('document.documentElement.children'));
    });

    test('le défilement n\'est débloqué qu\'après un retrait', () {
      final body = functionBody('removeOverlays');
      expect(body.indexOf("node.style.overflow = ''"),
          greaterThan(body.indexOf('if (removed > 0)')));
    });
  });

  group('surveillance', () {
    test('l\'observateur surveille <html> entier, pas seulement <body>', () {
      expect(script,
          contains('observer.observe(document.documentElement'));
      expect(script, isNot(contains('observer.observe(document.body')));
    });

    test('les mutations sont regroupées', () {
      expect(script, contains('new MutationObserver(scheduleRemoveAds)'));
      expect(functionBody('scheduleRemoveAds'),
          contains('if (cleanupScheduled) return;'));
    });
  });
}
