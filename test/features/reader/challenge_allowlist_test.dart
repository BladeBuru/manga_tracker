import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/challenge_allowlist.dart';

void main() {
  group('ChallengeAllowlist.isChallengeHost', () {
    test('autorise les domaines Cloudflare de défi', () {
      expect(ChallengeAllowlist.isChallengeHost('challenges.cloudflare.com'), isTrue);
      expect(ChallengeAllowlist.isChallengeHost('cloudflare.com'), isTrue);
      expect(ChallengeAllowlist.isChallengeHost('static.cloudflareinsights.com'), isTrue);
    });

    test('autorise les autres fournisseurs de défi', () {
      expect(ChallengeAllowlist.isChallengeHost('hcaptcha.com'), isTrue);
      expect(ChallengeAllowlist.isChallengeHost('newassets.hcaptcha.com'), isTrue);
      expect(ChallengeAllowlist.isChallengeHost('www.recaptcha.net'), isTrue);
    });

    test('est insensible à la casse et au point final', () {
      expect(ChallengeAllowlist.isChallengeHost('Challenges.CloudFlare.COM'), isTrue);
      expect(ChallengeAllowlist.isChallengeHost('challenges.cloudflare.com.'), isTrue);
    });

    test('n\'autorise pas un hôte qui imite un domaine de défi', () {
      // Le point clé : correspondance par suffixe, jamais par `contains`.
      expect(
        ChallengeAllowlist.isChallengeHost('challenges.cloudflare.com.pub-malveillante.net'),
        isFalse,
      );
      expect(ChallengeAllowlist.isChallengeHost('notcloudflare.com'), isFalse);
      expect(ChallengeAllowlist.isChallengeHost('cloudflare.com.evil.net'), isFalse);
    });

    test('n\'autorise pas un domaine quelconque', () {
      expect(ChallengeAllowlist.isChallengeHost('doubleclick.net'), isFalse);
      expect(ChallengeAllowlist.isChallengeHost('lelmanga.com'), isFalse);
      expect(ChallengeAllowlist.isChallengeHost(''), isFalse);
    });
  });

  group('ChallengeAllowlist.isChallengeUrl', () {
    test('préserve les ressources Turnstile', () {
      expect(
        ChallengeAllowlist.isChallengeUrl('https://challenges.cloudflare.com/turnstile/v0/api.js'),
        isTrue,
      );
      expect(
        ChallengeAllowlist.isChallengeUrl(
          'https://challenges.cloudflare.com/cdn-cgi/challenge-platform/h/g/turnstile/if/ov2/av0/rcv0/0/abcde',
        ),
        isTrue,
      );
    });

    test('préserve les endpoints /cdn-cgi/ servis par le site d\'origine', () {
      // C'est ainsi que le défi « Un instant… » est servi : sur l'origine.
      expect(
        ChallengeAllowlist.isChallengeUrl(
          'https://lelmanga.com/cdn-cgi/challenge-platform/h/g/orchestrate/chl_page/v1?ray=8f2a',
        ),
        isTrue,
      );
      expect(
        ChallengeAllowlist.isChallengeUrl(
          'https://un-site-quelconque.org/cdn-cgi/challenge-platform/scripts/jsd/main.js',
        ),
        isTrue,
      );
    });

    test('préserve les chemins reCAPTCHA sans autoriser google.com en entier', () {
      expect(
        ChallengeAllowlist.isChallengeUrl('https://www.google.com/recaptcha/api2/anchor'),
        isTrue,
      );
      expect(
        ChallengeAllowlist.isChallengeUrl('https://www.gstatic.com/recaptcha/releases/abc.js'),
        isTrue,
      );
      // google.com hors chemin reCAPTCHA n'est pas mis en liste blanche.
      expect(
        ChallengeAllowlist.isChallengeUrl('https://adservice.google.com/pagead/ads'),
        isFalse,
      );
    });

    test('ne préserve pas les URL publicitaires', () {
      expect(
        ChallengeAllowlist.isChallengeUrl('https://pagead2.googlesyndication.com/pagead/js/ads.js'),
        isFalse,
      );
      expect(ChallengeAllowlist.isChallengeUrl('https://doubleclick.net/xyz'), isFalse);
      expect(ChallengeAllowlist.isChallengeUrl('pas une url du tout'), isFalse);
    });
  });

  group('ChallengeAllowlist.challengeSelectorGroup', () {
    test('cible les conteneurs de défi Cloudflare', () {
      final group = ChallengeAllowlist.challengeSelectorGroup;
      expect(group, contains('#challenge-form'));
      expect(group, contains('.cf-turnstile'));
      expect(group, contains('iframe[src*="challenges.cloudflare.com"]'));
    });

    test('produit un groupe de sélecteurs séparé par des virgules', () {
      expect(
        ChallengeAllowlist.challengeSelectorGroup.split(', ').length,
        ChallengeAllowlist.challengeSelectors.length,
      );
    });
  });
}
