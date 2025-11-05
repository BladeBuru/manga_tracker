import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/components/search_bar.dart' show CustomSearchBar;
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/bloc/library_state.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import '../../auth/views/login.view.dart';
import '../../manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vue réactive de la bibliothèque utilisant BLoC
class LibraryBlocView extends StatefulWidget {
  const LibraryBlocView({super.key});

  @override
  State<LibraryBlocView> createState() => _LibraryBlocViewState();
}

class _LibraryBlocViewState extends State<LibraryBlocView> {
  final LibraryBloc _libraryBloc = getIt<LibraryBloc>();
  final TextEditingController _searchController = TextEditingController();
  final Map<ReadingStatus, bool> _isExpanded = {
    ReadingStatus.reading: true,
    ReadingStatus.readLater: true,
    ReadingStatus.caughtUp: true,
    ReadingStatus.completed: true,
  };
  bool _isCardView = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint('📚 LibraryBlocView initialisée - Utilisation du BLoC !');
    // Charger la bibliothèque au démarrage
    _libraryBloc.add(const LoadLibrary());
    _searchController.addListener(_onSearchChanged);
    _loadViewState();
  }

  Future<void> _loadViewState() async {
    final prefs = await SharedPreferences.getInstance();
    final isCardView = prefs.getBool('library_view_mode') ?? false;
    setState(() {
      _isCardView = isCardView;
    });
  }

  Future<void> _saveViewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('library_view_mode', _isCardView);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  /// Calcule le score de pertinence d'un manga pour une recherche
  int _calculateMatchScore(MangaQuickViewDto manga, String query) {
    if (query.isEmpty) return 0;
    
    final queryLower = query.toLowerCase();
    int maxScore = 0;
    
    // Score pour le titre principal
    final titleLower = manga.title.toLowerCase();
    if (titleLower == queryLower) {
      maxScore = 1000; // Correspondance exacte
    } else if (titleLower.startsWith(queryLower)) {
      maxScore = 500; // Commence par la recherche
    } else if (titleLower.contains(queryLower)) {
      maxScore = 100; // Contient la recherche
    }
    
    // Score pour les noms associés
    if (manga.associated != null) {
      for (final name in manga.associated!) {
        final nameLower = name.toLowerCase();
        int score = 0;
        if (nameLower == queryLower) {
          score = 900; // Correspondance exacte dans nom associé
        } else if (nameLower.startsWith(queryLower)) {
          score = 450; // Commence par la recherche
        } else if (nameLower.contains(queryLower)) {
          score = 90; // Contient la recherche
        }
        if (score > maxScore) {
          maxScore = score;
        }
      }
    }
    
    return maxScore;
  }

  List<MangaQuickViewDto> _filterMangas(List<MangaQuickViewDto> mangas) {
    if (_searchQuery.isEmpty) {
      return mangas;
    }
    
    // Filtrer et calculer les scores
    final filtered = mangas.map((manga) {
      final titleMatch = manga.title.toLowerCase().contains(_searchQuery);
      final associatedMatch = manga.associated?.any((name) => 
        name.toLowerCase().contains(_searchQuery)
      ) ?? false;
      
      if (titleMatch || associatedMatch) {
        return MapEntry(manga, _calculateMatchScore(manga, _searchQuery));
      }
      return null;
    }).whereType<MapEntry<MangaQuickViewDto, int>>().toList();
    
    // Trier par score décroissant
    filtered.sort((a, b) => b.value.compareTo(a.value));
    
    return filtered.map((e) => e.key).toList();
  }

  /// Trouve le nom associé qui correspond à la recherche, ou retourne le titre
  String _getDisplayName(MangaQuickViewDto manga) {
    if (_searchQuery.isEmpty) {
      return manga.title;
    }
    
    final queryLower = _searchQuery.toLowerCase();
    final titleLower = manga.title.toLowerCase();
    
    // Si le titre correspond, on l'utilise
    if (titleLower.contains(queryLower)) {
      return manga.title;
    }
    
    // Sinon, chercher dans les noms associés
    if (manga.associated != null) {
      for (final name in manga.associated!) {
        final nameLower = name.toLowerCase();
        if (nameLower.contains(queryLower)) {
          return name; // Retourner le nom associé qui match
        }
      }
    }
    
    // Par défaut, retourner le titre
    return manga.title;
  }

  /// Groupe les mangas par statut et les trie par pertinence dans chaque groupe
  Map<ReadingStatus, List<MangaQuickViewDto>> _groupAndSortByStatus(List<MangaQuickViewDto> mangas) {
    final grouped = <ReadingStatus, List<MangaQuickViewDto>>{};
    
    for (var status in ReadingStatus.values) {
      final statusMangas = mangas.where((m) => m.readingStatus == status).toList();
      
      // Trier par score de pertinence si recherche active
      if (_searchQuery.isNotEmpty) {
        statusMangas.sort((a, b) {
          final scoreA = _calculateMatchScore(a, _searchQuery);
          final scoreB = _calculateMatchScore(b, _searchQuery);
          return scoreB.compareTo(scoreA);
        });
      }
      
      if (statusMangas.isNotEmpty) {
        grouped[status] = statusMangas;
      }
    }
    
    return grouped;
  }

  void _redirectToLoginPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.library ?? 'Ma Bibliothèque');
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isCardView ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _isCardView = !_isCardView;
              });
              _saveViewState();
            },
            tooltip: _isCardView ? 'Vue liste' : 'Vue carte',
          ),
        ],
      ),
      body: BlocConsumer<LibraryBloc, LibraryState>(
        bloc: _libraryBloc,
        listener: (context, state) {
          // Gérer les erreurs d'authentification
          if (state is LibraryError) {
            if (state.message.contains('InvalidCredentials') || 
                state.message.contains('Expired session')) {
              _redirectToLoginPage();
            }
          }
        },
        builder: (context, state) {
          return _buildBody(state);
        },
      ),
    );
  }

  Widget _buildBody(LibraryState state) {
    if (state is LibraryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is LibraryError) {
      return _buildErrorState(state);
    }
    
    if (state is LibraryLoaded) {
      return _buildLibraryContent(state);
    }
    
    if (state is LibraryActionInProgress) {
      return _buildActionInProgress(state);
    }
    
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Center(child: Text(l10n?.error ?? 'État inconnu'));
      },
    );
  }

  Widget _buildErrorState(LibraryError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.isOffline ? Icons.cloud_off : Icons.error,
            size: 64,
            color: state.isOffline ? Colors.orange : Colors.red,
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                state.isOffline 
                    ? (l10n?.offlineModeNoCache ?? 'Mode hors ligne - Aucune donnée en cache')
                    : '${l10n?.error ?? "Erreur"}: ${state.message}',
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return ElevatedButton(
                onPressed: () => _libraryBloc.add(const LoadLibrary()),
                child: Text(l10n?.retry ?? 'Réessayer'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionInProgress(LibraryActionInProgress state) {
    final filteredMangas = _filterMangas(state.mangas);
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
            controller: _searchController,
            onChanged: (value) {},
          ),
        ),
        // Indicateur de mode hors ligne
        if (state.isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.offlineModeActionQueued ?? 'Mode hors ligne - Action en queue',
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        
        // Indicateur d'action en cours
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.action,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        
        // Contenu de la bibliothèque
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _libraryBloc.add(const RefreshLibrary());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: _isCardView 
                ? _buildLibraryGrid(filteredMangas)
                : _buildLibraryList(filteredMangas),
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryContent(LibraryLoaded state) {
    // Debug : afficher l'état offline
    debugPrint('📚 LibraryBlocView: isOffline=${state.isOffline}, pendingActions=${state.pendingActions}, mangas=${state.mangas.length}');
    
    final filteredMangas = _filterMangas(state.mangas);
    
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
            controller: _searchController,
            onChanged: (value) {},
          ),
        ),
        // Indicateur de mode hors ligne
        if (state.isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      final offlineText = state.pendingActions > 0
                          ? l10n?.pendingActions(state.pendingActions) ?? 'Mode hors ligne - Données en cache (${state.pendingActions} actions en attente)'
                          : l10n?.offlineModeCached ?? 'Mode hors ligne - Données en cache';
                      return Text(
                        offlineText,
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        
        // Liste de la bibliothèque
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _libraryBloc.add(const RefreshLibrary());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: _isCardView 
                ? _buildLibraryGrid(filteredMangas)
                : _buildLibraryList(filteredMangas),
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryList(List<MangaQuickViewDto> mangas) {
    if (mangas.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.noData ?? "Aucun résultat trouvé.");
          },
        ),
      );
    }

    final groupedMangas = _groupAndSortByStatus(mangas);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: groupedMangas.entries.map((entry) {
        final status = entry.key;
        final items = entry.value;
        final isExpanded = _isExpanded[status] ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Builder(
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    status.getLabel(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (value) {
              setState(() {
                _isExpanded[status] = value;
              });
            },
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            childrenPadding: EdgeInsets.zero,
            children: items.map((manga) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: MangaRow(
                    muId: manga.muId.toString(),
                    mangaName: _getDisplayName(manga),
                    mangaAuthor: manga.year,
                    lastChapter: manga.totalChapters,
                    readChapter: manga.readChapters,
                    mediumImgPath: manga.mediumCoverUrl,
                    rating: manga.rating,
                    onDetailReturn: () => _libraryBloc.add(const RefreshLibrary()),
                  ),
                )).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLibraryGrid(List<MangaQuickViewDto> mangas) {
    if (mangas.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.noData ?? "Aucun résultat trouvé.");
          },
        ),
      );
    }

    final groupedMangas = _groupAndSortByStatus(mangas);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: groupedMangas.entries.map((entry) {
        final status = entry.key;
        final items = entry.value;
        final isExpanded = _isExpanded[status] ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Builder(
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    status.getLabel(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (value) {
              setState(() {
                _isExpanded[status] = value;
              });
            },
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            childrenPadding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.52,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final manga = items[index];
                    return MangaCard(
                      muId: manga.muId.toString(),
                      mangaTitle: _getDisplayName(manga),
                      mangaAuthor: manga.year,
                      mediumImgPath: manga.mediumCoverUrl,
                      rating: manga.rating,
                      lastChapter: manga.totalChapters,
                      readChapter: manga.readChapters,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
