import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/features/library/services/chapter_log.service.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/download/services/chapter_download_service.dart';
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/custom_selectors.service.dart';
import 'package:mangatracker/features/reader/utils/reading_progress_helper.dart';
import 'package:mangatracker/features/reader/services/scroll_position_service.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';
import 'package:mangatracker/features/reader/services/captcha_detection_service.dart';
import 'package:mangatracker/features/reader/services/challenge_loop_detector.dart';
import 'package:mangatracker/features/reader/services/reader_navigation_policy.dart';
import 'package:mangatracker/features/reader/services/reader_web_view_settings.dart';
import 'package:mangatracker/features/reader/widgets/challenge_escape_dialog.dart';
import 'package:mangatracker/features/reader/widgets/chapter_completion_dialog.dart';
import 'package:mangatracker/features/reader/widgets/chapter_skip_dialog.dart';
import 'package:mangatracker/features/reader/widgets/reader_action_bar.dart';
import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';
import 'package:mangatracker/features/reader/services/webview_navigation_service.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'dart:async';

class ReaderWebView extends StatefulWidget {
  final int muId;
  final String? mangaTitle;
  final int initialLastRead;      // ex. 119
  final String initialUrl;        // ex. URL du 120 si résoluble, sinon baseLink
  final String baseUserLink;      // le lien saisi par l'utilisateur (référence)
  final bool autoDownload;       // Télécharger automatiquement après chargement
  final Function(bool)? onDownloadComplete; // Callback quand le téléchargement est terminé

  const ReaderWebView({
    super.key,
    required this.muId,
    this.mangaTitle,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
    this.autoDownload = false,    // Par défaut false
    this.onDownloadComplete,     // Callback optionnel
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView>
    with WidgetsBindingObserver {
  final _notifier = getIt<Notifier>();
  final _library = getIt<LibraryService>();
  final _chapterLog = getIt<ChapterLogService>();
  final _downloadManager = DownloadManagerService();
  final _scrollPositionService = getIt<ScrollPositionService>();
  final _adBlockerService = getIt<AdBlockerService>();
  final _captchaDetectionService = getIt<CaptchaDetectionService>();
  final _navigationService = getIt<WebViewNavigationService>();

  InAppWebViewController? _controller;
  final TextEditingController _urlTextController = TextEditingController();
  List<ContentBlocker> _cachedBlockers = []; // Cache pour les blockers
  bool _hasRestoredScroll = false; // Indique si la position de scroll a été restaurée

  // État lecteur
  late int _lastCommitted;      // dernier chapitre confirmé en base
  int? _currentChapter;         // chapitre actuellement affiché (détecté)
  late String _originHost;      // domaine d'origine (pour filtrer)
  bool _adBlockerEnabled = true;
  bool _corsBlocked = false;
  bool _interactiveAdBlockMode = false; // Mode interactif pour détecter les pubs
  bool _captchaDetected = false; // Indique si un captcha est détecté
  bool _adBlockerWasEnabled = true; // Mémorise l'état du bloqueur avant désactivation pour captcha

  // Politique d'enregistrement des chapitres lus : PURE et verrouillée par
  // test/features/reader/chapter_commit_policy_test.dart. La vue exécute sa
  // décision, elle ne décide pas.
  static const _commitPolicy = ChapterCommitPolicy();

  // Sérialisation des détections d'URL : `_handleDetected` est appelé jusqu'à
  // trois fois par navigation (shouldOverrideUrlLoading, onLoadStart,
  // onUpdateVisitedHistory). Sans garde, une seule navigation produisait
  // plusieurs PUT, plusieurs notifications et plusieurs entrées de journal, et
  // les transitions étaient reclassées à tort parce que `_currentChapter`
  // n'était mis à jour qu'après plusieurs `await`.
  bool _processingDetection = false;
  Uri? _pendingDetection; // file d'attente de profondeur 1 (la plus récente)
  String? _lastHandledUrl; // idempotence : une URL n'est traitée qu'une fois

  // Garde de réentrance de la sortie : un double appui sur « retour » ne doit
  // pas empiler deux modales de fin de chapitre.
  bool _exitFlowRunning = false;

  // Détection des vérifications anti-robot qui bouclent
  final _loopDetector = ChallengeLoopDetector();
  // Politique anti-redirection : pure, verrouillée par tests. Voir la
  // documentation de ReaderNavigationPolicy avant d'y toucher.
  late final ReaderNavigationPolicy _navigationPolicy;

  // Ad-blocker amélioré avec sélecteurs CSS plus précis
  Future<List<ContentBlocker>> _getBlockers() async {
    return await _adBlockerService.getBlockers(
      enabled: _adBlockerEnabled,
      captchaDetected: _captchaDetected,
    );
  }

  // Script JavaScript pour nettoyer le DOM des publicités
  Future<String> _buildAdBlockScript() async {
    return await _adBlockerService.buildAdBlockScript(_controller);
  }

  @override
  void initState() {
    super.initState();
    // Cycle de vie : sans cet observateur, une mise en arrière-plan (ou une
    // app tuée par le système) laissait la position de lecture figée au
    // dernier tick du timer de 5 s.
    WidgetsBinding.instance.addObserver(this);
    // Initialiser le service de patterns d'URL personnalisés
    ChapterLinkResolver.init(CustomSelectorsService());
    _lastCommitted = widget.initialLastRead;
    _originHost = Uri.parse(widget.initialUrl).host;
    _navigationPolicy = ReaderNavigationPolicy(
      blocksRequest: _adBlockerService.shouldBlockRequest,
      allowsHost: _isAllowedDomain,
    );
    _loadAdBlockerPreference();
    // Charger les blockers de manière asynchrone
    _loadBlockers();
    // Vérifier si le chapitre est téléchargé et rediriger si nécessaire
    _checkAndRedirectToOffline();
  }

  /// Sauvegarde la position de lecture quand l'app passe en arrière-plan.
  ///
  /// On n'enregistre **jamais** un chapitre en silence ici : passer en
  /// arrière-plan ne prouve pas qu'un chapitre est terminé. Seule la position
  /// de défilement est écrite, pour reprendre au bon endroit.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.inactive) {
      return;
    }
    final controller = _controller;
    final chapter = _currentChapter;
    if (controller == null || chapter == null) return;
    unawaited(
      _scrollPositionService
          .saveScrollPosition(controller, widget.muId, chapter)
          .then((_) {}, onError: (Object e) {
        debugPrint('⚠️ Sauvegarde de position en arrière-plan impossible: $e');
      }),
    );
  }

  /// Vérifie si le chapitre suivant est téléchargé et redirige vers OfflineReaderView si c'est le cas
  ///
  /// Sortie légitime qui contourne la modale de fin de chapitre : elle a lieu
  /// avant toute lecture (aucun chapitre n'est encore détecté), et le lecteur
  /// hors ligne pose lui-même la question à sa propre sortie.
  Future<void> _checkAndRedirectToOffline() async {
    try {
      final nextChapterNumber = widget.initialLastRead + 1;
      final isDownloaded = await _downloadManager.isChapterDownloaded(widget.muId, nextChapterNumber);
      
      if (isDownloaded && widget.mangaTitle != null && mounted) {
        // Attendre un peu pour que le widget soit complètement monté
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          context.pushReplacement(
            '/manga/${widget.muId}/read-offline?chapter=$nextChapterNumber',
            extra: OfflineReaderExtras(mangaTitle: widget.mangaTitle!),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ ReaderWebView: Erreur lors de la vérification du chapitre téléchargé: $e');
    }
  }

  Future<void> _loadBlockers() async {
    _cachedBlockers = await _getBlockers();
    if (mounted) {
      setState(() {
        // Forcer la mise à jour pour recharger les blockers
      });
    }
  }

  Future<void> _loadAdBlockerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adBlockerEnabled = prefs.getBool('ad_blocker_enabled') ?? true;
    });
  }

