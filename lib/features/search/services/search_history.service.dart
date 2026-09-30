import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'historique de recherche
class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryLength = 10;

  /// Charge l'historique de recherche
  Future<List<String>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_historyKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde l'historique de recherche
  Future<void> saveHistory(List<String> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Limiter à maxHistoryLength
      final limitedHistory =
          history.length > _maxHistoryLength
              ? history.sublist(0, _maxHistoryLength)
              : history;
      await prefs.setStringList(_historyKey, limitedHistory);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  /// Ajoute une recherche **validée** à l'historique.
  ///
  /// À n'appeler que lorsque l'utilisateur a réellement mené sa recherche
  /// (validation au clavier, ouverture d'un résultat, reprise d'un terme de
  /// l'historique) — jamais sur la recherche automatique déclenchée par une
  /// pause de frappe, qui enregistrait « My » puis « My Hero ».
  Future<List<String>> addSearch(String query) async {
    final history = await loadHistory();
    final merged = merge(history, query);
    if (identical(merged, history)) return history;
    await saveHistory(merged);
    return merged;
  }

  /// Règle pure d'insertion (testable sans préférences) :
  ///  - le terme passe en tête, sans doublon (casse ignorée) ;
  ///  - les entrées qui n'en sont qu'un **début** (« My », « My He » pour
  ///    « My Hero ») disparaissent — elles ne sont que des étapes de
  ///    frappe, et nettoient au passage l'historique pollué par l'ancien
  ///    comportement ;
  ///  - [_maxHistoryLength] entrées au plus.
  static List<String> merge(List<String> history, String query) {
    final term = query.trim();
    if (term.isEmpty) return history;
    final lower = term.toLowerCase();
    final kept = history.where((entry) {
      final e = entry.trim().toLowerCase();
      if (e == lower) return false;
      return !(e.isNotEmpty && lower.startsWith(e));
    });
    final merged = [term, ...kept];
    return merged.length > _maxHistoryLength
        ? merged.sublist(0, _maxHistoryLength)
        : merged;
  }

  /// Supprime une recherche de l'historique
  Future<List<String>> removeSearch(String query) async {
    final history = await loadHistory();
    history.remove(query);
    await saveHistory(history);
    return history;
  }

  /// Efface tout l'historique
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Ignorer les erreurs
    }
  }
}
