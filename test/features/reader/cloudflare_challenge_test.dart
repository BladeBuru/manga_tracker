import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/cloudflare_challenge.dart';

void main() {
  group('CloudflareChallenge.isChallengeResponse', () {
    // Réponse réelle relevée sur l'appareil le 2026-09-27 (manga-scantrad.io).
    const challengeHeaders = {
      'server': 'cloudflare',
      'cf-mitigated': 'challenge',
      'cf-ray': 'a41b20bcf87c9ecf-CDG',
    };

    test('403 + cf-mitigated: challenge sur la frame principale → défi', () {
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: 403,
          headers: challengeHeaders,
        ),
        isTrue,
      );
    });

    test('la casse de l\'en-tête et de sa valeur est ignorée', () {
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: 503,
          headers: const {'CF-Mitigated': ' Challenge '},
        ),
        isTrue,
      );
    });

    test('une ressource secondaire atténuée (favicon) n\'est PAS un défi', () {
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: false,
          statusCode: 403,
          headers: challengeHeaders,
        ),
        isFalse,
      );
    });

    test('un 403 ordinaire (sans l\'en-tête) n\'est pas un défi', () {
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: 403,
          headers: const {'server': 'cloudflare'},
        ),
        isFalse,
      );
    });

    test('une autre atténuation (block) n\'est pas un défi', () {
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: 403,
          headers: const {'cf-mitigated': 'block'},
        ),
        isFalse,
      );
    });

    test('pas d\'en-têtes ou statut de succès → jamais un défi', () {
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: 403,
          headers: null,
        ),
        isFalse,
      );
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: 200,
          headers: challengeHeaders,
        ),
        isFalse,
      );
      expect(
        CloudflareChallenge.isChallengeResponse(
          isForMainFrame: true,
          statusCode: null,
          headers: challengeHeaders,
        ),
        isFalse,
      );
    });
  });

  group('CloudflareChallenge.isClearanceRenewed', () {
    test('un nouveau cookie remplace l\'ancien → défi validé', () {
      expect(
        CloudflareChallenge.isClearanceRenewed(before: 'ancien', after: 'neuf'),
        isTrue,
      );
    });

    test('premier cookie posé alors qu\'il n\'y en avait pas → validé', () {
      expect(
        CloudflareChallenge.isClearanceRenewed(before: null, after: 'neuf'),
        isTrue,
      );
    });

    test('cookie inchangé → pas encore validé', () {
      expect(
        CloudflareChallenge.isClearanceRenewed(before: 'même', after: 'même'),
        isFalse,
      );
    });

    test('cookie absent ou vide → pas validé', () {
      expect(
        CloudflareChallenge.isClearanceRenewed(before: 'ancien', after: null),
        isFalse,
      );
      expect(
        CloudflareChallenge.isClearanceRenewed(before: null, after: ''),
        isFalse,
      );
    });
  });
}
