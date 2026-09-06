import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';
import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';

/// Type de changement de chapitre détecté
enum ChapterChangeType {
  firstDetected, // Premier chapitre détecté
  nextChapter, // Passage au chapitre suivant (+1)
  jumpForward, // Saut vers l'avant (>+1)
  jumpBackward, // Retour en arrière (<)
  noChange, // Même chapitre
}

/// Traduction vers le vocabulaire de [ChapterCommitPolicy], qui est pur et ne
/// peut donc pas dépendre de ce fichier (lié à la WebView).
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

/// Service pour gérer la navigation et la détection de chapitres dans les WebViews
class WebViewNavigationService {
  /// Vérifie si deux domaines appartiennent au même provider
  bool sameProvider(String a, String b) {
    String root(String h) {
      final parts = h.split('.');
      return parts.length >= 2 ? '${parts[parts.length - 2]}.${parts.last}' : h;
    }
    return root(a) == root(b);
  }

  /// Détecte un changement de chapitre depuis une URI
  /// Retourne null si aucun changement n'est détecté ou si le domaine n'est pas valide
  Future<ChapterChangeResult?> detectChapterChange(
    Uri uri,
    String originHost,
    int? currentChapter,
  ) async {
    // Filtrage domaines : on ne réagit pas aux pubs/trackers
    final host = uri.host;
    if (AdBlockerService.denyHosts.contains(host)) return null;
    
    // On reste sur le même provider (ou sous-domaines)
    if (!sameProvider(host, originHost)) return null;

    final newCh = await ChapterLinkResolver.extractChapter(uri.toString());
    if (newCh == null) return null;

    // Premier chapitre détecté
    if (currentChapter == null) {
      return ChapterChangeResult(
        newChapter: newCh,
        changeType: ChapterChangeType.firstDetected,
      );
    }

    // Passage naturel au suivant
    if (newCh == currentChapter + 1) {
      return ChapterChangeResult(
        newChapter: newCh,
        changeType: ChapterChangeType.nextChapter,
        previousChapter: currentChapter,
      );
    }

    // Saut vers l'avant
    if (newCh > currentChapter + 1) {
      return ChapterChangeResult(
        newChapter: newCh,
        changeType: ChapterChangeType.jumpForward,
        previousChapter: currentChapter,
      );
    }

    // Retour en arrière
    if (newCh < currentChapter) {
      return ChapterChangeResult(
        newChapter: newCh,
        changeType: ChapterChangeType.jumpBackward,
        previousChapter: currentChapter,
      );
    }

    // Même chapitre
    return ChapterChangeResult(
      newChapter: newCh,
      changeType: ChapterChangeType.noChange,
      previousChapter: currentChapter,
    );
  }
}

