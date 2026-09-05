import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';
import 'package:mangatracker/features/reader/services/reader_navigation_policy.dart';

/// Régression v0.13.0 : la protection anti-redirection du lecteur.
///
/// Pendant la lecture, la frame principale ne doit JAMAIS pouvoir quitter le
/// site du lien de l'utilisateur (sauf vers une vérification anti-robot).
/// Ces tests verrouillent la décision ; `reader_invariants_test.dart`
/// verrouille son branchement effectif sur la WebView.
void main() {
  group('ReaderNavigationPolicy — règles (prédicats simulés)', () {
    final adHosts = {'ads.example.net', 'popunder.biz'};
    final policy = ReaderNavigationPolicy(
      blocksRequest: (url) => adHosts.any(url.contains),
      allowsHost: (host) => host == 'lecture.site' || host == 'cdn.lecture.site',
    );

    ReaderNavigationDecision decide(String url, {bool mainFrame = true}) =>
        policy.decide(url: Uri.parse(url), isForMainFrame: mainFrame);

    test('URL absente → autorisée (rien à juger)', () {
      expect(
        policy.decide(url: null, isForMainFrame: true),
        ReaderNavigationDecision.allow,
      );
    });

    test('même site → autorisée', () {
      expect(decide('https://lecture.site/manga/x/chapitre-12'),
          ReaderNavigationDecision.allow);
      expect(decide('https://cdn.lecture.site/page-3.jpg', mainFrame: false),
          ReaderNavigationDecision.allow);
    });

    test('REDIRECTION de la frame principale vers un autre site → ANNULÉE',
        () {
      expect(decide('https://autre-site.com/promo'),
          ReaderNavigationDecision.cancel);
      expect(decide('https://bit.ly/3xyz'), ReaderNavigationDecision.cancel);
      expect(decide('http://lecture.site.evil.tld/'),
          ReaderNavigationDecision.cancel);
    });

    test('URL publicitaire → annulée, même dans une sous-frame', () {
      expect(decide('https://ads.example.net/click?id=1'),
          ReaderNavigationDecision.cancel);
      expect(decide('https://popunder.biz/x', mainFrame: false),
          ReaderNavigationDecision.cancel);
    });

    test('sous-frame vers un autre site non publicitaire → autorisée', () {
      // Images, CDN, widgets légitimes : on ne bloque que la frame principale.
      expect(decide('https://images.tiers.com/a.jpg', mainFrame: false),
          ReaderNavigationDecision.allow);
    });
  });

  group('ReaderNavigationPolicy — branchée sur AdBlockerService (réel)', () {
    late ReaderNavigationPolicy policy;
    const origin = 'lelmanga.com';

    setUp(() {
      // AdBlockerService résout Notifier dans un initialiseur de champ.
      if (!getIt.isRegistered<Notifier>()) {
        getIt.registerSingleton<Notifier>(Notifier());
      }
      final service = AdBlockerService();
      policy = ReaderNavigationPolicy(
        blocksRequest: service.shouldBlockRequest,
        allowsHost: (host) => service.isAllowedDomain(host, origin),
      );
    });

    ReaderNavigationDecision decide(String url, {bool mainFrame = true}) =>
        policy.decide(url: Uri.parse(url), isForMainFrame: mainFrame);

    test('navigation entre chapitres du même site → autorisée', () {
      expect(decide('https://lelmanga.com/one-piece-chapter-1100'),
          ReaderNavigationDecision.allow);
      expect(decide('https://www.lelmanga.com/one-piece-chapter-1101'),
          ReaderNavigationDecision.allow);
    });

    test('redirection publicitaire de la frame principale → annulée', () {
      for (final url in const [
        'https://doubleclick.net/pagead/ads',
        'https://googleads.g.doubleclick.net/pagead/id',
        'https://un-site-de-pub-quelconque.com/landing',
        'https://mangaupdates.com/series/123', // autre site, même légitime
      ]) {
        expect(decide(url), ReaderNavigationDecision.cancel, reason: url);
      }
    });

    test('vérification anti-robot → toujours autorisée', () {
      for (final url in const [
        'https://challenges.cloudflare.com/turnstile/v0/api.js',
        'https://lelmanga.com/cdn-cgi/challenge-platform/h/g/orchestrate/chl_page/v1',
      ]) {
        expect(decide(url), ReaderNavigationDecision.allow, reason: url);
        expect(decide(url, mainFrame: false), ReaderNavigationDecision.allow,
            reason: url);
      }
    });
  });
}
