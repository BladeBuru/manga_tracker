import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mémoire locale de la position de lecture — **le seul endroit** qui touche
/// à `SharedPreferences` pour ces clés.
///
/// Deux écritures complémentaires, et c'est volontaire :
///  - **des pixels**, par manga et chapitre : mesurés sur cet appareil, donc
///    les plus fidèles pour y revenir ;
///  - **un marque-page** au format du serveur (chapitre + pourcentage +
///    horodatage), un par manga : la seule forme transposable d'un écran à
///    l'autre, et la seule qui permette d'arbitrer avec le serveur.
///
/// ⚠️ Ces clés sont **personnelles**. Elles sont purgées à la déconnexion et
/// au changement de compte par `purgeUserScopedCache()` — sur un appareil
/// partagé, sans ça, le compte suivant rouvrirait un manga au milieu d'un
/// chapitre qu'il n'a jamais ouvert. Toute nouvelle clé de position doit
/// porter l'un des deux préfixes déclarés dans `reading_constants.dart`.
class ReadingPositionStore {
  const ReadingPositionStore();

  /// Écrit la position du chapitre courant, sous ses deux formes, et oublie
  /// les autres chapitres de ce manga.
  Future<void> write({
    required int muId,
    required int chapter,
    required double scrollY,
    required double positionPercent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(scrollKey(muId, chapter), scrollY);
    await prefs.setString(
      bookmarkKey(muId),
      jsonEncode(ReadingPositionDto(
        chapter: chapter,
        positionPercent: positionPercent,
        updatedAt: DateTime.now().toUtc(),
      ).toJson()),
    );
    await cleanOtherChapters(muId, chapter);
  }

  /// Défilement en pixels mémorisé pour ce chapitre, `null` si aucun.
  Future<double?> readScrollY(int muId, int chapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(scrollKey(muId, chapter));
    } catch (e) {
      debugPrint('ReadingPositionStore: lecture impossible ($e)');
      return null;
    }
  }

  /// Marque-page du manga, `null` si absent ou illisible (version antérieure,
  /// écriture interrompue).
  Future<ReadingPositionDto?> readBookmark(int muId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(bookmarkKey(muId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ReadingPositionDto.fromJson(decoded);
    } catch (e) {
      debugPrint('ReadingPositionStore: marque-page illisible ($e)');
      return null;
    }
  }

  /// Efface la position d'un chapitre. Rend `true` si le marque-page du manga
  /// désignait bien ce chapitre et a donc été effacé lui aussi — l'appelant
  /// sait alors qu'il doit aussi couper la synchronisation serveur.
  ///
  /// Libérer un chapitre **quitté** ne doit pas effacer la lecture en cours du
  /// suivant : d'où la vérification, plutôt qu'une suppression aveugle.
  Future<bool> deleteChapter(int muId, int chapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(scrollKey(muId, chapter));

      final bookmark = await readBookmark(muId);
      if (bookmark == null || bookmark.chapter != chapter) return false;
      await prefs.remove(bookmarkKey(muId));
      return true;
    } catch (e) {
      debugPrint('ReadingPositionStore: suppression impossible ($e)');
      return false;
    }
  }

  /// Ne garde que la position du chapitre en cours, pour ce manga seulement.
  Future<void> cleanOtherChapters(int muId, int currentChapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keep = scrollKey(muId, currentChapter);
      final stale = prefs
          .getKeys()
          .where((key) =>
              key.startsWith('$kScrollPositionKeyPrefix${muId}_') &&
              key != keep)
          .toList();
      for (final key in stale) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('ReadingPositionStore: nettoyage impossible ($e)');
    }
  }

  String scrollKey(int muId, int chapter) =>
      '$kScrollPositionKeyPrefix${muId}_$chapter';

  String bookmarkKey(int muId) => '$kReadingBookmarkKeyPrefix$muId';
}