  /// Bascule le bloqueur de publicités **et applique l'effet à la page en
  /// cours**.
  ///
  /// Rafraîchir `_cachedBlockers` ne suffirait pas : `initialSettings` n'est
  /// lu qu'à la création de la WebView, donc la couche `ContentBlocker` est
  /// inerte (voir known-issues.md). Le seul blocage réellement actif est le
  /// script injecté — c'est donc lui qu'il faut piloter, sinon le bouton
  /// n'aurait aucun effet visible.
  Future<void> _toggleAdBlocker(bool enabled) async {
    // Résolu avant tout `await` : le contexte ne survit pas aux gaps async.
    final l10n = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_blocker_enabled', enabled);
    setState(() {
      _adBlockerEnabled = enabled;
      // Si on réactive le bloqueur et qu'un captcha était détecté, réinitialiser
      if (enabled && _captchaDetected) {
        _captchaDetected = false;
      }
    });
    // Tenu à jour pour la prochaine création de WebView.
    await _reloadBlockers();

    final controller = _controller;
    if (controller == null) return;

    if (enabled) {
      // Injection immédiate : l'effet est visible sans rechargement, donc
      // sans rien coûter à la position de lecture.
      try {
        final script = await _buildAdBlockScript();
        await controller.evaluateJavascript(source: script);
        _notifier.info(l10n?.adBlockerEnabledNotice ??
            'Bloqueur de publicités activé sur cette page.');
      } catch (e) {
        debugPrint('⚠️ Injection du script de blocage impossible: $e');
      }
      return;
    }

    // Désactivation : arrêter le script suspend le nettoyage, mais ne fait pas
    // réapparaître ce qu'il a déjà retiré du DOM (`el.remove()` est
    // irréversible). Un rechargement est donc nécessaire pour rétablir la
    // page — on passe par `_refreshPage` pour préserver la lecture en cours.
    await _adBlockerService.stopAdBlockScript(controller);
    _notifier.info(l10n?.adBlockerDisabledNotice ??
        'Bloqueur désactivé — page rechargée pour rétablir le contenu.');
    await _refreshPage();
  }

  /// Recharge la page courante en préservant le contexte de lecture.
  ///
  /// Le chapitre est repéré par l'URL, que `reload()` conserve :
  /// `_currentChapter` reste donc valide et `detectChapterChange` conclut à
  /// `noChange`, si bien qu'aucun chapitre n'est validé par mégarde.
  ///
  /// La position de défilement, elle, n'est écrite que par le timer
  /// périodique : on la sauvegarde explicitement avant de recharger, sans
  /// quoi tout ce qui a été lu depuis le dernier tick serait perdu.
  /// `onLoadStop` la restaure ensuite pour le chapitre courant.
  Future<void> _refreshPage() async {
    final controller = _controller;
    if (controller == null) return;

    final chapter = _currentChapter;
    if (chapter != null) {
      await _scrollPositionService.saveScrollPosition(
        controller,
        widget.muId,
        chapter,
      );
    }
    // Autorise `onLoadStop` à restaurer de nouveau après le rechargement.
    _hasRestoredScroll = false;
    // Un rechargement demandé par l'utilisateur est un geste délibéré : il ne
    // doit pas compter comme un tour de la boucle de vérification anti-robot.
    _loopDetector.reset();

    await controller.reload();
  }

  /// Exécute une action choisie dans le menu « trois points ».
  Future<void> _handleOverflowAction(ReaderOverflowAction action) async {
    switch (action) {
      case ReaderOverflowAction.downloadPage:
        final success = await _downloadCurrentPage();
        // Si autoDownload est activé et que le téléchargement a réussi,
        // fermer la webview
        if (widget.autoDownload && success && mounted) {
          Navigator.of(context).pop();
        }
        break;
      case ReaderOverflowAction.copyUrl:
        await _copyCurrentUrl();
        break;
      case ReaderOverflowAction.toggleInteractiveAdBlock:
        await _toggleInteractiveAdBlockMode();
        break;
      case ReaderOverflowAction.adBlockerInfo:
        await _showAdBlockerInfo();
        break;
    }
  }

