import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/profile/dto/user.dto.dart';
import 'package:mangatracker/features/home/bloc/homepage_state.dart';

/// Helper qui encapsule les fetchers de donnees de la HomePage
/// (reseau + cache + mapping). Extrait de `HomePageBloc` pour
/// respecter la limite de 200 lignes par BLoC.
class HomePageDataLoader {
  final MangaService _mangaService;
  final RecommendationService _recommendationService;
  final UserService _userService;
  final CacheHelperService _cacheHelper;

  const HomePageDataLoader({
    required MangaService mangaService,
    required RecommendationService recommendationService,
    required UserService userService,
    required CacheHelperService cacheHelper,
  })  : _mangaService = mangaService,
        _recommendationService = recommendationService,
        _userService = userService,
        _cacheHelper = cacheHelper;

  Future<List<MangaQuickViewDto>> loadPopularMangas() => _cacheHelper
      .loadSearchResults(
          query: 'popular', networkCall: () => _mangaService.getPopularMangas());

  Future<List<MangaQuickViewDto>> loadNewMangas() => _cacheHelper
      .loadSearchResults(
          query: 'new', networkCall: () => _mangaService.getNewMangas());

  Future<List<MangaQuickViewDto>> loadTrendingMangas() =>
      _cacheHelper.loadSearchResults(
          query: 'trending',
          networkCall: () => _mangaService.getTrendingMangas());

  /// Charge les recommandations personnalisees (limite 5 pour le carrousel
  /// compact de la home). Silencieux en cas d'erreur (graceful degradation).
  Future<List<MangaQuickViewDto>> loadRecommendations() async {
    try {
      return await _recommendationService.getPersonalizedRecommendations(
          limit: 5);
    } catch (e) {
      debugPrint('HomePageDataLoader: Erreur recommandations (ignoree): $e');
      return [];
    }
  }

  /// Charge les informations utilisateur depuis le service.
  ///
  /// Si le cache dit `emailVerified=false`, on refait un fetch réseau pour
  /// détecter une vérification effectuée hors de la VerifyEmailView (lien
  /// cliqué depuis un navigateur PC, validation manuelle, etc.). Sans ça,
  /// le cache 7j garde l'ancienne valeur et la banner « Vérifiez votre
  /// email » reste affichée même après vérif côté serveur.
  Future<UserDto?> loadUserInfo() async {
    try {
      var userInfo = await _userService.getUserInformation();
      if (!userInfo.emailVerified) {
        try {
          userInfo =
              await _userService.getUserInformation(forceRefresh: true);
        } catch (_) {
          // Erreur réseau silencieuse : on garde la valeur du cache
        }
      }
      return UserDto(
        username: userInfo.username,
        email: userInfo.email,
        avatar: null,
        lastLogin: null,
        emailVerified: userInfo.emailVerified,
      );
    } catch (e) {
      return null;
    }
  }

  /// Recupere les informations utilisateur depuis le cache.
  /// Pour l'instant retourne null — un cache utilisateur pourrait etre ajoute.
  Future<UserDto?> getCachedUserInfo() async => null;

  /// Recupere le nombre d'actions en attente dans la file offline.
  Future<int> getPendingActionsCount() async {
    try {
      return (await _cacheHelper.getOfflineQueue()).length;
    } catch (_) {
      return 0;
    }
  }

  /// Snapshot complet du cache (popular / new / trending / user).
  /// Utilise par `_onLoadHomePage` et son fallback offline.
  Future<HomeCacheSnapshot> snapshotCache() async {
    return HomeCacheSnapshot(
      popular: await _cacheHelper.getCachedSearchResults('popular'),
      newMangas: await _cacheHelper.getCachedSearchResults('new'),
      trending: await _cacheHelper.getCachedSearchResults('trending'),
      user: await getCachedUserInfo(),
    );
  }
}

/// Snapshot immuable des donnees du cache HomePage. Sert a la fois pour
/// l'affichage rapide initial et le fallback offline.
class HomeCacheSnapshot {
  final List<MangaQuickViewDto>? popular;
  final List<MangaQuickViewDto>? newMangas;
  final List<MangaQuickViewDto>? trending;
  final UserDto? user;

  const HomeCacheSnapshot({
    required this.popular,
    required this.newMangas,
    required this.trending,
    required this.user,
  });

  bool get hasData =>
      (popular?.isNotEmpty ?? false) ||
      (newMangas?.isNotEmpty ?? false) ||
      (trending?.isNotEmpty ?? false);

  /// Convertit le snapshot en `HomePageLoaded`.
  HomePageLoaded toLoaded({
    required int pendingActions,
    required bool stale,
    bool isOffline = false,
  }) {
    return HomePageLoaded(
      popularMangas: popular ?? const <MangaQuickViewDto>[],
      newMangas: newMangas ?? const <MangaQuickViewDto>[],
      trendingMangas: trending ?? const <MangaQuickViewDto>[],
      user: user,
      isOffline: isOffline,
      pendingActions: pendingActions,
      stale: stale,
    );
  }
}
