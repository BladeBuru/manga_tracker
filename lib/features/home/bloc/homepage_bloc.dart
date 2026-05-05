import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/manga/services/recommendation.service.dart';
import 'package:mangatracker/features/profile/services/user.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/profile/dto/user.dto.dart';
import 'package:mangatracker/features/home/helpers/homepage_data_loader.dart';
import 'homepage_event.dart';
import 'homepage_state.dart';

/// BLoC pour la gestion de la page d'accueil.
///
/// Les fetchers (reseau + cache + mapping) sont extraits dans
/// [HomePageDataLoader] pour respecter la limite de 200 lignes par BLoC.
class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  final HomePageDataLoader _loader = HomePageDataLoader(
    mangaService: getIt<MangaService>(),
    recommendationService: getIt<RecommendationService>(),
    userService: getIt<UserService>(),
    cacheHelper: getIt<CacheHelperService>(),
  );
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();

  StreamSubscription<bool>? _connectivitySubscription;

  HomePageBloc() : super(const HomePageInitial()) {
    on<LoadHomePage>(_onLoadHomePage);
    on<RefreshHomePage>((_, __) => add(const LoadHomePage()));
    on<LoadPopularMangas>((e, emit) => _section(emit,
        label: 'Chargement des mangas populaires...',
        fetch: _loader.loadPopularMangas,
        apply: (s, d) => s.copyWith(popularMangas: d),
        errorPrefix: 'Erreur lors du chargement des mangas populaires'));
    on<LoadNewMangas>((e, emit) => _section(emit,
        label: 'Chargement des nouveaux mangas...',
        fetch: _loader.loadNewMangas,
        apply: (s, d) => s.copyWith(newMangas: d),
        errorPrefix: 'Erreur lors du chargement des nouveaux mangas'));
    on<LoadTrendingMangas>((e, emit) => _section(emit,
        label: 'Chargement des mangas en tendance...',
        fetch: _loader.loadTrendingMangas,
        apply: (s, d) => s.copyWith(trendingMangas: d),
        errorPrefix: 'Erreur lors du chargement des mangas en tendance'));
    on<LoadUserInfo>((e, emit) => _section<UserDto?>(emit,
        label: 'Chargement des informations utilisateur...',
        fetch: _loader.loadUserInfo,
        apply: (s, d) => s.copyWith(user: d),
        errorPrefix:
            'Erreur lors du chargement des informations utilisateur'));

    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((_) {});
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  /// Charge la page d'accueil complete (initial load + fallback offline).
  Future<void> _onLoadHomePage(
      LoadHomePage event, Emitter<HomePageState> emit) async {
    debugPrint('HomePageBloc: Chargement de la page d\'accueil...');

    final cache = await _loader.snapshotCache();
    if (cache.hasData) {
      emit(cache.toLoaded(
        pendingActions: await _loader.getPendingActionsCount(),
        stale: true,
      ));
    } else {
      emit(const HomePageLoading());
    }

    try {
      final results = await Future.wait([
        _loader.loadPopularMangas(),
        _loader.loadNewMangas(),
        _loader.loadTrendingMangas(),
        _loader.loadUserInfo(),
      ]);
      emit(HomePageLoaded(
        popularMangas: results[0] as List<MangaQuickViewDto>,
        newMangas: results[1] as List<MangaQuickViewDto>,
        trendingMangas: results[2] as List<MangaQuickViewDto>,
        recommendations: await _loader.loadRecommendations(),
        user: results[3] as UserDto?,
        pendingActions: await _loader.getPendingActionsCount(),
      ));
    } catch (e) {
      await _emitOfflineFallback(emit, e, cache);
    }
  }

  /// Handler factorise pour les chargements de section (populaires / nouveaux /
  /// tendances / user info). Emet ActionInProgress, fetch, puis copyWith ou
  /// HomePageError selon le resultat.
  Future<void> _section<T>(
    Emitter<HomePageState> emit, {
    required String label,
    required Future<T> Function() fetch,
    required HomePageLoaded Function(HomePageLoaded state, T data) apply,
    required String errorPrefix,
  }) async {
    if (state is! HomePageLoaded) return;
    final current = state as HomePageLoaded;
    emit(HomePageActionInProgress(
      popularMangas: current.popularMangas,
      newMangas: current.newMangas,
      trendingMangas: current.trendingMangas,
      user: current.user,
      action: label,
      isOffline: current.isOffline,
    ));
    try {
      emit(apply(current, await fetch()));
    } catch (e) {
      emit(HomePageError(
        message: '$errorPrefix: $e',
        isOffline: current.isOffline,
        cachedPopularMangas: current.popularMangas,
        cachedNewMangas: current.newMangas,
        cachedTrendingMangas: current.trendingMangas,
        cachedUser: current.user,
      ));
    }
  }

  /// Tente d'emettre un fallback offline depuis le cache. Gere le cas
  /// particulier `InvalidCredentialsException` (auth, pas reseau).
  Future<void> _emitOfflineFallback(
      Emitter<HomePageState> emit, Object error, HomeCacheSnapshot cache) async {
    if (error.toString().contains('InvalidCredentialsException')) {
      debugPrint('HomePageBloc: Erreur d\'authentification');
      emit(const HomePageError(message: 'Authentification requise'));
      return;
    }
    debugPrint(
        'Erreur de chargement, tentative de recuperation depuis le cache...');
    try {
      final fallback = cache.hasData ? cache : await _loader.snapshotCache();
      if (fallback.hasData) {
        emit(fallback.toLoaded(
          pendingActions: await _loader.getPendingActionsCount(),
          stale: true,
          isOffline: true,
        ));
      } else {
        emit(HomePageError(message: error.toString(), isOffline: true));
      }
    } catch (_) {
      emit(HomePageError(message: error.toString(), isOffline: true));
    }
  }
}
