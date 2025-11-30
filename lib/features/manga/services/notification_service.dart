import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mangatracker/features/manga/services/new_chapter_service.dart';

/// Service pour gérer les notifications locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NewChapterService _newChapterService = NewChapterService();
  bool _isInitialized = false;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Demander les permissions sur Android 13+
      if (await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>() != null) {
        await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
            .requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('✅ NotificationService: Service initialisé');
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur lors de l\'initialisation: $e');
    }
  }

  /// Gère le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 NotificationService: Notification tapée: ${response.payload}');
    // TODO: Naviguer vers le manga correspondant
    // Utiliser navigatorKey pour naviguer vers la page de détail du manga
  }

  /// Affiche une notification pour un nouveau chapitre
  Future<void> showNewChapterNotification({
    required int muId,
    required String mangaTitle,
    required int chapterNumber,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Récupérer le nombre total de nouveaux chapitres pour ce manga
      final newChaptersCount = await _newChapterService.getNewChaptersCount(muId);
      
      final title = 'Nouveau chapitre disponible !';
      final body = newChaptersCount > 1
          ? '$mangaTitle - $newChaptersCount nouveaux chapitres'
          : '$mangaTitle - Chapitre $chapterNumber';

      const androidDetails = AndroidNotificationDetails(
        'new_chapters',
        'Nouveaux chapitres',
        channelDescription: 'Notifications pour les nouveaux chapitres de manga',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        muId, // Utiliser muId comme ID unique pour grouper les notifications par manga
        title,
        body,
        details,
        payload: muId.toString(), // Passer le muId comme payload pour navigation
      );

      debugPrint('✅ NotificationService: Notification affichée pour $mangaTitle - Chapitre $chapterNumber');
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur lors de l\'affichage de la notification: $e');
    }
  }

  /// Affiche une notification groupée pour plusieurs nouveaux chapitres
  Future<void> showMultipleNewChaptersNotification({
    required Map<int, Map<String, dynamic>> newChapters, // muId -> {title, chapters}
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (newChapters.isEmpty) return;

    try {
      final mangaCount = newChapters.length;
      final totalChapters = newChapters.values.fold<int>(
        0,
        (sum, data) => sum + (data['chapters'] as List<int>).length,
      );

      final title = mangaCount > 1
          ? '$mangaCount mangas ont de nouveaux chapitres'
          : 'Nouveau chapitre disponible';
      
      final body = totalChapters > 1
          ? '$totalChapters nouveaux chapitres disponibles'
          : '1 nouveau chapitre disponible';

      const androidDetails = AndroidNotificationDetails(
        'new_chapters',
        'Nouveaux chapitres',
        channelDescription: 'Notifications pour les nouveaux chapitres de manga',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Utiliser un ID fixe pour les notifications groupées
      await _notifications.show(
        999999, // ID spécial pour les notifications groupées
        title,
        body,
        details,
      );

      debugPrint('✅ NotificationService: Notification groupée affichée pour $mangaCount mangas');
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur lors de l\'affichage de la notification groupée: $e');
    }
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Annule les notifications pour un manga spécifique
  Future<void> cancelMangaNotifications(int muId) async {
    await _notifications.cancel(muId);
  }
}

