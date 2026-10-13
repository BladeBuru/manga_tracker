import 'dart:js_interop';

/// `window.history` — appelé comme méthode de l'objet (pas de fonction
/// détachée, qui lèverait « Illegal invocation »).
@JS('history')
external _History get _history;

@JS('location')
external _Location get _location;

extension type _History(JSObject _) implements JSObject {
  external JSAny? get state;
  external void go(int delta);
}

extension type _Location(JSObject _) implements JSObject {
  external void reload();
}

/// `history.state` vaut `{serialCount: n, state: …}` (moteur Flutter web,
/// `MultiEntriesBrowserHistory`).
int? historySerialCount() {
  try {
    final raw = _history.state.dartify();
    if (raw is! Map) return null;
    final serial = raw['serialCount'];
    return serial is num ? serial.toInt() : null;
  } catch (_) {
    return null;
  }
}

void historyGo(int delta) => _history.go(delta);

void reloadPage() => _location.reload();
