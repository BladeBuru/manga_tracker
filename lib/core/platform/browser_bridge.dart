/// Accès minimal au navigateur (historique, rechargement de la page).
///
/// Implémentation réelle sur le web uniquement ; ailleurs, un stub sans
/// effet — aucun `dart:html` / `package:web` hors de ce fichier conditionnel.
///
/// - `historySerialCount()` : rang de l'entrée d'historique courante, tel que
///   le moteur Flutter web le range dans `history.state.serialCount`
///   (`null` hors web ou si inconnu).
/// - `historyGo(delta)` : `history.go(delta)` — retour arrière réel.
/// - `reloadPage()` : recharge l'application (nouvelle version déployée).
library;

export 'browser_bridge_stub.dart'
    if (dart.library.js_interop) 'browser_bridge_web.dart';
