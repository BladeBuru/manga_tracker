import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/profile/dto/user.dto.dart';
import 'homepage_event.dart';
import 'homepage_state.dart';

/// BLoC pour la gestion de la page d'accueil
class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  final MangaService _mangaService = getIt<MangaService>();
  final UserService _userService = getIt<UserService>();
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  
  StreamSubscription<bool>? _connectivitySubscription;

  HomePageBloc() : super(const HomePageInitial()) {
    on<LoadHomePage>(_onLoadHomePage);
    on<RefreshHomePage>(_onRefreshHomePage);
    on<LoadPopularMangas>(_onLoadPopularMangas);
    on<LoadNewMangas>(_onLoadNewMangas);
    on<LoadTrendingMangas>(_onLoadTrendingMangas);
    on<LoadUserInfo>(_onLoadUserInfo);
    
    _initializeConnectivityListener();
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  /// Initialise l'écoute de la connectivité
  void _initializeConnectivityListener() {
    // L'état offline est maintenant détecté directement via les erreurs réseau
    // Plus besoin de mettre à jour l'état via le listener
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        // L'état sera mis à jour automatiquement lors des prochains chargements
      },
    );
  }

  /// Charge la page d'accueil complète
  Future<void> _onLoadHomePage(LoadHomePage event, Emitter<HomePageState> emit) async {
    print('🔄 HomePageBloc: Chargement de la page d\'accueil...');
    emit(const HomePageLoading());
    
    try {
      // Charger toutes les données en parallèle
      final results = await Future.wait([
        _loadPopularMangas(),
        _loadNewMangas(),
        _loadTrendingMangas(),
        _loadUserInfo(),
      ]);
      
      final pendingActions = await _getPendingActionsCount();
      
      // Si aucune erreur, on est online
      emit(HomePageLoaded(
        popularMangas: results[0] as List<MangaQuickViewDto>,
        newMangas: results[1] as List<MangaQuickViewDto>,
        trendingMangas: results[2] as List<MangaQuickViewDto>,
        user: results[3] as UserDto?,
        isOffline: false,
        pendingActions: pendingActions,
      ));
    } catch (e) {
      // Erreur réseau détectée : on est offline
      print('⚠️ Erreur de chargement, tentative de récupération depuis le cache...');
      
      try {
        final cachedPopular = await _cacheHelper.getCachedHomePageData();
        final cachedUser = await _getCachedUserInfo();
        
        if (cachedPopular != null && cachedPopular.isNotEmpty) {
          print('✅ Données chargées depuis le cache (mode offline)');
          emit(HomePageLoaded(
            popularMangas: cachedPopular,
            newMangas: cachedPopular,
            trendingMangas: cachedPopular,
            user: cachedUser,
            isOffline: true,
            pendingActions: await _getPendingActionsCount(),
          ));
        } else {
          emit(HomePageError(
            message: e.toString(),
            isOffline: true,
          ));
        }
      } catch (cacheError) {
        emit(HomePageError(
          message: e.toString(),
          isOffline: true,
        ));
      }
    }
  }

  /// Rafraîchit la page d'accueil
  Future<void> _onRefreshHomePage(RefreshHomePage event, Emitter<HomePageState> emit) async {
    add(const LoadHomePage());
  }

  /// Charge les mangas populaires
  Future<void> _onLoadPopularMangas(LoadPopularMangas event, Emitter<HomePageState> emit) async {
    if (state is! HomePageLoaded) return;
    
    final currentState = state as HomePageLoaded;
    emit(HomePageActionInProgress(
      popularMangas: currentState.popularMangas,
      newMangas: currentState.newMangas,
      trendingMangas: currentState.trendingMangas,
      user: currentState.user,
      action: 'Chargement des mangas populaires...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final popularMangas = await _loadPopularMangas();
      emit(currentState.copyWith(popularMangas: popularMangas));
    } catch (e) {
      emit(HomePageError(
        message: 'Erreur lors du chargement des mangas populaires: $e',
        isOffline: currentState.isOffline,
        cachedPopularMangas: currentState.popularMangas,
        cachedNewMangas: currentState.newMangas,
        cachedTrendingMangas: currentState.trendingMangas,
        cachedUser: currentState.user,
      ));
    }
  }

  /// Charge les nouveaux mangas
  Future<void> _onLoadNewMangas(LoadNewMangas event, Emitter<HomePageState> emit) async {
    if (state is! HomePageLoaded) return;
    
    final currentState = state as HomePageLoaded;
    emit(HomePageActionInProgress(
      popularMangas: currentState.popularMangas,
      newMangas: currentState.newMangas,
      trendingMangas: currentState.trendingMangas,
      user: currentState.user,
      action: 'Chargement des nouveaux mangas...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final newMangas = await _loadNewMangas();
      emit(currentState.copyWith(newMangas: newMangas));
    } catch (e) {
      emit(HomePageError(
        message: 'Erreur lors du chargement des nouveaux mangas: $e',
        isOffline: currentState.isOffline,
        cachedPopularMangas: currentState.popularMangas,
        cachedNewMangas: currentState.newMangas,
        cachedTrendingMangas: currentState.trendingMangas,
        cachedUser: currentState.user,
      ));
    }
  }

  /// Charge les mangas en tendance
  Future<void> _onLoadTrendingMangas(LoadTrendingMangas event, Emitter<HomePageState> emit) async {
    if (state is! HomePageLoaded) return;
    
    final currentState = state as HomePageLoaded;
    emit(HomePageActionInProgress(
      popularMangas: currentState.popularMangas,
      newMangas: currentState.newMangas,
      trendingMangas: currentState.trendingMangas,
      user: currentState.user,
      action: 'Chargement des mangas en tendance...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final trendingMangas = await _loadTrendingMangas();
      emit(currentState.copyWith(trendingMangas: trendingMangas));
    } catch (e) {
      emit(HomePageError(
        message: 'Erreur lors du chargement des mangas en tendance: $e',
        isOffline: currentState.isOffline,
        cachedPopularMangas: currentState.popularMangas,
        cachedNewMangas: currentState.newMangas,
        cachedTrendingMangas: currentState.trendingMangas,
        cachedUser: currentState.user,
      ));
    }
  }

  /// Charge les informations utilisateur
  Future<void> _onLoadUserInfo(LoadUserInfo event, Emitter<HomePageState> emit) async {
    if (state is! HomePageLoaded) return;
    
    final currentState = state as HomePageLoaded;
    emit(HomePageActionInProgress(
      popularMangas: currentState.popularMangas,
      newMangas: currentState.newMangas,
      trendingMangas: currentState.trendingMangas,
      user: currentState.user,
      action: 'Chargement des informations utilisateur...',
      isOffline: currentState.isOffline,
    ));
    
    try {
      final user = await _loadUserInfo();
      emit(currentState.copyWith(user: user));
    } catch (e) {
      emit(HomePageError(
        message: 'Erreur lors du chargement des informations utilisateur: $e',
        isOffline: currentState.isOffline,
        cachedPopularMangas: currentState.popularMangas,
        cachedNewMangas: currentState.newMangas,
        cachedTrendingMangas: currentState.trendingMangas,
        cachedUser: currentState.user,
      ));
    }
  }

  /// Charge les mangas populaires avec cache
  Future<List<MangaQuickViewDto>> _loadPopularMangas() async {
    return await _cacheHelper.loadSearchResults(
      query: 'popular',
      networkCall: () => _mangaService.getPopularMangas(),
    );
  }

  /// Charge les nouveaux mangas avec cache
  Future<List<MangaQuickViewDto>> _loadNewMangas() async {
    return await _cacheHelper.loadSearchResults(
      query: 'new',
      networkCall: () => _mangaService.getNewMangas(),
    );
  }

  /// Charge les mangas en tendance avec cache
  Future<List<MangaQuickViewDto>> _loadTrendingMangas() async {
    return await _cacheHelper.loadSearchResults(
      query: 'trending',
      networkCall: () => _mangaService.getTrendingMangas(),
    );
  }

  /// Charge les informations utilisateur
  Future<UserDto?> _loadUserInfo() async {
    try {
      final userInfo = await _userService.getUserInformation();
      return UserDto(
        username: userInfo.username,
        email: userInfo.email,
        avatar: null, // UserInformationDto n'a pas d'avatar
        lastLogin: null, // UserInformationDto n'a pas de lastLogin
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupère les informations utilisateur depuis le cache
  Future<UserDto?> _getCachedUserInfo() async {
    // Pour l'instant, retourner null. On pourrait implémenter un cache pour l'utilisateur
    return null;
  }

  /// Récupère le nombre d'actions en attente
  Future<int> _getPendingActionsCount() async {
    try {
      final queue = await _cacheHelper.getOfflineQueue();
      return queue.length;
    } catch (e) {
      return 0;
    }
  }
}
