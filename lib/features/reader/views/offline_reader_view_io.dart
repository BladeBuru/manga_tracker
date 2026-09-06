import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/library/services/chapter_log.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mangatracker/features/reader/utils/reading_progress_helper.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';
import 'package:mangatracker/features/reader/utils/offline_html_sanitizer.dart';
import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';
import 'package:mangatracker/features/reader/widgets/chapter_completion_dialog.dart';

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

class _OfflineReaderViewState extends State<OfflineReaderView>
    with WidgetsBindingObserver {
  final DownloadManagerService _downloadManager = DownloadManagerService();
  final LibraryService _libraryService = getIt<LibraryService>();
  final ChapterLogService _chapterLogService = getIt<ChapterLogService>();
  DownloadedChapter? _chapter;
  List<DownloadedChapter> _allChapters = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  InAppWebViewController? _webViewController;
  Timer? _scrollSaveTimer;
  bool _hasSavedProgress = false;

  // Même politique que le lecteur en ligne : « chapitres lus » = dernier
  // chapitre TERMINÉ. Arriver sur un chapitre ne le marque jamais comme lu.
  static const _commitPolicy = ChapterCommitPolicy();

  // Garde de réentrance : un double appui sur « retour » ne doit pas empiler
  // deux modales de fin de chapitre.
  bool _exitFlowRunning = false;

  @override
  void initState() {
    super.initState();
    // Cycle de vie : sauvegarder la position quand l'app passe en
    // arrière-plan, sinon la lecture reprend au dernier tick du timer.
    WidgetsBinding.instance.addObserver(this);
    _loadChapter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollSaveTimer?.cancel();
    _saveScrollPosition();
    // NE PLUS enregistrer le chapitre ici : `dispose()` ne peut rien
    // demander à l'utilisateur, et un chapitre atteint à 85 % n'est pas un
    // chapitre fini. La question est posée par la modale de sortie
    // (`_handleExitRequest`), comme dans le lecteur en ligne.
    super.dispose();
  }

  /// Sauvegarde la position de lecture quand l'app passe en arrière-plan.
  /// Aucun chapitre n'est enregistré en silence : passer en arrière-plan ne
  /// prouve pas qu'un chapitre est terminé.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_saveScrollPosition());
    }
  }




  /// Enregistre [chapter] comme TERMINÉ.
  ///
  /// N'est appelée que sur une affirmation explicite de l'utilisateur (modale
  /// de fin de chapitre) ou sur un passage au chapitre suivant : ce lecteur
  /// enregistrait auparavant en silence dès 85 % de défilement, sans rien
  /// demander — l'utilisateur se retrouvait avec des chapitres « lus » qu'il
  /// n'avait pas finis.
  Future<void> _commitChapter(int chapter) async {
    if (_hasSavedProgress) return;
    try {
      await _libraryService.saveChapterProgress(widget.muId, chapter);
      _hasSavedProgress = true;
      // Journal additif (Stats v2) — fire-and-forget, cf. RETRO-015.
      unawaited(
        _chapterLogService
            .recordChapterLog(widget.muId, chapterNumber: chapter)
            .then((_) {}, onError: (Object e) {
          debugPrint('⚠️ chapterLog offline: $e');
        }),
      );
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la sauvegarde de la progression: $e');
    }
  }

  /// Mesure « suis-je proche de la fin ? » bornée dans le temps, pour qu'un
  /// retour ne paraisse jamais figé si la page ne répond pas.
  Future<bool> _isNearEndOfChapter() async {
    try {
      return await ReadingProgressHelper.isNearEndOfChapter(_webViewController)
          .timeout(kNearEndMeasureTimeout, onTimeout: () => false);
    } catch (e) {
      debugPrint('⚠️ Mesure de fin de chapitre impossible: $e');
      return false;
    }
  }

  /// Sortie du lecteur : même comportement que le lecteur en ligne — on
  /// sauvegarde la position, puis on demande « Avez-vous fini le chapitre
  /// N ? » si la lecture est proche de la fin. Protégée contre la réentrance.
  Future<void> _handleExitRequest() async {
    if (_exitFlowRunning) return;
    _exitFlowRunning = true;
    try {
      await _saveScrollPosition();

      final exit = _commitPolicy.onExit(
        currentChapter: widget.chapterNumber,
        // Ce lecteur ne connaît pas le pointeur serveur : `_hasSavedProgress`
        // suffit à ne pas reposer la question deux fois dans la même session.
        lastCommitted: _hasSavedProgress ? widget.chapterNumber : 0,
        isNearEnd: await _isNearEndOfChapter(),
      );

      final chapter = exit.askUserToCommitChapter;
      if (chapter != null && mounted) {
        final answer =
            await ChapterCompletionDialog.show(context, chapter: chapter);
        if (_commitPolicy.resolveAnswer(answer: answer, chapter: chapter) !=
            null) {
          await _commitChapter(chapter);
        }
      }
    } finally {
      _exitFlowRunning = false;
      if (mounted) Navigator.of(context).pop();
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

  /// Navigation entre chapitres téléchargés.
  ///
  /// `pushReplacement` contourne la modale de sortie : c'est voulu, la
  /// question serait redondante. La règle de progression est appliquée ici
  /// par la même politique — passer au chapitre SUIVANT enregistre le
  /// chapitre courant (on vient de le finir) ; revenir en arrière ou sauter
  /// n'enregistre rien.
  Future<void> _navigateToChapter(int chapterNumber) async {
    final decision = _commitPolicy.onTransition(
      transition: chapterNumber == widget.chapterNumber + 1
          ? ChapterTransition.nextChapter
          : ChapterTransition.jumpBackward,
      newChapter: chapterNumber,
      previousChapter: widget.chapterNumber,
    );
    await _saveScrollPosition();
    final commit = decision.commitChapter;
    if (commit != null) {
      await _commitChapter(commit);
    }
    if (!mounted) return;
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
          title: Text(
              '${AppLocalizations.of(context)?.chapter ?? 'Chapitre'} ${widget.chapterNumber}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_chapter == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              '${AppLocalizations.of(context)?.chapter ?? 'Chapitre'} ${widget.chapterNumber}'),
        ),
        body: Center(
          child: Text(AppLocalizations.of(context)?.chapterNotFound ??
              'Chapitre non trouvé'),
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
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            unawaited(_handleExitRequest());
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  '${widget.mangaTitle} - ${AppLocalizations.of(context)?.chapter ?? 'Chapitre'} ${widget.chapterNumber}'),
            actions: [
              if (previousChapter != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _navigateToChapter(previousChapter),
                  tooltip: AppLocalizations.of(context)?.previousChapterTooltip ??
                      'Chapitre précédent',
                ),
              if (nextChapter != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _navigateToChapter(nextChapter),
                  tooltip: AppLocalizations.of(context)?.nextChapterTooltip ??
                      'Chapitre suivant',
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              final originalHtml = htmlFile.readAsStringSync();
              final cleanedHtml = OfflineHtmlSanitizer.sanitize(originalHtml);
              
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
          title: Text('${widget.mangaTitle} - '
              '${AppLocalizations.of(context)?.chapter ?? 'Chapitre'} '
              '${widget.chapterNumber}'),
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
        title: Text(
            '${AppLocalizations.of(context)?.chapter ?? 'Chapitre'} '
            '${widget.chapterNumber}'),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)?.readerNoContentAvailable ??
            'Aucun contenu disponible'),
      ),
    );
  }
}
