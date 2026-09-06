import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';

/// Sémantique de la progression de lecture.
///
/// « Chapitres lus » = dernier chapitre TERMINÉ. Ces tests décrivent la règle
/// en français parce qu'elle est produit, pas technique : un utilisateur qui
/// ouvre le chapitre 134 n'a pas lu le 134.
void main() {
  const policy = ChapterCommitPolicy();

  group('non-régression — le décalage d\'un chapitre (bug cc586a0, v0.8.0)',
      () {
    test('arriver sur un chapitre ne le marque JAMAIS comme lu', () {
      // Le cœur du bug : 133 → 134 enregistrait 133 ET 134, si bien que
      // l'app affichait « progression du chapitre 134 » à la seconde où on
      // l'ouvrait. Un chapitre d'avance, en permanence.
      for (final transition in ChapterTransition.values) {
        final decision = policy.onTransition(
          transition: transition,
          newChapter: 134,
          previousChapter: 133,
        );
        expect(
          decision.commitChapter,
          isNot(134),
          reason: '$transition enregistre le chapitre d\'ARRIVÉE (134) : '
              'ouvrir un chapitre ne prouve pas qu\'on l\'a lu.',
        );
        expect(
          decision.askUserToCommitChapter,
          isNot(134),
          reason: '$transition propose d\'enregistrer le chapitre '
              'd\'ARRIVÉE (134), ce qui n\'a aucun sens.',
        );
      }
    });

    test('133 → 134 n\'enregistre QUE 133', () {
      final decision = policy.onTransition(
        transition: ChapterTransition.nextChapter,
        newChapter: 134,
        previousChapter: 133,
      );

      expect(decision.commitChapter, 133);
      expect(decision.askUserToCommitChapter, isNull,
          reason: 'Le passage au suivant est une preuve, pas une question.');
      expect(decision.initializeChapter, 134,
          reason: 'On suit bien le 134, on ne l\'enregistre simplement pas.');
      expect(decision.releaseScrollOfChapter, 133);
    });
  });

  group('transitions', () {
    test('premier chapitre détecté n\'enregistre rien', () {
      final decision = policy.onTransition(
        transition: ChapterTransition.firstDetected,
        newChapter: 120,
      );

      expect(decision.commitsNothing, isTrue);
      expect(decision.initializeChapter, 120);
      expect(decision.releaseScrollOfChapter, isNull,
          reason: 'Aucun chapitre n\'a été quitté.');
    });

    test('retour en arrière n\'enregistre rien', () {
      final decision = policy.onTransition(
        transition: ChapterTransition.jumpBackward,
        newChapter: 120,
        previousChapter: 133,
      );

      expect(decision.commitsNothing, isTrue,
          reason: 'Relire un chapitre antérieur ne fait pas avancer la '
              'progression.');
      expect(decision.initializeChapter, 120);
    });

    test('même chapitre (rechargement) ne fait rien du tout', () {
      final decision = policy.onTransition(
        transition: ChapterTransition.noChange,
        newChapter: 133,
        previousChapter: 133,
      );

      expect(decision, ChapterChangeDecision.none);
    });

    test('134 → 140 propose 134, jamais 140 ni 139', () {
      final decision = policy.onTransition(
        transition: ChapterTransition.jumpForward,
        newChapter: 140,
        previousChapter: 134,
      );

      expect(decision.askUserToCommitChapter, 134,
          reason: 'La modale dit « Marquer 134 comme lu ? » — le code '
              'enregistrait 139 (newChapter - 1).');
      expect(decision.commitChapter, isNull,
          reason: 'Un saut n\'enregistre rien sans confirmation.');
      expect(decision.initializeChapter, 140);
    });

    test('134 → 140 avec « Oui » enregistre 134', () {
      final decision = policy.onTransition(
        transition: ChapterTransition.jumpForward,
        newChapter: 140,
        previousChapter: 134,
      );

      expect(
        policy.resolveAnswer(
          answer: true,
          chapter: decision.askUserToCommitChapter,
        ),
        134,
      );
    });

    test('134 → 140 avec « Non » n\'enregistre rien', () {
      expect(policy.resolveAnswer(answer: false, chapter: 134), isNull);
    });

    test('modale fermée sans répondre n\'enregistre rien', () {
      expect(policy.resolveAnswer(answer: null, chapter: 134), isNull);
    });
  });

  group('sortie du lecteur', () {
    test('proche de la fin et chapitre non enregistré → on demande', () {
      final exit = policy.onExit(
        currentChapter: 133,
        lastCommitted: 132,
        isNearEnd: true,
      );

      expect(exit.shouldAsk, isTrue);
      expect(exit.askUserToCommitChapter, 133);
    });

    test('« Oui » à la sortie enregistre le chapitre courant', () {
      final exit = policy.onExit(
        currentChapter: 133,
        lastCommitted: 132,
        isNearEnd: true,
      );

      expect(
        policy.resolveAnswer(
          answer: true,
          chapter: exit.askUserToCommitChapter,
        ),
        133,
      );
    });

    test('« Non » à la sortie n\'enregistre rien', () {
      final exit = policy.onExit(
        currentChapter: 133,
        lastCommitted: 132,
        isNearEnd: true,
      );

      expect(
        policy.resolveAnswer(
          answer: false,
          chapter: exit.askUserToCommitChapter,
        ),
        isNull,
      );
    });

    test('loin de la fin → aucune question, aucun enregistrement', () {
      final exit = policy.onExit(
        currentChapter: 133,
        lastCommitted: 132,
        isNearEnd: false,
      );

      expect(exit, ReaderExitDecision.leaveSilently);
    });

    test('chapitre déjà enregistré → aucune question', () {
      // C'est exactement ce qui rendait la modale structurellement morte :
      // le commit du chapitre d'arrivée mettait `lastCommitted` au niveau du
      // chapitre courant, donc la garde était toujours fausse.
      final exit = policy.onExit(
        currentChapter: 134,
        lastCommitted: 134,
        isNearEnd: true,
      );

      expect(exit.shouldAsk, isFalse);
    });

    test('aucun chapitre détecté → aucune question', () {
      final exit = policy.onExit(
        currentChapter: null,
        lastCommitted: 0,
        isNearEnd: true,
      );

      expect(exit.shouldAsk, isFalse);
    });

    test('mesure impossible (traitée comme « pas à la fin ») → on sort', () {
      final exit = policy.onExit(
        currentChapter: 133,
        lastCommitted: 0,
        isNearEnd: false,
      );

      expect(exit.shouldAsk, isFalse,
          reason: 'Préférer un faux négatif à un faux « chapitre fini ».');
    });
  });

  group('monotonie de la progression', () {
    test('un chapitre déjà dépassé n\'est jamais réenregistré', () {
      expect(policy.shouldCommit(120, 133), isFalse);
      expect(policy.shouldCommit(133, 133), isFalse);
      expect(policy.shouldCommit(134, 133), isTrue);
    });
  });
}
