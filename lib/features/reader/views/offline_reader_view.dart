/// Façade conditionnelle pour `OfflineReaderView`.
///
/// **Mobile** : lecteur hors-ligne complet (lit le HTML+images cachés).
/// **Web** : Scaffold simple "Non disponible sur web" (la feature offline
///   n'existe pas côté navigateur — les call sites guardent avec `kIsWeb`).
library;

export 'offline_reader_view_io.dart'
    if (dart.library.html) 'offline_reader_view_web.dart';
