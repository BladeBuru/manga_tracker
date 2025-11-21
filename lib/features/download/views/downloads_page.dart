import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/reader/views/offline_reader_view.dart';
import 'package:intl/intl.dart';

/// Page de gestion des téléchargements
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final DownloadManagerService _downloadManager = DownloadManagerService();
  final MangaService _mangaService = getIt<MangaService>();
  Map<int, List<DownloadedChapter>> _downloadedChapters = {};
  Map<int, String> _mangaTitles = {}; // Cache pour les titres de manga
  bool _isLoading = true;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chapters = await _downloadManager.getAllDownloadedChapters();
      final totalSize = await _downloadManager.getTotalDownloadSize();

      // Charger les titres des mangas
      final titles = <int, String>{};
      for (final muId in chapters.keys) {
        try {
          final mangaDetail = await _mangaService.getMangaDetail(muId.toString());
          titles[muId] = mangaDetail.title;
        } catch (e) {
          // Si erreur, utiliser le muId comme fallback
          titles[muId] = 'Manga $muId';
        }
      }

      setState(() {
        _downloadedChapters = chapters;
        _mangaTitles = titles;
        _totalSize = totalSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _deleteChapter(int muId, int chapterNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le chapitre'),
        content: Text('Voulez-vous vraiment supprimer le chapitre $chapterNumber ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadManager.removeDownloadedChapter(muId, chapterNumber);
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapitre supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllChapters(int muId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tous les chapitres'),
        content: const Text('Voulez-vous vraiment supprimer tous les chapitres téléchargés pour ce manga ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadManager.removeAllDownloadedChapters(muId);
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tous les chapitres supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tous les téléchargements'),
        content: const Text('Voulez-vous vraiment supprimer TOUS les téléchargements ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer tout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadManager.removeAllDownloads();
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tous les téléchargements supprimés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléchargements'),
        actions: [
          if (_totalSize > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formatFileSize(_totalSize),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          if (_downloadedChapters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _deleteAllDownloads,
              tooltip: 'Supprimer tous les téléchargements',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedChapters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun chapitre téléchargé',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDownloads,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _downloadedChapters.length,
                    itemBuilder: (context, index) {
                      final entry = _downloadedChapters.entries.elementAt(index);
                      final muId = entry.key;
                      final chapters = entry.value;
                      final mangaTitle = _mangaTitles[muId] ?? 'Manga $muId';
                      final sortedChapters = chapters.toList()..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ExpansionTile(
                          leading: const Icon(Icons.book),
                          title: Text(mangaTitle),
                          subtitle: Text('${chapters.length} chapitre(s) téléchargé(s)'),
                          onExpansionChanged: (expanded) {
                            // Quand on ouvre, ouvrir directement le premier chapitre si c'est depuis la library
                          },
                          children: [
                            ...sortedChapters.map((chapter) => ListTile(
                                  title: Text('Chapitre ${chapter.chapterNumber}'),
                                  subtitle: Text(
                                    DateFormat('dd/MM/yyyy').format(chapter.downloadDate),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) => OfflineReaderView(
                                                muId: muId,
                                                chapterNumber: chapter.chapterNumber,
                                                mangaTitle: mangaTitle,
                                              ),
                                            ),
                                          );
                                        },
                                        tooltip: 'Lire',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteChapter(muId, chapter.chapterNumber),
                                        tooltip: 'Supprimer',
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Ouvrir directement le chapitre au tap
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => OfflineReaderView(
                                          muId: muId,
                                          chapterNumber: chapter.chapterNumber,
                                          mangaTitle: mangaTitle,
                                        ),
                                      ),
                                    );
                                  },
                                )),
                            ListTile(
                              leading: const Icon(Icons.delete_sweep, color: Colors.red),
                              title: const Text(
                                'Supprimer tous les chapitres',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () => _deleteAllChapters(muId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

