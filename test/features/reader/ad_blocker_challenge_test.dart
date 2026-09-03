import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';

/// Régression : le bloqueur de publicités ne doit jamais couper ni masquer
/// l'infrastructure d'une vérification anti-robot, sous peine de faire
/// boucler indéfiniment la page de vérification.
void main() {
  late AdBlockerService service;

  setUp(() {
    // AdBlockerService résout Notifier dans un initialiseur de champ.
    if (!getIt.isRegistered<Notifier>()) {
      getIt.registerSingleton<Notifier>(Notifier());
    }
    service = AdBlockerService();
  });

  group('shouldBlockRequest — infrastructure de défi', () {
    const challengeUrls = [
      'https://challenges.cloudflare.com/turnstile/v0/api.js',
      'https://challenges.cloudflare.com/cdn-cgi/challenge-platform/h/g/turnstile/if/ov2/av0',
      'https://lelmanga.com/cdn-cgi/challenge-platform/h/g/orchestrate/chl_page/v1?ray=8f2a',
      'https://lelmanga.com/cdn-cgi/challenge-platform/scripts/jsd/main.js',
      'https://lelmanga.com/cdn-cgi/rum?req_id=abc',
      'https://static.cloudflareinsights.com/beacon.min.js',
      'https://newassets.hcaptcha.com/captcha/v1/api.js',
      'https://www.google.com/recaptcha/api2/anchor',
    ];

    for (final url in challengeUrls) {
      test('ne bloque jamais $url', () {
        expect(service.shouldBlockRequest(url), isFalse, reason: url);
      });
    }
  });

  group('shouldBlockRequest — non-régression publicités', () {
    const adUrls = [
      'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js',
      'https://doubleclick.net/pixel',
      'https://a.pemsrv.com/ad.js',
      'https://imp9.pubadx.one/req',
      'https://sync.kueezrtb.com/sync',
    ];

    for (final url in adUrls) {
      test('bloque toujours $url', () {
        expect(service.shouldBlockRequest(url), isTrue, reason: url);
      });
    }
  });

  group('isAllowedDomain', () {
    const origin = 'lelmanga.com';

    test('autorise le domaine du défi même s\'il est tiers', () {
      // Turnstile est servi depuis un domaine différent de l'origine :
      // sans cette autorisation, la navigation vers le défi était annulée.
      expect(service.isAllowedDomain('challenges.cloudflare.com', origin), isTrue);
      expect(service.isAllowedDomain('hcaptcha.com', origin), isTrue);
    });

    test('conserve le comportement d\'origine pour le site lu', () {
      expect(service.isAllowedDomain('lelmanga.com', origin), isTrue);
      expect(service.isAllowedDomain('www.lelmanga.com', origin), isTrue);
    });

    test('refuse toujours un domaine tiers non lié à un défi', () {
      expect(service.isAllowedDomain('doubleclick.net', origin), isFalse);
      expect(service.isAllowedDomain('un-autre-site.com', origin), isFalse);
    });

    test('refuse un domaine qui imite un domaine de défi', () {
      expect(
        service.isAllowedDomain('challenges.cloudflare.com.pub-malveillante.net', origin),
        isFalse,
      );
    });
  });

  group('sélecteurs de nettoyage DOM', () {
    test('ne cible plus iframe[sandbox] (le widget Turnstile est sandboxé)', () async {
      final script = await service.buildAdBlockScript(null);
      expect(
        script,
        isNot(contains("'iframe[sandbox]'")),
        reason: 'iframe[sandbox] supprimait le widget de vérification',
      );
    });

    test('ne cible plus [data-cfasync] (attribut Cloudflare)', () async {
      final script = await service.buildAdBlockScript(null);
      expect(script, isNot(contains("'[data-cfasync]'")));
      expect(script, isNot(contains("'data-cfasync'")));
    });

    test('injecte la garde de défi et le registre d\'arrêt', () async {
      final script = await service.buildAdBlockScript(null);
      expect(script, contains('CHALLENGE_SELECTORS'));
      expect(script, contains('pageHasChallenge'));
      expect(script, contains('challenges.cloudflare.com'));
      expect(script, contains('window.__mtAdBlock'));
    });

    test('reconnaît « ad » comme mot entier et non comme sous-chaîne', () async {
      final script = await service.buildAdBlockScript(null);
      expect(script, contains('hasAdToken'));
      // L'ancienne heuristique prenait « loading », « header », « shadow »
      // pour des publicités.
      expect(script, isNot(contains("el.className.includes('ad')")));
      expect(script, isNot(contains("el.id.includes('ad')")));
    });
  });
}
