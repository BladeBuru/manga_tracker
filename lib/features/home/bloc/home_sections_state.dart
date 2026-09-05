import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';

/// Etats du [HomeSectionsBloc].
///
/// `isOffline` = « ce qui est affiche vient du cache, faute d'avoir pu joindre
/// le serveur » ; `requiresReauth` = le serveur a rejete la session, invitation
/// **non bloquante** a se reconnecter (le contenu en cache reste affiche).
abstract class HomeSectionsState extends Equatable {
  const HomeSectionsState();

  bool get isOffline => false;
  bool get requiresReauth => false;

  @override
  List<Object?> get props => [];
}

class HomeSectionsInitial extends HomeSectionsState {
  const HomeSectionsInitial();
}

/// Premier chargement sans cache : la vue affiche des squelettes.
class HomeSectionsLoading extends HomeSectionsState {
  const HomeSectionsLoading();
}

class HomeSectionsLoaded extends HomeSectionsState {
  final HomeSectionsDto data;

  @override
  final bool isOffline;

  /// Donnees servies depuis le cache en attendant (ou faute de) reseau.
  final bool isStale;

  @override
  final bool requiresReauth;

  const HomeSectionsLoaded({
    required this.data,
    this.isOffline = false,
    this.isStale = false,
    this.requiresReauth = false,
  });

  /// Sections a afficher, dans l'ordre du serveur, sans les vides.
  List<HomeSectionDto> get sections => data.nonEmptySections;

  HomeSectionsLoaded copyWith({
    HomeSectionsDto? data,
    bool? isOffline,
    bool? isStale,
    bool? requiresReauth,
  }) {
    return HomeSectionsLoaded(
      data: data ?? this.data,
      isOffline: isOffline ?? this.isOffline,
      isStale: isStale ?? this.isStale,
      requiresReauth: requiresReauth ?? this.requiresReauth,
    );
  }

  @override
  List<Object?> get props => [data, isOffline, isStale, requiresReauth];
}

/// Echec sans aucune donnee a montrer (pas de cache).
class HomeSectionsError extends HomeSectionsState {
  final String message;

  @override
  final bool isOffline;

  @override
  final bool requiresReauth;

  const HomeSectionsError({
    required this.message,
    this.isOffline = false,
    this.requiresReauth = false,
  });

  @override
  List<Object?> get props => [message, isOffline, requiresReauth];
}
