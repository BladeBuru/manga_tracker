import 'dart:convert';

/// Normalisation des retours de `evaluateJavascript` — **pur**, sans Flutter.
///
/// `InAppWebViewController.evaluateJavascript` ne renvoie pas le même type
/// selon la plateforme : côté **Android** le plugin décode lui-même le JSON et
/// rend une `Map`, côté **iOS / Web** on récupère souvent une **chaîne** JSON.
/// Un code qui suppose l'un des deux marche par accident sur une plateforme et
/// reste **inerte** sur l'autre — c'était exactement le cas des garde-fous de
/// restauration de `ScrollPositionService`, qui découpaient le résultat comme
/// du texte (`split('"scrollY":')`) et n'ont donc jamais rien gardé sur
/// Android : la restauration écrasait le défilement de l'utilisateur.
///
/// `ReadingProgressHelper` traitait déjà les deux cas ; cette classe extrait
/// ce traitement pour qu'il n'y ait plus qu'**une** façon de lire un retour de
/// WebView, testable sans WebView.
class WebViewResultParser {
  const WebViewResultParser._();

  /// Rend l'objet JavaScript sous forme de `Map`, quelle que soit la
  /// plateforme. `null` si le retour est absent, illisible ou d'un autre type.
  static Map<String, dynamic>? asMap(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Retour non JSON (message d'erreur du moteur, `undefined`…).
      }
    }
    return null;
  }

  /// Lit un nombre dans un objet JavaScript déjà normalisé.
  ///
  /// Tolère les nombres rendus comme chaînes (`"1200"`), ce que font certains
  /// ponts natifs, et refuse tout ce qui n'est pas fini (`NaN`, `Infinity`)
  /// pour ne jamais propager une mesure absurde dans un calcul de pourcentage.
  static double? numberAt(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    return asNumber(map[key]);
  }

  /// Lit un nombre isolé (retour scalaire d'un script JavaScript).
  static double? asNumber(Object? raw) {
    double? value;
    if (raw is num) {
      value = raw.toDouble();
    } else if (raw is String) {
      value = double.tryParse(raw.trim());
    }
    if (value == null || !value.isFinite) return null;
    return value;
  }

  /// Lit un booléen, en tolérant la chaîne `"true"` renvoyée par certains
  /// ponts natifs.
  static bool asBool(Object? raw) => raw == true || raw == 'true';
}
