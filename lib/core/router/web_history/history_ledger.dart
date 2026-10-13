/// Mémoire des entrées d'historique du navigateur vues pendant cette session
/// de page — logique **pure**, testée dans
/// `test/core/router/history_ledger_test.dart`.
///
/// Chaque entrée est repérée par son rang (`history.state.serialCount`, posé
/// par le moteur Flutter web) et décrite par l'empreinte de l'état go_router
/// qu'elle porte. Permet de savoir si « revenir à tel écran » correspond à
/// l'entrée précédente du navigateur, auquel cas l'application fait un vrai
/// retour arrière au lieu d'empiler un doublon.
library;

import 'dart:collection';
import 'dart:convert';

class HistoryLedger {
  final Map<int, String> _bySerial = <int, String>{};

  String? at(int serial) => _bySerial[serial];

  void record(int serial, String fingerprint) => _bySerial[serial] = fingerprint;

  /// Une nouvelle entrée en `serial` efface tout ce qui était « en avant ».
  void truncateAfter(int serial) =>
      _bySerial.removeWhere((key, _) => key > serial);

  /// Nombre de pas en arrière (1..[maxSteps]) jusqu'à une entrée identique à
  /// [fingerprint], ou `null` si l'entrée n'est pas connue (rechargement,
  /// arrivée depuis un autre site…) — on n'invente jamais un retour.
  int? stepsBackTo(int serial, String fingerprint, {required int maxSteps}) {
    for (var steps = 1; steps <= maxSteps; steps++) {
      final known = _bySerial[serial - steps];
      if (known == null) return null;
      if (known == fingerprint) return steps;
    }
    return null;
  }
}

/// Empreinte stable d'un état d'historique go_router (clés triées : l'état
/// relu au retour du navigateur n'a pas forcément le même ordre de clés).
String historyFingerprint(Object? state) => jsonEncode(_canonical(state));

Object? _canonical(Object? value) {
  if (value is Map) {
    final sorted = SplayTreeMap<String, Object?>();
    value.forEach((key, v) => sorted['$key'] = _canonical(v));
    return sorted;
  }
  if (value is List) return value.map(_canonical).toList();
  if (value is num && value == value.roundToDouble()) return value.toInt();
  return value;
}

const String _locationKey = 'location';
const String _extraKey = 'state';
const String _imperativeKey = 'imperativeMatches';

/// Combien de pages [next] retire de [current] : > 0 seulement si [next] est
/// exactement [current] privé de ses dernières pages (retour), 0 sinon.
///
/// Deux formes de retour :
/// - pages empilées (`push`) : mêmes racine et extra, et la pile de [next]
///   est un préfixe strict de celle de [current] ;
/// - sous-page déclarative (`/home/section/x` → `/home`) : la racine de
///   [next] est le parent de celle de [current].
int popDepth(Object? next, Object? current) {
  if (next is! Map || current is! Map) return 0;
  final nextStack = _stack(next);
  final currentStack = _stack(current);
  final sameRoot = next[_locationKey] == current[_locationKey] &&
      historyFingerprint(next[_extraKey]) ==
          historyFingerprint(current[_extraKey]);
  if (sameRoot) {
    if (nextStack.length >= currentStack.length) return 0;
    for (var i = 0; i < nextStack.length; i++) {
      if (nextStack[i] != currentStack[i]) return 0;
    }
    return currentStack.length - nextStack.length;
  }
  if (nextStack.isNotEmpty || currentStack.isNotEmpty) return 0;
  final nextPath = Uri.tryParse('${next[_locationKey]}')?.path;
  final currentPath = Uri.tryParse('${current[_locationKey]}')?.path;
  if (nextPath == null || currentPath == null) return 0;
  final parent = nextPath.endsWith('/') ? nextPath : '$nextPath/';
  return currentPath.startsWith(parent) ? 1 : 0;
}

List<String> _stack(Map<Object?, Object?> state) {
  final raw = state[_imperativeKey];
  if (raw is! List) return const <String>[];
  return raw.map(historyFingerprint).toList();
}
