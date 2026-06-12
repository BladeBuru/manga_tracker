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
import 'package:mangatracker/features/reader/services/webview_navigation_service.dart';
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

class _ReaderWebViewState extends State<ReaderWebView> {
  final _notifier = getIt<Notifier>();
  final _library = getIt<LibraryService>();
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
    // Initialiser le service de patterns d'URL personnalisés
    ChapterLinkResolver.init(CustomSelectorsService());
    _lastCommitted = widget.initialLastRead;
    _originHost = Uri.parse(widget.initialUrl).host;
    _loadAdBlockerPreference();
    // Charger les blockers de manière asynchrone
    _loadBlockers();
    // Vérifier si le chapitre est téléchargé et rediriger si nécessaire
    _checkAndRedirectToOffline();
  }

  /// Vérifie si le chapitre suivant est téléchargé et redirige vers OfflineReaderView si c'est le cas
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

  Future<void> _toggleAdBlocker(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_blocker_enabled', enabled);
    setState(() {
      _adBlockerEnabled = enabled;
      // Si on réactive le bloqueur et qu'un captcha était détecté, réinitialiser
      if (enabled && _captchaDetected) {
        _captchaDetected = false;
      }
    });
    // Recharger les blockers
    await _reloadBlockers();
    // Recharger la page pour appliquer les changements
    await _controller?.reload();
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

  /// Détecte la présence d'un captcha et désactive temporairement le bloqueur de pub
  Future<void> _detectAndHandleCaptcha(InAppWebViewController controller, WebUri url) async {
    try {
      final captchaType = await _captchaDetectionService.detectCaptcha(controller);
      
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
    setState(() {
      _interactiveAdBlockMode = !_interactiveAdBlockMode;
    });

    if (_controller == null) return;

    if (_interactiveAdBlockMode) {
      _notifier.info("Mode détection activé - Cliquez sur une pub pour la bloquer automatiquement");
      await _adBlockerService.injectInteractiveAdBlockScript(_controller!);
    } else {
      _notifier.info("Mode détection désactivé");
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
        icon: const Icon(Icons.block, color: Colors.red, size: 48),
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
            icon: const Icon(Icons.chat, size: 18),
            label: Text(l10n?.joinDiscord ?? 'Rejoindre Discord'),
          ),
        ],
      ),
    );
  }

  Future<void> _commitIfNeeded(int chapter) async {
    if (chapter <= _lastCommitted) {
      return;
    }
    final ok = await _library.saveChapterProgress(widget.muId, chapter);
    if (ok) {
      _lastCommitted = chapter;
      // Journal additif (Stats v2) : trace la session de lecture pour
      // l'historique + l'activité hebdo. Fire-and-forget : n'altère PAS
      // le pointeur de progression (RETRO-015), un échec perd juste une
      // entrée d'historique.
      unawaited(
        _library
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

  void _handleDetected(Uri uri) async {
    final result = await _navigationService.detectChapterChange(
      uri,
      _originHost,
      _currentChapter,
    );
    
    if (result == null) return;
    
    final newCh = result.newChapter!;
    
    // Fonction helper pour initialiser un nouveau chapitre
    void initializeChapter(int chapter) {
      _currentChapter = chapter;
      _updateNextLinkFrom(uri.toString(), currentChapter: chapter);
      _hasRestoredScroll = false;
      if (_controller != null) {
        _scrollPositionService.startSaveTimer(_controller!, widget.muId, chapter);
      }
    }
    
    switch (result.changeType) {
      case ChapterChangeType.firstDetected:
        initializeChapter(newCh);
        break;
        
      case ChapterChangeType.nextChapter:
        // Passage naturel au suivant => on valide le précédent ET le nouveau
        final prev = result.previousChapter!;
        // Sauvegarder la position du chapitre actuel avant de changer
        if (_controller != null) {
          await _scrollPositionService.saveScrollPosition(_controller!, widget.muId, prev);
        }
        // Supprimer la position sauvegardée du chapitre précédent (on avance)
        await _scrollPositionService.deleteScrollPosition(widget.muId, prev);
        // Sauvegarder le chapitre précédent comme lu
        await _commitIfNeeded(prev);
        // Sauvegarder aussi le nouveau chapitre comme lu (car on est dessus)
        await _commitIfNeeded(newCh);
        initializeChapter(newCh);
        break;
        
      case ChapterChangeType.jumpForward:
        // Saut de chapitres => on propose de valider le précédent
        final prev = result.previousChapter!;
        // Sauvegarder la position du chapitre actuel avant de changer
        if (_controller != null) {
          await _scrollPositionService.saveScrollPosition(_controller!, widget.muId, prev);
        }
        // Supprimer la position sauvegardée du chapitre actuel (on avance)
        await _scrollPositionService.deleteScrollPosition(widget.muId, prev);
        _promptJumpConfirm(prev: prev, next: newCh).then((yes) {
          if (yes == true) _commitIfNeeded(newCh - 1); // on valide au moins le précédent
          initializeChapter(newCh);
        });
        break;
        
      case ChapterChangeType.jumpBackward:
        // Retour en arrière => sauvegarder la position du chapitre actuel avant de changer
        final prev = result.previousChapter!;
        if (_controller != null) {
          await _scrollPositionService.saveScrollPosition(_controller!, widget.muId, prev);
        }
        // Supprimer la position sauvegardée du chapitre actuel car on recule
        await _scrollPositionService.deleteScrollPosition(widget.muId, prev);
        initializeChapter(newCh);
        break;
        
      case ChapterChangeType.noChange:
        // Même chapitre, rien à faire
        break;
    }
  }

  bool _isAllowedDomain(String host) {
    return _adBlockerService.isAllowedDomain(host, _originHost);
  }

  Future<bool?> _promptJumpConfirm({required int prev, required int next}) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.skip_next, color: Colors.orange, size: 48),
        title: Text(l10n?.chapterSkip ?? "Saut de chapitres"),
        content: Text(
          l10n?.chapterSkipMessage(prev.toString(), next.toString()) ?? 
          "Vous passez du chapitre $prev au $next.\nMarquer $prev comme lu ?"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.no ?? "Non"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n?.yes ?? "Oui"),
          ),
        ],
      ),
    );
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
    
    // Si on est sur le chap C et que le dernier validé est < C,
    // on demande si l'utilisateur a fini le chapitre C UNIQUEMENT s'il est proche de la fin.
    final c = _currentChapter;
    if (c != null && _lastCommitted < c) {
      // Vérifier si l'utilisateur est proche de la fin du chapitre
      final isNearEnd = await ReadingProgressHelper.isNearEndOfChapter(_controller);
      
      // Ne demander la validation que si l'utilisateur est proche de la fin
      if (!isNearEnd) {
        // NE PAS marquer le chapitre comme lu si l'utilisateur n'est pas proche de la fin
        // La position de scroll est déjà sauvegardée par ScrollPositionService
        return true; // Fermer sans demander
      }
      
      final l10n = AppLocalizations.of(context);
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          title: Text(l10n?.validateReading ?? "Valider la lecture"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.validateReadingMessage(c.toString()) ?? 
                "Avez-vous fini le chapitre $c ?",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.validateReadingHint ?? 
                        "Votre progression sera sauvegardée automatiquement.",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n?.no ?? "Non"),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n?.yesValidate ?? "Oui, valider"),
            ),
          ],
        ),
      );
      if (yes == true) {
        await _commitIfNeeded(c);
        final currentUrl = await _controller?.getUrl();
        await _updateNextLinkFrom(
          (currentUrl?.toString() ?? widget.baseUserLink),
          currentChapter: c,
        );
      }
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.webModeProgressTracking ?? 'Mode Web - Suivi de progression',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
      return WillPopScope(
        onWillPop: _onWillPop,
        child: _buildWebFallback(),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.readOnline ?? 'Lire en ligne'),
          actions: [
            // Bouton pour télécharger la page actuelle
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async {
                final success = await _downloadCurrentPage();
                // Si autoDownload est activé et que le téléchargement a réussi, fermer la webview
                if (widget.autoDownload && success && mounted) {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Télécharger cette page',
            ),
            // Bouton pour copier l'URL
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyCurrentUrl,
              tooltip: AppLocalizations.of(context)?.copyUrl ?? 'Copier l\'URL',
            ),
            // Toggle pour activer/désactiver le bloqueur de pub avec icône
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône d'information
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: _showAdBlockerInfo,
                  tooltip: AppLocalizations.of(context)?.adBlockerTooltip ?? 'Informations sur le bloqueur de pub',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Bouton pour le mode interactif de détection de pub
                IconButton(
                  icon: Icon(
                    _interactiveAdBlockMode ? Icons.touch_app : Icons.touch_app_outlined,
                    size: 20,
                    color: _interactiveAdBlockMode ? Colors.orange : Colors.grey,
                  ),
                  onPressed: _toggleInteractiveAdBlockMode,
                  tooltip: _interactiveAdBlockMode 
                    ? 'Mode détection activé - Cliquez sur une pub pour la bloquer'
                    : 'Activer le mode détection de pub',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                // Icône de blocage au lieu du texte
                Icon(
                  _adBlockerEnabled ? Icons.block : Icons.block_outlined,
                  size: 20,
                  color: _adBlockerEnabled ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                // Switch
                Switch(
                  value: _adBlockerEnabled,
                  onChanged: _toggleAdBlocker,
                ),
              ],
            ),
          ],
        ),
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: true,
            contentBlockers: _cachedBlockers,
            allowsInlineMediaPlayback: true,
            iframeAllow: "camera; microphone",
            iframeAllowFullscreen: true,
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

          // 1) Nouvelle navigation principale - Blocage strict des redirections
          shouldOverrideUrlLoading: (controller, action) async {
            if (action.request.url == null) {
              return NavigationActionPolicy.ALLOW;
            }

            final url = action.request.url!.toString();
            final uri = action.request.url!;
            final host = uri.host;

            // Bloquer les domaines de publicités
            if (_adBlockerService.shouldBlockRequest(url)) {
              return NavigationActionPolicy.CANCEL;
            }

            // Pour les frames principales, vérifier le domaine
            if (action.isForMainFrame) {
              // Si ce n'est pas le même domaine, bloquer
              if (!_isAllowedDomain(host)) {
                return NavigationActionPolicy.CANCEL;
              }
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
