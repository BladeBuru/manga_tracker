import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/challenge_loop_detector.dart';

void main() {
  const challengeUrl = 'https://lelmanga.com/manga/one-piece/chapitre-1100/';

  /// Horloge contrôlable pour piloter la fenêtre temporelle.
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime(2026, 8, 31, 12));

  ChallengeLoopDetector build({int threshold = 3, Duration? window}) =>
      ChallengeLoopDetector(
        threshold: threshold,
        window: window ?? const Duration(seconds: 90),
        clock: clock,
      );

  group('détection de boucle', () {
    test('ne propose rien avant le seuil', () {
      final d = build();

      expect(d.recordChallenge(challengeUrl), isFalse);
      expect(d.shouldOfferEscape, isFalse);
      expect(d.failureCount, 1);

      now = now.add(const Duration(seconds: 5));
      expect(d.recordChallenge(challengeUrl), isFalse);
      expect(d.shouldOfferEscape, isFalse);
      expect(d.failureCount, 2);
    });

    test('propose la sortie au N-ième échec consécutif', () {
      final d = build();

      d.recordChallenge(challengeUrl);
      now = now.add(const Duration(seconds: 5));
      d.recordChallenge(challengeUrl);
      now = now.add(const Duration(seconds: 5));

      // 3e présentation → franchissement du seuil.
      expect(d.recordChallenge(challengeUrl), isTrue);
      expect(d.shouldOfferEscape, isTrue);
      expect(d.failureCount, 3);
    });

    test('ne propose la sortie qu\'une seule fois par boucle', () {
      final d = build();

      for (var i = 0; i < 2; i++) {
        d.recordChallenge(challengeUrl);
        now = now.add(const Duration(seconds: 5));
      }
      expect(d.recordChallenge(challengeUrl), isTrue, reason: 'premier franchissement');

      now = now.add(const Duration(seconds: 5));
      expect(
        d.recordChallenge(challengeUrl),
        isFalse,
        reason: 'la proposition ne doit pas être répétée à chaque rechargement',
      );
      expect(d.escapeAlreadyOffered, isTrue);
      expect(d.shouldOfferEscape, isTrue);
    });

    test('ignore la query : chaque itération Cloudflare a un jeton différent', () {
      final d = build();

      // Sans normalisation, ces 3 URL passeraient pour 3 pages distinctes
      // et la boucle ne serait jamais détectée.
      d.recordChallenge('$challengeUrl?__cf_chl_rt_tk=aaa');
      now = now.add(const Duration(seconds: 5));
      d.recordChallenge('$challengeUrl?__cf_chl_rt_tk=bbb');
      now = now.add(const Duration(seconds: 5));

      expect(d.recordChallenge('$challengeUrl?__cf_chl_rt_tk=ccc'), isTrue);
      expect(d.failureCount, 3);
    });

    test('repart de zéro sur une page différente', () {
      final d = build();

      d.recordChallenge(challengeUrl);
      now = now.add(const Duration(seconds: 5));
      d.recordChallenge(challengeUrl);
      now = now.add(const Duration(seconds: 5));

      d.recordChallenge('https://lelmanga.com/manga/naruto/chapitre-1/');
      expect(d.failureCount, 1);
      expect(d.shouldOfferEscape, isFalse);
    });

    test('repart de zéro si les présentations sont trop espacées', () {
      final d = build(window: const Duration(seconds: 90));

      d.recordChallenge(challengeUrl);
      d.recordChallenge(challengeUrl);
      expect(d.failureCount, 2);

      // Au-delà de la fenêtre : nouveau défi, pas une boucle.
      now = now.add(const Duration(seconds: 91));
      d.recordChallenge(challengeUrl);
      expect(d.failureCount, 1);
      expect(d.shouldOfferEscape, isFalse);
    });

    test('un succès clôt la séquence', () {
      final d = build();

      d.recordChallenge(challengeUrl);
      now = now.add(const Duration(seconds: 5));
      d.recordChallenge(challengeUrl);

      d.recordSuccess();

      expect(d.failureCount, 0);
      expect(d.shouldOfferEscape, isFalse);
      expect(d.currentKey, isNull);

      // Après un succès, il faut de nouveau N échecs pour proposer la sortie.
      now = now.add(const Duration(seconds: 5));
      expect(d.recordChallenge(challengeUrl), isFalse);
      expect(d.failureCount, 1);
    });

    test('respecte un seuil personnalisé', () {
      final d = build(threshold: 2);

      expect(d.recordChallenge(challengeUrl), isFalse);
      now = now.add(const Duration(seconds: 5));
      expect(d.recordChallenge(challengeUrl), isTrue);
    });

    test('refuse un seuil nul ou négatif', () {
      expect(() => ChallengeLoopDetector(threshold: 0), throwsAssertionError);
    });
  });
}
