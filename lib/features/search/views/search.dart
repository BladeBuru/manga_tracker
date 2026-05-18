import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/home/widgets/homepage_manga_list.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/search/services/search_history.service.dart';
import 'package:mangatracker/features/search/widgets/popular_genres_wrap.dart';
import 'package:mangatracker/features/search/widgets/search_bar_input.dart';
import 'package:mangatracker/features/search/widgets/search_header.dart';
import 'package:mangatracker/features/search/widgets/search_history_list.dart';

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
/// Mode résultats : titre + barre + liste de résultats (HomepageMangaList).
class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final MangaService _mangaService = getIt<MangaService>();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  Future<List<MangaQuickViewDto>>? _searchedMangas;
  String _activeQuery = '';
  List<String> _history = const [];

  // Genres populaires — hardcodés (correspondent au design source).
  // Ne sont pas traduits : ce sont des termes de recherche manga universels.
  static const List<String> _popularGenres = [
    'Shounen',
    'Seinen',
    'Romance',
    'Action',
    'Aventure',
    'Drama',
    'Fantasy',
    'Sci-Fi',
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
  }

  @override
  void dispose() {
    _historyService.saveHistory(_history);
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

  Future<void> _addToHistory(String query) async {
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
      setState(() {
        _searchedMangas = null;
        _activeQuery = '';
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 800),
      _runSearch,
    );
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    await _addToHistory(query);
    if (!mounted) return;
    setState(() {
      _activeQuery = query;
      _searchedMangas = _mangaService.searchForMangas(query);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _searchedMangas = null;
      _activeQuery = '';
    });
  }

  void _selectTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _debounce?.cancel();
    setState(() {}); // re-render barre
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? AppColors.dsBgDark
        : AppColors.dsBgLight;
    final hasResults = _searchedMangas != null && _activeQuery.isNotEmpty;
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1200;
            final content = _BrowseOrResults(
              hasResults: hasResults,
              searchedMangas: _searchedMangas,
              activeQuery: _activeQuery,
              controller: _controller,
              history: _history,
              genres: _popularGenres,
              onQueryChanged: _onQueryChanged,
              onClearQuery: _clearQuery,
              onSelectTerm: _selectTerm,
              onRemoveTerm: _removeFromHistory,
              onClearHistory: _clearHistory,
              onSelectGenre: _selectTerm,
            );
            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: content,
                ),
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}

/// Switcher entre le mode "browse" (historique + genres) et "results"
/// (liste de mangas matching la query). Conserve la barre de recherche
/// + le titre dans les deux cas.
class _BrowseOrResults extends StatelessWidget {
  final bool hasResults;
  final Future<List<MangaQuickViewDto>>? searchedMangas;
  final String activeQuery;
  final TextEditingController controller;
  final List<String> history;
  final List<String> genres;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String> onSelectTerm;
  final ValueChanged<String> onRemoveTerm;
  final VoidCallback onClearHistory;
  final ValueChanged<String> onSelectGenre;

  const _BrowseOrResults({
    required this.hasResults,
    required this.searchedMangas,
    required this.activeQuery,
    required this.controller,
    required this.history,
    required this.genres,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSelectTerm,
    required this.onRemoveTerm,
    required this.onClearHistory,
    required this.onSelectGenre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            controller: controller,
            onChanged: onQueryChanged,
            onClear: onClearQuery,
          ),
        ),
        if (hasResults)
          Expanded(
            child: HomepageMangaList(
              mangas: searchedMangas!,
              searchQuery: activeQuery,
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
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
                  PopularGenresWrap(
                    genres: genres,
                    onSelectGenre: onSelectGenre,
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
