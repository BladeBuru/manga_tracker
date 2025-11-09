import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/profile/dto/user.dto.dart';

/// États pour HomePageBloc
abstract class HomePageState extends Equatable {
  const HomePageState();

  @override
  List<Object?> get props => [];
}

/// État initial
class HomePageInitial extends HomePageState {
  const HomePageInitial();
}

/// Chargement en cours
class HomePageLoading extends HomePageState {
  const HomePageLoading();
}

/// Page d'accueil chargée avec succès
class HomePageLoaded extends HomePageState {
  final List<MangaQuickViewDto> popularMangas;
  final List<MangaQuickViewDto> newMangas;
  final List<MangaQuickViewDto> trendingMangas;
  final UserDto? user;
  final bool isOffline;
  final int pendingActions;
  final bool isStale;
  
  const HomePageLoaded({
    required this.popularMangas,
    required this.newMangas,
    required this.trendingMangas,
    this.user,
    this.isOffline = false,
    this.pendingActions = 0,
    bool? stale,
  }) : isStale = stale ?? false;
  
  @override
  List<Object?> get props => [popularMangas, newMangas, trendingMangas, user, isOffline, pendingActions, isStale];
  
  /// Créer une copie avec de nouveaux paramètres
  HomePageLoaded copyWith({
    List<MangaQuickViewDto>? popularMangas,
    List<MangaQuickViewDto>? newMangas,
    List<MangaQuickViewDto>? trendingMangas,
    UserDto? user,
    bool? isOffline,
    int? pendingActions,
    bool? stale,
  }) {
    return HomePageLoaded(
      popularMangas: popularMangas ?? this.popularMangas,
      newMangas: newMangas ?? this.newMangas,
      trendingMangas: trendingMangas ?? this.trendingMangas,
      user: user ?? this.user,
      isOffline: isOffline ?? this.isOffline,
      pendingActions: pendingActions ?? this.pendingActions,
      stale: stale ?? this.isStale,
    );
  }
}

/// Erreur lors du chargement
class HomePageError extends HomePageState {
  final String message;
  final bool isOffline;
  final List<MangaQuickViewDto>? cachedPopularMangas;
  final List<MangaQuickViewDto>? cachedNewMangas;
  final List<MangaQuickViewDto>? cachedTrendingMangas;
  final UserDto? cachedUser;
  
  const HomePageError({
    required this.message,
    this.isOffline = false,
    this.cachedPopularMangas,
    this.cachedNewMangas,
    this.cachedTrendingMangas,
    this.cachedUser,
  });
  
  @override
  List<Object?> get props => [message, isOffline, cachedPopularMangas, cachedNewMangas, cachedTrendingMangas, cachedUser];
}

/// Action en cours (chargement d'une section)
class HomePageActionInProgress extends HomePageState {
  final List<MangaQuickViewDto> popularMangas;
  final List<MangaQuickViewDto> newMangas;
  final List<MangaQuickViewDto> trendingMangas;
  final UserDto? user;
  final String action;
  final bool isOffline;
  
  const HomePageActionInProgress({
    required this.popularMangas,
    required this.newMangas,
    required this.trendingMangas,
    this.user,
    required this.action,
    this.isOffline = false,
  });
  
  @override
  List<Object?> get props => [popularMangas, newMangas, trendingMangas, user, action, isOffline];
}
