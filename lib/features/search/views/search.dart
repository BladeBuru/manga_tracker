import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/components/search_bar.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../home/widgets/homepage_manga_list.dart';
import '../../manga/dto/manga_quick_view.dto.dart';
import '../../manga/services/manga.service.dart';
import '../services/search_history.service.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _RechercheState();
}

class _RechercheState extends State<Search> {
  get border => null;
  final MangaService mangaService = getIt<MangaService>();
  SearchHistoryService get _historyService {
    try {
      return getIt<SearchHistoryService>();
    } catch (e) {
      // Si le service n'est pas encore enregistré, créer une instance directement
      return SearchHistoryService();
    }
  }
  late Future<List<MangaQuickViewDto>> searchedMangas;
  final searchController = TextEditingController();
  Timer? searchOnStoppedTyping;
  final Color themePage = const Color(0xffe0234f);
  int indexButtonBar = 0;
  List<String> _searchHistory = [];
  bool _isLoadingHistory = true;
  
  late Widget childWidget = Builder(
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return _buildEmptyState(l10n);
    },
  );
  
  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }
  
  @override
  void dispose() {
    // Sauvegarder l'historique avant de quitter
    _historyService.saveHistory(_searchHistory);
    searchController.dispose();
    searchOnStoppedTyping?.cancel();
    super.dispose();
  }
  
  Future<void> _loadSearchHistory() async {
    try {
      final history = await _historyService.loadHistory();
      if (mounted) {
        setState(() {
          _searchHistory = history;
          _isLoadingHistory = false;
          // Reconstruire le widget avec l'historique chargé
          final l10n = AppLocalizations.of(context);
          childWidget = _buildEmptyState(l10n);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchHistory = [];
          _isLoadingHistory = false;
          final l10n = AppLocalizations.of(context);
          childWidget = _buildEmptyState(l10n);
        });
      }
    }
  }
  
  Future<void> _addToHistory(String query) async {
    final updatedHistory = await _historyService.addSearch(query);
    if (mounted) {
      setState(() {
        _searchHistory = updatedHistory;
        // Reconstruire le widget si on est en mode historique (pas de recherche active)
        if (searchController.text.isEmpty) {
          final l10n = AppLocalizations.of(context);
          childWidget = _buildEmptyState(l10n);
        }
      });
    }
  }
  
  Future<void> _removeFromHistory(String query) async {
    if (!mounted) return;
    
    // Créer une nouvelle liste pour forcer le rebuild
    final updatedHistory = _searchHistory.where((q) => q != query).toList();
    
    // Mise à jour immédiate de l'UI
    setState(() {
      _searchHistory = updatedHistory;
      // Reconstruire le widget avec l'historique mis à jour
      final l10n = AppLocalizations.of(context);
      childWidget = _buildEmptyState(l10n);
    });
    
    // Sauvegarde en arrière-plan
    try {
      await _historyService.removeSearch(query);
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }
  
  Future<void> _clearSearchHistory() async {
    if (!mounted) return;
    
    // Supprimer immédiatement de la liste locale
    setState(() {
      _searchHistory = [];
      // Reconstruire le widget avec l'historique vidé
      final l10n = AppLocalizations.of(context);
      childWidget = _buildEmptyState(l10n);
    });
    // Puis sauvegarder
    try {
      await _historyService.clearHistory();
    } catch (e) {
      // Ignorer les erreurs de sauvegarde
    }
  }
  
  Widget _buildEmptyState(AppLocalizations? l10n) {
    if (_isLoadingHistory) {
      // Afficher un état par défaut au lieu d'un spinner pour éviter le flash
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noData ?? "Rien à afficher pour le moment !",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noData ?? "Rien à afficher pour le moment !",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.searchEmptyStateMessage ?? 'Recherchez un manga, manhwa ou manhua',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.searchHistoryTitle ?? 'Historique de recherche',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: Text(
                  l10n?.clear ?? 'Effacer',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: ValueKey(_searchHistory.length), // Force le rebuild quand la liste change
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                key: ValueKey('history_$query'), // Clé unique pour chaque élément
                leading: Icon(
                  Icons.history,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(query),
                onTap: () {
                  searchController.text = query;
                  _onChangeHandler(query);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _removeFromHistory(query),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              );
            },
          ),
        ),
      ],
    );
  }

  void doSearchManga() async {
    if (searchController.text.isEmpty) {
      setState(() {
        final l10n = AppLocalizations.of(context);
        childWidget = _buildEmptyState(l10n);
      });
      return;
    }
    await _addToHistory(searchController.text);
    searchedMangas = mangaService.searchForMangas(searchController.text);
    setState(() {
      childWidget = HomepageMangaList(mangas: searchedMangas);
    });
  }

  _onChangeHandler(String value) {
    if (value.isEmpty) {
      setState(() {
        final l10n = AppLocalizations.of(context);
        childWidget = _buildEmptyState(l10n);
      });
      return;
    }
    const duration = Duration(milliseconds: 800);
    if (searchOnStoppedTyping != null) {
      searchOnStoppedTyping?.cancel();
    }
    searchOnStoppedTyping = Timer(duration, () => doSearchManga());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            //Espace en haut
            const SizedBox(height: 80),

            // Search bar harmonisée
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: CustomSearchBar(
                controller: searchController,
                onChanged: _onChangeHandler,
                showLogo: true,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(child: SizedBox(child: childWidget)),
          ],
        ),
      ),
    );
  }
}
