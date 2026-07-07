part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Lance une nouvelle recherche (page 1) pour [query].
class SearchRequested extends SearchEvent {
  final String query;

  const SearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

/// Charge la page suivante des résultats courants (scroll infini).
class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}

/// Réinitialise l'écran (query vidée → retour au mode browse).
class SearchCleared extends SearchEvent {
  const SearchCleared();
}
