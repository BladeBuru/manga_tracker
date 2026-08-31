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

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const DetailLoaded({
    required this.mangaDetail,
    this.isOffline = false,
    this.pendingActions = 0,
    this.requiresReauth = false,
    bool? stale,
  }) : isStale = stale ?? false;

  @override
  List<Object> get props =>
      [mangaDetail, isOffline, pendingActions, isStale, requiresReauth];

  /// Créer une copie avec de nouveaux paramètres
  DetailLoaded copyWith({
    MangaDetailDto? mangaDetail,
    bool? isOffline,
    int? pendingActions,
    bool? isStale,
    bool? requiresReauth,
  }) {
    return DetailLoaded(
      mangaDetail: mangaDetail ?? this.mangaDetail,
      isOffline: isOffline ?? this.isOffline,
      pendingActions: pendingActions ?? this.pendingActions,
      stale: isStale ?? this.isStale,
      requiresReauth: requiresReauth ?? this.requiresReauth,
    );
  }
}

/// Erreur lors du chargement
class DetailError extends DetailState {
  final String message;
  final bool isOffline;
  final MangaDetailDto? cachedMangaDetail;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const DetailError({
    required this.message,
    this.isOffline = false,
    this.cachedMangaDetail,
    this.requiresReauth = false,
  });

  @override
  List<Object?> get props =>
      [message, isOffline, cachedMangaDetail, requiresReauth];
}

/// Action en cours (ajout, suppression, etc.)
class DetailActionInProgress extends DetailState {
  final MangaDetailDto mangaDetail;
  final String action;
  final bool isOffline;

  /// Le serveur a rejeté la session (401/403) : l'utilisateur est invité à se
  /// reconnecter, **sans être bloqué**. Le contenu en cache reste affiché
  /// derrière l'invitation — cf. `failure_classifier.dart`, frontière de
  /// sécurité. Ne jamais rebrancher une redirection forcée dessus.
  final bool requiresReauth;

  const DetailActionInProgress({
    required this.mangaDetail,
    required this.action,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  @override
  List<Object> get props => [mangaDetail, action, isOffline, requiresReauth];
}
