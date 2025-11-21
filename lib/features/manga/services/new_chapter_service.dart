import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service pour gérer les nouveaux chapitres détectés
class NewChapterService {
  static const String _prefsKeyLastChecked = 'new_chapters_last_checked';
  static const String _prefsKeyNewChapters = 'new_chapters_map';
  static const String _prefsKeyLastCheckedChapter = 'last_checked_chapter_map';

  /// Récupère le dernier chapitre vérifié pour un manga
  Future<int?> getLastCheckedChapter(int muId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyLastCheckedChapter);
      if (mapJson == null) return null;
      
      final map = jsonDecode(mapJson) as Map<String, dynamic>;
      final value = map[muId.toString()];
      return value != null ? int.tryParse(value.toString()) : null;
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur getLastCheckedChapter: $e');
      return null;
    }
  }

  /// Enregistre le dernier chapitre vérifié pour un manga
  Future<void> setLastCheckedChapter(int muId, int chapterNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyLastCheckedChapter);
      Map<String, dynamic> map = {};
      
      if (mapJson != null) {
        map = jsonDecode(mapJson) as Map<String, dynamic>;
      }
      
      map[muId.toString()] = chapterNumber;
      await prefs.setString(_prefsKeyLastCheckedChapter, jsonEncode(map));
      
      debugPrint('✅ NewChapterService: Dernier chapitre vérifié pour $muId: $chapterNumber');
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur setLastCheckedChapter: $e');
    }
  }

  /// Récupère la liste des nouveaux chapitres pour un manga
  Future<List<int>> getNewChapters(int muId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyNewChapters);
      if (mapJson == null) return [];
      
      final map = jsonDecode(mapJson) as Map<String, dynamic>;
      final chaptersJson = map[muId.toString()];
      if (chaptersJson == null) return [];
      
      final List<dynamic> chaptersList = chaptersJson is List 
          ? chaptersJson 
          : jsonDecode(chaptersJson.toString()) as List<dynamic>;
      
      return chaptersList.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList()..sort();
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur getNewChapters: $e');
      return [];
    }
  }

  /// Ajoute un nouveau chapitre à la liste
  Future<void> addNewChapter(int muId, int chapterNumber) async {
    try {
      final currentChapters = await getNewChapters(muId);
      if (currentChapters.contains(chapterNumber)) {
        debugPrint('ℹ️ NewChapterService: Chapitre $chapterNumber déjà dans la liste pour $muId');
        return;
      }

      currentChapters.add(chapterNumber);
      currentChapters.sort();

      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyNewChapters);
      Map<String, dynamic> map = {};
      
      if (mapJson != null) {
        map = jsonDecode(mapJson) as Map<String, dynamic>;
      }
      
      map[muId.toString()] = currentChapters;
      await prefs.setString(_prefsKeyNewChapters, jsonEncode(map));
      
      debugPrint('✅ NewChapterService: Nouveau chapitre ajouté pour $muId: $chapterNumber');
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur addNewChapter: $e');
    }
  }

  /// Marque un chapitre comme lu (le retire de la liste des nouveaux)
  Future<void> markChapterAsRead(int muId, int chapterNumber) async {
    try {
      final currentChapters = await getNewChapters(muId);
      if (!currentChapters.contains(chapterNumber)) {
        return; // Déjà marqué comme lu ou pas dans la liste
      }

      currentChapters.remove(chapterNumber);

      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyNewChapters);
      Map<String, dynamic> map = {};
      
      if (mapJson != null) {
        map = jsonDecode(mapJson) as Map<String, dynamic>;
      }
      
      map[muId.toString()] = currentChapters;
      await prefs.setString(_prefsKeyNewChapters, jsonEncode(map));
      
      debugPrint('✅ NewChapterService: Chapitre $chapterNumber marqué comme lu pour $muId');
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur markChapterAsRead: $e');
    }
  }

  /// Vérifie si un manga a de nouveaux chapitres
  Future<bool> hasNewChapters(int muId) async {
    final chapters = await getNewChapters(muId);
    return chapters.isNotEmpty;
  }

  /// Récupère le nombre de nouveaux chapitres pour un manga
  Future<int> getNewChaptersCount(int muId) async {
    final chapters = await getNewChapters(muId);
    return chapters.length;
  }

  /// Supprime tous les nouveaux chapitres pour un manga
  Future<void> clearNewChapters(int muId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyNewChapters);
      if (mapJson == null) return;
      
      final map = jsonDecode(mapJson) as Map<String, dynamic>;
      map.remove(muId.toString());
      
      await prefs.setString(_prefsKeyNewChapters, jsonEncode(map));
      debugPrint('✅ NewChapterService: Nouveaux chapitres supprimés pour $muId');
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur clearNewChapters: $e');
    }
  }

  /// Récupère la date de dernière vérification
  Future<DateTime?> getLastCheckDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_prefsKeyLastChecked);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur getLastCheckDate: $e');
      return null;
    }
  }

  /// Enregistre la date de dernière vérification
  Future<void> setLastCheckDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyLastChecked, date.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur setLastCheckDate: $e');
    }
  }

  /// Récupère tous les mangas avec de nouveaux chapitres
  Future<Map<int, List<int>>> getAllNewChapters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyNewChapters);
      if (mapJson == null) return {};
      
      final map = jsonDecode(mapJson) as Map<String, dynamic>;
      final result = <int, List<int>>{};
      
      for (final entry in map.entries) {
        final muId = int.tryParse(entry.key);
        if (muId == null) continue;
        
        final chaptersJson = entry.value;
        final List<dynamic> chaptersList = chaptersJson is List 
            ? chaptersJson 
            : jsonDecode(chaptersJson.toString()) as List<dynamic>;
        
        final chapters = chaptersList
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((e) => e > 0)
            .toList()
          ..sort();
        
        if (chapters.isNotEmpty) {
          result[muId] = chapters;
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('❌ NewChapterService: Erreur getAllNewChapters: $e');
      return {};
    }
  }
}

