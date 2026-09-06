import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';
import 'package:mangatracker/features/reader/services/reading_resume_policy.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';

/// Décision de reprise à l'ouverture d'un manga — classe pure.
///
/// Deux principes en tension, qu'aucun test ne doit laisser s'inverser :
/// ne jamais faire **perdre** ce qui a été lu, ne jamais faire **relire ni
/// sauter** sans le vouloir.
void main() {
  const policy = ReadingResumePolicy();

  ReadingPositionDto position(
    int chapter,
    double percent, {
    DateTime? at,
  }) =>
      ReadingPositionDto(
        chapter: chapter,
        positionPercent: percent,
        updatedAt: at,
      );

  group('aucune position exploitable', () {
    test('rien nulle part → dernier lu + 1, en haut de page', () {
      final decision = policy.decide(lastReadChapter: 41);

      expect(decision.mode, ReadingResumeMode.fromStart);
      expect(decision.chapter, 42);
      expect(decision.positionPercent, isNull);
      expect(decision.needsConfirmation, isFalse);
    });

    test('position trop haute dans le chapitre → on ouvre en haut', () {
      // Sous 3 %, rouvrir en haut ne fait rien perdre : ce n'est pas la peine
      // de traiter ça comme une lecture en cours.
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 1.5),
      );

      expect(decision.mode, ReadingResumeMode.fromStart);
      expect(decision.chapter, 42);
      expect(decision.positionPercent, isNull);
    });

    test('position en zone « fin de chapitre » → on ouvre en haut', () {
      // Reprendre à 97 % poserait l'utilisateur devant les commentaires.
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, kReadingEndThresholdPercent + 5),
      );

      expect(decision.mode, ReadingResumeMode.fromStart);
    });

    test('le seuil de fin est exclusif, celui de départ inclusif', () {
      expect(
        policy
            .decide(lastReadChapter: 41, local: position(42, 3))
            .mode,
        ReadingResumeMode.resumeSilently,
      );
      expect(
        policy
            .decide(
              lastReadChapter: 41,
              local: position(42, kReadingEndThresholdPercent.toDouble()),
            )
            .mode,
        ReadingResumeMode.fromStart,
      );
    });
  });

  group('garde-fou : un chapitre terminé ne se rouvre jamais au milieu', () {
    test('une position sur un chapitre déjà lu est ignorée', () {
      // Cas réel : le PUT d\'une position part juste avant que le chapitre ne
      // soit validé. Le serveur nettoie de son côté, mais ce garde-fou pur
      // rattrape la course sans dépendre de lui.
      final decision = policy.decide(
        lastReadChapter: 42,
        remote: position(42, 60, at: DateTime.utc(2026, 9, 6)),
      );

      expect(decision.mode, ReadingResumeMode.fromStart);
      expect(decision.chapter, 43);
    });

    test('une position sur un chapitre antérieur est ignorée aussi', () {
      final decision = policy.decide(
        lastReadChapter: 42,
        local: position(12, 50, at: DateTime.utc(2026, 9, 6)),
      );

      expect(decision.mode, ReadingResumeMode.fromStart);
      expect(decision.chapter, 43);
    });
  });

  group('reprise silencieuse — le chapitre attendu', () {
    test('la position porte sur dernier lu + 1 → on reprend sans demander',
        () {
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 37.5),
      );

      expect(decision.mode, ReadingResumeMode.resumeSilently);
      expect(decision.chapter, 42);
      expect(decision.positionPercent, 37.5);
      expect(decision.needsConfirmation, isFalse);
    });

    test('la position vient du serveur, même chapitre → toujours silencieux',
        () {
      final decision = policy.decide(
        lastReadChapter: 41,
        remote: position(42, 60, at: DateTime.utc(2026, 9, 6)),
      );

      expect(decision.mode, ReadingResumeMode.resumeSilently);
      expect(decision.positionPercent, 60);
    });
  });

  group('confirmation — la lecture en cours est sur un AUTRE chapitre', () {
    test('le serveur est plus avancé que la progression locale → on demande',
        () {
      // La tablette lisait le 50 ; le téléphone, lui, allait ouvrir le 42.
      // Ouvrir le 50 en silence ferait sauter 8 chapitres ; ouvrir le 42
      // perdrait l'avancée. Les deux ont un coût → question.
      final decision = policy.decide(
        lastReadChapter: 41,
        remote: position(50, 40, at: DateTime.utc(2026, 9, 6)),
      );

      expect(decision.mode, ReadingResumeMode.askUser);
      expect(decision.needsConfirmation, isTrue);
      expect(decision.chapter, 50);
      expect(decision.positionPercent, 40);
      expect(decision.declinedChapter, 42,
          reason: 'refuser doit rendre exactement le comportement d\'avant');
    });
  });

  group('arbitrage local / serveur', () {
    test('la position la plus récente gagne', () {
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 20, at: DateTime.utc(2026, 9, 6, 8)),
        remote: position(45, 70, at: DateTime.utc(2026, 9, 6, 11)),
      );

      expect(decision.chapter, 45);
      expect(decision.positionPercent, 70);
      expect(decision.mode, ReadingResumeMode.askUser);
    });

    test('la position locale gagne si elle est la plus fraîche', () {
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 20, at: DateTime.utc(2026, 9, 6, 12)),
        remote: position(45, 70, at: DateTime.utc(2026, 9, 6, 11)),
      );

      expect(decision.chapter, 42);
      expect(decision.positionPercent, 20);
      expect(decision.mode, ReadingResumeMode.resumeSilently);
    });

    test('une position sans horodatage perd l\'arbitrage', () {
      // Entrée héritée d'une version antérieure : on ne sait pas si elle date
      // d'une minute ou d'un mois.
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 20),
        remote: position(45, 70, at: DateTime.utc(2026, 1, 1)),
      );

      expect(decision.chapter, 45);
    });

    test('si la plus récente est inexploitable, l\'autre reprend la main', () {
      // Le serveur pointe un chapitre déjà terminé ; la mémoire locale, plus
      // ancienne mais valide, doit quand même servir.
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 30, at: DateTime.utc(2026, 9, 6, 8)),
        remote: position(30, 55, at: DateTime.utc(2026, 9, 6, 11)),
      );

      expect(decision.chapter, 42);
      expect(decision.positionPercent, 30);
      expect(decision.mode, ReadingResumeMode.resumeSilently);
    });

    test('à horodatage égal, le serveur tranche (vue partagée)', () {
      final sameMoment = DateTime.utc(2026, 9, 6, 10);
      final decision = policy.decide(
        lastReadChapter: 41,
        local: position(42, 20, at: sameMoment),
        remote: position(42, 65, at: sameMoment),
      );

      expect(decision.positionPercent, 65);
    });
  });

  test('un pourcentage non fini n\'est jamais retenu', () {
    final decision = policy.decide(
      lastReadChapter: 41,
      local: position(42, double.nan),
    );

    expect(decision.mode, ReadingResumeMode.fromStart);
  });
}
