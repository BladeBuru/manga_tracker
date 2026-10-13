/// Classement d'un chapitre détecté par rapport au chapitre courant —
/// **pur** (ni Flutter, ni GetIt, ni WebView).
///
/// Extrait de `WebViewNavigationService.detectChapterChange`, qui mêlait
/// l'extraction du numéro (URL) et ce classement : le même classement sert
/// désormais aussi au numéro lu dans la page (`PageChapterParser`), sans
/// dupliquer la règle. Ce qu'on ENREGISTRE ensuite reste décidé par
/// [ChapterCommitPolicy], inchangée.
/// Testé par `test/features/reader/chapter_change_classifier_test.dart`.
library;

import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';

/// Type de changement de chapitre détecté
enum ChapterChangeType {
  firstDetected, // Premier chapitre détecté
  nextChapter, // Passage au chapitre suivant (+1)
  jumpForward, // Saut vers l'avant (>+1)
  jumpBackward, // Retour en arrière (<)
  noChange, // Même chapitre
}

/// Traduction vers le vocabulaire de [ChapterCommitPolicy].
extension ChapterChangeTypeTransition on ChapterChangeType {
  ChapterTransition get asTransition {
    switch (this) {
      case ChapterChangeType.firstDetected:
        return ChapterTransition.firstDetected;
      case ChapterChangeType.nextChapter:
        return ChapterTransition.nextChapter;
      case ChapterChangeType.jumpForward:
        return ChapterTransition.jumpForward;
      case ChapterChangeType.jumpBackward:
        return ChapterTransition.jumpBackward;
      case ChapterChangeType.noChange:
        return ChapterTransition.noChange;
    }
  }
}

/// Résultat d'une détection de changement de chapitre
class ChapterChangeResult {
  final int? newChapter;
  final ChapterChangeType changeType;
  final int? previousChapter;

  ChapterChangeResult({
    required this.newChapter,
    required this.changeType,
    this.previousChapter,
  });
}

/// Classe [newChapter] par rapport à [currentChapter] (`null` = aucun
/// chapitre suivi pour l'instant).
class ChapterChangeClassifier {
  const ChapterChangeClassifier();

  ChapterChangeResult classify(int newChapter, int? currentChapter) {
    if (currentChapter == null) {
      return ChapterChangeResult(
        newChapter: newChapter,
        changeType: ChapterChangeType.firstDetected,
      );
    }
    final ChapterChangeType type;
    if (newChapter == currentChapter + 1) {
      type = ChapterChangeType.nextChapter;
    } else if (newChapter > currentChapter + 1) {
      type = ChapterChangeType.jumpForward;
    } else if (newChapter < currentChapter) {
      type = ChapterChangeType.jumpBackward;
    } else {
      type = ChapterChangeType.noChange;
    }
    return ChapterChangeResult(
      newChapter: newChapter,
      changeType: type,
      previousChapter: currentChapter,
    );
  }
}
