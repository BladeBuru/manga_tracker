import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/chapter_check_service.dart';
import 'package:mangatracker/features/manga/services/new_chapter_service.dart';
import 'package:mangatracker/features/manga/services/notification_service.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';

/// Service pour gérer les vérifications périodiques de nouveaux chapitres en arrière-plan
class ChapterCheckBackgroundService {
  static const String _taskName = 'chapterCheckTask';
  static const String _taskUniqueName = 'uniqueChapterCheckTask';
  
  final LibraryService _libraryService = getIt<LibraryService>();
  final ChapterCheckService _chapterCheckService = ChapterCheckService();
  final NewChapterService _newChapterService = NewChapterService();
  final NotificationService _notificationService = NotificationService();
  final NotificationPreferencesService _notificationPreferences = NotificationPreferencesService();

  /// Initialise le service de vérification en arrière-plan
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('✅ ChapterCheckBackgroundService: Workmanager initialisé');
    } catch (e) {
      debugPrint('❌ ChapterCheckBackgroundService: Erreur lors de l\'initialisation: $e');
    }
  }

  /// Démarre la vérification périodique (toutes les X heures)
  /// [intervalHours] : Intervalle en heures entre chaque vérification (par défaut 6 heures)
  Future<void> startPeriodicCheck({int intervalHours = 6}) async {
    try {
      // Annuler toute tâche existante
      await cancelPeriodicCheck();

      // Programmer une tâche périodique
      await Workmanager().registerPeriodicTask(
        _taskUniqueName,
        _taskName,
        frequency: Duration(hours: intervalHours),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        initialDelay: const Duration(minutes: 15), // Démarrer après 15 minutes
      );
      
      debugPrint('✅ ChapterCheckBackgroundService: Vérification périodique démarrée (toutes les $intervalHours heures)');
    } catch (e) {
      debugPrint('❌ ChapterCheckBackgroundService: Erreur lors du démarrage de la vérification périodique: $e');
    }
  }

  /// Annule la vérification périodique
  Future<void> cancelPeriodicCheck() async {
    try {
      await Workmanager().cancelByUniqueName(_taskUniqueName);
      debugPrint('✅ ChapterCheckBackgroundService: Vérification périodique annulée');
    } catch (e) {
      debugPrint('❌ ChapterCheckBackgroundService: Erreur lors de l\'annulation: $e');
    }
  }

  /// Exécute une vérification manuelle de tous les mangas
  Future<void> checkAllMangas() async {
    try {
      debugPrint('🔍 ChapterCheckBackgroundService: Début de la vérification manuelle...');
      await _performCheck();
      debugPrint('✅ ChapterCheckBackgroundService: Vérification manuelle terminée');
    } catch (e) {
      debugPrint('❌ ChapterCheckBackgroundService: Erreur lors de la vérification manuelle: $e');
    }
  }

  /// Effectue la vérification des nouveaux chapitres pour tous les mangas avec customLink
  Future<void> _performCheck() async {
    try {
      // Récupérer tous les mangas de la bibliothèque
      final mangas = await _libraryService.getUserSavedMangas();
      
      // Filtrer uniquement les mangas avec des chapitres lus
      final mangasToCheck = mangas.where((manga) {
        return manga.readChapters != null && manga.readChapters! > 0;
      }).toList();

      debugPrint('🔍 ChapterCheckBackgroundService: Vérification de ${mangasToCheck.length} mangas...');

      int newChaptersFound = 0;

      for (final manga in mangasToCheck) {
        try {
          final muId = manga.muId.toInt();
          final readChapters = manga.readChapters?.toInt() ?? 0;
          if (readChapters <= 0) continue;

          // Récupérer le customLink depuis le service
          final customLink = await _libraryService.getCustomLink(muId);
          if (customLink == null || customLink.isEmpty) {
            continue; // Pas de customLink, skip
          }

          // Vérifier le dernier chapitre vérifié
          final lastChecked = await _newChapterService.getLastCheckedChapter(muId);
          
          // Si on a déjà vérifié ce chapitre récemment, skip
          if (lastChecked != null && lastChecked >= readChapters) {
            continue;
          }

          // Vérifier si le chapitre suivant existe
          final nextChapterExists = await _chapterCheckService.checkNextChapter(
            muId,
            customLink,
            readChapters,
          );

          if (nextChapterExists) {
            final nextChapter = readChapters + 1;
            await _newChapterService.addNewChapter(muId, nextChapter);
            newChaptersFound++;
            debugPrint('✅ ChapterCheckBackgroundService: Nouveau chapitre détecté pour ${manga.title}: $nextChapter');
            
            // Envoyer une notification seulement si les notifications sont activées
            final notificationsEnabled = await _notificationPreferences.areNewChapterNotificationsEnabled();
            if (notificationsEnabled) {
              await _notificationService.showNewChapterNotification(
                muId: muId,
                mangaTitle: manga.title,
                chapterNumber: nextChapter,
              );
            }
          }

          // Enregistrer le dernier chapitre vérifié
          await _newChapterService.setLastCheckedChapter(muId, readChapters);
          
        } catch (e) {
          debugPrint('⚠️ ChapterCheckBackgroundService: Erreur pour le manga ${manga.muId}: $e');
        }
      }

      // Enregistrer la date de dernière vérification
      await _newChapterService.setLastCheckDate(DateTime.now());

      if (newChaptersFound > 0) {
        debugPrint('✅ ChapterCheckBackgroundService: $newChaptersFound nouveaux chapitres détectés');
      } else {
        debugPrint('ℹ️ ChapterCheckBackgroundService: Aucun nouveau chapitre détecté');
      }
    } catch (e) {
      debugPrint('❌ ChapterCheckBackgroundService: Erreur lors de la vérification: $e');
    }
  }
}

/// Callback appelé par Workmanager en arrière-plan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 ChapterCheckBackgroundService: Tâche exécutée: $task');
    
    try {
      // Initialiser les services nécessaires
      await getIt.allReady();
      
      // Initialiser le service de notifications
      await NotificationService().initialize();
      
      final service = ChapterCheckBackgroundService();
      await service._performCheck();
      
      debugPrint('✅ ChapterCheckBackgroundService: Tâche terminée avec succès');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ ChapterCheckBackgroundService: Erreur lors de l\'exécution de la tâche: $e');
      return Future.value(false);
    }
  });
}

