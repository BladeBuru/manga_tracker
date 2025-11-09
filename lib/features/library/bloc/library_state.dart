import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// États pour LibraryBloc
abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

/// État initial
class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

/// Chargement en cours
class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

/// Bibliothèque chargée avec succès
class LibraryLoaded extends LibraryState {
  final List<MangaQuickViewDto> mangas;
  final bool isOffline;
  final int pendingActions;
  final bool isStale;
  
  const LibraryLoaded({
    required this.mangas,
    this.isOffline = false,
    this.pendingActions = 0,
    bool? stale,
  }) : isStale = stale ?? false;
  
  @override
  List<Object> get props => [mangas, isOffline, pendingActions, isStale];
  
  /// Créer une copie avec de nouveaux paramètres
  LibraryLoaded copyWith({
    List<MangaQuickViewDto>? mangas,
    bool? isOffline,
    int? pendingActions,
    bool? stale,
  }) {
    return LibraryLoaded(
      mangas: mangas ?? this.mangas,
      isOffline: isOffline ?? this.isOffline,
      pendingActions: pendingActions ?? this.pendingActions,
      stale: stale ?? this.isStale,
    );
  }
}

/// Erreur lors du chargement
class LibraryError extends LibraryState {
  final String message;
  final bool isOffline;
  final List<MangaQuickViewDto>? cachedMangas;
  
  const LibraryError({
    required this.message,
    this.isOffline = false,
    this.cachedMangas,
  });
  
  @override
  List<Object?> get props => [message, isOffline, cachedMangas];
}

/// Action en cours (ajout, suppression, etc.)
class LibraryActionInProgress extends LibraryState {
  final List<MangaQuickViewDto> mangas;
  final String action;
  final bool isOffline;
  
  const LibraryActionInProgress({
    required this.mangas,
    required this.action,
    this.isOffline = false,
  });
  
  @override
  List<Object> get props => [mangas, action, isOffline];
}
