import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_chapter.model.dart';

/// Service pour gérer les chapitres téléchargés
class DownloadManagerService {
  static const String _prefsKeyDownloads = 'downloaded_chapters';

  /// Récupère le dossier de base pour les téléchargements
  Future<String> getDownloadsBasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'chapters');
  }

  /// Récupère le chemin du dossier pour un manga spécifique (utilise le nom du manga)
  Future<String> getMangaDownloadPath(String mangaTitle) async {
    final basePath = await getDownloadsBasePath();
    // Nettoyer le nom du manga pour qu'il soit valide comme nom de dossier
    final cleanTitle = mangaTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return path.join(basePath, cleanTitle);
  }

  /// Récupère le chemin du dossier pour un chapitre spécifique (utilise le nom du manga)
  Future<String> getChapterDownloadPath(String mangaTitle, int chapterNumber) async {
    final mangaPath = await getMangaDownloadPath(mangaTitle);
    return path.join(mangaPath, chapterNumber.toString());
  }

  /// Récupère tous les chapitres téléchargés
  Future<Map<int, List<DownloadedChapter>>> getAllDownloadedChapters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_prefsKeyDownloads);
      if (mapJson == null) return {};

      final map = jsonDecode(mapJson) as Map<String, dynamic>;
      final result = <int, List<DownloadedChapter>>{};

      for (final entry in map.entries) {
        final muId = int.tryParse(entry.key);
        if (muId == null) continue;

        final chaptersJson = entry.value;
        final List<dynamic> chaptersList = chaptersJson is List
            ? chaptersJson
            : jsonDecode(chaptersJson.toString()) as List<dynamic>;

        final chapters = chaptersList
            .map((e) => DownloadedChapter.fromJson(e as Map<String, dynamic>))
            .toList();

        if (chapters.isNotEmpty) {
          result[muId] = chapters;
        }
      }

      return result;
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur getAllDownloadedChapters: $e');
      return {};
    }
  }

  /// Récupère les chapitres téléchargés pour un manga spécifique
  Future<List<DownloadedChapter>> getDownloadedChapters(int muId) async {
    try {
      final allChapters = await getAllDownloadedChapters();
      return allChapters[muId] ?? [];
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur getDownloadedChapters: $e');
      return [];
    }
  }

  /// Ajoute un chapitre téléchargé
  Future<void> addDownloadedChapter(DownloadedChapter chapter) async {
    try {
      final allChapters = await getAllDownloadedChapters();
      final mangaChapters = allChapters[chapter.muId] ?? [];
      
      // Vérifier si le chapitre existe déjà
      final existingIndex = mangaChapters.indexWhere(
        (c) => c.chapterNumber == chapter.chapterNumber,
      );

      if (existingIndex >= 0) {
        mangaChapters[existingIndex] = chapter;
      } else {
        mangaChapters.add(chapter);
      }

      allChapters[chapter.muId] = mangaChapters;

      await _saveAllChapters(allChapters);
      debugPrint('✅ DownloadManagerService: Chapitre ajouté: ${chapter.muId}/${chapter.chapterNumber}');
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur addDownloadedChapter: $e');
    }
  }

  /// Supprime un chapitre téléchargé
  Future<void> removeDownloadedChapter(int muId, int chapterNumber) async {
    try {
      final allChapters = await getAllDownloadedChapters();
      final mangaChapters = allChapters[muId] ?? [];
      
      // Trouver le chapitre à supprimer pour récupérer son chemin
      final chapterToDelete = mangaChapters.firstWhere(
        (c) => c.chapterNumber == chapterNumber,
        orElse: () => throw Exception('Chapitre non trouvé'),
      );

      mangaChapters.removeWhere((c) => c.chapterNumber == chapterNumber);

      if (mangaChapters.isEmpty) {
        allChapters.remove(muId);
      } else {
        allChapters[muId] = mangaChapters;
      }

      await _saveAllChapters(allChapters);

      // Supprimer les fichiers du disque en utilisant le chemin du chapitre
      final chapterPath = chapterToDelete.folderPath;
      if (chapterPath.isNotEmpty) {
        final dir = Directory(chapterPath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          debugPrint('✅ DownloadManagerService: Dossier supprimé: $chapterPath');
        }
      }

      // Essayer aussi avec muId.toString() pour les anciens téléchargements
      try {
        final oldChapterPath = await getChapterDownloadPath(muId.toString(), chapterNumber);
        final oldDir = Directory(oldChapterPath);
        if (await oldDir.exists()) {
          await oldDir.delete(recursive: true);
          debugPrint('✅ DownloadManagerService: Ancien dossier supprimé: $oldChapterPath');
        }
      } catch (e) {
        // Ignorer les erreurs pour les anciens chemins
      }

      debugPrint('✅ DownloadManagerService: Chapitre supprimé: $muId/$chapterNumber');
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur removeDownloadedChapter: $e');
    }
  }

  /// Supprime tous les chapitres téléchargés pour un manga
  Future<void> removeAllDownloadedChapters(int muId) async {
    try {
      final allChapters = await getAllDownloadedChapters();

      // Supprimer les fichiers du disque
      // Note: On utilise muId.toString() car on n'a pas le mangaTitle ici
      final mangaPath = await getMangaDownloadPath(muId.toString());
      final dir = Directory(mangaPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      allChapters.remove(muId);
      await _saveAllChapters(allChapters);

      debugPrint('✅ DownloadManagerService: Tous les chapitres supprimés pour: $muId');
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur removeAllDownloadedChapters: $e');
    }
  }

  /// Vérifie si un chapitre est téléchargé
  Future<bool> isChapterDownloaded(int muId, int chapterNumber) async {
    try {
      final chapters = await getDownloadedChapters(muId);
      return chapters.any((c) => c.chapterNumber == chapterNumber);
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur isChapterDownloaded: $e');
      return false;
    }
  }

  /// Récupère un chapitre téléchargé spécifique
  Future<DownloadedChapter?> getDownloadedChapter(int muId, int chapterNumber) async {
    try {
      final chapters = await getDownloadedChapters(muId);
      try {
        return chapters.firstWhere((c) => c.chapterNumber == chapterNumber);
      } catch (e) {
        return null;
      }
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur getDownloadedChapter: $e');
      return null;
    }
  }

  /// Calcule l'espace disque utilisé par les téléchargements (en bytes)
  Future<int> getTotalDownloadSize() async {
    try {
      final basePath = await getDownloadsBasePath();
      final dir = Directory(basePath);
      
      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur getTotalDownloadSize: $e');
      return 0;
    }
  }

  /// Sauvegarde tous les chapitres téléchargés
  Future<void> _saveAllChapters(Map<int, List<DownloadedChapter>> allChapters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};

      for (final entry in allChapters.entries) {
        map[entry.key.toString()] = entry.value.map((c) => c.toJson()).toList();
      }

      await prefs.setString(_prefsKeyDownloads, jsonEncode(map));
    } catch (e) {
      debugPrint('❌ DownloadManagerService: Erreur _saveAllChapters: $e');
    }
  }
}

