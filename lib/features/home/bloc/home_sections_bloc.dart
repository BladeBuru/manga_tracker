import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/core/network/failure_classifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/services/home_sections.service.dart';

import 'home_sections_event.dart';
import 'home_sections_state.dart';

/// BLoC des sections de l'accueil catalogue (`/mangas/home/sections`).
///
/// Distinct de `HomePageBloc` (utilisateur + recommandations) : une seule
/// responsabilite, et un cache dedie. Pattern offline-first du projet :
///
/// 1. cache affiche immediatement s'il existe (`isStale: true`) ;
/// 2. reseau → `HomeSectionsLoaded` frais ;
/// 3. echec → `classifyFailure()` : le cache est servi **quel que soit** le
///    mode d'echec (decision produit 2026-08-31), `isOffline` re-evalue a
///    chaque echec, `requiresReauth` sur rejet explicite du serveur.
class HomeSectionsBloc extends Bloc<HomeSectionsEvent, HomeSectionsState> {
  final HomeSectionsService? _serviceOverride;
  final ConnectivityService? _connectivityOverride;

  /// Un seul chargement a la fois : un pull-to-refresh pendant le chargement
  /// initial est ignore plutot que de faire courir deux requetes.
  bool _inFlight = false;

  /// Dependances injectables (tests), sinon resolues depuis GetIt a l'appel.
  HomeSectionsBloc({
    HomeSectionsService? service,
    ConnectivityService? connectivity,
  })  : _serviceOverride = service,
        _connectivityOverride = connectivity,
        super(const HomeSectionsInitial()) {
    on<LoadHomeSections>((_, emit) => _load(emit, cacheFirst: true));
    on<RefreshHomeSections>((_, emit) => _load(emit, cacheFirst: false));
  }

  HomeSectionsService get _service =>
      _serviceOverride ?? getIt<HomeSectionsService>();

  bool get _isConnected {
    try {
      return (_connectivityOverride ?? getIt<ConnectivityService>())
          .isConnected;
    } catch (_) {
      return true; // service indisponible : on laisse le reseau trancher
    }
  }

  Future<void> _load(
    Emitter<HomeSectionsState> emit, {
    required bool cacheFirst,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      HomeSectionsDto? cached;
      if (cacheFirst) {
        cached = await _readCache();
        if (cached != null && !cached.isEmpty) {
          // Bandeau immediat si l'appareil se sait deja hors ligne, au lieu
          // d'attendre l'echec de la requete.
          emit(HomeSectionsLoaded(
            data: cached,
            isStale: true,
            isOffline: !_isConnected,
          ));
        } else if (state is! HomeSectionsLoaded) {
          emit(const HomeSectionsLoading());
        }
      }

      try {
        final fresh = await _service.fetchSections(
          limit: HomeSectionsService.defaultLimit,
        );
        emit(HomeSectionsLoaded(data: fresh));
      } catch (e) {
        await _emitFallback(emit, e, cached);
      }
    } finally {
      _inFlight = false;
    }
  }

  /// Repli sur les donnees deja connues : cache lu pour ce chargement, sinon
  /// etat courant (rafraichissement), sinon relecture du cache.
  Future<void> _emitFallback(
    Emitter<HomeSectionsState> emit,
    Object error,
    HomeSectionsDto? cached,
  ) async {
    final mode = classifyFailure(error);
    final offline = showsOfflineIndicator(mode);
    final reauth = requiresReauthPrompt(mode);
    debugPrint('HomeSectionsBloc: echec ($mode), repli cache');

    final current = state;
    final fallback = cached ??
        (current is HomeSectionsLoaded ? current.data : null) ??
        await _readCache();

    if (fallback != null && !fallback.isEmpty) {
      emit(HomeSectionsLoaded(
        data: fallback,
        isStale: true,
        isOffline: offline,
        requiresReauth: reauth,
      ));
    } else {
      emit(HomeSectionsError(
        message: error.toString(),
        isOffline: offline,
        requiresReauth: reauth,
      ));
    }
  }

  Future<HomeSectionsDto?> _readCache() async {
    try {
      return await _service.getCachedSections();
    } catch (_) {
      return null;
    }
  }
}
