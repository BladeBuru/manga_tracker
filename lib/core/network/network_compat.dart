/// Compat layer pour `dart:io` HttpStatus / HttpHeaders / SocketException.
///
/// **Pourquoi** : `dart:io` n'existe pas sur le web Flutter. Ce module expose
/// les mêmes APIs (constants HTTP + SocketException) avec une implémentation
/// native sur mobile (re-exporte `dart:io`) et un stub sur web qui compile.
///
/// **Mobile** : utilise `dart:io` natif → comportement identique à avant.
/// **Web** : utilise des constantes locales + une SocketException stub qui
/// permet la compilation. En pratique, sur web `package:http` lève
/// `ClientException` (pas `SocketException`), donc le `catch (SocketException)`
/// ne match jamais — c'est volontaire, on n'a pas la même sémantique réseau.
///
/// Usage :
/// ```dart
/// // au lieu de :
/// import 'dart:io';
/// // utiliser :
/// import 'package:mangatracker/core/network/network_compat.dart';
/// ```
library;

export 'network_compat_io.dart' if (dart.library.html) 'network_compat_web.dart';
