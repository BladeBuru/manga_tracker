import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/core/notifier/notifier.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/services/custom_selectors.service.dart';

/// Service pour gérer le blocage de publicités dans les WebViews
class AdBlockerService {
  final CustomSelectorsService _customSelectorsService = CustomSelectorsService();
  final Notifier _notifier = getIt<Notifier>();

  // Liste étendue de domaines de publicités
  static const Set<String> denyHosts = {
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

  /// Génère la liste de ContentBlocker pour bloquer les publicités
  Future<List<ContentBlocker>> getBlockers({
    required bool enabled,
    required bool captchaDetected,
  }) async {
    if (!enabled || captchaDetected) return [];

    final blockers = <ContentBlocker>[
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
            [class*="gfpl-"],
            .exo-native-widget-item-image,
            .exo-native-widget-item-title,
            .exo-native-widget-item-text,
            .exo-native-widget-item-content,
            .exo-native-widget-item-image-ratio,
            [class*="exo-native-widget"]
          """,
        ),
      ),
    ];

    // Ajouter les sélecteurs personnalisés (uniquement ceux de type adBlocker, pas urlPattern)
    try {
      final customSelectors = await _customSelectorsService.loadSelectors();
      final adBlockSelectors = customSelectors
          .where((s) => s.type == SelectorType.adBlocker)
          .toList();

      if (adBlockSelectors.isNotEmpty) {
        // Grouper par domaine pour créer des blockers spécifiques
        final selectorsByDomain = <String, List<String>>{};

        for (final selector in adBlockSelectors) {
          final domain = selector.domain == '*' ? '.*' : selector.domain.replaceAll('.', '\\.');
          if (!selectorsByDomain.containsKey(domain)) {
            selectorsByDomain[domain] = [];
          }
          selectorsByDomain[domain]!.add(selector.selector);
        }

        // Créer un ContentBlocker pour chaque domaine
        for (final entry in selectorsByDomain.entries) {
          final domainPattern = entry.key == '.*' ? r".*" : r"https?://[^/]*" + entry.key + r".*";
          blockers.add(
            ContentBlocker(
              trigger: ContentBlockerTrigger(urlFilter: domainPattern),
              action: ContentBlockerAction(
                type: ContentBlockerActionType.CSS_DISPLAY_NONE,
                selector: entry.value.join(',\n'),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du chargement des sélecteurs personnalisés: $e');
    }

    return blockers;
  }

  /// Construit le script JavaScript pour nettoyer le DOM des publicités
  Future<String> buildAdBlockScript(InAppWebViewController? controller) async {
    // Charger les sélecteurs personnalisés
    final customSelectors = <String>[];
    try {
      final url = await controller?.getUrl();
      if (url != null) {
        final uri = Uri.parse(url.toString());
        final domain = uri.host;
        final selectors = await _customSelectorsService.loadSelectors();
        final adBlockSelectors = selectors
            .where((s) =>
                (s.domain == domain || s.domain == '*') &&
                s.type == SelectorType.adBlocker)
            .map((s) => s.selector)
            .toList();
        customSelectors.addAll(adBlockSelectors);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du chargement des sélecteurs personnalisés pour le script: $e');
    }

    // Créer la liste complète des sélecteurs
    final allSelectors = [
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
      'script[id*="popmagic"]', '.pf-banner-default',
      '.exo-native-widget-item-image', '.exo-native-widget-item-title',
      '.exo-native-widget-item-text', '.exo-native-widget-item-content',
      '.exo-native-widget-item-image-ratio', '[class*="exo-native-widget"]',
      // Sélecteurs spécifiques pour les divs de pub
      'div.flex.flex-wrap.gap-2:has(script[src*="pubadx"]), div.flex.flex-wrap.gap-2:has(script[src*="tapioni"]), div.flex.flex-wrap.gap-2:has(script[src*="chnsrv"]), div.flex.flex-wrap.gap-2:has(script[src*="noritesfarrago"]), div.flex.flex-wrap.gap-2:has([id*="bg-ssp-"]), div.flex.flex-wrap.gap-2:has([data-funnel]), div.flex.flex-wrap.gap-2:has([data-asg-ins])',
      'div.flex.flex-wrap.gap-2.items-center.justify-center:has(script[src*="pubadx"]), div.flex.flex-wrap.gap-2.items-center.justify-center:has(script[src*="tapioni"]), div.flex.flex-wrap.gap-2.items-center.justify-center:has(script[src*="chnsrv"]), div.flex.flex-wrap.gap-2.items-center.justify-center:has([id*="bg-ssp-"]), div.flex.flex-wrap.gap-2.items-center.justify-center:has([data-funnel]), div.flex.flex-wrap.gap-2.items-center.justify-center:has([data-asg-ins])',
      // Attributs data-* suspects
      '[data-asg-ins]', '[data-spots]', '[data-funnel]', '[data-bg]', '[data-cfasync]',
      '[data-aa]', '[data-keywords]', '[data-zoneid]', '[data-processed]',
      // Scripts suspects
      'script[src*="pubadx"]', 'script[src*="tapioni"]', 'script[src*="chnsrv"]', 'script[src*="noritesfarrago"]',
      'script[src*="tsyndicate"]', 'script[src*="trcktr"]', 'script[src*="acscdn"]', 'script[src*="diveinthebluesky"]',
      'script[src*="smacksmallness"]', 'script[src*="ad-provider"]',
      // Containers de pub spécifiques
      '[id*="bg-container-"]', '[class*="bg-container-"]', '[class*="bg-dsp-"]',
      '[id*="pa-dsp-"]', '[id*="pa-"]', '[class*="qtxoBITy"]',
      ...customSelectors, // Ajouter les sélecteurs personnalisés
    ];

    // Échapper les sélecteurs pour JavaScript
    final escapedSelectors = allSelectors.map((s) => "'${s.replaceAll("'", "\\'")}'").join(', ');

    return """
    (function() {
      // Supprimer les éléments publicitaires spécifiques
      const adSelectors = [
        $escapedSelectors
      ];
      
      // Fonction pour détecter intelligemment si un élément est une pub
      function isAdElement(el) {
        if (!el || el.nodeType !== 1) return false;
        
        // Vérifier par ID
        if (el.id && (el.id.includes('ad') || el.id.includes('pf-') || 
            el.id.includes('asg-') || el.id.includes('bg-ssp-') || 
            el.id.includes('note-') || el.id.includes('dl-banner-') ||
            el.id.includes('bg-container-') || el.id.includes('pa-dsp-') ||
            el.id.match(/bg-ssp-\\d+/) || el.id.match(/pa-\\d+/))) {
          return true;
        }
        
        // Vérifier par classe
        if (el.className && typeof el.className === 'string' && 
            (el.className.includes('ad') || el.className.includes('PUBFUTURE') || 
             el.className.includes('pf-') || el.className.includes('gfpl-') ||
             el.className.includes('bg-ssp-') || el.className.includes('bg-container-') ||
             el.className.includes('bg-dsp-') || el.className.match(/qtxo[A-Za-z0-9]+/))) {
          return true;
        }
        
        // Vérifier par attributs data-*
        const adDataAttrs = ['data-unit', 'data-banner-id', 'data-asg-handled', 'data-funnel',
                             'data-icon', 'data-bg', 'data-asg-ins', 'data-spots', 'data-cfasync',
                             'data-aa', 'data-keywords', 'data-zoneid', 'data-processed'];
        if (adDataAttrs.some(attr => el.hasAttribute(attr))) {
          return true;
        }
        
        // Vérifier les scripts avec sources suspectes
        if (el.tagName === 'SCRIPT') {
          const src = el.src || '';
          const adScripts = ['onclck', 'pemsrv', 'pubfuture', 'adxbid', 'aqle3', 'pubadx',
                            'tapioni', 'chnsrv', 'noritesfarrago', 'tsyndicate', 'trcktr',
                            'acscdn', 'diveinthebluesky', 'smacksmallness', 'ad-provider'];
          if (adScripts.some(keyword => src.includes(keyword))) {
            return true;
          }
          const content = el.textContent || el.innerHTML || '';
          if (content.includes('AdProvider') || content.includes('aclib.runInPagePush') ||
              content.includes('pubfuturetag') || content.includes('popMagic')) {
            return true;
          }
        }
        
        // Vérifier les iframes
        if (el.tagName === 'IFRAME') {
          const src = el.src || '';
          const adIframes = ['onclck', 'pemsrv', 'pubfuture', 'adxbid', 'kueezrtb', 'monetixads',
                            'tsyndicate', 'trcktr', 'smacksmallness', 'noritesfarrago'];
          if (adIframes.some(keyword => src.includes(keyword))) {
            return true;
          }
          // Dimensions standard de pub
          if ((el.width === '300' && el.height === '250') ||
              (el.width === '728' && el.height === '90')) {
            return true;
          }
          const style = el.getAttribute('style') || '';
          if ((style.includes('300px') && style.includes('250px')) ||
              (style.includes('width: 300') && style.includes('height: 250'))) {
            return true;
          }
          // Iframe avec srcdoc suspect
          if (el.hasAttribute('srcdoc')) {
            const srcdoc = el.getAttribute('srcdoc');
            if (srcdoc.includes('AdProvider') || srcdoc.includes('tsyndicate') ||
                (srcdoc.includes('iframe') && srcdoc.includes('300'))) {
              return true;
            }
          }
        }
        
        // Vérifier les divs flex qui contiennent des pubs
        if (el.tagName === 'DIV' && el.className && typeof el.className === 'string' &&
            el.className.includes('flex') && el.className.includes('gap-2')) {
          if (el.querySelector('script[src*="pubadx"]') || el.querySelector('script[src*="tapioni"]') ||
              el.querySelector('script[src*="chnsrv"]') || el.querySelector('[id*="bg-ssp-"]') ||
              el.querySelector('[data-funnel]') || el.querySelector('[data-asg-ins]')) {
            return true;
          }
        }
        
        return false;
      }
      
      // Fonction pour supprimer les éléments publicitaires
      function removeAds() {
        // Supprimer avec les sélecteurs CSS
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
        
        // Détection intelligente supplémentaire
        try {
          document.querySelectorAll('div, script, iframe, ins').forEach(el => {
            if (isAdElement(el)) {
              const isChapterImage = el.closest('.chapter-content, .chapter-images, .manga-reader, .reader-content, .reading-content, [class*="chapter"], [id*="chapter"]');
              if (!isChapterImage) {
                el.remove();
              }
            }
          });
        } catch(e) {}
        
        // Supprimer les scripts de publicités spécifiques
        try {
          document.querySelectorAll('script').forEach(script => {
            const src = script.src || '';
            const content = script.textContent || script.innerHTML || '';
            const adScriptKeywords = ['onclck', 'pemsrv', 'pubfuture', 'adxbid', 'aqle3', 'pubadx',
                                     'tapioni', 'chnsrv', 'noritesfarrago', 'tsyndicate', 'trcktr',
                                     'acscdn', 'diveinthebluesky', 'smacksmallness', 'ad-provider'];
            if (adScriptKeywords.some(keyword => src.includes(keyword)) ||
                content.includes('pubfuturetag') || content.includes('popMagic') ||
                content.includes('window.pubfuturetag') || content.includes('popmagic') ||
                content.includes('aclib.runInPagePush') || content.includes('AdProvider')) {
              script.remove();
            }
          });
        } catch(e) {}
      }
      
      // Exécuter immédiatement
      removeAds();
      
      // Observer les changements du DOM pour supprimer les nouvelles pubs
      const observer = new MutationObserver(function(mutations) {
        removeAds();
      });
      
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
      
      // Nettoyer périodiquement (toutes les 2 secondes)
      setInterval(removeAds, 2000);
    })();
    """;
  }

  /// Vérifie si une URL doit être bloquée
  bool shouldBlockRequest(String url) {
    return denyHosts.any((h) => url.contains(h));
  }

  /// Vérifie si un domaine est autorisé (pas dans la liste de blocage)
  bool isAllowedDomain(String host, String originHost) {
    // Vérifier si c'est un domaine de publicité
    if (denyHosts.contains(host)) return false;
    // Vérifier si c'est le même provider (même domaine de base)
    return _sameProvider(host, originHost);
  }

  /// Vérifie si deux domaines appartiennent au même provider
  bool _sameProvider(String a, String b) {
    if (a == b) return true;
    // Extraire le domaine de base (sans sous-domaines)
    final aBase = _extractBaseDomain(a);
    final bBase = _extractBaseDomain(b);
    return aBase == bBase;
  }

  /// Extrait le domaine de base d'un host (ex: "sub.example.com" -> "example.com")
  String _extractBaseDomain(String host) {
    final parts = host.split('.');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    }
    return host;
  }

  /// Injecte le script JavaScript pour le mode interactif de détection de pub
  Future<void> injectInteractiveAdBlockScript(InAppWebViewController controller) async {
    final script = """
      (function() {
        if (window._adBlockInteractiveMode) return; // Déjà injecté
        
        window._adBlockInteractiveMode = true;
        window._adBlockClickedElement = null;
        
        // Fonction pour générer un sélecteur CSS unique et spécifique pour un élément
        function getSelector(element) {
          if (!element) return null;
          
          // Essayer d'abord avec l'ID (le plus spécifique)
          if (element.id && element.id.trim() !== '') {
            return '#' + element.id;
          }
          
          // Ensuite avec toutes les classes (plus spécifique qu'une seule classe)
          if (element.className && typeof element.className === 'string') {
            const classes = element.className.trim().split(/\\s+/).filter(c => c && c.length > 0);
            if (classes.length > 0) {
              // Utiliser toutes les classes pour être plus spécifique
              return element.tagName.toLowerCase() + '.' + classes.join('.');
            }
          }
          
          // Ensuite avec le tag et les attributs data-*
          const tagName = element.tagName.toLowerCase();
          const dataAttrs = [];
          
          // Collecter tous les attributs data-*
          for (let attr of element.attributes) {
            if (attr.name.startsWith('data-') && attr.value) {
              dataAttrs.push('[' + attr.name + '="' + attr.value + '"]');
            }
          }
          
          if (dataAttrs.length > 0) {
            return tagName + dataAttrs.join('');
          }
          
          // Si on a une classe mais pas d'ID, utiliser tag + classe
          if (element.getAttribute('class')) {
            const classes = element.getAttribute('class').trim().split(/\\s+/).filter(c => c);
            if (classes.length > 0) {
              return tagName + '.' + classes[0];
            }
          }
          
          // Dernier recours : tag seul (mais on va le rejeter côté Flutter)
          return tagName;
        }
        
        // Gestionnaire de clic
        function handleClick(e) {
          if (!window._adBlockInteractiveMode) return;
          
          const element = e.target;
          if (!element) return;
          
          const selector = getSelector(element);
          
          if (selector) {
            window._adBlockClickedElement = {
              selector: selector,
              tagName: element.tagName.toLowerCase(),
              className: element.className || '',
              id: element.id || '',
            };
            
            // Empêcher le comportement par défaut
            e.preventDefault();
            e.stopPropagation();
            
            // Bloquer immédiatement l'élément cliqué
            try {
              if (element.parentNode) {
                element.style.display = 'none';
                // Attendre un peu avant de supprimer pour éviter les erreurs
                setTimeout(function() {
                  try {
                    if (element.parentNode) {
                      element.remove();
                    }
                  } catch(err) {
                    // Ignorer les erreurs de suppression
                  }
                }, 10);
              }
            } catch(err) {
              // Ignorer les erreurs
            }
            
            // Notifier Flutter
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              window.flutter_inappwebview.callHandler('onAdBlockClick', selector);
            }
          }
        }
        
        document.addEventListener('click', handleClick, true);
      })();
    """;

    try {
      await controller.evaluateJavascript(source: script);
    } catch (e) {
      debugPrint('Erreur lors de l\'injection du script interactif: $e');
    }
  }

  /// Retire le script JavaScript du mode interactif
  Future<void> removeInteractiveAdBlockScript(InAppWebViewController controller) async {
    final script = """
      (function() {
        if (window._adBlockInteractiveMode) {
          window._adBlockInteractiveMode = false;
          // Retirer le gestionnaire de clic serait complexe, on le laisse mais on désactive le mode
        }
      })();
    """;

    try {
      await controller.evaluateJavascript(source: script);
    } catch (e) {
      debugPrint('Erreur lors de la suppression du script interactif: $e');
    }
  }

  /// Vérifie si un sélecteur est trop générique pour être utilisé comme bloqueur de pub
  bool isSelectorTooGeneric(String selector) {
    // Liste des sélecteurs trop génériques qui bloqueraient trop de contenu
    final genericSelectors = [
      'img',
      'div',
      'span',
      'a',
      'p',
      'body',
      'html',
      'section',
      'article',
      'main',
      'header',
      'footer',
      'nav',
      'ul',
      'ol',
      'li',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
    ];

    // Normaliser le sélecteur (enlever les espaces)
    final normalized = selector.trim().toLowerCase();

    // Vérifier si c'est un sélecteur trop générique
    if (genericSelectors.contains(normalized)) {
      return true;
    }

    // Vérifier si c'est juste un tag HTML sans classe ni ID
    if (normalized.length <= 3 && normalized.contains(RegExp(r'^[a-z]+$'))) {
      return true;
    }

    return false;
  }

  /// Gère le clic sur un élément de pub en mode interactif
  Future<void> handleAdBlockClick(
    InAppWebViewController controller,
    String selector,
  ) async {
    try {
      final url = await controller.getUrl();
      if (url == null) return;

      final uri = Uri.parse(url.toString());
      final domain = uri.host;

      // Vérifier si le sélecteur est trop générique
      if (isSelectorTooGeneric(selector)) {
        _notifier.error("Ce sélecteur est trop générique et bloquerait trop de contenu. Veuillez cliquer sur un élément plus spécifique.");
        debugPrint('⚠️ Sélecteur trop générique ignoré: $selector');
        return;
      }

      // Vérifier si un sélecteur similaire ou équivalent existe déjà
      final existingSelectors = await _customSelectorsService.loadSelectors();
      final adBlockSelectors = existingSelectors
          .where((s) => s.domain == domain && s.type == SelectorType.adBlocker)
          .toList();

      // Vérifier si le sélecteur est équivalent à un existant
      // Par exemple : "div.class" équivaut à ".class", "tag.class" équivaut à ".class"
      bool isEquivalent(String sel1, String sel2) {
        if (sel1 == sel2) return true;

        // Normaliser les sélecteurs (enlever les tags devant les classes)
        String normalize(String s) {
          // Si c'est "tag.class", retourner ".class"
          if (s.contains('.') && !s.startsWith('.')) {
            final parts = s.split('.');
            if (parts.length > 1) {
              return '.${parts.sublist(1).join('.')}';
            }
          }
          return s;
        }

        final norm1 = normalize(sel1);
        final norm2 = normalize(sel2);
        return norm1 == norm2;
      }

      final equivalentSelector = adBlockSelectors.firstWhere(
        (s) => isEquivalent(s.selector, selector),
        orElse: () => CustomSelector(
          id: '',
          domain: '',
          selector: '',
          type: SelectorType.adBlocker,
        ),
      );

      if (equivalentSelector.id.isNotEmpty) {
        // Ne pas afficher de notification si le sélecteur est déjà bloqué
        debugPrint('ℹ️ Sélecteur équivalent déjà existant: $selector (équivaut à ${equivalentSelector.selector})');
        // Bloquer quand même l'élément immédiatement sans créer de doublon
        final blockScript = """
          (function() {
            try {
              const elements = document.querySelectorAll('$selector');
              let blockedCount = 0;
              elements.forEach(function(el) {
                try {
                  if (el && el.offsetParent !== null && el.parentNode !== null) {
                    el.style.display = 'none';
                    if (el.parentNode) {
                      el.remove();
                      blockedCount++;
                    }
                  }
                } catch(e) {
                  // Ignorer si l'élément est déjà supprimé
                }
              });
              console.log('Bloqué ' + blockedCount + ' élément(s) existant avec le sélecteur: $selector');
            } catch(e) {
              console.error('Erreur lors du blocage: ' + e);
            }
          })();
        """;
        await controller.evaluateJavascript(source: blockScript);

        // Recharger le script complet pour s'assurer que le sélecteur est bien inclus
        try {
          final script = await buildAdBlockScript(controller);
          await controller.evaluateJavascript(source: script);
        } catch (e) {
          debugPrint('⚠️ Erreur lors du rechargement du script de blocage: $e');
        }
        return;
      }

      // Créer un sélecteur personnalisé
      final customSelector = CustomSelector(
        id: 'interactive_${domain}_${DateTime.now().millisecondsSinceEpoch}',
        domain: domain,
        selector: selector,
        type: SelectorType.adBlocker,
        description: 'Ajouté via le mode interactif',
      );

      // Sauvegarder le sélecteur
      await _customSelectorsService.addSelector(customSelector);
      _notifier.success("Publicité bloquée avec succès !");

      // Bloquer immédiatement tous les éléments correspondants
      final blockScript = """
        (function() {
          try {
            const elements = document.querySelectorAll('$selector');
            let blockedCount = 0;
            elements.forEach(function(el) {
              try {
                if (el && el.offsetParent !== null && el.parentNode !== null) {
                  el.style.display = 'none';
                  if (el.parentNode) {
                    el.remove();
                    blockedCount++;
                  }
                }
              } catch(e) {
                // Ignorer si l'élément est déjà supprimé
              }
            });
            console.log('Bloqué ' + blockedCount + ' élément(s) avec le sélecteur: $selector');
          } catch(e) {
            console.error('Erreur lors du blocage: ' + e);
          }
        })();
      """;
      await controller.evaluateJavascript(source: blockScript);

      // Recharger le script complet pour s'assurer que le sélecteur est bien inclus
      try {
        final script = await buildAdBlockScript(controller);
        await controller.evaluateJavascript(source: script);
      } catch (e) {
        debugPrint('⚠️ Erreur lors du rechargement du script de blocage: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la gestion du clic sur la pub: $e');
      _notifier.error("Erreur lors du blocage de la publicité");
    }
  }

  /// Génère une réponse WebResourceResponse pour bloquer une requête Android
  WebResourceResponse? createBlockedResponse() {
    return WebResourceResponse(
      contentType: 'text/plain',
      data: Uint8List(0),
      statusCode: 403,
      reasonPhrase: 'Blocked',
    );
  }
}

