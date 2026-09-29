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
import 'package:mangatracker/features/download/services/chapter_image_source.dart';
import 'package:mangatracker/features/download/services/download_readiness_policy.dart';
import 'package:mangatracker/features/reader/utils/webview_result_parser.dart';
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/custom_selectors.service.dart';
import 'package:mangatracker/features/reader/utils/reading_progress_helper.dart';
import 'package:mangatracker/features/reader/services/scroll_position_service.dart';
import 'package:mangatracker/features/reader/services/reading_position.service.dart';
import 'package:mangatracker/features/reader/services/ad_blocker_service.dart';
import 'package:mangatracker/features/reader/services/captcha_detection_service.dart';
import 'package:mangatracker/features/reader/services/challenge_loop_detector.dart';
import 'package:mangatracker/features/reader/services/cloudflare_challenge.dart';
import 'package:mangatracker/features/reader/services/reader_navigation_policy.dart';
import 'package:mangatracker/features/reader/services/reader_web_view_settings.dart';
import 'package:mangatracker/features/reader/services/reader_diagnostics.dart';
import 'package:mangatracker/features/reader/widgets/challenge_escape_dialog.dart';
import 'package:mangatracker/features/reader/widgets/challenge_handoff_view.dart';
import 'package:mangatracker/features/reader/widgets/chapter_completion_dialog.dart';
import 'package:mangatracker/features/reader/widgets/chapter_skip_dialog.dart';
import 'package:mangatracker/features/reader/widgets/reader_action_bar.dart';
import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';
import 'package:mangatracker/features/reader/widgets/link_discovery_banner.dart';
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

  /// Position (0..100) décidée par `ReadingResumePolicy` à l'ouverture — la
  /// lecture reprise depuis un autre appareil. Consommée une seule fois, pour
  /// le premier chapitre affiché.
  final double? initialPositionPercent;

  /// Mode « recherche de lien » (voir `ReaderWebExtras.linkDiscovery`) :
  /// lecture seule, comme le mode téléchargement, plus l'action « Ceci est
  /// le nouveau lien ».
  final bool linkDiscovery;

  const ReaderWebView({
    super.key,
    required this.muId,
    this.mangaTitle,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
    this.autoDownload = false,    // Par défaut false
    this.onDownloadComplete,     // Callback optionnel
    this.initialPositionPercent,
    this.linkDiscovery = false,
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
  final _readingPositionService = getIt<ReadingPositionService>();
  final _adBlockerService = getIt<AdBlockerService>();
  final _captchaDetectionService = getIt<CaptchaDetectionService>();
  final _navigationService = getIt<WebViewNavigationService>();

  InAppWebViewController? _controller;
  final TextEditingController _urlTextController = TextEditingController();
  List<ContentBlocker> _cachedBlockers = []; // Cache pour les blockers
  bool _hasRestoredScroll = false; // Indique si la position de scroll a été restaurée

  /// Position venue du serveur, à n'appliquer qu'au premier chapitre affiché.
  /// Consommée puis mise à `null` : rouvrir le chapitre suivant ne doit pas
  /// rejouer la position d'un autre chapitre.
  double? _pendingResumePercent;

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

  // Vérification Cloudflare confiée à une WebView brute (voir
  // ChallengeHandoffView). Tant que `_challengePending` est vrai, la WebView
  // du lecteur affiche une page vierge : rien à lire, mesurer, sauvegarder
  // ni télécharger.
  WebUri? _challengeUrl;
  bool _challengePending = false;
  bool _showHandoff = false;
  String? _clearanceBefore;

  // Mode téléchargement (ouvert par ChapterDownloadDialog) : le lecteur ne
  // sert qu'à charger la page. Il n'enregistre RIEN — ni chapitre lu, ni
  // lien de lecture, ni position : `initialLastRead` y vaut une valeur
  // factice (chapitre demandé − 1), et télécharger les chapitres 10 à 12
  // réécrivait le lien de lecture d'un lecteur rendu au chapitre 95.
  bool get _downloadMode => widget.autoDownload;

  // Lecture seule : ni chapitre lu, ni lien réécrit, ni position. Le mode
  // « recherche de lien » y ajoute la seule écriture voulue par
  // l'utilisateur (« Ceci est le nouveau lien »). Invariant : la page
  // affichée n'est PAS un chapitre de ce titre tant que le lien n'est pas
  // trouvé — y détecter des chapitres corromprait sa progression.
  bool get _readOnlyMode => _downloadMode || widget.linkDiscovery;
  int get _expectedDownloadChapter => widget.initialLastRead + 1;
  bool _autoDownloadRunning = false;
  bool _discoveryHintVisible = true;
  bool _downloadReported = false;

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
    _pendingResumePercent = widget.initialPositionPercent;
    _originHost = Uri.parse(widget.initialUrl).host;
    _navigationPolicy = ReaderNavigationPolicy(
      blocksRequest: _adBlockerService.shouldBlockRequest,
      allowsHost: _isAllowedDomain,
    );
    ReaderDiagnostics.log('open', {
      'muId': widget.muId,
      'lastRead': widget.initialLastRead,
      'initialUrl': widget.initialUrl,
      'baseUserLink': widget.baseUserLink,
      'originHost': _originHost,
      'resumePercent': widget.initialPositionPercent,
      'autoDownload': widget.autoDownload,
    });
    unawaited(ReaderDiagnostics.logEnvironment());
    unawaited(ReaderDiagnostics.enableRemoteInspection());
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
    if (controller == null || chapter == null || _challengePending) return;
    unawaited(
      _scrollPositionService
          .saveScrollPosition(controller, widget.muId, chapter, immediate: true)
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
    // Recherche de lien : on navigue sur le site, pas dans un chapitre.
    if (widget.linkDiscovery) return;
    try {
      final nextChapterNumber = widget.initialLastRead + 1;
      final isDownloaded = await _downloadManager.isChapterDownloaded(widget.muId, nextChapterNumber);
      
      ReaderDiagnostics.log('offline.check', {
        'chapter': nextChapterNumber,
        'downloaded': isDownloaded,
      });
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
    ReaderDiagnostics.log('adblock.pref', {'enabled': _adBlockerEnabled});
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

    // Vérification en cours : la WebView affiche une page vierge. Rafraîchir,
    // c'est redemander la page du défi (geste délibéré : hors boucle).
    final challengeUrl = _challengeUrl;
    if (_challengePending && challengeUrl != null) {
      _loopDetector.reset();
      await _reloadAfterChallenge(challengeUrl);
      return;
    }

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
        final success = await _downloadCurrentPage(
          expectedChapter: _downloadMode ? _expectedDownloadChapter : null,
        );
        // Mode téléchargement : un succès ferme le lecteur — une seule fois,
        // par _finishAutoDownload (un double pop fermait aussi la fenêtre de
        // téléchargement multiple et tuait la série).
        if (_downloadMode && success) await _finishAutoDownload(true);
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
      case ReaderOverflowAction.setAsMangaLink:
        await _saveCurrentUrlAsLink();
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
    ReaderDiagnostics.log('challenge.loop', {
      'url': url,
      'count': _loopDetector.failureCount,
    });
    final action = await ChallengeEscapeDialog.show(
      context: context,
      url: url.toString(),
    );
    ReaderDiagnostics.log('challenge.loop.answer', {'action': action});
    if (action == ChallengeEscapeAction.retry && mounted) {
      _loopDetector.reset();
      if (_challengePending) {
        // La WebView affiche une page vierge : recharger la page du défi.
        await _reloadAfterChallenge(url);
      } else {
        await _controller?.reload();
      }
    }
  }

  /// `cf_clearance` courant de [url]. En mémoire seulement : c'est un jeton
  /// d'autorisation, il n'est JAMAIS journalisé.
  Future<String?> _readClearance(WebUri url) async {
    try {
      final cookie = await CookieManager.instance().getCookie(
        url: url,
        name: CloudflareChallenge.clearanceCookie,
      );
      return cookie?.value?.toString();
    } catch (_) {
      return null;
    }
  }

  /// La page principale est une vérification Cloudflare : on la confie à une
  /// WebView brute (voir ChallengeHandoffView pour le pourquoi, mesuré sur
  /// appareil).
  ///
  /// Appelé à la RÉPONSE du document, avant que le moindre script du défi ne
  /// tourne dans le lecteur. C'est essentiel : exécuté ici, le défi est
  /// « validé » avec un `cf_clearance` que Cloudflare refuse ensuite — et ce
  /// cookie écraserait celui obtenu par la WebView brute.
  Future<void> _startChallengeHandoff(
    InAppWebViewController controller,
    WebUri url,
  ) async {
    if (_challengePending || !mounted) return;
    _challengePending = true;
    _challengeUrl = url;
    ReaderDiagnostics.log('handoff.start', {
      'url': url,
      'loopCount': _loopDetector.failureCount,
    });
    // La page vierge n'a pas de position de lecture à sauvegarder.
    _scrollPositionService.stopSaveTimer();
    try {
      await controller.stopLoading();
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri('about:blank')),
      );
    } catch (e) {
      debugPrint('⚠️ Arrêt de la page de vérification impossible: $e');
    }
    if (!mounted) return;

    // Le défi revient encore et encore, même délégué : cesser d'insister et
    // proposer la sortie vers le navigateur.
    if (_loopDetector.recordChallenge(url.toString())) {
      await _handleChallengeLoop(url);
      return;
    }

    final before = await _readClearance(url);
    if (!mounted) return;
    setState(() {
      _clearanceBefore = before;
      _showHandoff = true;
    });
  }

  /// La WebView brute a obtenu un nouveau `cf_clearance` : le lecteur
  /// recharge la page, cette fois acceptée par Cloudflare.
  Future<void> _onHandoffPassed() async {
    final url = _challengeUrl;
    if (url == null || !mounted) return;
    ReaderDiagnostics.log('handoff.done', {'url': url});
    await _reloadAfterChallenge(url);
  }

  /// Quitte l'état « vérification » et recharge [url] dans le lecteur.
  ///
  /// Même page, même chapitre : `detectChapterChange` conclut à `noChange`,
  /// aucun chapitre n'est validé, et `onLoadStop` restaure la position.
  Future<void> _reloadAfterChallenge(WebUri url) async {
    _challengePending = false;
    _hasRestoredScroll = false;
    if (mounted) setState(() => _showHandoff = false);
    await _controller?.loadUrl(urlRequest: URLRequest(url: url));
  }

  Future<void> _openChallengeInBrowser() async {
    final url = _challengeUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url.toString()),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('⚠️ Ouverture dans le navigateur impossible: $e');
    }
  }

  /// Détecte la présence d'un captcha et désactive temporairement le bloqueur de pub
  Future<void> _detectAndHandleCaptcha(InAppWebViewController controller, WebUri url) async {
    try {
      final captchaType = await _captchaDetectionService.detectCaptcha(controller);
      ReaderDiagnostics.log('captcha.check', {
        'url': url,
        'type': captchaType ?? 'none',
        'flagged': _captchaDetected,
        'loopCount': _loopDetector.failureCount,
      });

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

  /// « Ceci est le nouveau lien » : la page affichée devient le lien de
  /// lecture du titre, puis on revient à sa fiche. Seule écriture du mode
  /// « recherche de lien », et uniquement sur geste explicite.
  Future<void> _saveCurrentUrlAsLink() async {
    final l10n = AppLocalizations.of(context);
    final url = (await _controller?.getUrl())?.toString();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _notifier.error(l10n?.invalidLink ??
          'Lien invalide. Le lien doit commencer par http:// ou https://');
      return;
    }
    final saved = await _library.updateCustomLink(widget.muId, url!);
    if (!mounted) return;
    if (!saved) {
      _notifier.error(l10n?.readerLinkSaveFailed ??
          "Impossible d'enregistrer ce lien. Réessayez.");
      return;
    }
    _notifier.success(l10n?.linkSaved ?? 'Lien enregistré !');
    // Sortie directe (PopScope ne concerne que les retours de l'utilisateur).
    Navigator.of(context).pop(true);
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

  /// En-têtes des requêtes d'images, comme les enverrait la WebView :
  /// `Referer` de la page, user-agent de la WebView et cookies de l'hôte de
  /// l'image. Sans eux, les serveurs d'images protégés contre le
  /// « hotlinking » (ou par Cloudflare) répondent 403 — et l'image était
  /// ignorée en silence.
  Future<ImageRequestHeaders> _imageRequestHeaders(String pageUrl) async {
    String? userAgent;
    try {
      userAgent = await InAppWebViewController.getDefaultUserAgent();
    } catch (_) {}
    final cookiesByOrigin = <String, String>{};
    return (Uri image) async {
      final origin = '${image.scheme}://${image.host}';
      var cookie = cookiesByOrigin[origin];
      if (cookie == null) {
        try {
          final cookies =
              await CookieManager.instance().getCookies(url: WebUri(origin));
          cookie = cookies.map((c) => '${c.name}=${c.value}').join('; ');
        } catch (_) {
          cookie = '';
        }
        cookiesByOrigin[origin] = cookie;
      }
      return {
        'Referer': pageUrl,
        if (userAgent != null && userAgent.isNotEmpty) 'User-Agent': userAgent,
        if (cookie.isNotEmpty) 'Cookie': cookie,
      };
    };
  }

  /// Relevé de la page pour [DownloadReadinessPolicy] — lecture seule.
  Future<DownloadPageProbe?> _probeDownloadPage() async {
    final controller = _controller;
    if (controller == null) return null;
    try {
      final raw = await controller.evaluateJavascript(source: _downloadProbeScript);
      final map = WebViewResultParser.asMap(raw);
      if (map == null) return null;
      final images = <ProbedImage>[];
      for (final entry in (map['imgs'] as List? ?? const [])) {
        if (entry is! Map) continue;
        final attrs = <String, String>{};
        (entry['a'] as Map? ?? const {}).forEach((key, value) {
          if (value != null) attrs['$key'] = '$value';
        });
        images.add(ProbedImage(
          attributes: attrs,
          width: (entry['w'] as num?)?.round() ?? 0,
        ));
      }
      final url = await controller.getUrl();
      return DownloadPageProbe(
        readyState: '${map['ready'] ?? ''}',
        urlChapter: url == null
            ? null
            : await ChapterLinkResolver.extractChapter(url.toString()),
        images: images,
      );
    } catch (e) {
      debugPrint('⚠️ Relevé de la page impossible: $e');
      return null;
    }
  }

  static final String _downloadProbeScript = '''
(function() {
  var names = ${jsonEncode(ChapterImageSource.relevantAttributes)};
  var imgs = [];
  var list = document.images || [];
  for (var i = 0; i < list.length && i < 500; i++) {
    var img = list[i], a = {};
    for (var j = 0; j < names.length; j++) {
      var v = img.getAttribute(names[j]);
      if (v) a[names[j]] = v;
    }
    imgs.push({ a: a, w: Math.round(img.getBoundingClientRect().width) });
  }
  return JSON.stringify({ ready: document.readyState, imgs: imgs });
})();
''';

  /// Mode téléchargement : télécharge le chapitre dès que la page est PRÊTE
  /// (voir [DownloadReadinessPolicy]), puis ferme le lecteur.
  ///
  /// Remplace un délai fixe de 2 s déclenché par la présence d'un cookie
  /// `cf_clearance` — déjà là sur la page « Un instant… » : le téléchargement
  /// partait avant le chargement et enregistrait un chapitre vide.
  Future<void> _runAutoDownload() async {
    if (_autoDownloadRunning || _downloadReported) return;
    _autoDownloadRunning = true;
    const policy = DownloadReadinessPolicy();
    final expected = _expectedDownloadChapter;
    final started = DateTime.now();
    DownloadPageProbe? previous;
    try {
      // Une vérification Cloudflare interrompt l'attente : la page sera
      // rechargée après la vérification, et l'attente reprendra.
      while (mounted && !_challengePending && !_downloadReported) {
        final probe = await _probeDownloadPage();
        if (probe == null) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        final decision = policy.decide(
          expectedChapter: expected,
          current: probe,
          previous: previous,
          elapsed: DateTime.now().difference(started),
        );
        ReaderDiagnostics.log('download.readiness', {
          'chapter': expected,
          'decision': decision.name,
          'ready': probe.readyState,
          'urlChapter': probe.urlChapter,
          'images': probe.chapterImageCount,
        });
        switch (decision) {
          case DownloadReadiness.wait:
            previous = probe;
            await Future.delayed(const Duration(seconds: 1));
          case DownloadReadiness.ready:
            final ok = await _downloadCurrentPage(expectedChapter: expected);
            await _finishAutoDownload(ok);
            return;
          case DownloadReadiness.wrongChapter:
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              _notifier.error(l10n?.downloadWrongChapter('$expected') ??
                  "Cette page n'est pas le chapitre $expected : téléchargement annulé.");
            }
            await _finishAutoDownload(false);
            return;
          case DownloadReadiness.timedOut:
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              _notifier.error(l10n?.downloadNotReady ??
                  "Le chapitre n'a pas fini de se charger : téléchargement abandonné.");
            }
            await _finishAutoDownload(false);
            return;
        }
      }
    } finally {
      _autoDownloadRunning = false;
    }
  }

  /// Fin du mode téléchargement : rend le résultat et ferme le lecteur —
  /// UNE seule fois, quel que soit le chemin (automatique ou bouton).
  ///
  /// Le résultat part par le rappel ET par `pop(success)` : la fenêtre de
  /// téléchargement multiple lit ce dernier, et un retour arrière de
  /// l'utilisateur (résultat `null`) y annule la série.
  Future<void> _finishAutoDownload(bool success) async {
    if (_downloadReported) return;
    _downloadReported = true;
    ReaderDiagnostics.log('download.done', {
      'chapter': _expectedDownloadChapter,
      'success': success,
    });
    widget.onDownloadComplete?.call(success);
    if (mounted) Navigator.of(context).pop(success);
  }

  /// Télécharge la page actuelle depuis le WebView.
  ///
  /// [expectedChapter] (mode téléchargement) : le chapitre DEMANDÉ. Une page
  /// qui en affiche un autre (redirection) n'est jamais enregistrée sous ce
  /// numéro.
  Future<bool> _downloadCurrentPage({int? expectedChapter}) async {
    try {
      final url = await _controller?.getUrl();
      if (url == null) {
        _notifier.error("Impossible de récupérer l'URL actuelle");
        return false;
      }

      final urlString = url.toString();

      // Extraire le numéro de chapitre depuis l'URL
      final urlChapter = await ChapterLinkResolver.extractChapter(urlString);
      if (expectedChapter != null &&
          urlChapter != null &&
          urlChapter != expectedChapter) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          _notifier.error(l10n?.downloadWrongChapter('$expectedChapter') ??
              "Cette page n'est pas le chapitre $expectedChapter : téléchargement annulé.");
        }
        return false;
      }
      final chapterNumber = urlChapter ?? expectedChapter;
      if (chapterNumber == null) {
        _notifier.error("Impossible de détecter le numéro de chapitre dans l'URL");
        return false;
      }

      // Afficher un message de chargement
      _notifier.info("Chargement des images...");

      // Le HTML tel quel, SANS le modifier : les vraies adresses des images
      // (data-src…) sont choisies côté Dart par ChapterImageSource. L'ancien
      // script partait de `src` — souvent une image d'attente — puis
      // SUPPRIMAIT data-src : la vraie adresse était perdue, et le chapitre
      // enregistré ne contenait que des images d'attente.
      const loadImagesScript = 'document.documentElement.outerHTML;';

      _notifier.info("Récupération du contenu de la page...");

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
      final processed = await downloadService.processHtmlForOfflineReport(
        cleanHtml,
        urlString,
        chapterPath,
        onProgress: (progress) {
          // La progression va de 0.0 à 1.0
          debugPrint('📥 Progression téléchargement images: ${(progress * 100).toStringAsFixed(1)}%');
        },
        headersFor: await _imageRequestHeaders(urlString),
      );
      ReaderDiagnostics.log('download.images', {
        'chapter': chapterNumber,
        'found': processed.imagesFound,
        'saved': processed.imagesSaved,
      });

      // Aucune image enregistrée : ce n'est PAS un chapitre téléchargé. Il
      // ne doit jamais apparaître « terminé » (il s'ouvrait vide hors ligne).
      if (!processed.hasContent) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          _notifier.error(l10n?.downloadNoImages ??
              "Aucune image du chapitre n'a pu être enregistrée : téléchargement annulé.");
        }
        return false;
      }

      // Sauvegarder le HTML traité avec les images localisées
      final htmlFilePath = path.join(chapterPath, 'chapter.html');
      final htmlFile = File(htmlFilePath);
      await htmlFile.writeAsString(processed.html, encoding: utf8);

      // Créer le modèle DownloadedChapter
      final downloadedChapter = DownloadedChapter(
        muId: widget.muId,
        chapterNumber: chapterNumber,
        downloadDate: DateTime.now(),
        imageCount: processed.imagesSaved,
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
      // Ni rappel ni fermeture ici : c'est l'appelant qui décide, une seule
      // fois (_finishAutoDownload). Fermer ici ET dans l'appelant dépilait
      // deux écrans — le second était la fenêtre de téléchargement multiple,
      // dont la série mourait en silence.
      return true;
    } catch (e) {
      debugPrint('❌ ReaderWebView: Erreur lors du téléchargement depuis le WebView: $e');
      _notifier.error("Erreur lors du téléchargement: $e");
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
      // Le chapitre est TERMINÉ : plus rien à reprendre dedans. On efface la
      // position locale et on cesse de l'envoyer — c'est cette suppression,
      // et non un refus d'écriture, qui garantit qu'un chapitre validé ne se
      // rouvre jamais en son milieu. Le serveur, lui, remet ses propres
      // champs à null tout seul.
      unawaited(
        _scrollPositionService
            .deleteScrollPosition(widget.muId, chapter)
            .then((_) {}, onError: (Object e) {
          debugPrint('⚠️ Position du chapitre $chapter non effacée: $e');
        }),
      );
      _readingPositionService.forget(widget.muId);
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
    // Lecture seule (téléchargement, recherche de lien) : aucun suivi.
    if (_readOnlyMode) return;
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
    ReaderDiagnostics.log('chapter.detect', {
      'url': uri,
      'previous': _currentChapter,
      'result': result == null
          ? 'null'
          : '${result.changeType} ${result.previousChapter}->${result.newChapter}',
    });
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
    // Mode téléchargement : rien n'a été lu — ni position à sauvegarder, ni
    // chapitre à proposer. Quitter ANNULE : la fenêtre de téléchargement
    // multiple reçoit un résultat `null` et arrête la série (au lieu
    // d'ouvrir aussitôt le chapitre suivant).
    if (_readOnlyMode) return true;

    // Sauvegarder la position de scroll avant de fermer
    debugPrint('🔍 _onWillPop - Sauvegarde de la position avant fermeture');
    debugPrint('🔍 _onWillPop - Controller: ${_controller != null}, Chapitre: $_currentChapter');
    // Vérification en cours : la WebView montre une page vierge, il n'y a ni
    // position à sauvegarder ni chapitre à proposer.
    final challengePending = _challengePending;
    if (_controller != null && _currentChapter != null && !challengePending) {
      debugPrint('🔍 _onWillPop - Sauvegarde de la position pour chapitre $_currentChapter');
      await _scrollPositionService.saveScrollPosition(
        _controller!,
        widget.muId,
        _currentChapter!,
        immediate: true,
      );
      debugPrint('🔍 _onWillPop - Position sauvegardée avec succès');
    } else {
      debugPrint('⚠️ _onWillPop - Impossible de sauvegarder: controller=${_controller != null}, chapter=$_currentChapter');
    }
    
    // Si on est sur le chapitre C, qu'il n'est pas déjà enregistré et que la
    // lecture est proche de la fin, on demande « Avez-vous fini le chapitre
    // C ? ». La décision appartient à ChapterCommitPolicy.
    final exit = _commitPolicy.onExit(
      currentChapter: _currentChapter,
      lastCommitted: _lastCommitted,
      isNearEnd: challengePending ? false : await _isNearEndOfChapter(),
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
              linkDiscovery: widget.linkDiscovery,
            ),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
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
            ReaderDiagnostics.log('nav', {
              'decision': decision.name,
              'reason': uri == null
                  ? 'no-url'
                  : _adBlockerService.shouldBlockRequest(uri.toString())
                      ? 'ad-url'
                      : (action.isForMainFrame && !_isAllowedDomain(uri.host))
                          ? 'foreign-host(origin=$_originHost)'
                          : 'allowed',
              'main': action.isForMainFrame,
              'redirect': action.isRedirect,
              'gesture': action.hasGesture,
              'method': action.request.method,
              // Noms seulement : ce que la relance via loadUrl renverra.
              'headers': action.request.headers?.keys.join(','),
              'url': uri,
            });
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
            ReaderDiagnostics.log('load.start', {
              'url': url,
              'allowedHost': url == null ? null : _isAllowedDomain(url.host),
            });
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
          onUpdateVisitedHistory: (controller, url, isReload) {
            ReaderDiagnostics.log('history', {'url': url, 'reload': isReload});
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
            ReaderDiagnostics.log('load.stop', {'url': url});
            // Vérification Cloudflare en cours (page vierge ou page de défi) :
            // rien à nettoyer, mesurer, restaurer ni télécharger. Sans cette
            // garde, le téléchargement automatique partait sur la page
            // « Un instant… » (le cookie cf_clearance y est déjà présent) et
            // la position du chapitre était écrasée par celle de cette page.
            if (_challengePending) return;
            if (ReaderDiagnostics.enabled && url != null) {
              await ReaderDiagnostics.probePage(controller, 'loadStop');
              await ReaderDiagnostics.logCookies(url, 'loadStop');
            }
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
            // (jamais en mode téléchargement : cela réécrivait le lien de
            // lecture de l'utilisateur).
            if (!_readOnlyMode && _currentChapter == null && url != null) {
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
            if (!_readOnlyMode &&
                _currentChapter != null &&
                mounted &&
                _controller != null) {
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
              final resumePercent = _pendingResumePercent;
              _pendingResumePercent = null;
              _scrollPositionService.restoreScrollPosition(
                _controller!,
                widget.muId,
                _currentChapter!,
                hasRestoredScroll: _hasRestoredScroll,
                fallbackPercent: resumePercent,
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
            
            // Mode téléchargement : télécharger dès que la page du chapitre
            // est PRÊTE (DownloadReadinessPolicy), une seule fois, puis
            // fermer. Plus de délai fixe déclenché par un cookie.
            if (_downloadMode && url != null && mounted) {
              unawaited(_runAutoDownload());
            }
          },

          // 5) Gestion des erreurs CORS en mode web
          onReceivedError: (controller, request, error) {
            ReaderDiagnostics.log('error', {
              'main': request.isForMainFrame,
              'type': error.type,
              'description': error.description,
              'url': request.url,
            });
            if (kIsWeb && error.description.contains('CORS')) {
              setState(() {
                _corsBlocked = true;
              });
            }
          },

          // 5 bis) Vérification Cloudflare : repérée à la RÉPONSE du document
          // principal (en-tête `cf-mitigated: challenge`), avant que le
          // moindre script du défi ne tourne, puis confiée à une WebView
          // brute. Voir ChallengeHandoffView (cause mesurée sur appareil).
          onReceivedHttpError: (controller, request, response) {
            final isMainFrame = request.isForMainFrame ?? false;
            if (ReaderDiagnostics.enabled) {
              final headers = response.headers ?? const {};
              String? header(String name) => headers.entries
                  .where((e) => e.key.toLowerCase() == name)
                  .map((e) => e.value)
                  .firstOrNull;
              ReaderDiagnostics.log('http', {
                'status': response.statusCode,
                'reason': response.reasonPhrase,
                'main': isMainFrame,
                'server': header('server'),
                'cfMitigated': header('cf-mitigated'),
                'cfRay': header('cf-ray'),
                'url': request.url,
              });
            }
            if (CloudflareChallenge.isChallengeResponse(
              isForMainFrame: isMainFrame,
              statusCode: response.statusCode,
              headers: response.headers,
            )) {
              unawaited(_startChallengeHandoff(controller, request.url));
            }
          },

          // Diagnostic uniquement : hors build de diagnostic, ces rappels
          // restent absents pour ne rien changer au comportement.
          onTitleChanged: ReaderDiagnostics.enabled
              ? (controller, title) =>
                  ReaderDiagnostics.log('title', {'title': title})
              : null,

          onRenderProcessGone: ReaderDiagnostics.enabled
              ? (controller, detail) => ReaderDiagnostics.log(
                  'render.gone', {'crash': detail.didCrash})
              : null,

          onConsoleMessage: (controller, consoleMessage) {
            ReaderDiagnostics.log('console', {
              'level': consoleMessage.messageLevel,
              'message': consoleMessage.message,
            });
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
            // Par-dessus le lecteur (qui reste monté : son contrôleur et son
            // état de lecture survivent à la vérification).
            if (_showHandoff && _challengeUrl != null)
              Positioned.fill(
                child: ChallengeHandoffView(
                  key: ValueKey(_challengeUrl.toString()),
                  url: Uri.parse(_challengeUrl.toString()),
                  clearanceBefore: _clearanceBefore,
                  readClearance: () => _readClearance(_challengeUrl!),
                  onPassed: _onHandoffPassed,
                  onOpenInBrowser: _openChallengeInBrowser,
                ),
              ),
            // Recherche de lien : consigne + raccourci « Ceci est le nouveau
            // lien » (aussi dans le menu ⋮).
            if (widget.linkDiscovery && !_showHandoff && _discoveryHintVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinkDiscoveryBanner(
                  mangaTitle: widget.mangaTitle,
                  onSaveLink: _saveCurrentUrlAsLink,
                  onDismiss: () =>
                      setState(() => _discoveryHintVisible = false),
                ),
              ),
          ],
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
    if (_controller != null && _currentChapter != null && !_challengePending) {
      debugPrint('🔍 dispose() - Sauvegarde de la position pour chapitre $_currentChapter');
      // Utiliser un Future pour sauvegarder sans bloquer dispose
      _scrollPositionService.saveScrollPosition(
        _controller!,
        widget.muId,
        _currentChapter!,
        immediate: true,
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
