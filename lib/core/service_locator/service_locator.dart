import 'package:get_it/get_it.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/email_auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/library/services/chapter_log.service.dart';
import 'package:mangatracker/features/library/services/chapter_report.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/recommendations/services/recommendation_dismissal.service.dart';
import 'package:mangatracker/features/profile/services/change_password.service.dart';
import 'package:mangatracker/features/profile/services/gdpr.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/stats/services/stats.service.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/comments/services/comments.service.dart';
import 'package:mangatracker/features/sharing/services/sharing.service.dart';
import 'package:mangatracker/features/sharing/services/reading_groups.service.dart';
import 'package:mangatracker/core/services/notification_counts_service.dart';
import 'package:mangatracker/core/network/http_service.dart';

import '../../features/auth/services/biometric.service.dart';
import '../services/app_update_service.dart';
import '../storage/services/storage.service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_cache_service.dart';
import '../services/sync_service.dart';
import '../services/cache_helper_service.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';
import '../services/theme_service.dart';
import '../bloc/connectivity_bloc.dart';
import '../../features/library/bloc/library_bloc.dart';
import '../../features/home/bloc/homepage_bloc.dart';
import '../../features/home/bloc/home_section_page_bloc.dart';
import '../../features/home/bloc/home_sections_bloc.dart';
import '../../features/home/services/home_sections.service.dart';
import '../../features/manga/bloc/detail_bloc.dart';
import '../../features/search/bloc/search_bloc.dart';
import '../../features/search/services/search_history.service.dart';
import '../../features/reader/services/scroll_position_service.dart';
import '../../features/reader/services/captcha_detection_service.dart';
import '../../features/reader/services/ad_blocker_service.dart';
import '../../features/reader/services/webview_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Services de base
  getIt.registerSingletonAsync<StorageService>(
      () async => StorageService().init());
  // Service d'historique de recherche (sans dépendances, peut être enregistré tôt)
  getIt.registerSingleton<SearchHistoryService>(SearchHistoryService());
  // LanguageService tôt : HttpService injecte le header Accept-Language à
  // chaque requête. PAS dans les dependsOn de HttpService — GetIt exige que
  // les types de dependsOn soient déjà enregistrés au moment de
  // l'enregistrement du dépendant (sinon ArgumentError async dans allReady()
  // → runApp jamais appelé → écran blanc, bug v0.12.1). Le header est
  // défensif côté HttpService : omis tant que le service n'est pas prêt.
  getIt.registerSingletonAsync<LanguageService>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return LanguageService(prefs);
      });
  getIt.registerSingletonWithDependencies<AuthService>(() => AuthService(),
      dependsOn: [StorageService]);
  getIt.registerSingletonWithDependencies<HttpService>(() => HttpService(),
      dependsOn: [StorageService, AuthService]);
  getIt.registerSingleton<ValidatorService>(ValidatorService());
  getIt.registerSingletonWithDependencies<MangaService>(() => MangaService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<RecommendationService>(
      () => RecommendationService(),
      dependsOn: [HttpService]);
  // Rejets « pas interesse / deja vu » sur les recommandations.
  // registerLazySingleton SANS dependsOn : le service resout HttpService et
  // OfflineCacheService a l'appel, pas a la construction. Il est donc
  // insensible a l'ordre d'enregistrement ci-dessus, qui n'est pas modifie
  // (cf. la regression d'ecran blanc documentee lignes 52-57).
  getIt.registerLazySingleton<RecommendationDismissalService>(
      () => const RecommendationDismissalService());
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerSingletonWithDependencies<UserService>(() => UserService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<StatsService>(() => StatsService(),
      dependsOn: [HttpService, StorageService]);
  getIt.registerSingletonWithDependencies<FriendsService>(
      () => FriendsService(),
      dependsOn: [HttpService, StorageService]);
  getIt.registerSingletonWithDependencies<CommentsService>(
      () => CommentsService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<SharingService>(
      () => SharingService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<ReadingGroupsService>(
      () => ReadingGroupsService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<NotificationCountsService>(
      () => NotificationCountsService(),
      dependsOn: [FriendsService, SharingService]);
  getIt.registerSingletonWithDependencies<GdprService>(() => GdprService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<EmailAuthService>(
      () => EmailAuthService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<ChangePasswordService>(
      () => ChangePasswordService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<AppUpdateService>(
      () => AppUpdateService(),
      dependsOn: [HttpService]);
  
  // Notifier doit être enregistré avant les autres services
  getIt.registerSingleton(Notifier());
  
  // Services pour l'architecture réactive et le mode hors ligne
  getIt.registerSingletonAsync<ConnectivityService>(
      () async {
        final service = ConnectivityService();
        await service.initialize();
        return service;
      });
  getIt.registerSingletonWithDependencies<OfflineCacheService>(
      () {
        final service = OfflineCacheService();
        service.initialize();
        return service;
      },
      dependsOn: [StorageService]);
  
  // LibraryService après ConnectivityService et OfflineCacheService
  getIt.registerSingletonAsync<LibraryService>(
      () async {
        final service = LibraryService();
        return await service.init();
      },
      dependsOn: [HttpService, MangaService, ConnectivityService, OfflineCacheService]);
  
  // Signalement « plus de chapitres » (chantier A) — après HttpService.
  getIt.registerSingletonWithDependencies<ChapterReportService>(
      () => ChapterReportService(),
      dependsOn: [HttpService]);

  // Journal additif des chapitres (Stats v2) — extrait de LibraryService.
  getIt.registerSingletonWithDependencies<ChapterLogService>(
      () => ChapterLogService(),
      dependsOn: [HttpService]);

  // SyncService après LibraryService
  getIt.registerSingletonAsync<SyncService>(
      () async {
        final service = SyncService();
        await service.initialize();
        return service;
      },
      dependsOn: [ConnectivityService, OfflineCacheService, LibraryService]);
  
  // Service helper pour faciliter l'utilisation du cache
  getIt.registerSingletonWithDependencies<CacheHelperService>(
      () => CacheHelperService(),
      dependsOn: [ConnectivityService, OfflineCacheService]);
  
  // Service de thème
  getIt.registerSingletonAsync<ThemeService>(
      () async {
        final prefs = await SharedPreferences.getInstance();
        return ThemeService(prefs);
      });
  
  // Service de gestion de la position de scroll pour les WebViews
  getIt.registerSingleton<ScrollPositionService>(ScrollPositionService());
  
  // Service de détection de captcha
  getIt.registerSingleton<CaptchaDetectionService>(CaptchaDetectionService());
  
  // Service de blocage de publicités
  getIt.registerSingleton<AdBlockerService>(AdBlockerService());
  
  // Service de navigation WebView
  getIt.registerSingleton<WebViewNavigationService>(WebViewNavigationService());
  
  // Service de traduction
  getIt.registerSingleton<TranslationService>(TranslationService());
  
  // BLoCs pour la gestion d'état réactive
  getIt.registerLazySingleton<ConnectivityBloc>(() => ConnectivityBloc());
  getIt.registerLazySingleton<LibraryBloc>(() => LibraryBloc());
  getIt.registerLazySingleton<HomePageBloc>(() => HomePageBloc());
  getIt.registerLazySingleton<SearchBloc>(() => SearchBloc(
        mangaService: getIt<MangaService>(),
        cacheService: getIt<OfflineCacheService>(),
      ));
  // DetailBloc doit être une factory, pas un singleton, pour éviter les race conditions
  // Chaque page de détails doit avoir sa propre instance de bloc
  getIt.registerFactory<DetailBloc>(() => DetailBloc());

  // Accueil « catalogue » (sections /mangas/home/sections) — 2026-09-05.
  // Enregistrements AJOUTÉS EN FIN, en lazy et SANS dependsOn : le service
  // et les BLoCs résolvent HttpService / StorageService / ConnectivityService
  // à l'appel, jamais à la construction. L'ordre ci-dessus n'est pas touché
  // (cf. régression d'écran blanc v0.12.1 sur un dependsOn prématuré).
  getIt.registerLazySingleton<HomeSectionsService>(
      () => const HomeSectionsService());
  getIt.registerLazySingleton<HomeSectionsBloc>(() => HomeSectionsBloc());
  // Une instance par page « Tout voir » (paramètre = id de section).
  getIt.registerFactoryParam<HomeSectionPageBloc, String, void>(
      (sectionId, _) => HomeSectionPageBloc(sectionId: sectionId));
}
