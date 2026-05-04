/// Façade conditionnelle pour `ChapterCheckBackgroundService`.
///
/// **Mobile** (Android) : `workmanager` pour vérifications périodiques.
/// **iOS** : workmanager partiellement supporté → ce stub mobile fait office.
///   À terme, abstraction `BGTaskScheduler` à implémenter (cf. CLAUDE.md).
/// **Web** : no-op (pas de background tasks possibles côté navigateur).
library;

export 'chapter_check_background_service_io.dart'
    if (dart.library.html) 'chapter_check_background_service_web.dart';
