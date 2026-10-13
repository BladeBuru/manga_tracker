import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';
import 'package:mangatracker/features/reader/services/chapter_change_classifier.dart';

export 'package:mangatracker/features/reader/services/chapter_change_classifier.dart';

/// Service pour gérer la navigation et la détection de chapitres dans les WebViews
class WebViewNavigationService {
  static const _classifier = ChapterChangeClassifier();

  /// Vérifie si deux domaines appartiennent au même provider
  bool sameProvider(String a, String b) {
    String root(String h) {
      final parts = h.split('.');
      return parts.length >= 2 ? '${parts[parts.length - 2]}.${parts.last}' : h;
    }
    return root(a) == root(b);
  }

  /// Classement pur d'un chapitre détecté (voir [ChapterChangeClassifier]).
  ChapterChangeResult classify(int newChapter, int? currentChapter) =>
      _classifier.classify(newChapter, currentChapter);

  /// Le lecteur ne réagit qu'à son propre site : ni pubs, ni trackers, ni
  /// autre domaine.
  bool _isReaderHost(String host, String originHost) {
    if (AdBlockerService.denyHosts.contains(host)) return false;
    // On reste sur le même provider (ou sous-domaines)
    return sameProvider(host, originHost);
  }

  /// Détecte un changement de chapitre depuis une URI
  /// Retourne null si aucun changement n'est détecté ou si le domaine n'est pas valide
  Future<ChapterChangeResult?> detectChapterChange(
    Uri uri,
    String originHost,
    int? currentChapter,
  ) async {
    if (!_isReaderHost(uri.host, originHost)) return null;
    final newCh = await ChapterLinkResolver.extractChapter(uri.toString());
    if (newCh == null) return null;
    return classify(newCh, currentChapter);
  }

  /// Changement de chapitre lu dans la PAGE ([pageChapter], cf.
  /// `PageChapterParser`) affichée à [uri].
  ///
  /// Uniquement quand l'URL ne donne AUCUN chapitre : un site déjà détecté
  /// par son URL garde exactement son comportement (l'URL reste prioritaire).
  Future<ChapterChangeResult?> detectPageChapterChange(
    Uri uri,
    String originHost, {
    required int pageChapter,
    int? currentChapter,
  }) async {
    if (!_isReaderHost(uri.host, originHost)) return null;
    if (await ChapterLinkResolver.extractChapter(uri.toString()) != null) {
      return null;
    }
    return classify(pageChapter, currentChapter);
  }
}
