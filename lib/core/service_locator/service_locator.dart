import 'package:get_it/get_it.dart';
import 'package:mangatracker/features/auth/services/auth.service.dart';
import 'package:mangatracker/features/auth/services/validator.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/core/network/http_service.dart';

import '../storage/services/storage.service.dart';

GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingletonAsync<StorageService>(
      () async => StorageService().init());
  getIt.registerSingletonWithDependencies<AuthService>(() => AuthService(),
      dependsOn: [StorageService]);
  getIt.registerSingletonWithDependencies<HttpService>(() => HttpService(),
      dependsOn: [StorageService, AuthService]);
  getIt.registerSingleton<ValidatorService>(ValidatorService());
  getIt.registerSingletonWithDependencies<MangaService>(() => MangaService(),
      dependsOn: [HttpService]);
  getIt.registerSingletonWithDependencies<LibraryService>(
      () => LibraryService(),
      dependsOn: [HttpService, MangaService]);
  getIt.registerSingletonWithDependencies<UserService>(() => UserService(),
      dependsOn: [HttpService]);
}
