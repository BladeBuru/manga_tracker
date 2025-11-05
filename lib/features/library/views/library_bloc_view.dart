import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/bloc/library_state.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import '../../auth/views/login.view.dart';
import '../../manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Vue réactive de la bibliothèque utilisant BLoC
class LibraryBlocView extends StatefulWidget {
  const LibraryBlocView({super.key});

  @override
  State<LibraryBlocView> createState() => _LibraryBlocViewState();
}

class _LibraryBlocViewState extends State<LibraryBlocView> {
  final LibraryBloc _libraryBloc = getIt<LibraryBloc>();
  final Map<ReadingStatus, bool> _isExpanded = {
    ReadingStatus.reading: true,
    ReadingStatus.readLater: true,
    ReadingStatus.caughtUp: true,
    ReadingStatus.completed: true,
  };

  @override
  void initState() {
    super.initState();
    debugPrint('📚 LibraryBlocView initialisée - Utilisation du BLoC !');
    // Charger la bibliothèque au démarrage
    _libraryBloc.add(const LoadLibrary());
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
            icon: const Icon(Icons.refresh),
            onPressed: () => _libraryBloc.add(const RefreshLibrary()),
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
    return Column(
      children: [
        // Indicateur de mode hors ligne
        if (state.isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
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
          child: _buildLibraryList(state.mangas),
        ),
      ],
    );
  }

  Widget _buildLibraryContent(LibraryLoaded state) {
    // Debug : afficher l'état offline
    debugPrint('📚 LibraryBlocView: isOffline=${state.isOffline}, pendingActions=${state.pendingActions}, mangas=${state.mangas.length}');
    
    return Column(
      children: [
        // Indicateur de mode hors ligne
        if (state.isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
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
          child: _buildLibraryList(state.mangas),
        ),
      ],
    );
  }

  Widget _buildLibraryList(List<MangaQuickViewDto> mangas) {
    final groupedMangas = <ReadingStatus, List<MangaQuickViewDto>>{};
    for (var status in ReadingStatus.values) {
      groupedMangas[status] = mangas.where((m) => m.readingStatus == status).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 8.0),
        ...groupedMangas.entries.map((entry) {
          final status = entry.key;
          final items = entry.value;
          final isExpanded = _isExpanded[status] ?? true;

          return Builder(
            builder: (context) {
              return ExpansionTile(
                title: Text(status.getLabel(context)),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (value) {
                  setState(() {
                    _isExpanded[status] = value;
                  });
                },
                children: items.isNotEmpty
                    ? items.map((manga) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: MangaRow(
                            muId: manga.muId.toString(),
                            mangaName: manga.title,
                            mangaAuthor: manga.year,
                            lastChapter: manga.totalChapters,
                            readChapter: manga.readChapters,
                            mediumImgPath: manga.mediumCoverUrl,
                            rating: manga.rating,
                            onDetailReturn: () => _libraryBloc.add(const RefreshLibrary()),
                          ),
                        )).toList()
                    : [
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(l10n?.noData ?? "Aucun manga."),
                            );
                          },
                        ),
                      ],
              );
            },
          );
        }).toList(),
      ],
    );
  }
}
