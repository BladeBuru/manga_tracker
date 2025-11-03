import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/core/services/connectivity_service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import '../../auth/exceptions/invalid_credentials.exception.dart';
import '../../auth/views/login.view.dart';
import '../../manga/dto/manga_quick_view.dto.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  late Future<List<MangaQuickViewDto>> savedMangas;
  bool _isOffline = false;
  final Map<ReadingStatus, bool> _isExpanded = {
    ReadingStatus.reading: true,
    ReadingStatus.readLater: true,
    ReadingStatus.caughtUp: true,
    ReadingStatus.completed: true,
  };

  @override
  void initState() {
    super.initState();
    _loadMangas();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
        // Rafraîchir les données si on revient en ligne
        if (isConnected) {
          _loadMangas();
        }
      }
    });
    
    // Vérifier l'état initial
    _checkInitialConnectivity();
  }
  
  void _checkInitialConnectivity() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  Future<void> _loadMangas() async {
    try {
      setState(() {
        savedMangas = _cacheHelper.loadLibraryData(
          networkCall: () async {
            final libraryService = getIt<LibraryService>();
            return await libraryService.getUserSavedMangas();
          },
        );
      });
    } on InvalidCredentialsException {
      if (context.mounted) {
        redirectToLoginPage();
      }
    } catch (e) {
      // Gérer les erreurs de cache
      if (context.mounted) {
        setState(() {
          savedMangas = Future.error(e);
        });
      }
    }
  }

  void reloadMangas() {
    _loadMangas();
  }

  void redirectToLoginPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Bibliothèque'),
        actions: [
          if (_isOffline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Hors ligne', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<MangaQuickViewDto>>(
        future: savedMangas,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isOffline ? Icons.cloud_off : Icons.error,
                    size: 64,
                    color: _isOffline ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isOffline 
                        ? 'Mode hors ligne - Aucune donnée en cache'
                        : 'Erreur lors du chargement des mangas',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: reloadMangas,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

        final mangas = snapshot.data ?? [];

        final groupedMangas = <ReadingStatus, List<MangaQuickViewDto>>{};
        for (var status in ReadingStatus.values) {
          groupedMangas[status] = mangas.where((m) => m.readingStatus == status).toList();
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Indicateur de mode hors ligne en haut de la liste
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode hors ligne - Données en cache',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8.0),
          ...groupedMangas.entries.map((entry) {
            final status = entry.key;
            final items = entry.value;
            final isExpanded = _isExpanded[status] ?? true;

            return ExpansionTile(
              title: Text(status.label),
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
                   onDetailReturn: reloadMangas
                ),
              )).toList()
                  : [const Padding(padding: EdgeInsets.all(8.0), child: Text("Aucun manga."))],
            );
          }).toList(),
          ],
        );
        },
      ),
    );
  }
}
