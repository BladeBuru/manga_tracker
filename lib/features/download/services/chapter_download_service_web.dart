/// Stub web pour `ChapterDownloadService`.
///
/// Le téléchargement de chapitres n'est pas supporté sur web (pas de FS
/// persistant côté navigateur). Les call sites doivent guarder avec `kIsWeb`.
library;

import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';

class ChapterDownloadService {
  ChapterDownloadService();

  Future<DownloadedChapter> downloadChapter({
    required int muId,
    required int chapterNumber,
    required String chapterUrl,
    String? mangaTitle,
    Function(double progress)? onProgress,
  }) {
    throw UnsupportedError(
      'ChapterDownloadService.downloadChapter() is not supported on web. '
      'Guard call sites with kIsWeb.',
    );
  }

  Future<String> processHtmlForOffline(
    String html,
    String baseUrl,
    String chapterPath, {
    Function(double progress)? onProgress,
  }) async {
    // Sur web, on retourne le HTML brut sans rien faire
    return html;
  }
}
