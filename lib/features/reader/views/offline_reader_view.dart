import 'package:flutter/material.dart';
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Vue pour lire un chapitre téléchargé hors ligne
class OfflineReaderView extends StatefulWidget {
  final int muId;
  final int chapterNumber;
  final String mangaTitle;

  const OfflineReaderView({
    super.key,
    required this.muId,
    required this.chapterNumber,
    required this.mangaTitle,
  });

  @override
  State<OfflineReaderView> createState() => _OfflineReaderViewState();
}

class _OfflineReaderViewState extends State<OfflineReaderView> {
  final DownloadManagerService _downloadManager = DownloadManagerService();
  DownloadedChapter? _chapter;
  List<DownloadedChapter> _allChapters = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    try {
      final chapters = await _downloadManager.getDownloadedChapters(widget.muId);
      final chapter = chapters.firstWhere(
        (c) => c.chapterNumber == widget.chapterNumber,
        orElse: () => throw Exception('Chapitre non trouvé'),
      );

      setState(() {
        _chapter = chapter;
        _allChapters = chapters.toList()..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  int? _getNextChapterNumber() {
    final currentIndex = _allChapters.indexWhere((c) => c.chapterNumber == widget.chapterNumber);
    if (currentIndex >= 0 && currentIndex < _allChapters.length - 1) {
      return _allChapters[currentIndex + 1].chapterNumber;
    }
    return null;
  }

  int? _getPreviousChapterNumber() {
    final currentIndex = _allChapters.indexWhere((c) => c.chapterNumber == widget.chapterNumber);
    if (currentIndex > 0) {
      return _allChapters[currentIndex - 1].chapterNumber;
    }
    return null;
  }

  void _navigateToChapter(int chapterNumber) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => OfflineReaderView(
          muId: widget.muId,
          chapterNumber: chapterNumber,
          mangaTitle: widget.mangaTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chapitre ${widget.chapterNumber}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chapter == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chapitre ${widget.chapterNumber}'),
        ),
        body: const Center(
          child: Text('Chapitre non trouvé'),
        ),
      );
    }

    // Si on a un fichier HTML, l'afficher dans un WebView
    if (_chapter!.htmlPath != null) {
      final htmlFile = File(_chapter!.htmlPath!);
      if (htmlFile.existsSync()) {
        final nextChapter = _getNextChapterNumber();
        final previousChapter = _getPreviousChapterNumber();
        
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.mangaTitle} - Chapitre ${widget.chapterNumber}'),
            actions: [
              if (previousChapter != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _navigateToChapter(previousChapter),
                  tooltip: 'Chapitre précédent',
                ),
              if (nextChapter != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _navigateToChapter(nextChapter),
                  tooltip: 'Chapitre suivant',
                ),
            ],
          ),
          body: InAppWebView(
            initialData: InAppWebViewInitialData(
              data: htmlFile.readAsStringSync(),
              mimeType: 'text/html',
              encoding: 'utf-8',
              baseUrl: WebUri('file://${htmlFile.parent.path}/'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              mediaPlaybackRequiresUserGesture: false,
              // Désactiver le chargement réseau pour forcer le mode hors ligne
              cacheEnabled: true,
              clearCache: false,
            ),
            // Bloquer toutes les requêtes réseau pour forcer le mode hors ligne
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Autoriser uniquement les URLs file://
              final url = navigationAction.request.url?.toString() ?? '';
              if (url.startsWith('file://')) {
                return NavigationActionPolicy.ALLOW;
              }
              // Bloquer toutes les autres requêtes (http://, https://)
              debugPrint('🚫 Blocage de la requête réseau en mode hors ligne: $url');
              return NavigationActionPolicy.CANCEL;
            },
            // Bloquer les requêtes de ressources (images, CSS, JS) depuis Internet
            androidShouldInterceptRequest: (controller, request) async {
              final url = request.url.toString();
              // Autoriser uniquement les fichiers locaux
              if (url.startsWith('file://')) {
                return null; // Laisser passer les fichiers locaux
              }
              // Bloquer toutes les requêtes réseau
              debugPrint('🚫 Blocage de la ressource réseau en mode hors ligne: $url');
              return WebResourceResponse(
                data: Uint8List(0),
                statusCode: 403,
                reasonPhrase: 'Blocked - Offline Mode',
                headers: {'Content-Type': 'text/plain'},
              );
            },
          ),
        );
      }
    }

    // Fallback: afficher les images si disponibles
    if (_chapter!.imagePaths.isNotEmpty) {
      final nextChapter = _getNextChapterNumber();
      final previousChapter = _getPreviousChapterNumber();
      
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.mangaTitle} - Chapitre ${widget.chapterNumber}'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_currentImageIndex + 1} / ${_chapter!.imagePaths.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            if (previousChapter != null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _navigateToChapter(previousChapter),
                tooltip: 'Chapitre précédent',
              ),
            if (nextChapter != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _navigateToChapter(nextChapter),
                tooltip: 'Chapitre suivant',
              ),
          ],
        ),
        body: PageView.builder(
          itemCount: _chapter!.imagePaths.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imagePath = _chapter!.imagePaths[index];
            return Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapitre ${widget.chapterNumber}'),
      ),
      body: const Center(
        child: Text('Aucun contenu disponible'),
      ),
    );
  }
}

