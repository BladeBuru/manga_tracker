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
      final limitedHistory = history.length > _maxHistoryLength
          ? history.sublist(0, _maxHistoryLength)
          : history;
      await prefs.setStringList(_historyKey, limitedHistory);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  /// Ajoute une recherche à l'historique
  Future<List<String>> addSearch(String query) async {
    if (query.trim().isEmpty) {
      return await loadHistory();
    }

    final trimmedQuery = query.trim();
    final history = await loadHistory();
    
    // Retirer la recherche si elle existe déjà
    history.remove(trimmedQuery);
    // Ajouter au début
    history.insert(0, trimmedQuery);
    // Limiter à maxHistoryLength
    final limitedHistory = history.length > _maxHistoryLength
        ? history.sublist(0, _maxHistoryLength)
        : history;
    
    await saveHistory(limitedHistory);
    return limitedHistory;
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

