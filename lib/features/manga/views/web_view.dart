import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import '../../reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ReaderWebView extends StatefulWidget {
  final int muId;
  final int initialLastRead;      // ex. 119
  final String initialUrl;        // ex. URL du 120 si résoluble, sinon baseLink
  final String baseUserLink;      // le lien saisi par l’utilisateur (référence)

  const ReaderWebView({
    super.key,
    required this.muId,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  final _notifier = getIt<Notifier>();
  final _library = getIt<LibraryService>();

  InAppWebViewController? _controller;
  final TextEditingController _urlTextController = TextEditingController();

  // État lecteur
  late int _lastCommitted;      // dernier chapitre confirmé en base
  int? _currentChapter;         // chapitre actuellement affiché (détecté)
  late String _originHost;      // domaine d'origine (pour filtrer)
  bool _adBlockerEnabled = true;
  bool _corsBlocked = false;

  // Liste étendue de domaines de publicités
  final Set<String> _denyHosts = {
    'google-analytics.com',
    'www.google-analytics.com',
    'googlesyndication.com',
    'pagead2.googlesyndication.com',
    'doubleclick.net',
    'adservice.google.com',
    'taboola.com',
    'outbrain.com',
    'criteo.com',
    'scorecardresearch.com',
    'adsafeprotected.com',
    'advertising.com',
    'amazon-adsystem.com',
    'adnxs.com',
    'adform.net',
    'adtechus.com',
    'adzerk.net',
    'casalemedia.com',
    'contextweb.com',
    'facebook.com/tr',
    'googletagmanager.com',
    'moatads.com',
    'openx.net',
    'pubmatic.com',
    'rubiconproject.com',
    'serving-sys.com',
    'smartadserver.com',
    'yieldlab.net',
    'zemanta.com',
    // Nouveaux domaines détectés
    'onclckmn.com',
    'onclckbn.net',
    'bid.onclckbn.net',
    'adxbid.info',
    'a.pemsrv.com',
    's.pemsrv.com',
    'pemsrv.com',
    'media.pubfuture.com',
    'pubfuture.com',
    'bobapsoabauns.com',
    // Domaines de synchronisation et overlay
    'kueezrtb.com',
    'sync.kueezrtb.com',
    'monetixads.com',
    'static.cdn.monetixads.com',
    // Nouveaux domaines détectés
    'crcdn.org',
    'adexchangeclear.com',
    'aqle3.com',
    'pubadx.one',
    'imp9.pubadx.one',
    'madurird.com',
  };

  // Ad-blocker amélioré avec sélecteurs CSS plus précis
  List<ContentBlocker> get _blockers {
    if (!_adBlockerEnabled) return [];
    
    return [
      // Blocage de domaines de publicités connus
      ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: r".*(doubleclick\.net|googlesyndication\.com|adservice\.google\..*|google-analytics\.com|taboola\.com|outbrain\.com|criteo\.com|scorecardresearch\.com|adsafeprotected\.com|advertising\.com|amazon-adsystem\.com|adnxs\.com|adform\.net|adtechus\.com|adzerk\.net|casalemedia\.com|contextweb\.com|googletagmanager\.com|moatads\.com|openx\.net|pubmatic\.com|rubiconproject\.com|serving-sys\.com|smartadserver\.com|yieldlab\.net|zemanta\.com|onclckmn\.com|onclckbn\.net|bid\.onclckbn\.net|adxbid\.info|pemsrv\.com|media\.pubfuture\.com|pubfuture\.com|bobapsoabauns\.com|kueezrtb\.com|monetixads\.com|crcdn\.org|adexchangeclear\.com|aqle3\.com|pubadx\.one|madurird\.com).*",
        ),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      ),
      // Sélecteurs CSS plus spécifiques pour éviter de bloquer les images du chapitre
      ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: r".*"),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.CSS_DISPLAY_NONE,
          selector: """
            .advertisement,
            .ad-banner,
            .ad-container,
            .ad-wrapper,
            .ad-box,
            .ad-unit,
            .ad-slot,
            .ad-placeholder,
            .ad-content,
            .ad-frame,
            .ad-holder,
            .ad-area,
            .ad-section,
            .ad-block,
            .ad-widget,
            .ad-panel,
            .ad-sidebar,
            .ad-header,
            .ad-footer,
            .ad-top,
            .ad-bottom,
            .ad-left,
            .ad-right,
            .ad-center,
            #advertisement,
            #ad-banner,
            #ad-container,
            #ad-wrapper,
            #ad-box,
            #ad-unit,
            #ad-slot,
            #ad-content,
            #ad-frame,
            #ad-area,
            #ad-section,
            #ad-block,
            #ad-widget,
            #ad-panel,
            #ad-sidebar,
            #ad-header,
            #ad-footer,
            iframe[src*='doubleclick'],
            iframe[src*='googlesyndication'],
            iframe[src*='adservice'],
            iframe[src*='advertising'],
            iframe[src*='ads'],
            iframe[src*='onclck'],
            iframe[src*='onclckbn'],
            iframe[src*='onclckmn'],
            iframe[src*='pemsrv'],
            iframe[src*='pubfuture'],
            iframe[src*='adxbid'],
            iframe[src*='kueezrtb'],
            iframe[src*='monetixads'],
            iframe[id*='ad'],
            iframe[class*='ad'],
            iframe[data-cbi],
            iframe[style*='position: fixed'],
            iframe[style*='z-index'],
            iframe[sandbox],
            iframe[data-asg-handled],
            div[id*='google_ads'],
            div[class*='google-ad'],
            div[id*='ad-'],
            div[class*='ad-'],
            div[id*='pf-'],
            div[class*='pf-'],
            div[class*='PUBFUTURE'],
            div[class*='pf-config'],
            div[class*='pf-wrapper'],
            div[class*='gfpl-'],
            div[id*='asg-'],
            div[class*='ammc8brnmqe2aahjvxvkti9jx6p1df1o'],
            div[id*='bg-ssp-'],
            div[class*='bg-ssp-'],
            div[id*='note-'],
            div[id*='dl-banner-'],
            in-page-message,
            [data-unit],
            [data-banner-id],
            [data-funnel],
            [data-bg],
            [data-icon],
            [data-title*='Bloquez'],
            [data-description*='Naviguez'],
            ins[class*='adsbygoogle'],
            script[src*='ads'],
            script[src*='advertising'],
            script[src*='onclck'],
            script[src*='pemsrv'],
            script[src*='pubfuture'],
            script[src*='adxbid'],
            script[id*='popmagic'],
            [data-ad-slot],
            [data-ad-client],
            [data-ad-format],
            [data-unit],
            [data-banner-id],
            .PUBFUTURE,
            [class*="pf-config"],
            [class*="pf-wrapper"],
            [class*="gfpl-"]
          """,
        ),
      ),
    ];
  }

  // Script JavaScript pour nettoyer le DOM des publicités
  String get _adBlockScript => """
    (function() {
      // Supprimer les éléments publicitaires spécifiques
      const adSelectors = [
        '.advertisement', '.ad-banner', '.ad-container', '.ad-wrapper',
        '.ad-box', '.ad-unit', '.ad-slot', '.ad-content', '.ad-frame',
        '#advertisement', '#ad-banner', '#ad-container', '#ad-wrapper',
        'iframe[src*="doubleclick"]', 'iframe[src*="googlesyndication"]',
        'iframe[src*="adservice"]', 'iframe[src*="onclck"]',
        'iframe[src*="onclckbn"]', 'iframe[src*="onclckmn"]',
        'iframe[src*="pemsrv"]', 'iframe[src*="pubfuture"]',
        'iframe[src*="adxbid"]', 'iframe[src*="kueezrtb"]',
        'iframe[src*="monetixads"]', 'iframe[data-cbi]',
        'iframe[sandbox]', 'iframe[data-asg-handled]',
        'ins.adsbygoogle', '[data-ad-slot]', '[data-ad-client]',
        '.PUBFUTURE', '[class*="pf-"]', '[id*="pf-"]',
        '[class*="pf-config"]', '[class*="pf-wrapper"]',
        '[class*="gfpl-"]', '[data-unit]', '[data-banner-id]',
        '[id*="asg-"]', '[class*="ammc8brnmqe2aahjvxvkti9jx6p1df1o"]',
        '[id*="bg-ssp-"]', '[class*="bg-ssp-"]',
        '[id*="note-"]', '[id*="dl-banner-"]',
        'in-page-message', '[data-funnel]', '[data-bg]',
        '[data-icon]', '[data-title*="Bloquez"]',
        'script[src*="onclck"]', 'script[src*="pemsrv"]',
        'script[src*="pubfuture"]', 'script[src*="adxbid"]',
        'script[src*="aqle3"]', 'script[src*="pubadx"]',
        'script[id*="popmagic"]', '.pf-banner-default'
      ];
      
      // Fonction pour supprimer les éléments publicitaires
      function removeAds() {
        adSelectors.forEach(selector => {
          try {
            document.querySelectorAll(selector).forEach(el => {
              // Vérifier que ce n'est pas une image du chapitre
              const isChapterImage = el.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content, .reading-content, [class*="chapter"], [id*="chapter"]');
              if (!isChapterImage) {
                el.remove();
              }
            });
          } catch(e) {}
        });
        
        // Supprimer les scripts de publicités spécifiques
        try {
          document.querySelectorAll('script').forEach(script => {
            const src = script.src || '';
            const content = script.textContent || script.innerHTML || '';
            if (src.includes('onclck') || src.includes('pemsrv') || 
                src.includes('pubfuture') || src.includes('adxbid') ||
                content.includes('pubfuturetag') || content.includes('popMagic') ||
                content.includes('window.pubfuturetag') || content.includes('popmagic')) {
              const isChapterScript = script.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content');
              if (!isChapterScript) {
                script.remove();
              }
            }
          });
        } catch(e) {}
        
        // Supprimer les iframes cachées (position: absolute avec top/left négatifs)
        try {
          document.querySelectorAll('iframe[style*="top: -"], iframe[style*="left: -"]').forEach(iframe => {
            const style = iframe.getAttribute('style') || '';
            if (style.includes('top: -') || style.includes('left: -') || 
                style.includes('visibility: hidden') || iframe.hasAttribute('data-asg-handled')) {
              const isChapterIframe = iframe.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content');
              if (!isChapterIframe) {
                iframe.remove();
              }
            }
          });
        } catch(e) {}
        
        // Supprimer les éléments in-page-message (publicités pour bloqueurs de pub)
        try {
          document.querySelectorAll('in-page-message, [id*="note-"], [data-icon], [data-title*="Bloquez"], [data-description*="Naviguez"]').forEach(el => {
            const isChapterElement = el.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content');
            if (!isChapterElement) {
              el.remove();
            }
          });
        } catch(e) {}
        
        // Supprimer les éléments ASG et bg-ssp
        try {
          document.querySelectorAll('[id*="asg-"], [class*="ammc8brnmqe2aahjvxvkti9jx6p1df1o"], [id*="bg-ssp-"], [class*="bg-ssp-"], [id*="dl-banner-"]').forEach(el => {
            const isChapterElement = el.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content');
            if (!isChapterElement) {
              el.remove();
            }
          });
        } catch(e) {}
        
        // Supprimer les scripts de publicités supplémentaires
        try {
          document.querySelectorAll('script').forEach(script => {
            const src = script.src || '';
            const content = script.textContent || script.innerHTML || '';
            if (src.includes('aqle3') || src.includes('pubadx') || src.includes('adexchangeclear') ||
                content.includes('bg-ssp') || content.includes('asg-') || content.includes('ammc8brnmqe2aahjvxvkti9jx6p1df1o')) {
              const isChapterScript = script.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content');
              if (!isChapterScript) {
                script.remove();
              }
            }
          });
        } catch(e) {}
        
        // Supprimer les iframes en overlay (qui couvrent toute la page)
        try {
          document.querySelectorAll('iframe').forEach(iframe => {
            const style = iframe.getAttribute('style') || '';
            const computedStyle = window.getComputedStyle(iframe);
            const zIndex = parseInt(computedStyle.zIndex || style.match(/z-index[\\s:]*([0-9]+)/)?.[1] || '0');
            const position = computedStyle.position || style.match(/position[\\s:]*([^;]+)/)?.[1]?.trim();
            const width = computedStyle.width || iframe.getAttribute('width') || '';
            const height = computedStyle.height || iframe.getAttribute('height') || '';
            
            // Détecter les iframes qui couvrent toute la page
            const isFullScreenOverlay = 
              (position === 'fixed' && zIndex > 1000) ||
              (style.includes('position: fixed') && zIndex > 1000) ||
              (style.includes('width: 100%') && style.includes('height: 100%') && zIndex > 1000) ||
              (style.includes('inset: 0px') && zIndex > 1000) ||
              (width === '100%' && height === '100%' && zIndex > 1000);
            
            // Détecter les iframes de synchronisation cachées
            const isSyncIframe = 
              iframe.hasAttribute('sandbox') && 
              (width === '0' || height === '0' || style.includes('width:0') || style.includes('height:0') ||
               iframe.src.includes('sync') || iframe.src.includes('kueezrtb') || iframe.src.includes('monetixads'));
            
            if (isFullScreenOverlay || isSyncIframe) {
              const isChapterIframe = iframe.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content, .reading-content, [class*="chapter"], [id*="chapter"]');
              if (!isChapterIframe) {
                iframe.remove();
              }
            }
          });
        } catch(e) {}
        
        // Supprimer les éléments avec des styles de popup/publicité
        try {
          document.querySelectorAll('div[style*="position: absolute"], div[style*="position: fixed"]').forEach(el => {
            const style = el.getAttribute('style') || '';
            const text = el.textContent || '';
            // Détecter les popups de publicité
            if ((style.includes('z-index') && parseInt(style.match(/z-index[\\s:]*([0-9]+)/)?.[1] || '0') > 100) ||
                text.includes('Validation requise') || text.includes('Veuillez compléter') ||
                text.includes('Continuer') && text.includes('Fermer') ||
                el.querySelector('[style*="background"][style*="border-radius"][style*="box-shadow"]')) {
              const isChapterPopup = el.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content');
              if (!isChapterPopup) {
                el.remove();
              }
            }
          });
        } catch(e) {}
      }
      
      // Exécuter immédiatement
      removeAds();
      
      // Observer pour les publicités chargées dynamiquement
      const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
          mutation.addedNodes.forEach(function(node) {
            if (node.nodeType === 1) {
              const element = node;
              // Vérifier si c'est une publicité
              const isAd = 
                (element.id && (element.id.includes('ad') || element.id.includes('pf-') || 
                 element.id.includes('asg-') || element.id.includes('bg-ssp-') || 
                 element.id.includes('note-') || element.id.includes('dl-banner-'))) ||
                (element.className && typeof element.className === 'string' && 
                 (element.className.includes('ad') || element.className.includes('PUBFUTURE') || 
                  element.className.includes('pf-') || element.className.includes('gfpl-') ||
                  element.className.includes('ammc8brnmqe2aahjvxvkti9jx6p1df1o') ||
                  element.className.includes('bg-ssp-'))) ||
                (element.tagName === 'SCRIPT' && (
                  (element.src && (element.src.includes('onclck') || element.src.includes('pemsrv') || 
                   element.src.includes('pubfuture') || element.src.includes('adxbid') ||
                   element.src.includes('aqle3') || element.src.includes('pubadx') ||
                   element.src.includes('adexchangeclear'))) ||
                  (element.textContent && (element.textContent.includes('pubfuturetag') || 
                   element.textContent.includes('popMagic') || element.textContent.includes('bg-ssp') ||
                   element.textContent.includes('asg-') || element.textContent.includes('ammc8brnmqe2aahjvxvkti9jx6p1df1o')))
                )) ||
                (element.tagName === 'IFRAME' && (
                  (element.src && (element.src.includes('onclck') || element.src.includes('pemsrv') ||
                   element.src.includes('pubfuture') || element.src.includes('adxbid') ||
                   element.src.includes('kueezrtb') || element.src.includes('monetixads'))) ||
                  (element.hasAttribute('sandbox') && (element.getAttribute('style')?.includes('width:0') || 
                   element.getAttribute('width') === '0')) ||
                  (element.getAttribute('style')?.includes('position: fixed') && 
                   parseInt(element.getAttribute('style')?.match(/z-index[\\s:]*([0-9]+)/)?.[1] || '0') > 1000) ||
                  element.hasAttribute('data-asg-handled')
                )) ||
                element.tagName === 'IN-PAGE-MESSAGE' ||
                element.hasAttribute('data-unit') || element.hasAttribute('data-banner-id') ||
                element.hasAttribute('data-asg-handled') || element.hasAttribute('data-funnel') ||
                element.hasAttribute('data-icon') || element.hasAttribute('data-bg') ||
                (element.hasAttribute('data-title') && element.getAttribute('data-title')?.includes('Bloquez')) ||
                (element.hasAttribute('data-description') && element.getAttribute('data-description')?.includes('Naviguez'));
              
              if (isAd) {
                const isChapterImage = element.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content, .reading-content, [class*="chapter"], [id*="chapter"]');
                if (!isChapterImage) {
                  element.remove();
                }
              }
            }
          });
        });
      });
      
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
      
      // Nettoyer périodiquement (toutes les 3 secondes au lieu de 2 pour réduire les appels)
      let cleanupInterval = null;
      function startPeriodicCleanup() {
        if (cleanupInterval) return; // Déjà démarré
        cleanupInterval = setInterval(function() {
          try {
            // Vérifier que le document est toujours valide
            if (document.body && document.body.parentNode) {
              removeAds();
            } else {
              // Arrêter le nettoyage si le document est détruit
              if (cleanupInterval) {
                clearInterval(cleanupInterval);
                cleanupInterval = null;
              }
            }
          } catch(e) {
            // Ignorer les erreurs silencieusement
          }
        }, 3000);
      }
      
      startPeriodicCleanup();
      
      // Arrêter le nettoyage si la page est déchargée
      window.addEventListener('beforeunload', function() {
        if (cleanupInterval) {
          clearInterval(cleanupInterval);
          cleanupInterval = null;
        }
      });
    })();
  """;

  @override
  void initState() {
    super.initState();
    _lastCommitted = widget.initialLastRead;
    _originHost = Uri.parse(widget.initialUrl).host;
    _loadAdBlockerPreference();
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
    });
    // Recharger la page pour appliquer les changements
    await _controller?.reload();
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
    if (chapter <= _lastCommitted) return;
    final ok = await _library.saveChapterProgress(widget.muId, chapter);
    if (ok) {
      _lastCommitted = chapter;
      final l10n = AppLocalizations.of(context);
      _notifier.info(l10n?.chapterSaved(chapter.toString()) ?? "Chapitre $chapter enregistré");
    }
  }

  Future<void> _updateNextLinkFrom(String currentUrl, {int? currentChapter}) async {
    final next = ChapterLinkResolver.buildNextUrl(currentUrl, currentChapter: currentChapter)
        ?? ChapterLinkResolver.buildNextUrl(widget.baseUserLink, currentChapter: currentChapter);
    if (next != null) {
      await _library.updateCustomLink(widget.muId, next);
    }
  }

  void _handleDetected(Uri uri) {
    // Filtrage domaines : on ne réagit pas aux pubs/trackers
    final host = uri.host;
    if (_denyHosts.contains(host)) return;
    // On reste sur le même provider (ou sous-domaines)
    if (!_sameProvider(host, _originHost)) return;

    final newCh = ChapterLinkResolver.extractChapter(uri.toString());
    if (newCh == null) return;

    if (_currentChapter == null) {
      _currentChapter = newCh; // premier chap détecté
      _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      return;
    }

    if (newCh == _currentChapter! + 1) {
      // Passage naturel au suivant => on valide le précédent
      final prev = _currentChapter!;
      _currentChapter = newCh;
      _commitIfNeeded(prev);
      _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      return;
    }

    if (newCh > _currentChapter! + 1) {
      // Saut de chapitres => on propose de valider le précédent
      _promptJumpConfirm(prev: _currentChapter!, next: newCh).then((yes) {
        _currentChapter = newCh;
        if (yes == true) _commitIfNeeded(newCh - 1); // on valide au moins le précédent
        _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      });
      return;
    }

    if (newCh < _currentChapter!) {
      // Retour en arrière => pas de commit
      _currentChapter = newCh;
      return;
    }
  }

  bool _sameProvider(String a, String b) {
    String root(String h) {
      final parts = h.split('.');
      return parts.length >= 2 ? '${parts[parts.length-2]}.${parts.last}' : h;
    }
    return root(a) == root(b);
  }

  bool _isAllowedDomain(String host) {
    // Vérifier si c'est un domaine de publicité
    if (_denyHosts.contains(host)) return false;
    // Vérifier si c'est le même provider
    return _sameProvider(host, _originHost);
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
    // Si on est sur le chap C et que le dernier validé est < C,
    // on demande si l'utilisateur a fini le chapitre C.
    final c = _currentChapter;
    if (c != null && _lastCommitted < c) {
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
            contentBlockers: _blockers,
            allowsInlineMediaPlayback: true,
            iframeAllow: "camera; microphone",
            iframeAllowFullscreen: true,
          ),
          onWebViewCreated: (c) => _controller = c,

          // 1) Nouvelle navigation principale - Blocage strict des redirections
          shouldOverrideUrlLoading: (controller, action) async {
            if (action.request.url == null) {
              return NavigationActionPolicy.ALLOW;
            }

            final url = action.request.url!.toString();
            final uri = action.request.url!;
            final host = uri.host;

            // Bloquer les domaines de publicités
            if (_denyHosts.any((h) => url.contains(h))) {
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

          // 2) Début de chargement - Vérification supplémentaire
          onLoadStart: (controller, url) {
            if (url != null) {
              final uri = url;
              final host = uri.host;
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
            if (_adBlockerEnabled && url != null) {
              try {
                // Vérifier que la WebView est toujours valide avant d'injecter le script
                final currentUrl = await controller.getUrl();
                if (currentUrl != null && mounted) {
                  await controller.evaluateJavascript(source: _adBlockScript);
                }
              } catch (e) {
                // Ignorer silencieusement si la WebView est détruite ou en cours de changement
                // C'est normal quand le site essaie d'ouvrir de nouvelles pages qui sont bloquées
              }
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
            if (!_adBlockerEnabled) return null;
            final u = req.url.toString();
            if (_denyHosts.any((h) => u.contains(h))) {
              return WebResourceResponse(
                contentType: 'text/plain',
                data: Uint8List(0),
                statusCode: 403,
                reasonPhrase: 'Blocked',
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlTextController.dispose();
    super.dispose();
  }
}
