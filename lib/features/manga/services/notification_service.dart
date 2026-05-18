import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mangatracker/features/manga/services/new_chapter_service.dart';
import 'package:mangatracker/features/manga/services/notification_preferences_service.dart';

/// Service pour gérer les notifications locales (Android + iOS).
///
/// Canaux Android :
///  - `new_chapters` : nouveaux chapitres d'un manga suivi.
///  - `friend_requests` : demandes d'ami entrantes.
///  - `shares_received` : recommandations / partages reçus.
///
/// Chaque famille est feature-gated par `NotificationPreferencesService`.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Channel IDs / labels (Android)
  static const _chanNewChapters = 'new_chapters';
  static const _chanNewChaptersLabel = 'Nouveaux chapitres';
  static const _chanNewChaptersDesc =
      'Notifications pour les nouveaux chapitres de manga';

  static const _chanFriendReq = 'friend_requests';
  static const _chanFriendReqLabel = 'Demandes d\'ami';
  static const _chanFriendReqDesc =
      'Notifications quand quelqu\'un vous envoie une demande d\'ami';

  static const _chanShares = 'shares_received';
  static const _chanSharesLabel = 'Recommandations reçues';
  static const _chanSharesDesc =
      'Notifications quand un ami vous partage un manga';

  // Plages d'IDs (évite les collisions entre canaux).
  static const int _idBaseFriendRequests = 1000000;
  static const int _idBaseSharesReceived = 2000000;
  static const int _idRange = 100000;

  // Payloads pour le tap-handler.
  static const String _payloadFriendRequest = 'friend_request';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NewChapterService _newChapterService = NewChapterService();
  final NotificationPreferencesService _preferences =
      NotificationPreferencesService();
  bool _isInitialized = false;

  /// Initialise le service de notifications (Android + iOS).
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      const init = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );
      await _notifications.initialize(
        init,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      _isInitialized = true;
      debugPrint('✅ NotificationService: Service initialisé');
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur init: $e');
    }
  }

  /// Gère le tap sur une notification (routing à câbler via navigatorKey).
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('🔔 NotificationService: Notification tapée: $payload');
    // TODO: routing selon le payload :
    //  - payload == 'friend_request' → naviguer vers /friends
    //  - payload est un id manga (muId) → naviguer vers le détail manga
    // Utiliser navigatorKey global pour pousser la route.
  }

  /// Helper : construit un `NotificationDetails` cross-platform.
  NotificationDetails _details(
    String channelId,
    String channelName,
    String channelDesc, {
    bool bigText = false,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: bigText ? const BigTextStyleInformation('') : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── Nouveaux chapitres ───

  /// Affiche une notification pour un nouveau chapitre.
  Future<void> showNewChapterNotification({
    required int muId,
    required String mangaTitle,
    required int chapterNumber,
  }) async {
    if (!await _preferences.areNewChapterNotificationsEnabled()) return;
    if (!_isInitialized) await initialize();
    try {
      final count = await _newChapterService.getNewChaptersCount(muId);
      final body = count > 1
          ? '$mangaTitle - $count nouveaux chapitres'
          : '$mangaTitle - Chapitre $chapterNumber';
      await _notifications.show(
        muId,
        'Nouveau chapitre disponible !',
        body,
        _details(_chanNewChapters, _chanNewChaptersLabel, _chanNewChaptersDesc),
        payload: muId.toString(),
      );
      debugPrint(
        '✅ NotificationService: Notif chapitre $mangaTitle - $chapterNumber',
      );
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur showNewChapter: $e');
    }
  }

  /// Affiche une notification groupée pour plusieurs nouveaux chapitres.
  Future<void> showMultipleNewChaptersNotification({
    required Map<int, Map<String, dynamic>> newChapters,
  }) async {
    if (!await _preferences.areNewChapterNotificationsEnabled()) return;
    if (!_isInitialized) await initialize();
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
      await _notifications.show(
        999999,
        title,
        body,
        _details(
          _chanNewChapters,
          _chanNewChaptersLabel,
          _chanNewChaptersDesc,
          bigText: true,
        ),
      );
      debugPrint(
        '✅ NotificationService: Notif groupée ($mangaCount mangas)',
      );
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur showMultiple: $e');
    }
  }

  // ─── Demandes d'ami ───

  /// Affiche une notification pour une demande d'ami entrante.
  ///
  /// [title] et [body] doivent être déjà traduits par l'appelant.
  Future<void> showFriendRequestNotification({
    required String senderUsername,
    required String title,
    required String body,
  }) async {
    if (!await _preferences.areFriendRequestNotificationsEnabled()) return;
    if (!_isInitialized) await initialize();
    try {
      final id =
          _idBaseFriendRequests + (senderUsername.hashCode.abs() % _idRange);
      await _notifications.show(
        id,
        title,
        body,
        _details(_chanFriendReq, _chanFriendReqLabel, _chanFriendReqDesc),
        payload: _payloadFriendRequest,
      );
      debugPrint(
        '✅ NotificationService: Notif demande d\'ami de $senderUsername',
      );
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur showFriendRequest: $e');
    }
  }

  // ─── Partages / recommandations ───

  /// Affiche une notification pour un manga partagé / recommandé par un ami.
  ///
  /// [title] et [body] doivent être déjà traduits.
  /// [muId] sert de payload pour naviguer vers le détail au tap.
  Future<void> showShareReceivedNotification({
    required String senderUsername,
    required String mangaTitle,
    required String muId,
    required String title,
    required String body,
  }) async {
    if (!await _preferences.areShareReceivedNotificationsEnabled()) return;
    if (!_isInitialized) await initialize();
    try {
      final id = _idBaseSharesReceived +
          ('$senderUsername:$mangaTitle'.hashCode.abs() % _idRange);
      await _notifications.show(
        id,
        title,
        body,
        _details(_chanShares, _chanSharesLabel, _chanSharesDesc),
        payload: muId,
      );
      debugPrint(
        '✅ NotificationService: Notif partage $senderUsername → $mangaTitle',
      );
    } catch (e) {
      debugPrint('❌ NotificationService: Erreur showShareReceived: $e');
    }
  }

  // ─── Cancel ───

  /// Annule toutes les notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Annule les notifications pour un manga spécifique (canal new_chapters).
  Future<void> cancelMangaNotifications(int muId) async {
    await _notifications.cancel(muId);
  }
}
