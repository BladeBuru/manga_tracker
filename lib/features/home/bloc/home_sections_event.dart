import 'package:equatable/equatable.dart';

/// Evenements du [HomeSectionsBloc] (accueil catalogue).
abstract class HomeSectionsEvent extends Equatable {
  const HomeSectionsEvent();

  @override
  List<Object?> get props => [];
}

/// Chargement initial : cache d'abord (si present), puis reseau.
class LoadHomeSections extends HomeSectionsEvent {
  const LoadHomeSections();
}

/// Rafraichissement (pull-to-refresh) : reseau, en gardant l'affichage
/// courant pendant l'attente.
class RefreshHomeSections extends HomeSectionsEvent {
  const RefreshHomeSections();
}
