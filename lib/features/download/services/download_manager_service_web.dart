/// Stub web pour `DownloadManagerService`.
///
/// La feature de téléchargement de chapitres n'a pas de sens sur Flutter Web
/// (pas de système de fichiers persistant accessible). Ce stub permet la
/// compilation tout en retournant des valeurs vides — les boutons Download
/// sont cachés sur web via `kIsWeb` (cf. CLAUDE.md, section cross-platform).
library;

import '../models/downloaded_chapter.model.dart';

class DownloadManagerService {
  Future<String> getDownloadsBasePath() async => '';

  Future<String> getMangaDownloadPath(String mangaTitle) async => '';

  Future<String> getChapterDownloadPath(String mangaTitle, int chapterNumber) async => '';

  Future<Map<int, List<DownloadedChapter>>> getAllDownloadedChapters() async => {};

  Future<List<DownloadedChapter>> getDownloadedChapters(int muId) async => [];

  Future<void> addDownloadedChapter(DownloadedChapter chapter) async {
    // No-op sur web
  }

  Future<void> removeDownloadedChapter(int muId, int chapterNumber) async {
    // No-op sur web
  }

  Future<void> removeAllDownloadedChapters(int muId) async {
    // No-op sur web
  }

  Future<void> removeAllDownloads() async {
    // No-op sur web
  }

  Future<bool> isChapterDownloaded(int muId, int chapterNumber) async => false;

  Future<DownloadedChapter?> getDownloadedChapter(int muId, int chapterNumber) async => null;

  Future<int> getTotalDownloadSize() async => 0;
}
