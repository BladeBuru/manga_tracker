import 'package:get_it/get_it.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/core/network/http_service.dart';

import '../../features/auth/services/biometric.service.dart';
import '../services/app_update_service.dart';
import '../storage/services/storage.service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_cache_service.dart';
import '../services/sync_service.dart';
import '../services/cache_helper_service.dart';
import '../bloc/connectivity_bloc.dart';
import '../../features/library/bloc/library_bloc.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Services de base
  getIt.registerSingletonAsync<StorageService>(
      () async => StorageService().init());
  getIt.registerSingletonWithDependencies<AuthService>(() => AuthService(),
      dependsOn: [StorageService]);
  getIt.registerSingletonWithDependencies<HttpService>(() => HttpService(),
      dependsOn: [StorageService, AuthService]);
  getIt.registerSingleton<ValidatorService>(ValidatorService());
  getIt.registerSingletonWithDependencies<MangaService>(() => MangaService(),
      dependsOn: [HttpService]);
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
  getIt.registerSingletonWithDependencies<UserService>(() => UserService(),
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
  
  // BLoCs pour la gestion d'état réactive
  getIt.registerLazySingleton<ConnectivityBloc>(() => ConnectivityBloc());
  getIt.registerLazySingleton<LibraryBloc>(() => LibraryBloc());
}
