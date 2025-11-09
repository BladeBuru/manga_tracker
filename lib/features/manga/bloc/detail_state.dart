import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';

/// États pour DetailBloc
abstract class DetailState extends Equatable {
  const DetailState();

  @override
  List<Object?> get props => [];
}

/// État initial
class DetailInitial extends DetailState {
  const DetailInitial();
}

/// Chargement en cours
class DetailLoading extends DetailState {
  const DetailLoading();
}

/// Détails chargés avec succès
class DetailLoaded extends DetailState {
  final MangaDetailDto mangaDetail;
  final bool isOffline;
  final int pendingActions;
  final bool isStale;
  
  const DetailLoaded({
    required this.mangaDetail,
    this.isOffline = false,
    this.pendingActions = 0,
    bool? isStale,
  }) : isStale = isStale ?? false;
  
  @override
  List<Object> get props => [mangaDetail, isOffline, pendingActions, isStale];
  
  /// Créer une copie avec de nouveaux paramètres
  DetailLoaded copyWith({
    MangaDetailDto? mangaDetail,
    bool? isOffline,
    int? pendingActions,
    bool? isStale,
  }) {
    return DetailLoaded(
      mangaDetail: mangaDetail ?? this.mangaDetail,
      isOffline: isOffline ?? this.isOffline,
      pendingActions: pendingActions ?? this.pendingActions,
      isStale: isStale ?? this.isStale,
    );
  }
}

/// Erreur lors du chargement
class DetailError extends DetailState {
  final String message;
  final bool isOffline;
  final MangaDetailDto? cachedMangaDetail;
  
  const DetailError({
    required this.message,
    this.isOffline = false,
    this.cachedMangaDetail,
  });
  
  @override
  List<Object?> get props => [message, isOffline, cachedMangaDetail];
}

/// Action en cours (ajout, suppression, etc.)
class DetailActionInProgress extends DetailState {
  final MangaDetailDto mangaDetail;
  final String action;
  final bool isOffline;
  
  const DetailActionInProgress({
    required this.mangaDetail,
    required this.action,
    this.isOffline = false,
  });
  
  @override
  List<Object> get props => [mangaDetail, action, isOffline];
}
