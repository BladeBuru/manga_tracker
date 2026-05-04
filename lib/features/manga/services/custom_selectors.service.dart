import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modèle pour un sélecteur personnalisé
class CustomSelector {
  final String id;
  final String domain; // Domaine du site (ex: "exemple.com")
  final String selector; // Sélecteur CSS
  final SelectorType type; // Type de sélecteur
  final String? description; // Description optionnelle

  CustomSelector({
    required this.id,
    required this.domain,
    required this.selector,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'domain': domain,
        'selector': selector,
        'type': type.name,
        'description': description,
      };

  factory CustomSelector.fromJson(Map<String, dynamic> json) => CustomSelector(
        id: json['id'] as String,
        domain: json['domain'] as String,
        selector: json['selector'] as String,
        type: SelectorType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => SelectorType.adBlocker,
        ),
        description: json['description'] as String?,
      );
}

enum SelectorType {
  adBlocker, // Pour bloquer des publicités spécifiques
  chapterContent, // Pour identifier le contenu du chapitre
  urlPattern, // Pour ajouter des patterns d'URL personnalisés (ex: /chapter-22)
}

/// Service pour gérer les sélecteurs personnalisés
class CustomSelectorsService {
  static const String _selectorsKey = 'custom_selectors';
  static const String _exportedSelectorsKey = 'exported_selectors'; // Pour stocker les sélecteurs partagés

  /// Charge tous les sélecteurs personnalisés
  Future<List<CustomSelector>> loadSelectors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_selectorsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => CustomSelector.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde tous les sélecteurs personnalisés
  Future<void> saveSelectors(List<CustomSelector> selectors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = selectors.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_selectorsKey, jsonString);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  /// Ajoute un sélecteur personnalisé
  Future<void> addSelector(CustomSelector selector) async {
    final selectors = await loadSelectors();
    // Vérifier si un sélecteur avec le même ID existe déjà
    selectors.removeWhere((s) => s.id == selector.id);
    selectors.add(selector);
    await saveSelectors(selectors);
  }

  /// Supprime un sélecteur personnalisé
  Future<void> removeSelector(String id) async {
    final selectors = await loadSelectors();
    selectors.removeWhere((s) => s.id == id);
    await saveSelectors(selectors);
  }

  /// Récupère les patterns d'URL pour un domaine spécifique
  Future<List<CustomSelector>> getUrlPatternsForDomain(String domain) async {
    final selectors = await loadSelectors();
    return selectors.where((s) => s.domain == domain && s.type == SelectorType.urlPattern).toList();
  }

  /// Récupère tous les patterns d'URL personnalisés
  Future<List<CustomSelector>> getAllUrlPatterns() async {
    final selectors = await loadSelectors();
    return selectors.where((s) => s.type == SelectorType.urlPattern).toList();
  }

  /// Exporte les sélecteurs au format JSON pour partage
  Future<String> exportSelectors() async {
    final selectors = await loadSelectors();
    final jsonList = selectors.map((s) => s.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Importe des sélecteurs depuis un JSON
  Future<int> importSelectors(String jsonString) async {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final importedSelectors = jsonList.map((json) => CustomSelector.fromJson(json)).toList();
      
      final existingSelectors = await loadSelectors();
      final existingIds = existingSelectors.map((s) => s.id).toSet();
      
      int addedCount = 0;
      for (final selector in importedSelectors) {
        if (!existingIds.contains(selector.id)) {
          existingSelectors.add(selector);
          addedCount++;
        }
      }
      
      await saveSelectors(existingSelectors);
      return addedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Stocke les sélecteurs exportés pour récupération ultérieure
  Future<void> storeExportedSelectors(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_exportedSelectorsKey, jsonString);
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  /// Récupère les sélecteurs exportés stockés
  Future<String?> getStoredExportedSelectors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_exportedSelectorsKey);
    } catch (e) {
      return null;
    }
  }
}

