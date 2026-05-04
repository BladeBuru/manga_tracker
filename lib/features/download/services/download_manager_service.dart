/// Façade conditionnelle pour `DownloadManagerService`.
///
/// **Mobile** (Android/iOS) : implémentation native via `dart:io` File/Directory
///   → cf. `download_manager_service_io.dart`
/// **Web** : stub no-op qui retourne des valeurs vides (la fonctionnalité de
///   téléchargement de chapitres n'existe pas sur web — l'UI cache les boutons
///   correspondants via `kIsWeb`)
///   → cf. `download_manager_service_web.dart`
///
/// Les call sites importent ce fichier sans avoir à se soucier de la plateforme.
library;

export 'download_manager_service_io.dart'
    if (dart.library.html) 'download_manager_service_web.dart';
