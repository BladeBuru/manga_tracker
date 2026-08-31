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

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const LibraryLoaded({
    required this.mangas,
    this.isOffline = false,
    this.pendingActions = 0,
    this.requiresReauth = false,
    bool? stale,
  }) : isStale = stale ?? false;

  @override
  List<Object> get props =>
      [mangas, isOffline, pendingActions, isStale, requiresReauth];

  /// Créer une copie avec de nouveaux paramètres
  LibraryLoaded copyWith({
    List<MangaQuickViewDto>? mangas,
    bool? isOffline,
    int? pendingActions,
    bool? stale,
    bool? requiresReauth,
  }) {
    return LibraryLoaded(
      mangas: mangas ?? this.mangas,
      isOffline: isOffline ?? this.isOffline,
      pendingActions: pendingActions ?? this.pendingActions,
      stale: stale ?? this.isStale,
      requiresReauth: requiresReauth ?? this.requiresReauth,
    );
  }
}

/// Erreur lors du chargement
class LibraryError extends LibraryState {
  final String message;
  final bool isOffline;
  final List<MangaQuickViewDto>? cachedMangas;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const LibraryError({
    required this.message,
    this.isOffline = false,
    this.cachedMangas,
    this.requiresReauth = false,
  });

  @override
  List<Object?> get props => [message, isOffline, cachedMangas, requiresReauth];
}

/// Action en cours (ajout, suppression, etc.)
class LibraryActionInProgress extends LibraryState {
  final List<MangaQuickViewDto> mangas;
  final String action;
  final bool isOffline;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const LibraryActionInProgress({
    required this.mangas,
    required this.action,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  @override
  List<Object> get props => [mangas, action, isOffline, requiresReauth];
}
