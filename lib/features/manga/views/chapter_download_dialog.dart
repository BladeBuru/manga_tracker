/// Façade conditionnelle pour `ChapterDownloadDialog`.
///
/// **Mobile** : dialog complet de téléchargement multi-chapitres.
/// **Web** : stub qui affiche un message "Non disponible sur web".
library;

export 'chapter_download_dialog_io.dart'
    if (dart.library.html) 'chapter_download_dialog_web.dart';
