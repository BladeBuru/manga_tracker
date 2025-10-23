// EXEMPLE D'INTÉGRATION DU CACHE DANS LES VUES
// Ce fichier montre comment utiliser le CacheHelperService dans les vues existantes

import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/cache_helper_service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/manga_detail.dto.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

/// EXEMPLE : Comment modifier LibraryView pour utiliser le cache
class LibraryViewWithCache extends StatefulWidget {
  const LibraryViewWithCache({super.key});

  @override
  State<LibraryViewWithCache> createState() => _LibraryViewWithCacheState();
}

class _LibraryViewWithCacheState extends State<LibraryViewWithCache> {
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  late Future<List<MangaQuickViewDto>> _mangasFuture;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadMangas();
  }

  Future<void> _loadMangas() async {
    setState(() {
      _mangasFuture = _cacheHelper.loadLibraryData(
        networkCall: () async {
          // Votre appel réseau existant
          final libraryService = getIt<LibraryService>();
          return await libraryService.getUserSavedMangas();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Bibliothèque'),
        actions: [
          if (_isOffline)
            const Icon(Icons.cloud_off, color: Colors.orange),
        ],
      ),
      body: FutureBuilder<List<MangaQuickViewDto>>(
        future: _mangasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  Text('Erreur: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _loadMangas,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final mangas = snapshot.data ?? [];
          return ListView.builder(
            itemCount: mangas.length,
            itemBuilder: (context, index) {
              final manga = mangas[index];
              return ListTile(
                title: Text(manga.title),
                subtitle: Text('${manga.readChapters}/${manga.totalChapters} chapitres'),
                leading: manga.mediumCoverUrl != null
                    ? Image.network(manga.mediumCoverUrl!)
                    : const Icon(Icons.book),
              );
            },
          );
        },
      ),
    );
  }
}

/// EXEMPLE : Comment modifier HomePage pour utiliser le cache
class HomePageWithCache extends StatefulWidget {
  const HomePageWithCache({super.key});

  @override
  State<HomePageWithCache> createState() => _HomePageWithCacheState();
}

class _HomePageWithCacheState extends State<HomePageWithCache> {
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  late Future<List<MangaQuickViewDto>> _mangasFuture;

  @override
  void initState() {
    super.initState();
    _loadHomePageData();
  }

  Future<void> _loadHomePageData() async {
    setState(() {
      _mangasFuture = _cacheHelper.loadHomePageData(
        networkCall: () async {
          // Votre appel réseau existant pour la page d'accueil
          final mangaService = getIt<MangaService>();
          return await mangaService.getPopularMangas(); // Exemple
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: FutureBuilder<List<MangaQuickViewDto>>(
        future: _mangasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  Text('Erreur: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _loadHomePageData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final mangas = snapshot.data ?? [];
          return ListView.builder(
            itemCount: mangas.length,
            itemBuilder: (context, index) {
              final manga = mangas[index];
              return ListTile(
                title: Text(manga.title),
                subtitle: Text(manga.year),
                leading: manga.mediumCoverUrl != null
                    ? Image.network(manga.mediumCoverUrl!)
                    : const Icon(Icons.book),
              );
            },
          );
        },
      ),
    );
  }
}

/// EXEMPLE : Comment modifier Detail pour utiliser le cache
class DetailWithCache extends StatefulWidget {
  final int muId;
  const DetailWithCache({super.key, required this.muId});

  @override
  State<DetailWithCache> createState() => _DetailWithCacheState();
}

class _DetailWithCacheState extends State<DetailWithCache> {
  final CacheHelperService _cacheHelper = getIt<CacheHelperService>();
  late Future<MangaDetailDto> _mangaDetailFuture;

  @override
  void initState() {
    super.initState();
    _loadMangaDetail();
  }

  Future<void> _loadMangaDetail() async {
    setState(() {
      _mangaDetailFuture = _cacheHelper.loadMangaDetail(
        muId: widget.muId,
        networkCall: () async {
          // Votre appel réseau existant
          final mangaService = getIt<MangaService>();
          return await mangaService.getMangaDetail(widget.muId.toString());
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails')),
      body: FutureBuilder<MangaDetailDto>(
        future: _mangaDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  Text('Erreur: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _loadMangaDetail,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final manga = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(manga.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Année: ${manga.year}'),
                Text('Chapitres: ${manga.totalChapters}'),
                if (manga.description != null) ...[
                  const SizedBox(height: 16),
                  Text('Description:', style: Theme.of(context).textTheme.titleMedium),
                  Text(manga.description!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
