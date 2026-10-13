import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/library/services/chapter_progress_result.dart';
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

/// Échec d'une action de la fiche qui ne remplace PAS la page : le contenu
/// chargé reste affiché, la vue montre la raison (et propose de réessayer).
///
/// Avant, un enregistrement de progression refusé émettait [DetailError] :
/// toute la fiche laissait place à un écran d'erreur (texte français codé en
/// dur) dont « Réessayer » rechargeait la page au lieu de réessayer.
sealed class DetailFailureNotice extends Equatable {
  const DetailFailureNotice();
}

/// La progression [readChapters] n'a pas été enregistrée, pour [reason].
final class ProgressSaveFailed extends DetailFailureNotice {
  final int readChapters;
  final ChapterProgressResult reason;

  const ProgressSaveFailed({required this.readChapters, required this.reason});

  @override
  List<Object?> get props => [readChapters, reason];
}

/// La note [rating] n'a pas été enregistrée ([offline] : faute de réseau).
final class RatingSaveFailed extends DetailFailureNotice {
  final int rating;
  final bool offline;

  const RatingSaveFailed({required this.rating, required this.offline});

  @override
  List<Object?> get props => [rating, offline];
}

/// [DetailLoaded] porteur d'un échec à signaler ([notice]) — effet ponctuel :
/// l'état suivant est un [DetailLoaded] ordinaire. [attempt] rend chaque
/// échec distinct (deux refus identiques s'affichent tous les deux).
class DetailActionFailed extends DetailLoaded {
  final DetailFailureNotice notice;
  final int attempt;

  const DetailActionFailed({
    required super.mangaDetail,
    super.isOffline,
    super.pendingActions,
    super.requiresReauth,
    super.stale,
    required this.notice,
    required this.attempt,
  });

  @override
  List<Object> get props => [...super.props, notice, attempt];
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
