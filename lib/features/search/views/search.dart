import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/features/search/bloc/search_bloc.dart';
import 'package:mangatracker/features/search/services/search_history.service.dart';
import 'package:mangatracker/features/search/widgets/popular_genres_wrap.dart';
import 'package:mangatracker/features/search/widgets/search_bar_input.dart';
import 'package:mangatracker/features/search/widgets/search_header.dart';
import 'package:mangatracker/features/search/widgets/search_history_list.dart';
import 'package:mangatracker/features/search/widgets/search_results_list.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Page Recherche — Design System V1 « Refined Classic ».
///
/// Source : `.claude-design/manga-tracker/project/screen-search.jsx`.
///
/// Structure (mode browse) :
///  - Titre "Rechercher" (24 / 900 / -0.025em)
///  - Barre de recherche pilule (radius 14, border rouge si query active)
///  - Historique de recherche (card hairline + rows refresh + clear)
///  - Genres populaires (Wrap de chips pilule)
///
/// Mode résultats : titre + barre + [SearchResultsList] (scroll infini
/// piloté par [SearchBloc] — résultats triés par pertinence côté API).
class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final SearchBloc _searchBloc = getIt<SearchBloc>();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<String> _history = const [];

  // Genres populaires : noms CANONIQUES MangaUpdates (« Adventure »,
  // « Sci-fi »), traduits à l'affichage. Une pastille ouvre la liste des
  // œuvres du genre — elle ne tape plus le nom du genre dans la barre de
  // recherche (qui cherchait alors des TITRES contenant « shounen »).
  static const List<String> _popularGenres = [
    'Shounen',
    'Seinen',
    'Shoujo',
    'Romance',
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Sci-fi',
    'Slice of Life',
    'Mystery',
    'Horror',
    'Sports',
  ];

  SearchHistoryService get _historyService {
    try {
      return getIt<SearchHistoryService>();
    } catch (_) {
      return SearchHistoryService();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _syncControllerWithBloc();
  }

  /// Le bloc est un singleton GetIt : au retour sur l'onglet Recherche, il
  /// peut encore porter une recherche (résultats conservés — voulu). On
  /// resynchronise la barre pour éviter « résultats affichés, barre vide ».
  void _syncControllerWithBloc() {
    final blocState = _searchBloc.state;
    final query = switch (blocState) {
      SearchLoading(:final query) => query,
      SearchLoaded(:final query) => query,
      SearchError(:final query) => query,
      _ => '',
    };
    if (query.isNotEmpty) {
      _controller.text = query;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _historyService.loadHistory();
      if (!mounted) return;
      setState(() => _history = history);
    } catch (_) {
      if (!mounted) return;
      setState(() => _history = const []);
    }
  }

  /// Enregistre une recherche VALIDÉE (clavier, résultat ouvert, terme
  /// repris de l'historique). La recherche automatique après une pause de
  /// frappe n'y passe jamais.
  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final updated = await _historyService.addSearch(query);
    if (!mounted) return;
    setState(() => _history = updated);
  }

  Future<void> _removeFromHistory(String term) async {
    if (!mounted) return;
    final updated = _history.where((q) => q != term).toList();
    setState(() => _history = updated);
    try {
      await _historyService.removeSearch(term);
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  Future<void> _clearHistory() async {
    if (!mounted) return;
    setState(() => _history = const []);
    try {
      await _historyService.clearHistory();
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  void _onQueryChanged(String value) {
    setState(() {}); // re-render barre (border rouge / bouton clear)
    if (value.isEmpty) {
      _debounce?.cancel();
      _searchBloc.add(const SearchCleared());
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _runSearch);
  }

  /// Recherche automatique (pause de frappe, réessai) : n'enregistre rien.
  void _runSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _searchBloc.add(SearchRequested(query));
  }

  /// Validation au clavier : recherche immédiate + historique.
  void _onSubmitted(String _) {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    final current = _searchBloc.state;
    final alreadyShown =
        (current is SearchLoaded && current.query == query) ||
        (current is SearchLoading && current.query == query);
    if (!alreadyShown) _runSearch();
    _addToHistory(query);
  }

  /// Une pastille de genre ouvre la page « œuvres du genre » (catalogue
  /// filtré par genre, trié par note, défilement infini).
  void _openGenre(String genre) {
    context.push(
      '/home/section/${Uri.encodeComponent('genre:$genre')}',
      extra: HomeSectionExtras(
        kind: HomeSectionKind.genre,
        params: HomeSectionParams(genre: genre),
      ),
    );
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    _searchBloc.add(const SearchCleared());
    setState(() {}); // re-render barre
  }

  void _selectTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _debounce?.cancel();
    setState(() {}); // re-render barre
    _runSearch();
    _addToHistory(term);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg =
        brightness == Brightness.dark
            ? AppColors.dsBgDark
            : AppColors.dsBgLight;
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      // Responsive (audit 2026-06-12) : breakpoint local 1200/720 remplacé
      // par le wrapper unifié AppContentWidth (contenu centré, max 1100).
      body: SafeArea(
        bottom: false,
        child: AppContentWidth(
          child: BlocProvider<SearchBloc>.value(
            value: _searchBloc,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SearchHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.m,
                    0,
                    AppSpacing.m,
                    22,
                  ),
                  child: SearchBarInput(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    onClear: _clearQuery,
                    onSubmitted: _onSubmitted,
                  ),
                ),
                Expanded(
                  child: BlocBuilder<SearchBloc, SearchState>(
                    builder:
                        (context, state) => switch (state) {
                          SearchLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          SearchLoaded() => SearchResultsList(
                            state: state,
                            onResultOpened: _addToHistory,
                          ),
                          SearchError() => _SearchErrorView(
                            state: state,
                            onRetry: _runSearch,
                          ),
                          _ => _BrowseContent(
                            history: _history,
                            genres: _popularGenres,
                            onSelectTerm: _selectTerm,
                            onSelectGenre: _openGenre,
                            onRemoveTerm: _removeFromHistory,
                            onClearHistory: _clearHistory,
                          ),
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mode "browse" : historique de recherche + genres populaires.
class _BrowseContent extends StatelessWidget {
  final List<String> history;
  final List<String> genres;
  final ValueChanged<String> onSelectTerm;
  final ValueChanged<String> onSelectGenre;
  final ValueChanged<String> onRemoveTerm;
  final VoidCallback onClearHistory;

  const _BrowseContent({
    required this.history,
    required this.genres,
    required this.onSelectTerm,
    required this.onSelectGenre,
    required this.onRemoveTerm,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchHistoryHeader(
            canClear: history.isNotEmpty,
            onClearAll: onClearHistory,
          ),
          SearchHistoryList(
            history: history,
            onSelect: onSelectTerm,
            onRemove: onRemoveTerm,
          ),
          PopularGenresWrap(genres: genres, onSelectGenre: onSelectGenre),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}

/// Erreur de recherche (page 1) : message réseau ou générique + Retry.
class _SearchErrorView extends StatelessWidget {
  final SearchError state;
  final VoidCallback onRetry;

  const _SearchErrorView({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppErrorState(
      message:
          state.isOffline
              ? (l10n?.networkError ??
                  'Veuillez vérifier votre connexion internet')
              : (l10n?.searchLoadFailed ?? 'La recherche a échoué'),
      retryLabel: l10n?.retry,
      onRetry: onRetry,
    );
  }
}
