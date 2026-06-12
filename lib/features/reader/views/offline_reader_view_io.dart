import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/features/reader/utils/reading_progress_helper.dart';

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
  final LibraryService _libraryService = getIt<LibraryService>();
  DownloadedChapter? _chapter;
  List<DownloadedChapter> _allChapters = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  InAppWebViewController? _webViewController;
  Timer? _scrollSaveTimer;
  bool _hasSavedProgress = false;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  @override
  void dispose() {
    _scrollSaveTimer?.cancel();
    _saveScrollPosition();
    _saveChapterProgress();
    super.dispose();
  }

  /// Nettoie le HTML pour supprimer toutes les références externes (CSS, JS, fonts, scripts de pub)
  /// Utilise des remplacements de chaînes simples pour éviter les problèmes de regex
  String _cleanHtmlForOffline(String html) {
    // Supprimer les balises <link> externes (CSS, fonts) mais garder les locales
    int startIndex = 0;
    while (true) {
      final linkStart = html.indexOf('<link', startIndex);
      if (linkStart == -1) break;
      
      final linkEnd = html.indexOf('>', linkStart);
      if (linkEnd == -1) break;
      
      final linkTag = html.substring(linkStart, linkEnd + 1);
      if (linkTag.contains('href="http') || linkTag.contains("href='http")) {
        html = html.replaceFirst(linkTag, '');
        startIndex = linkStart;
      } else {
        startIndex = linkEnd + 1;
      }
    }
    
    // Supprimer les balises <script> externes
    startIndex = 0;
    while (true) {
      final scriptStart = html.indexOf('<script', startIndex);
      if (scriptStart == -1) break;
      
      final scriptEnd = html.indexOf('</script>', scriptStart);
      if (scriptEnd == -1) break;
      
      final scriptTag = html.substring(scriptStart, scriptEnd + 9);
      if (scriptTag.contains('src="http') || 
          scriptTag.contains("src='http") ||
          scriptTag.contains('https://') ||
          scriptTag.contains('http://') ||
          scriptTag.contains('goomaphy') ||
          scriptTag.contains('tzegilo') ||
          scriptTag.contains('rlcdn') ||
          scriptTag.contains('ohffs')) {
        html = html.replaceFirst(scriptTag, '');
        startIndex = scriptStart;
      } else {
        startIndex = scriptEnd + 9;
      }
    }
    
    // Supprimer les balises <iframe> externes
    startIndex = 0;
    while (true) {
      final iframeStart = html.indexOf('<iframe', startIndex);
      if (iframeStart == -1) break;
      
      final iframeEnd = html.indexOf('</iframe>', iframeStart);
      if (iframeEnd == -1) break;
      
      final iframeTag = html.substring(iframeStart, iframeEnd + 9);
      if (iframeTag.contains('src="http') || iframeTag.contains("src='http")) {
        html = html.replaceFirst(iframeTag, '');
        startIndex = iframeStart;
      } else {
        startIndex = iframeEnd + 9;
      }
    }
    
    // Supprimer les @import dans les styles
    html = html.replaceAll('@import url("http', '/* blocked */');
    html = html.replaceAll("@import url('http", '/* blocked */');
    html = html.replaceAll('@import url(http', '/* blocked */');
    
    // S'assurer qu'il y a une meta viewport simple (comme le ReaderWebView en ligne)
    final viewportIndex = html.indexOf('<meta name="viewport"');
    if (viewportIndex == -1) {
      // Si pas de meta viewport, l'ajouter dans le <head>
      final headIndex = html.indexOf('<head>');
      if (headIndex != -1) {
        final headEnd = html.indexOf('>', headIndex);
        html = html.substring(0, headEnd + 1) + 
               '\n<meta name="viewport" content="width=device-width, initial-scale=1">' +
               html.substring(headEnd + 1);
      }
    } else {
      // La meta viewport existe - la REMPLACER par une version simple
      final viewportEnd = html.indexOf('>', viewportIndex);
      if (viewportEnd != -1) {
        html = html.substring(0, viewportIndex) +
               '<meta name="viewport" content="width=device-width, initial-scale=1">' +
               html.substring(viewportEnd + 1);
      }
    }
    
    // S'assurer que les images et le contenu sont responsives (pas de largeur fixe)
    // Injecter du CSS pour forcer la responsivité
    final styleIndex = html.indexOf('</head>');
    if (styleIndex != -1) {
      final responsiveStyle = '''
<style>
  img {
    max-width: 100% !important;
    height: auto !important;
    width: auto !important;
  }
  body {
    max-width: 100% !important;
    width: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
  }
  * {
    box-sizing: border-box;
  }
</style>
''';
      html = html.substring(0, styleIndex) + responsiveStyle + html.substring(styleIndex);
    }
    return html;
  }



  /// Sauvegarde la progression de lecture du chapitre UNIQUEMENT si l'utilisateur est proche de la fin
  Future<void> _saveChapterProgress() async {
    if (_hasSavedProgress) return;
    
    try {
      // Vérifier si l'utilisateur est proche de la fin du chapitre
      final isNearEnd = await ReadingProgressHelper.isNearEndOfChapter(_webViewController);
      
      if (isNearEnd) {
        // Sauvegarder le chapitre actuel comme lu seulement si proche de la fin
        await _libraryService.saveChapterProgress(widget.muId, widget.chapterNumber);
        _hasSavedProgress = true;
        // Journal additif (Stats v2) — fire-and-forget, cf. RETRO-015.
        unawaited(
          _libraryService
              .recordChapterLog(widget.muId,
                  chapterNumber: widget.chapterNumber)
              .then((_) {}, onError: (Object e) {
            debugPrint('⚠️ chapterLog offline: $e');
          }),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la sauvegarde de la progression: $e');
    }
  }

  /// Sauvegarde la position de scroll actuelle
  Future<void> _saveScrollPosition() async {
    if (_webViewController == null || _chapter == null) return;
    
    try {
      final scrollPosition = await ReadingProgressHelper.getScrollPosition(_webViewController);
      
      if (scrollPosition != null && scrollPosition > 0) {
        // Mettre à jour le chapitre avec la nouvelle position de scroll
        final updatedChapter = _chapter!.copyWith(scrollPosition: scrollPosition);
        await _downloadManager.addDownloadedChapter(updatedChapter);
        setState(() {
          _chapter = updatedChapter;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la sauvegarde de la position de scroll: $e');
    }
  }


  /// Restaure la position de scroll sauvegardée
  Future<void> _restoreScrollPosition() async {
    if (_webViewController == null || _chapter == null || _chapter!.scrollPosition == null) return;
    
    final scrollPosition = _chapter!.scrollPosition!;
    if (scrollPosition > 0) {
      await ReadingProgressHelper.restoreScrollPosition(_webViewController, scrollPosition);
    }
  }

  Future<void> _loadChapter() async {
    try {
      final chapters = await _downloadManager.getDownloadedChapters(widget.muId);
      _allChapters = chapters;
      
      final chapter = chapters.firstWhere(
        (c) => c.chapterNumber == widget.chapterNumber,
        orElse: () => chapters.first,
      );
      
      setState(() {
        _chapter = chapter;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('⚠️ Erreur lors du chargement du chapitre: $e');
      setState(() {
        _isLoading = false;
      });
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
    context.pushReplacement(
      '/manga/${widget.muId}/read-offline?chapter=$chapterNumber',
      extra: OfflineReaderExtras(mangaTitle: widget.mangaTitle),
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
        
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            
            // Sauvegarder la position de scroll avant de quitter
            await _saveScrollPosition();
            
            // Vérifier si l'utilisateur est proche de la fin avant de marquer comme terminé
            final isNearEnd = await ReadingProgressHelper.isNearEndOfChapter(_webViewController);
            
            if (!isNearEnd) {
              // Sauvegarder quand même la position de scroll pour la prochaine fois
              // mais ne pas marquer le chapitre comme terminé
              if (mounted) {
                Navigator.of(context).pop();
              }
              return;
            }
            
            // Si proche de la fin, sauvegarder la progression et fermer
            await _saveChapterProgress();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
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
          body: Builder(
            builder: (context) {
              final originalHtml = htmlFile.readAsStringSync();
              final cleanedHtml = _cleanHtmlForOffline(originalHtml);
              
              return InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: cleanedHtml,
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
                  cacheEnabled: true,
                  clearCache: false,
                  // Utiliser les mêmes paramètres que le ReaderWebView en ligne
                  // Pas de paramètres de zoom spécifiques - laisser le WebView gérer naturellement
                ),
                onWebViewCreated: (controller) async {
                  _webViewController = controller;
                },
                onLoadStop: (controller, url) async {
                  // Attendre que le DOM soit prêt
                  await Future.delayed(const Duration(milliseconds: 200));
                  
                  // Restaurer la position de scroll après le chargement
                  await _restoreScrollPosition();
              
              // Configurer la sauvegarde périodique de la position de scroll
              _scrollSaveTimer?.cancel();
              _scrollSaveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
                _saveScrollPosition();
              });
              
              // Ajouter un listener JavaScript pour le scroll
              await controller.evaluateJavascript(source: """
                (function() {
                  let scrollTimeout;
                  window.addEventListener('scroll', function() {
                    clearTimeout(scrollTimeout);
                    scrollTimeout = setTimeout(function() {
                      // La sauvegarde sera faite par le timer Dart
                    }, 100);
                  }, { passive: true });
                })();
              """); 
                },
                // Bloquer toutes les requêtes réseau pour forcer le mode hors ligne
                shouldOverrideUrlLoading: (controller, navigationAction) async {
              // Autoriser uniquement les URLs file://
              final url = navigationAction.request.url?.toString() ?? '';
              if (url.startsWith('file://')) {
                return NavigationActionPolicy.ALLOW;
              }
              // Bloquer toutes les autres requêtes (http://, https://)
              return NavigationActionPolicy.CANCEL;
                },
                // Bloquer les requêtes de ressources (images, CSS, JS) depuis Internet (Android)
                androidShouldInterceptRequest: (controller, request) async {
              final url = request.url.toString();
              // Autoriser uniquement les fichiers locaux
              if (url.startsWith('file://')) {
                return null; // Laisser passer les fichiers locaux
              }
              // Bloquer TOUTES les requêtes réseau, même si elles sont dans le cache
              // Cela empêche les scripts de pub et autres ressources externes de se charger
              return WebResourceResponse(
                data: Uint8List(0),
                statusCode: 403,
                reasonPhrase: 'Blocked - Offline Mode',
                headers: {'Content-Type': 'text/plain'},
              );
                },
                // Note: shouldOverrideUrlLoading gère déjà les navigations principales pour iOS et Android
                // androidShouldInterceptRequest gère les ressources pour Android
                // Pour iOS, shouldOverrideUrlLoading devrait suffire, mais on peut aussi injecter du JavaScript
                // pour bloquer les requêtes réseau au niveau du DOM
              );
            },
          ),
          ),
        );
      }
    }

    // Fallback: afficher les images si disponibles
    if (_chapter!.imagePaths.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.mangaTitle} - Chapitre ${widget.chapterNumber}'),
        ),
        body: PageView.builder(
          itemCount: _chapter!.imagePaths.length,
          controller: PageController(initialPage: _currentImageIndex),
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final imagePath = _chapter!.imagePaths[index];
            return Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
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
