import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Web : détecte qu'une version plus récente de l'application a été déployée
/// pendant que la page était ouverte (ou que la page a été servie depuis un
/// vieux cache), pour proposer de recharger.
///
/// Compare la version **compilée** ([compiledVersion], passée au build par
/// `--dart-define=MT_WEB_BUILD=<version+build>`, cf. `deploy/web/Dockerfile`)
/// à `/version.json` (généré par `flutter build web`, servi sans cache par
/// nginx). Sans version compilée (build local), la première version lue sert
/// de référence : seul un déploiement survenu PENDANT la session est vu.
///
/// Logique pure (récupération injectée) : `test/core/services/web_version_watcher_test.dart`.
class WebVersionWatcher {
  WebVersionWatcher({
    Future<String?> Function()? fetchDeployedVersion,
    String runningVersion = compiledVersion,
    DateTime Function()? clock,
    this.minInterval = const Duration(minutes: 1),
  })  : _fetch = fetchDeployedVersion ?? fetchServedVersion,
        _baseline = runningVersion.isEmpty ? null : runningVersion,
        _clock = clock ?? DateTime.now;

  /// Version de ce code, figée au build (`version+build` du pubspec).
  static const String compiledVersion = String.fromEnvironment('MT_WEB_BUILD');

  final Future<String?> Function() _fetch;
  final DateTime Function() _clock;

  /// Écart minimal entre deux vérifications (retours au premier plan
  /// rapprochés).
  final Duration minInterval;

  String? _baseline;
  DateTime? _lastCheck;
  bool _checking = false;

  /// `true` dès qu'une version différente est servie (ne redevient jamais
  /// `false` : seul un rechargement l'efface).
  final ValueNotifier<bool> updateAvailable = ValueNotifier<bool>(false);

  Future<void> check() async {
    if (_checking || updateAvailable.value) return;
    final now = _clock();
    final last = _lastCheck;
    if (last != null && now.difference(last) < minInterval) return;
    _checking = true;
    _lastCheck = now;
    try {
      final served = await _fetch();
      if (served == null || served.isEmpty) return;
      final baseline = _baseline ??= served;
      if (served != baseline) updateAvailable.value = true;
    } finally {
      _checking = false;
    }
  }

  void dispose() => updateAvailable.dispose();

  /// `/version.json` du site, sans cache : `version+build_number`, ou
  /// `null` (hors ligne, réponse inattendue).
  static Future<String?> fetchServedVersion() async {
    try {
      final uri = Uri.base.resolve('/version.json').replace(
        queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
      );
      final res = await http
          .get(uri, headers: const {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      return parseVersionJson(res.body);
    } catch (_) {
      return null;
    }
  }

  /// `{"version":"0.18.1","build_number":"34"}` → `0.18.1+34`.
  @visibleForTesting
  static String? parseVersionJson(String body) {
    final json = jsonDecode(body);
    if (json is! Map) return null;
    final version = json['version'];
    if (version is! String || version.isEmpty) return null;
    final build = json['build_number'];
    return build == null || '$build'.isEmpty ? version : '$version+$build';
  }
}
