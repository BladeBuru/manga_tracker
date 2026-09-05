import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
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

    on<DismissRecommendation>(_onDismissRecommendation);

    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((_) {});
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  /// Retire un titre ecarte des recommandations de l'etat courant.
  ///
  /// Les deux collections sont filtrees : `recommendations` (section de
  /// l'accueil) et `recommendationsByGenre`, pour qu'un futur ecran qui
  /// consommerait la seconde ne reaffiche pas le titre.
  void _onDismissRecommendation(
      DismissRecommendation event, Emitter<HomePageState> emit) {
    final current = state;
    if (current is! HomePageLoaded) return;

    emit(current.copyWith(
      recommendations: current.recommendations
          .where((m) => m.muId != event.muId)
          .toList(),
      recommendationsByGenre: current.recommendationsByGenre.map(
        (genre, list) => MapEntry(
          genre,
          list.where((m) => m.muId != event.muId).toList(),
        ),
      ),
    ));
  }

  /// Charge le « compagnon » de l'accueil : utilisateur + recommandations.
  ///
  /// Depuis l'accueil catalogue (2026-09-05), les listes tendances /
  /// nouveautes / populaires ne sont plus chargees ici : les sections
  /// editoriales viennent de `HomeSectionsBloc`, avec leur propre cache.
  /// Les deux chargeurs restants se degradent silencieusement (utilisateur
  /// `null`, recommandations vides ou en cache), d'ou l'absence de repli :
  /// `isOffline` reflete l'etat connu de la connectivite.
  Future<void> _onLoadHomePage(
      LoadHomePage event, Emitter<HomePageState> emit) async {
    debugPrint('HomePageBloc: Chargement de la page d\'accueil...');
    if (state is! HomePageLoaded) emit(const HomePageLoading());

    final user = await _loader.loadUserInfo();
    final recommendations = await _loader.loadRecommendations();
    emit(HomePageLoaded(
      popularMangas: const <MangaQuickViewDto>[],
      newMangas: const <MangaQuickViewDto>[],
      trendingMangas: const <MangaQuickViewDto>[],
      recommendations: recommendations,
      user: user,
      pendingActions: await _loader.getPendingActionsCount(),
      isOffline: !_connectivityService.isConnected,
    ));
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
      // L'état réseau est RE-ÉVALUÉ : hériter de `current` laissait une
      // section échouée hors ligne s'afficher sans bandeau.
      final mode = classifyFailure(e);
      emit(HomePageError(
        message: '$errorPrefix: $e',
        isOffline: showsOfflineIndicator(mode),
        requiresReauth: requiresReauthPrompt(mode),
        cachedPopularMangas: current.popularMangas,
        cachedNewMangas: current.newMangas,
        cachedTrendingMangas: current.trendingMangas,
        cachedUser: current.user,
      ));
    }
  }

}
