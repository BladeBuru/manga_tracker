/// Façade conditionnelle pour `ChapterDownloadService`.
///
/// **Mobile** : impl complète qui télécharge HTML + images via `dart:io`.
/// **Web** : stub qui throw `UnsupportedError` si appelé (les call sites
///   doivent guarder avec `kIsWeb` pour ne pas l'invoquer sur web).
library;

export 'chapter_download_service_io.dart'
    if (dart.library.html) 'chapter_download_service_web.dart';