  /// Recharge les blockers en mettant à jour le cache
  Future<void> _reloadBlockers() async {
    _cachedBlockers = await _getBlockers();
    if (mounted) {
      setState(() {
        // Forcer la mise à jour pour recharger les blockers
      });
    }
  }

  /// La vérification boucle : on cesse d'insister et on propose une sortie.
  Future<void> _handleChallengeLoop(WebUri url) async {
    final action = await ChallengeEscapeDialog.show(
      context: context,
      url: url.toString(),
    );
    if (action == ChallengeEscapeAction.retry && mounted) {
      _loopDetector.reset();
      await _controller?.reload();
    }
  }

  /// Détecte la présence d'un captcha et désactive temporairement le bloqueur de pub
  Future<void> _detectAndHandleCaptcha(InAppWebViewController controller, WebUri url) async {
    try {
      final captchaType = await _captchaDetectionService.detectCaptcha(controller);

      if (captchaType != null) {
        // Le script de nettoyage déjà injecté tourne sur un intervalle de 2 s
        // et survivrait au changement d'état : il faut l'arrêter dans la page.
        await _adBlockerService.stopAdBlockScript(controller);

        // Compter les présentations successives. Au-delà du seuil, on cesse
        // de boucler et on propose la sortie vers le navigateur externe.
        if (_loopDetector.recordChallenge(url.toString()) && mounted) {
          await _handleChallengeLoop(url);
          return;
        }
      } else {
        _loopDetector.recordSuccess();
      }

      if (captchaType != null && _adBlockerEnabled) {
        // Captcha détecté, désactiver temporairement le bloqueur
        if (!_captchaDetected) {
          debugPrint('🔒 Captcha détecté ($captchaType), désactivation temporaire du bloqueur de pub');
          setState(() {
            _adBlockerWasEnabled = _adBlockerEnabled;
            _adBlockerEnabled = false;
            _captchaDetected = true;
          });
          
          // Recharger les blockers pour désactiver le blocage
          await _reloadBlockers();
          
          final l10n = AppLocalizations.of(context);
          _notifier.info(l10n?.captchaDetected ?? "Captcha détecté - Le bloqueur de pub a été temporairement désactivé");
        }
      } else if (captchaType == null && _captchaDetected) {
        // Vérifier si le captcha est résolu
        final isResolved = await _captchaDetectionService.isCaptchaResolved(controller, url);
        
        if (isResolved) {
          // Captcha résolu, réactiver le bloqueur
          debugPrint('✅ Captcha résolu, réactivation du bloqueur de pub');
          setState(() {
            _adBlockerEnabled = _adBlockerWasEnabled;
            _captchaDetected = false;
          });
          
          // Recharger les blockers pour réactiver le blocage
          await _reloadBlockers();
          
          final l10n = AppLocalizations.of(context);
          _notifier.success(l10n?.captchaResolved ?? "Captcha résolu - Le bloqueur de pub a été réactivé");
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la détection du captcha: $e');
    }
  }

  Future<void> _copyCurrentUrl() async {
    try {
      final url = await _controller?.getUrl();
      if (url != null) {
        await Clipboard.setData(ClipboardData(text: url.toString()));
        final l10n = AppLocalizations.of(context);
        _notifier.info(l10n?.urlCopied ?? "URL copiée dans le presse-papiers");
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      _notifier.error(l10n?.urlCopyError ?? "Erreur lors de la copie de l'URL");
    }
  }

  Future<void> _toggleInteractiveAdBlockMode() async {
    // Résolu avant tout `await` : le contexte ne survit pas aux gaps async.
    final l10n = AppLocalizations.of(context);
    setState(() {
      _interactiveAdBlockMode = !_interactiveAdBlockMode;
    });

    if (_controller == null) return;

    if (_interactiveAdBlockMode) {
      _notifier.info(l10n?.adBlockerInteractiveOnNotice ??
          'Mode détection activé — touchez une publicité pour la bloquer.');
      await _adBlockerService.injectInteractiveAdBlockScript(_controller!);
    } else {
      _notifier.info(l10n?.adBlockerInteractiveOffNotice ??
          'Mode détection désactivé.');
      await _adBlockerService.removeInteractiveAdBlockScript(_controller!);
    }
  }

  Future<void> _handleAdBlockClick(String selector) async {
    if (_controller == null) return;
    await _adBlockerService.handleAdBlockClick(_controller!, selector);
    
    // Recharger le script complet pour s'assurer que le sélecteur est bien inclus
    try {
      final script = await _buildAdBlockScript();
      await _controller?.evaluateJavascript(source: script);
    } catch (e) {
      debugPrint('⚠️ Erreur lors du rechargement du script de blocage: $e');
    }
  }

  /// Sauvegarde les cookies du WebView pour un domaine donné (pour les téléchargements automatiques)
  Future<void> _saveCookiesForDomain(WebUri url) async {
    try {
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: url);
      
      if (cookies.isEmpty) {
        debugPrint('⚠️ ReaderWebView: Aucun cookie trouvé pour ${url.host}');
        return;
      }

      // Construire la chaîne de cookies pour les requêtes HTTP
      final cookieString = cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
      
      // Sauvegarder les cookies dans SharedPreferences pour ce domaine
      final prefs = await SharedPreferences.getInstance();
      final domain = url.host;
      await prefs.setString('cookies_$domain', cookieString);
      
      debugPrint('✅ ReaderWebView: Cookies sauvegardés pour $domain (${cookies.length} cookies)');
    } catch (e) {
      debugPrint('⚠️ ReaderWebView: Erreur lors de la sauvegarde des cookies: $e');
    }
  }

  /// Télécharge la page actuelle depuis le WebView (après résolution du captcha)
  Future<bool> _downloadCurrentPage() async {
    try {
      final url = await _controller?.getUrl();
      if (url == null) {
        _notifier.error("Impossible de récupérer l'URL actuelle");
        return false;
      }

      final urlString = url.toString();
      
      // Extraire le numéro de chapitre depuis l'URL
      final chapterNumber = await ChapterLinkResolver.extractChapter(urlString);
      if (chapterNumber == null) {
        _notifier.error("Impossible de détecter le numéro de chapitre dans l'URL");
        return false;
      }

      // Afficher un message de chargement
      _notifier.info("Chargement des images...");

      // Script JavaScript pour forcer le chargement de toutes les images et attendre qu'elles soient chargées
      // Utiliser une approche plus simple qui retourne directement le HTML
      final loadImagesScript = """
        (function() {
          // Fonction pour convertir les URLs relatives en absolues
          function toAbsoluteUrl(url) {
            if (!url) return url;
            if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
              return url;
            }
            if (url.startsWith('//')) {
              return window.location.protocol + url;
            }
            if (url.startsWith('/')) {
              return window.location.origin + url;
            }
            const basePath = window.location.href.substring(0, window.location.href.lastIndexOf('/') + 1);
            return basePath + url;
          }
          
          // Récupérer toutes les images
          const images = document.querySelectorAll('img');
          const totalImages = images.length;
          
          console.log('📸 Nombre d\\'images trouvées: ' + totalImages);
          
          // Convertir toutes les URLs d'images en URLs absolues et forcer le chargement
          images.forEach(function(img, index) {
            // Récupérer toutes les sources possibles
            let src = img.src || img.getAttribute('src') || 
                     img.getAttribute('data-src') || 
                     img.getAttribute('data-lazy-src') || 
                     img.getAttribute('data-original') ||
                     img.getAttribute('data-url') ||
                     img.getAttribute('data-image');
            
            if (src && !src.startsWith('data:')) {
              const absoluteSrc = toAbsoluteUrl(src.trim());
              
              // Supprimer les attributs de lazy loading
              img.removeAttribute('loading');
              img.removeAttribute('data-src');
              img.removeAttribute('data-lazy-src');
              img.removeAttribute('data-original');
              
              // Mettre l'URL absolue dans src
              img.src = absoluteSrc;
              
              console.log('Image ' + index + ': ' + absoluteSrc);
            }
          });
          
          // Retourner le HTML directement (les images seront chargées par le navigateur)
          return document.documentElement.outerHTML;
        })();
      """;

      // Exécuter le script pour récupérer le HTML avec les images
      _notifier.info("Récupération du contenu de la page...");
      
      // Attendre un peu pour que les images commencent à charger
      await Future.delayed(const Duration(milliseconds: 500));
      
      var htmlResult = await _controller?.evaluateJavascript(source: loadImagesScript);
      if (htmlResult == null) {
        _notifier.error("Impossible de récupérer le contenu de la page");
        return false;
      }
      
      // Vérifier si le résultat est vide ou invalide
      if (htmlResult.toString().isEmpty || htmlResult.toString() == '{}' || htmlResult.toString() == 'null') {
        debugPrint('⚠️ Le résultat est vide, tentative de récupération directe du HTML...');
        // Essayer une approche alternative : récupérer directement le HTML sans traitement
        final directHtmlScript = "document.documentElement.outerHTML;";
        final directResult = await _controller?.evaluateJavascript(source: directHtmlScript);
        if (directResult != null && directResult.toString().isNotEmpty && directResult.toString() != '{}') {
          htmlResult = directResult;
        } else {
          _notifier.error("Impossible de récupérer le HTML de la page");
          return false;
        }
      }

      // Le résultat devrait être directement le HTML
      String cleanHtml = htmlResult.toString();
      
      // Nettoyer le HTML (retirer les guillemets JSON et décoder les échappements)
      if (cleanHtml.startsWith('"') && cleanHtml.endsWith('"')) {
        cleanHtml = cleanHtml.substring(1, cleanHtml.length - 1);
      }
      // Décoder les échappements JSON
      cleanHtml = cleanHtml.replaceAll('\\"', '"').replaceAll('\\n', '\n').replaceAll('\\/', '/').replaceAll('\\\\', '\\');
      
      // Vérifier que le HTML contient bien des images
      if (!cleanHtml.contains('<img') && !cleanHtml.contains('reading-content')) {
        debugPrint('⚠️ Le HTML ne contient pas d\'images ou de contenu de lecture');
        _notifier.warning("Le HTML récupéré semble vide ou invalide");
      }

      // Obtenir le chemin du dossier du chapitre (utiliser le nom du manga si disponible)
      final mangaTitle = widget.mangaTitle ?? widget.muId.toString();
      final chapterPath = await _downloadManager.getChapterDownloadPath(mangaTitle, chapterNumber);
      final dir = Directory(chapterPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Utiliser ChapterDownloadService pour télécharger les images localement
      _notifier.info("Téléchargement des images...");
      final downloadService = ChapterDownloadService();
      final processedHtml = await downloadService.processHtmlForOffline(
        cleanHtml,
        urlString,
        chapterPath,
        onProgress: (progress) {
          // La progression va de 0.0 à 1.0
          debugPrint('📥 Progression téléchargement images: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      // Sauvegarder le HTML traité avec les images localisées
      final htmlFilePath = path.join(chapterPath, 'chapter.html');
      final htmlFile = File(htmlFilePath);
      await htmlFile.writeAsString(processedHtml, encoding: utf8);

      // Créer le modèle DownloadedChapter
      final downloadedChapter = DownloadedChapter(
        muId: widget.muId,
        chapterNumber: chapterNumber,
        downloadDate: DateTime.now(),
        imageCount: 0,
        imagePaths: [],
        htmlPath: htmlFilePath,
        status: DownloadStatus.completed,
      );

      // Sauvegarder les métadonnées
      final metadataPath = downloadedChapter.metadataPath;
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(downloadedChapter.toJson()));

      // Enregistrer dans le DownloadManagerService
      await _downloadManager.addDownloadedChapter(downloadedChapter);

      _notifier.success("Chapitre $chapterNumber téléchargé avec succès");
      
      debugPrint('✅ ReaderWebView: Chapitre $chapterNumber téléchargé depuis le WebView');
      
      // Si autoDownload est activé, fermer automatiquement la webview après un court délai
      // MAIS appeler le callback AVANT de fermer pour que le dialog puisse continuer
      if (widget.autoDownload && mounted) {
        // Appeler le callback AVANT de fermer
        if (widget.onDownloadComplete != null) {
          widget.onDownloadComplete!(true);
        }
        // Attendre un peu pour que le callback soit traité
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Si pas en mode autoDownload, appeler le callback normalement
        if (widget.onDownloadComplete != null) {
          widget.onDownloadComplete!(true);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ ReaderWebView: Erreur lors du téléchargement depuis le WebView: $e');
      _notifier.error("Erreur lors du téléchargement: $e");
      
      // Appeler le callback si fourni
      if (widget.onDownloadComplete != null) {
        widget.onDownloadComplete!(false);
      }
      
      return false;
    }
  }

  Future<void> _updateProgressFromUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      _handleDetected(uri);
      final l10n = AppLocalizations.of(context);
      _notifier.info(l10n?.progressUpdated ?? "Progression mise à jour");
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      _notifier.error(l10n?.invalidUrl ?? "URL invalide");
    }
  }

  Future<void> _showAdBlockerInfo() async {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.block,
          color: AppColors.error,
          size: AppSpacing.jumbo,
        ),
        title: Text(l10n?.adBlockerTitle ?? 'Bloqueur de publicités'),
        content: Text(
          l10n?.adBlockerDescription ?? 
          'Le bloqueur de publicités bloque automatiquement les publicités sur les sites de lecture.\n\n'
          'Si vous souhaitez ajouter des liens ou suggérer des améliorations pour le blocage de publicités, '
          'rejoignez notre serveur Discord !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.close ?? 'Fermer'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse('https://discord.gg/X6sBgFY7');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.chat, size: AppSpacing.m),
            label: Text(l10n?.joinDiscord ?? 'Rejoindre Discord'),
          ),
        ],
      ),
    );
  }

  /// [confirmedByUser] : l'utilisateur vient d'affirmer explicitement avoir
  /// lu ce chapitre (dialogue de validation ou de saut). Dans ce cas
  /// seulement, un chapitre au-delà du total connu déclenche un
  /// signalement automatique côté serveur au lieu d'être perdu en silence.
  /// La détection d'URL, elle, ne confirme rien : un numéro mal détecté ne
  /// doit jamais alimenter la base communautaire.
  Future<void> _commitIfNeeded(int chapter, {bool confirmedByUser = false}) async {
    if (chapter <= _lastCommitted) {
      return;
    }
    final ok = await _library.saveChapterProgress(
      widget.muId,
      chapter,
      autoReportIfAboveTotal: confirmedByUser,
    );
    if (ok) {
      _lastCommitted = chapter;
      // Journal additif (Stats v2) : trace la session de lecture pour
      // l'historique + l'activité hebdo. Fire-and-forget : n'altère PAS
      // le pointeur de progression (RETRO-015), un échec perd juste une
      // entrée d'historique.
      unawaited(
        _chapterLog
            .recordChapterLog(widget.muId, chapterNumber: chapter)
            .then((_) {}, onError: (Object e) {
          debugPrint('⚠️ chapterLog: $e');
        }),
      );
      final l10n = AppLocalizations.of(context);
      _notifier.info(l10n?.chapterSaved(chapter.toString()) ?? "Chapitre $chapter enregistré");
    }
  }

  Future<void> _updateNextLinkFrom(String currentUrl, {int? currentChapter}) async {
    final next = await ChapterLinkResolver.buildNextUrl(currentUrl, currentChapter: currentChapter)
        ?? await ChapterLinkResolver.buildNextUrl(widget.baseUserLink, currentChapter: currentChapter);
    if (next != null) {
      await _library.updateCustomLink(widget.muId, next);
    }
  }

  /// Point d'entrée unique des détections d'URL — **sérialisé et idempotent**.
  ///
  /// Les trois callbacks de la WebView signalent la même navigation ; une URL
  /// n'est traitée qu'une fois, et un seul traitement court à la fois. Une
  /// navigation qui survient pendant un traitement est mise en attente (la
  /// plus récente gagne) au lieu d'être perdue.
  void _handleDetected(Uri uri) {
    if (uri.toString() == _lastHandledUrl) return;
    if (_processingDetection) {
      _pendingDetection = uri;
      return;
    }
    unawaited(_drainDetections(uri));
  }

  Future<void> _drainDetections(Uri first) async {
    _processingDetection = true;
    try {
      Uri? next = first;
      while (next != null) {
        final url = next.toString();
        if (url != _lastHandledUrl) {
          _lastHandledUrl = url;
          await _applyChapterChange(next);
        }
        next = _pendingDetection;
        _pendingDetection = null;
      }
    } catch (e) {
      debugPrint('⚠️ Détection de chapitre impossible: $e');
    } finally {
      _processingDetection = false;
    }
  }

  /// Applique la décision de [ChapterCommitPolicy] pour une URL détectée.
  ///
  /// INVARIANT : **arriver sur un chapitre ne le marque jamais comme lu.**
  /// Le chapitre d'arrivée (`result.newChapter`) n'est jamais passé à
  /// `_commitIfNeeded` — seul le chapitre quitté peut l'être. Verrouillé par
  /// `test/features/reader/reader_invariants_test.dart`.
  Future<void> _applyChapterChange(Uri uri) async {
    final result = await _navigationService.detectChapterChange(
      uri,
      _originHost,
      _currentChapter,
    );
    if (result == null) return;

    final decision = _commitPolicy.onTransition(
      transition: result.changeType.asTransition,
      newChapter: result.newChapter!,
      previousChapter: result.previousChapter,
    );

    // 1. Le chapitre quitté : on fige sa position puis on l'oublie (on ne le
    //    relira pas là où on l'avait laissé).
    final released = decision.releaseScrollOfChapter;
    if (released != null) {
      if (_controller != null) {
        await _scrollPositionService.saveScrollPosition(
            _controller!, widget.muId, released);
      }
      await _scrollPositionService.deleteScrollPosition(widget.muId, released);
    }

    // 2. Enregistrement automatique : uniquement un chapitre TERMINÉ.
    final commit = decision.commitChapter;
    if (commit != null) {
      await _commitIfNeeded(commit);
    }

    // 3. Enregistrement sur confirmation explicite (saut de chapitres).
    final ask = decision.askUserToCommitChapter;
    if (ask != null && mounted) {
      final answer = await ChapterSkipDialog.show(
        context,
        previousChapter: ask,
        nextChapter: result.newChapter!,
      );
      final confirmed = _commitPolicy.resolveAnswer(
        answer: answer,
        chapter: ask,
      );
      if (confirmed != null) {
        // Confirmation explicite → auto-signalement autorisé.
        await _commitIfNeeded(confirmed, confirmedByUser: true);
      }
    }

    // 4. Suivi du nouveau chapitre courant.
    final initialize = decision.initializeChapter;
    if (initialize != null) {
      _currentChapter = initialize;
      unawaited(
          _updateNextLinkFrom(uri.toString(), currentChapter: initialize));
      _hasRestoredScroll = false;
      if (_controller != null) {
        _scrollPositionService.startSaveTimer(
            _controller!, widget.muId, initialize);
      }
    }
  }

  bool _isAllowedDomain(String host) {
    return _adBlockerService.isAllowedDomain(host, _originHost);
  }

  /// Traite une demande de sortie, quel qu'en soit le chemin : geste retour
  /// (y compris le retour prédictif Android 13+, qui ignore `WillPopScope`),
  /// bouton retour de l'AppBar (`maybePop`) ou bouton système.
  ///
  /// Protégée contre la réentrance : un second appui pendant que la modale
  /// est ouverte est ignoré au lieu d'empiler une deuxième modale.
  /// Rappel de `PopScope` : la fermeture est refusée (`canPop: false`), on la
  /// rejoue nous-mêmes une fois la question de fin de chapitre traitée.
  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) return;
    unawaited(_handleExitRequest());
  }

  Future<void> _handleExitRequest() async {
    if (_exitFlowRunning) return;
    _exitFlowRunning = true;
    try {
      await _onWillPop();
      if (mounted) Navigator.of(context).pop();
    } finally {
      _exitFlowRunning = false;
    }
  }

  /// Mesure « suis-je proche de la fin ? » bornée dans le temps.
  ///
  /// La mesure tourne dans la page : une page figée ou une WebView en cours
  /// de destruction pourrait ne jamais répondre et donner l'impression d'un
  /// retour bloqué. À l'expiration on répond « non » — préférer un faux
  /// négatif à une sortie qui ne réagit pas.
  Future<bool> _isNearEndOfChapter() async {
    try {
      return await ReadingProgressHelper.isNearEndOfChapter(_controller)
          .timeout(kNearEndMeasureTimeout, onTimeout: () => false);
    } catch (e) {
      debugPrint('⚠️ Mesure de fin de chapitre impossible: $e');
      return false;
    }
  }

  Future<bool> _onWillPop() async {
    // Sauvegarder la position de scroll avant de fermer
    debugPrint('🔍 _onWillPop - Sauvegarde de la position avant fermeture');
    debugPrint('🔍 _onWillPop - Controller: ${_controller != null}, Chapitre: $_currentChapter');
    if (_controller != null && _currentChapter != null) {
      debugPrint('🔍 _onWillPop - Sauvegarde de la position pour chapitre $_currentChapter');
      await _scrollPositionService.saveScrollPosition(
        _controller!,
        widget.muId,
        _currentChapter!,
      );
      debugPrint('🔍 _onWillPop - Position sauvegardée avec succès');
    } else {
      debugPrint('⚠️ _onWillPop - Impossible de sauvegarder: controller=${_controller != null}, chapter=$_currentChapter');
    }
    
    // Si autoDownload est activé et que le callback existe, l'appeler avec false si on ferme sans télécharger
    if (widget.autoDownload && widget.onDownloadComplete != null) {
      // Vérifier si le chapitre a été téléchargé avant de fermer
      final url = await _controller?.getUrl();
      if (url != null) {
        final urlString = url.toString();
        final chapterNumber = await ChapterLinkResolver.extractChapter(urlString);
        if (chapterNumber != null) {
          final downloaded = await _downloadManager.getDownloadedChapters(widget.muId);
          final isDownloaded = downloaded.any((c) => c.chapterNumber == chapterNumber);
          if (!isDownloaded) {
            // Le chapitre n'a pas été téléchargé, appeler le callback avec false
            widget.onDownloadComplete!(false);
          }
        }
      }
    }
    
    // Si on est sur le chapitre C, qu'il n'est pas déjà enregistré et que la
    // lecture est proche de la fin, on demande « Avez-vous fini le chapitre
    // C ? ». La décision appartient à ChapterCommitPolicy.
    final exit = _commitPolicy.onExit(
      currentChapter: _currentChapter,
      lastCommitted: _lastCommitted,
      isNearEnd: await _isNearEndOfChapter(),
    );

    final chapter = exit.askUserToCommitChapter;
    if (chapter == null || !mounted) {
      // Rien à demander : la position de défilement est déjà sauvegardée,
      // aucun chapitre n'est marqué comme lu en silence.
      return true;
    }

    final answer = await ChapterCompletionDialog.show(context, chapter: chapter);
    if (_commitPolicy.resolveAnswer(answer: answer, chapter: chapter) != null) {
      // « Avez-vous fini le chapitre N ? » → oui : assertion explicite,
      // on autorise le signalement automatique si N dépasse le total.
      await _commitIfNeeded(chapter, confirmedByUser: true);
      final currentUrl = await _controller?.getUrl();
      await _updateNextLinkFrom(
        (currentUrl?.toString() ?? widget.baseUserLink),
        currentChapter: chapter,
      );
    }
    return true; // quitter la page
  }


  Future<void> _openInExternalBrowser() async {
    final url = widget.initialUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildWebFallback() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.readOnline ?? 'Lire en ligne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.initialUrl));
              _notifier.info(l10n?.urlCopied ?? "URL copiée");
            },
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.paddingAllM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingAllM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.webModeProgressTracking ?? 'Mode Web - Suivi de progression',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.webModeProgressDescription ?? 
                      'Pour suivre votre progression, collez l\'URL du chapitre que vous êtes en train de lire.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlTextController,
                      decoration: InputDecoration(
                        labelText: l10n?.chapterUrlLabel ?? 'URL du chapitre',
                        hintText: 'https://...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_urlTextController.text.isNotEmpty) {
                          _updateProgressFromUrl(_urlTextController.text);
                        }
                      },
                      child: Text(l10n?.updateProgress ?? 'Mettre à jour la progression'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openInExternalBrowser,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n?.openInNewTab ?? 'Ouvrir dans un nouvel onglet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si CORS bloque en mode web, afficher l'interface de fallback
    if (kIsWeb && _corsBlocked) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: _onPopInvoked,
        child: _buildWebFallback(),
      );
    }

    // INVARIANT : PopScope, PAS WillPopScope. `AndroidManifest.xml` déclare
    // `android:enableOnBackInvokedCallback="true"` : sur Android 13+ le geste
    // retour prédictif IGNORE purement et simplement `WillPopScope`, si bien
    // que la modale de fin de chapitre était injoignable au geste retour —
    // le chemin de sortie le plus utilisé. `canPop: false` capte aussi le
    // bouton retour de l'AppBar, qui passe par `Navigator.maybePop`.
    // Verrouillé par test/features/reader/reader_invariants_test.dart.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.readOnline ?? 'Lire en ligne'),
          actions: [
            ReaderActionBar(
              adBlockerEnabled: _adBlockerEnabled,
              interactiveAdBlockMode: _interactiveAdBlockMode,
              onRefresh: _refreshPage,
              onToggleAdBlocker: _toggleAdBlocker,
              onOverflowAction: _handleOverflowAction,
            ),
          ],
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
          // INVARIANT (régression v0.13.0) : `initialSettings` est le SEUL
          // endroit où les réglages sont posés. Ne JAMAIS appeler
          // `controller.setSettings(...)` sur cette WebView : côté Android,
          // l'appel remplace l'objet de réglages ENTIER par un neuf, ce qui
          // remettait `useShouldOverrideUrlLoading` à false et rendait le
          // garde `shouldOverrideUrlLoading` ci-dessous inerte — toutes les
          // redirections publicitaires passaient. Verrouillé par
          // test/features/reader/reader_invariants_test.dart.
          initialSettings: ReaderWebViewSettings.build(
            contentBlockers: _cachedBlockers,
          ),
          onWebViewCreated: (c) {
            _controller = c;
            // Ajouter le handler JavaScript pour le mode interactif
            c.addJavaScriptHandler(handlerName: 'onAdBlockClick', callback: (args) async {
              if (args.isNotEmpty && _interactiveAdBlockMode) {
                final selector = args[0] as String;
                await _handleAdBlockClick(selector);
              }
            });
          },

          // 1) Navigation principale — blocage strict des redirections.
          // Toute navigation de la frame principale vers un autre domaine
          // que celui du lien de l'utilisateur est ANNULÉE (protection
          // anti-pub). La décision est dans ReaderNavigationPolicy (pure).
          shouldOverrideUrlLoading: (controller, action) async {
            final uri = action.request.url;
            final decision = _navigationPolicy.decide(
              url: uri,
              isForMainFrame: action.isForMainFrame,
            );
            if (decision == ReaderNavigationDecision.cancel) {
              return NavigationActionPolicy.CANCEL;
            }
            if (uri != null && action.isForMainFrame) {
              _handleDetected(uri);
            }
            return NavigationActionPolicy.ALLOW;
          },

          // 2) Début de chargement - Vérification supplémentaire et détection précoce de captcha
          onLoadStart: (controller, url) async {
            if (url != null) {
              final uri = url;
              final host = uri.host;
              final urlString = url.toString();
              
              // Détecter le captcha dès le début du chargement via l'URL
              if (_captchaDetectionService.urlContainsCaptcha(urlString) || _captchaDetectionService.isCaptchaDomain(host)) {
                if (!_captchaDetected && _adBlockerEnabled) {
                  debugPrint('🔒 Captcha détecté dans l\'URL, désactivation précoce du bloqueur de pub');
                  setState(() {
                    _adBlockerWasEnabled = _adBlockerEnabled;
                    _adBlockerEnabled = false;
                    _captchaDetected = true;
                  });
                  await _reloadBlockers();
                  final l10n = AppLocalizations.of(context);
          _notifier.info(l10n?.captchaDetected ?? "Captcha détecté - Le bloqueur de pub a été temporairement désactivé");
                }
              }
              
              // Vérifier que c'est un domaine autorisé
              if (_isAllowedDomain(host)) {
                _handleDetected(uri);
              }
            }
          },

          // 3) SPA / pushState
          onUpdateVisitedHistory: (controller, url, _) {
            if (url != null) {
              final uri = url;
              final host = uri.host;
              if (_isAllowedDomain(host)) {
                _handleDetected(uri);
              }
            }
          },

          // 4) Injection JavaScript après chargement pour nettoyer les publicités
          onLoadStop: (controller, url) async {
            // Détecter la présence d'un captcha
            if (url != null && mounted) {
              await _detectAndHandleCaptcha(controller, url);
            }
            
            if (_adBlockerEnabled && url != null && !_captchaDetected) {
              try {
                // Vérifier que la WebView est toujours valide avant d'injecter le script
                final currentUrl = await controller.getUrl();
                if (currentUrl != null && mounted) {
                  final script = await _buildAdBlockScript();
                  await controller.evaluateJavascript(source: script);
                }
              } catch (e) {
                // Ignorer silencieusement si la WebView est détruite ou en cours de changement
                // C'est normal quand le site essaie d'ouvrir de nouvelles pages qui sont bloquées
              }
            }
            
            // Sauvegarder les cookies après chargement de la page (pour les téléchargements automatiques)
            if (url != null) {
              await _saveCookiesForDomain(url);
            }
            
            // Détecter le chapitre depuis l'URL si pas encore détecté
            if (_currentChapter == null && url != null) {
              final uri = url;
              final newCh = await ChapterLinkResolver.extractChapter(uri.toString());
              if (newCh != null) {
                debugPrint('🔍 onLoadStop - Détection du chapitre depuis l\'URL: $newCh');
                _currentChapter = newCh;
                _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
                _hasRestoredScroll = false;
              }
            }
            
            // Restaurer la position de scroll si disponible (en arrière-plan pour ne pas bloquer)
            if (_currentChapter != null && mounted && _controller != null) {
              debugPrint('🔍 onLoadStop - Chapitre $_currentChapter détecté, démarrage du timer');
              // Réinitialiser le flag de restauration pour le nouveau chapitre
              _hasRestoredScroll = false;
              // Démarrer le timer de sauvegarde périodique AVANT la restauration
              // pour s'assurer qu'il démarre même si la restauration échoue
              _scrollPositionService.startSaveTimer(
                _controller!,
                widget.muId,
                _currentChapter!,
              );
              // Restaurer en arrière-plan pour ne pas bloquer le chargement
              _scrollPositionService.restoreScrollPosition(
                _controller!,
                widget.muId,
                _currentChapter!,
                hasRestoredScroll: _hasRestoredScroll,
              ).then((restored) {
                if (mounted) {
                  setState(() {
                    _hasRestoredScroll = restored;
                  });
                }
              }).catchError((e) {
                debugPrint('⚠️ Erreur lors de la restauration en arrière-plan: $e');
              });
            } else {
              debugPrint('⚠️ onLoadStop - Chapitre non détecté: _currentChapter=$_currentChapter, controller=${_controller != null}, mounted=$mounted');
            }
            
            // Si autoDownload est activé, lancer automatiquement le téléchargement après un délai
            // Exécuter en arrière-plan pour ne pas bloquer le chargement de la page
            if (widget.autoDownload && url != null && mounted) {
              // Exécuter en arrière-plan pour ne pas bloquer le chargement
              Future.delayed(const Duration(seconds: 2), () async {
                if (mounted && _controller != null) {
                  try {
                    // Vérifier si les cookies sont déjà présents (captcha déjà résolu)
                    final cookieManager = CookieManager.instance();
                    final cookies = await cookieManager.getCookies(url: url);
                    if (cookies.isNotEmpty && cookies.any((c) => c.name.contains('cf_clearance') || c.name.contains('clearance'))) {
                      // Les cookies sont présents, lancer automatiquement le téléchargement
                      debugPrint('✅ Cookies détectés, lancement automatique du téléchargement...');
                      _downloadCurrentPage();
                    } else {
                      // Pas de cookies, afficher un message pour guider l'utilisateur
                      _notifier.info("Résolvez le captcha si nécessaire, puis cliquez sur le bouton de téléchargement.");
                    }
                  } catch (e) {
                    debugPrint('⚠️ Erreur lors de la vérification des cookies en arrière-plan: $e');
                  }
                }
              });
            }
          },

          // 5) Gestion des erreurs CORS en mode web
          onReceivedError: (controller, request, error) {
            if (kIsWeb && error.description.contains('CORS')) {
              setState(() {
                _corsBlocked = true;
              });
            }
          },

          onConsoleMessage: (controller, consoleMessage) {
            if (kIsWeb && consoleMessage.message.contains('CORS')) {
              setState(() {
                _corsBlocked = true;
              });
            }
          },

          // 6) Android: blocage réseau supplémentaire (images/scripts pubs)
          androidShouldInterceptRequest: (controller, req) async {
            if (!_adBlockerEnabled || _captchaDetected) return null;
            final u = req.url.toString();
            final host = req.url.host;
            
            // Ne pas bloquer les domaines de captcha
            if (_captchaDetectionService.isCaptchaDomain(host) || _captchaDetectionService.urlContainsCaptcha(u)) {
              return null;
            }
            
            if (_adBlockerService.shouldBlockRequest(u)) {
              return _adBlockerService.createBlockedResponse();
            }
            return null;
          },
        ),
      ),
    );
  }

  /// Vérifie si l'utilisateur est proche de la fin du chapitre (dans les 15% de la fin)


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔍 dispose() - Arrêt du timer et sauvegarde finale');
    debugPrint('🔍 dispose() - Controller: ${_controller != null}, Chapitre: $_currentChapter');
    _scrollPositionService.stopSaveTimer();
    // Sauvegarder la position de scroll avant de fermer (sans await car dispose ne peut pas être async)
    // La sauvegarde sera faite de manière synchrone dans le service
    if (_controller != null && _currentChapter != null) {
      debugPrint('🔍 dispose() - Sauvegarde de la position pour chapitre $_currentChapter');
      // Utiliser un Future pour sauvegarder sans bloquer dispose
      _scrollPositionService.saveScrollPosition(
        _controller!,
        widget.muId,
        _currentChapter!,
      ).then((_) {
        debugPrint('🔍 dispose() - Position sauvegardée avec succès');
      }).catchError((e) {
        debugPrint('⚠️ Erreur lors de la sauvegarde dans dispose: $e');
      });
    } else {
      debugPrint('⚠️ dispose() - Impossible de sauvegarder: controller=${_controller != null}, chapter=$_currentChapter');
    }
    
    // NE PAS sauvegarder automatiquement le chapitre dans dispose()
    // La sauvegarde doit être gérée par _onWillPop() qui vérifie si l'utilisateur est proche de la fin
    // Si dispose() est appelé directement (par exemple lors d'un crash), on ne veut pas marquer
    // le chapitre comme lu si l'utilisateur n'était pas à la fin
    
    _urlTextController.dispose();
    super.dispose();
  }
}
