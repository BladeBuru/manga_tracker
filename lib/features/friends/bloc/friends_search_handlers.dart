part of 'friends_bloc.dart';

/// Recherche d'utilisateurs, à l'abri des réponses périmées.
///
/// Chaque frappe (après la temporisation du champ) lance une recherche ;
/// plusieurs peuvent être en vol. Seule la **dernière** a le droit d'écrire
/// dans l'état : une réponse lente à « lé » ne doit pas écraser celle de
/// « léa » arrivée avant elle. Un échec s'affiche (« La recherche a
/// échoué ») au lieu de passer pour « Aucun utilisateur trouvé ».
mixin _FriendsSearchHandlers on Bloc<FriendsEvent, FriendsState> {
  FriendsService get _service;

  /// Numéro de la recherche la plus récente.
  int _searchGeneration = 0;

  Future<void> _onSearch(
    SearchUsers event,
    Emitter<FriendsState> emit,
  ) async {
    if (state is! FriendsLoaded) return;
    final generation = ++_searchGeneration;
    final query = event.query.trim();
    if (query.length < 2) {
      emit((state as FriendsLoaded).copyWith(
        searchQuery: query,
        searchResults: const [],
        searchLoading: false,
        searchError: () => null,
      ));
      return;
    }
    emit((state as FriendsLoaded).copyWith(
      searchQuery: query,
      searchLoading: true,
      searchError: () => null,
    ));
    try {
      final results = await _service.searchUsers(query);
      if (generation != _searchGeneration || state is! FriendsLoaded) return;
      emit((state as FriendsLoaded).copyWith(
        searchResults: results,
        searchLoading: false,
      ));
    } catch (e) {
      if (generation != _searchGeneration || state is! FriendsLoaded) return;
      emit((state as FriendsLoaded).copyWith(
        searchResults: const [],
        searchLoading: false,
        searchError: () => e,
      ));
    }
  }
}
