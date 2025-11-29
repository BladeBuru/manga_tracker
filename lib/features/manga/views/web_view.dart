import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
import 'package:mangatracker/features/reader/views/offline_reader_view.dart';
import 'package:mangatracker/features/reader/utils/reading_progress_helper.dart';
import 'dart:async';

final _customSelectorsService = CustomSelectorsService();

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

  InAppWebViewController? _controller;
  final TextEditingController _urlTextController = TextEditingController();
  List<ContentBlocker> _cachedBlockers = []; // Cache pour les blockers
  Timer? _scrollSaveTimer; // Timer pour sauvegarder périodiquement la position de scroll
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

  /// Vérifie si l'URL contient des indices de captcha
  bool _urlContainsCaptcha(String url) {
    final urlLower = url.toLowerCase();
    return urlLower.contains('challenge') ||
           urlLower.contains('cf_challenge') ||
           urlLower.contains('challenges.cloudflare.com') ||
           urlLower.contains('challenge-platform.cloudflare.com') ||
           urlLower.contains('recaptcha') ||
           urlLower.contains('hcaptcha');
  }

  /// Vérifie si un domaine est lié à un captcha (à ne pas bloquer)
  bool _isCaptchaDomain(String host) {
    final hostLower = host.toLowerCase();
    return hostLower.contains('cloudflare.com') ||
           hostLower.contains('challenges.cloudflare.com') ||
           hostLower.contains('challenge-platform.cloudflare.com') ||
           hostLower.contains('google.com') && hostLower.contains('recaptcha') ||
           hostLower.contains('hcaptcha.com') ||
           hostLower.contains('recaptcha.net');
  }

  // Ad-blocker amélioré avec sélecteurs CSS plus précis
  Future<List<ContentBlocker>> _getBlockers() async {
    if (!_adBlockerEnabled || _captchaDetected) return [];
    
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

  // Script JavaScript pour nettoyer le DOM des publicités
  Future<String> _buildAdBlockScript() async {
    // Charger les sélecteurs personnalisés
    final customSelectors = <String>[];
    try {
      final url = await _controller?.getUrl();
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
                content.includes('AdProvider') || content.includes('aclib.runInPagePush')) {
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
            const adScriptKeywords = ['aqle3', 'pubadx', 'adexchangeclear', 'tapioni', 'chnsrv',
                                     'noritesfarrago', 'tsyndicate', 'trcktr', 'acscdn',
                                     'diveinthebluesky', 'smacksmallness', 'ad-provider'];
            if (adScriptKeywords.some(keyword => src.includes(keyword)) ||
                content.includes('bg-ssp') || content.includes('asg-') || 
                content.includes('ammc8brnmqe2aahjvxvkti9jx6p1df1o') ||
                content.includes('AdProvider') || content.includes('aclib.runInPagePush')) {
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
            
            // Détecter les iframes de synchronisation cachées ou avec sources suspectes
            const adIframeKeywords = ['sync', 'kueezrtb', 'monetixads', 'tsyndicate', 'trcktr',
                                      'smacksmallness', 'noritesfarrago', 'onclck', 'pemsrv',
                                      'pubfuture', 'adxbid'];
            const isSyncIframe = 
              iframe.hasAttribute('sandbox') && 
              (width === '0' || height === '0' || style.includes('width:0') || style.includes('height:0') ||
               adIframeKeywords.some(keyword => iframe.src.includes(keyword))) ||
              // Iframe avec dimensions standard de pub
              ((iframe.width === '300' && iframe.height === '250') ||
               (iframe.width === '728' && iframe.height === '90') ||
               (style.includes('300px') && style.includes('250px')) ||
               (style.includes('width: 300') && style.includes('height: 250'))) ||
              // Iframe avec srcdoc suspect
              (iframe.hasAttribute('srcdoc') && (
                iframe.getAttribute('srcdoc').includes('AdProvider') ||
                iframe.getAttribute('srcdoc').includes('tsyndicate') ||
                (iframe.getAttribute('srcdoc').includes('iframe') && iframe.getAttribute('srcdoc').includes('300'))
              ));
            
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
              // Vérifier si c'est une publicité avec détection intelligente améliorée
              const isAd = 
                // Vérification par ID
                (element.id && (element.id.includes('ad') || element.id.includes('pf-') || 
                 element.id.includes('asg-') || element.id.includes('bg-ssp-') || 
                 element.id.includes('note-') || element.id.includes('dl-banner-') ||
                 element.id.includes('bg-container-') || element.id.includes('pa-dsp-') ||
                 element.id.includes('pa-') || element.id.match(/bg-ssp-\\d+/))) ||
                // Vérification par classe
                (element.className && typeof element.className === 'string' && 
                 (element.className.includes('ad') || element.className.includes('PUBFUTURE') || 
                  element.className.includes('pf-') || element.className.includes('gfpl-') ||
                  element.className.includes('ammc8brnmqe2aahjvxvkti9jx6p1df1o') ||
                  element.className.includes('bg-ssp-') || element.className.includes('bg-container-') ||
                  element.className.includes('bg-dsp-') || element.className.match(/qtxo[A-Za-z0-9]+/))) ||
                // Vérification par attributs data-* suspects
                element.hasAttribute('data-unit') || element.hasAttribute('data-banner-id') ||
                element.hasAttribute('data-asg-handled') || element.hasAttribute('data-funnel') ||
                element.hasAttribute('data-icon') || element.hasAttribute('data-bg') ||
                element.hasAttribute('data-asg-ins') || element.hasAttribute('data-spots') ||
                element.hasAttribute('data-cfasync') || element.hasAttribute('data-aa') ||
                element.hasAttribute('data-keywords') || element.hasAttribute('data-zoneid') ||
                element.hasAttribute('data-processed') ||
                // Vérification par tag SCRIPT avec sources suspectes
                (element.tagName === 'SCRIPT' && (
                  (element.src && (element.src.includes('onclck') || element.src.includes('pemsrv') || 
                   element.src.includes('pubfuture') || element.src.includes('adxbid') ||
                   element.src.includes('aqle3') || element.src.includes('pubadx') ||
                   element.src.includes('adexchangeclear') || element.src.includes('tapioni') ||
                   element.src.includes('chnsrv') || element.src.includes('noritesfarrago') ||
                   element.src.includes('tsyndicate') || element.src.includes('trcktr') ||
                   element.src.includes('acscdn') || element.src.includes('diveinthebluesky') ||
                   element.src.includes('smacksmallness') || element.src.includes('ad-provider'))) ||
                  (element.textContent && (element.textContent.includes('pubfuturetag') || 
                   element.textContent.includes('popMagic') || element.textContent.includes('bg-ssp') ||
                   element.textContent.includes('asg-') || element.textContent.includes('ammc8brnmqe2aahjvxvkti9jx6p1df1o') ||
                   element.textContent.includes('AdProvider') || element.textContent.includes('aclib.runInPagePush')))
                )) ||
                // Vérification par tag IFRAME avec sources ou dimensions suspectes
                (element.tagName === 'IFRAME' && (
                  (element.src && (element.src.includes('onclck') || element.src.includes('pemsrv') ||
                   element.src.includes('pubfuture') || element.src.includes('adxbid') ||
                   element.src.includes('kueezrtb') || element.src.includes('monetixads') ||
                   element.src.includes('tsyndicate') || element.src.includes('trcktr') ||
                   element.src.includes('smacksmallness') || element.src.includes('noritesfarrago'))) ||
                  // Iframe avec dimensions standard de pub (300x250, 728x90, etc.)
                  ((element.width === '300' && element.height === '250') ||
                   (element.width === '728' && element.height === '90') ||
                   (element.getAttribute('style')?.includes('300px') && element.getAttribute('style')?.includes('250px')) ||
                   (element.getAttribute('style')?.includes('width: 300') && element.getAttribute('style')?.includes('height: 250'))) ||
                  (element.hasAttribute('sandbox') && (element.getAttribute('style')?.includes('width:0') || 
                   element.getAttribute('width') === '0')) ||
                  (element.getAttribute('style')?.includes('position: fixed') && 
                   parseInt(element.getAttribute('style')?.match(/z-index[\\s:]*([0-9]+)/)?.[1] || '0') > 1000) ||
                  element.hasAttribute('data-asg-handled') ||
                  // Iframe avec srcdoc contenant des mots-clés de pub
                  (element.hasAttribute('srcdoc') && (
                    element.getAttribute('srcdoc').includes('AdProvider') ||
                    element.getAttribute('srcdoc').includes('tsyndicate') ||
                    element.getAttribute('srcdoc').includes('iframe') && element.getAttribute('srcdoc').includes('300')
                  ))
                )) ||
                // Vérification par tag IN-PAGE-MESSAGE
                element.tagName === 'IN-PAGE-MESSAGE' ||
                // Vérification par attributs data-title/data-description
                (element.hasAttribute('data-title') && element.getAttribute('data-title')?.includes('Bloquez')) ||
                (element.hasAttribute('data-description') && element.getAttribute('data-description')?.includes('Naviguez')) ||
                // Détection intelligente : div avec classes flex qui contient des scripts de pub
                (element.tagName === 'DIV' && element.className && typeof element.className === 'string' &&
                 (element.className.includes('flex') && element.className.includes('gap-2')) &&
                 (element.querySelector('script[src*="pubadx"]') || element.querySelector('script[src*="tapioni"]') ||
                  element.querySelector('script[src*="chnsrv"]') || element.querySelector('[id*="bg-ssp-"]') ||
                  element.querySelector('[data-funnel]') || element.querySelector('[data-asg-ins]')));
              
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OfflineReaderView(
                muId: widget.muId,
                chapterNumber: nextChapterNumber,
                mangaTitle: widget.mangaTitle!,
              ),
            ),
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
      // Script pour détecter les captchas (Cloudflare, reCAPTCHA, etc.)
      final captchaDetectionScript = """
        (function() {
          // Détecter les iframes Cloudflare
          const cloudflareIframes = document.querySelectorAll('iframe[src*="challenges.cloudflare.com"], iframe[src*="challenge-platform.cloudflare.com"]');
          if (cloudflareIframes.length > 0) {
            return 'cloudflare';
          }
          
          // Détecter les éléments Cloudflare
          const cfElements = document.querySelectorAll('[id*="cf-"], [class*="cf-"], [id*="challenge"], [class*="challenge"], [id*="cf_challenge"], [class*="cf_challenge"]');
          if (cfElements.length > 0) {
            return 'cloudflare';
          }
          
          // Détecter reCAPTCHA
          const recaptchaElements = document.querySelectorAll('[id*="recaptcha"], [class*="recaptcha"], iframe[src*="recaptcha"], iframe[src*="google.com/recaptcha"]');
          if (recaptchaElements.length > 0) {
            return 'recaptcha';
          }
          
          // Détecter hCaptcha
          const hcaptchaElements = document.querySelectorAll('[id*="hcaptcha"], [class*="hcaptcha"], iframe[src*="hcaptcha"]');
          if (hcaptchaElements.length > 0) {
            return 'hcaptcha';
          }
          
          // Détecter dans l'URL
          if (window.location.href.includes('challenge') || window.location.href.includes('cf_challenge')) {
            return 'url';
          }
          
          return 'none';
        })();
      """;
      
      final result = await controller.evaluateJavascript(source: captchaDetectionScript);
      final captchaType = result?.toString().replaceAll('"', '') ?? 'none';
      
      if (captchaType != 'none' && _adBlockerEnabled) {
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
      } else if (captchaType == 'none' && _captchaDetected) {
        // Vérifier si le captcha est résolu (présence de cookies cf_clearance)
        final cookieManager = CookieManager.instance();
        final cookies = await cookieManager.getCookies(url: url);
        final hasClearanceCookie = cookies.any((c) => c.name.contains('cf_clearance') || c.name.contains('clearance'));
        
        if (hasClearanceCookie) {
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

    if (_interactiveAdBlockMode) {
      _notifier.info("Mode détection activé - Cliquez sur une pub pour la bloquer automatiquement");
      // Injecter le script de détection de clic
      await _injectInteractiveAdBlockScript();
    } else {
      _notifier.info("Mode détection désactivé");
      // Retirer le script de détection
      await _removeInteractiveAdBlockScript();
    }
  }

  Future<void> _injectInteractiveAdBlockScript() async {
    if (_controller == null) return;

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
      await _controller?.evaluateJavascript(source: script);
    } catch (e) {
      debugPrint('Erreur lors de l\'injection du script interactif: $e');
    }
  }

  Future<void> _removeInteractiveAdBlockScript() async {
    if (_controller == null) return;

    final script = """
      (function() {
        if (window._adBlockInteractiveMode) {
          window._adBlockInteractiveMode = false;
          // Retirer le gestionnaire de clic serait complexe, on le laisse mais on désactive le mode
        }
      })();
    """;

    try {
      await _controller?.evaluateJavascript(source: script);
    } catch (e) {
      debugPrint('Erreur lors de la suppression du script interactif: $e');
    }
  }

  /// Vérifie si un sélecteur est trop générique pour être utilisé comme bloqueur de pub
  bool _isSelectorTooGeneric(String selector) {
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

  Future<void> _handleAdBlockClick(String selector) async {
    try {
      final url = await _controller?.getUrl();
      if (url == null) return;

      final uri = Uri.parse(url.toString());
      final domain = uri.host;

      // Vérifier si le sélecteur est trop générique
      if (_isSelectorTooGeneric(selector)) {
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
        if (_controller != null) {
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
          await _controller?.evaluateJavascript(source: blockScript);
          
          // Recharger le script complet pour s'assurer que le sélecteur est bien inclus
          try {
            final script = await _buildAdBlockScript();
            await _controller?.evaluateJavascript(source: script);
          } catch (e) {
            debugPrint('⚠️ Erreur lors du rechargement du script de blocage: $e');
          }
        }
        return;
      }

      // Créer un sélecteur personnalisé
      final customSelector = CustomSelector(
        id: 'interactive_${domain}_${DateTime.now().millisecondsSinceEpoch}',
        domain: domain,
        selector: selector,
        type: SelectorType.adBlocker,
        description: 'Détecté automatiquement par clic utilisateur',
      );

      // Sauvegarder le sélecteur
      await _customSelectorsService.addSelector(customSelector);

      // Bloquer immédiatement l'élément
      if (_controller != null) {
        final blockScript = """
          (function() {
            try {
              const elements = document.querySelectorAll('$selector');
              let blockedCount = 0;
              elements.forEach(function(el) {
                try {
                  // Vérifier que l'élément existe toujours et n'est pas déjà supprimé
                  if (el && el.parentNode && el.offsetParent !== null) {
                    el.style.display = 'none';
                    // Vérifier à nouveau avant de supprimer
                    if (el.parentNode) {
                      el.remove();
                      blockedCount++;
                    }
                  }
                } catch(e) {
                  // Ignorer les erreurs pour cet élément spécifique
                  console.log('Erreur pour un élément: ' + e);
                }
              });
              console.log('Bloqué ' + blockedCount + ' élément(s) avec le sélecteur: $selector');
              
              // Ajouter le sélecteur à la liste des sélecteurs actifs pour le nettoyage périodique
              if (typeof window._adBlockSelectors !== 'undefined') {
                if (!window._adBlockSelectors.includes('$selector')) {
                  window._adBlockSelectors.push('$selector');
                }
              }
            } catch(e) {
              console.error('Erreur lors du blocage: ' + e);
            }
          })();
        """;
        await _controller?.evaluateJavascript(source: blockScript);
        
        // Recharger le script complet pour inclure le nouveau sélecteur dans le nettoyage périodique
        try {
          final script = await _buildAdBlockScript();
          await _controller?.evaluateJavascript(source: script);
        } catch (e) {
          debugPrint('⚠️ Erreur lors du rechargement du script de blocage: $e');
        }
      }

      _notifier.success("Pub bloquée avec succès: $selector");
      debugPrint('✅ Pub bloquée: $selector sur $domain');
    } catch (e) {
      debugPrint('❌ Erreur lors du blocage de la pub: $e');
      _notifier.error("Erreur lors du blocage de la pub: $e");
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
    // Filtrage domaines : on ne réagit pas aux pubs/trackers
    final host = uri.host;
    if (_denyHosts.contains(host)) return;
    // On reste sur le même provider (ou sous-domaines)
    if (!_sameProvider(host, _originHost)) return;

    final newCh = await ChapterLinkResolver.extractChapter(uri.toString());
    if (newCh == null) return;

    if (_currentChapter == null) {
      _currentChapter = newCh; // premier chap détecté
      _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      // Réinitialiser le flag de restauration pour le nouveau chapitre
      _hasRestoredScroll = false;
      return;
    }

    if (newCh == _currentChapter! + 1) {
      // Passage naturel au suivant => on valide le précédent ET le nouveau
      final prev = _currentChapter!;
      // Sauvegarder la position de scroll du chapitre précédent avant de changer
      await _saveScrollPosition();
      _currentChapter = newCh;
      // Sauvegarder le chapitre précédent comme lu
      await _commitIfNeeded(prev);
      // Sauvegarder aussi le nouveau chapitre comme lu (car on est dessus)
      await _commitIfNeeded(newCh);
      _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
      // Réinitialiser le flag de restauration pour le nouveau chapitre
      _hasRestoredScroll = false;
      return;
    }

    if (newCh > _currentChapter! + 1) {
      // Saut de chapitres => on propose de valider le précédent
      // Sauvegarder la position de scroll du chapitre actuel avant de changer
      await _saveScrollPosition();
      _promptJumpConfirm(prev: _currentChapter!, next: newCh).then((yes) {
        _currentChapter = newCh;
        if (yes == true) _commitIfNeeded(newCh - 1); // on valide au moins le précédent
        _updateNextLinkFrom(uri.toString(), currentChapter: newCh);
        // Réinitialiser le flag de restauration pour le nouveau chapitre
        _hasRestoredScroll = false;
      });
      return;
    }

    if (newCh < _currentChapter!) {
      // Retour en arrière => pas de commit
      // Sauvegarder la position de scroll du chapitre actuel avant de changer
      await _saveScrollPosition();
      _currentChapter = newCh;
      // Réinitialiser le flag de restauration pour le nouveau chapitre
      _hasRestoredScroll = false;
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
    // Sauvegarder la position de scroll avant de fermer
    await _saveScrollPosition();
    
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
        // La position de scroll est déjà sauvegardée par _saveScrollPosition()
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

          // 2) Début de chargement - Vérification supplémentaire et détection précoce de captcha
          onLoadStart: (controller, url) async {
            if (url != null) {
              final uri = url;
              final host = uri.host;
              final urlString = url.toString();
              
              // Détecter le captcha dès le début du chargement via l'URL
              if (_urlContainsCaptcha(urlString) || _isCaptchaDomain(host)) {
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
            
            // Restaurer la position de scroll si disponible (en arrière-plan pour ne pas bloquer)
            if (_currentChapter != null && mounted) {
              // Réinitialiser le flag de restauration pour le nouveau chapitre
              _hasRestoredScroll = false;
              // Restaurer en arrière-plan pour ne pas bloquer le chargement
              _restoreScrollPosition().catchError((e) {
                debugPrint('⚠️ Erreur lors de la restauration en arrière-plan: $e');
              });
              // Démarrer le timer de sauvegarde périodique
              _startScrollSaveTimer();
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
            if (_isCaptchaDomain(host) || _urlContainsCaptcha(u)) {
              return null;
            }
            
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

  /// Vérifie si l'utilisateur est proche de la fin du chapitre (dans les 15% de la fin)

  /// Sauvegarde la position de scroll actuelle dans SharedPreferences
  Future<void> _saveScrollPosition() async {
    if (_controller == null || _currentChapter == null) return;
    
    try {
      final scrollScript = """
        (function() {
          return window.scrollY || window.pageYOffset || document.documentElement.scrollTop || 0;
        })();
      """;
      
      final scrollResult = await _controller?.evaluateJavascript(source: scrollScript);
      final scrollPosition = scrollResult != null ? double.tryParse(scrollResult.toString()) : null;
      
      if (scrollPosition != null && scrollPosition > 0) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'scroll_position_${widget.muId}_${_currentChapter}';
        await prefs.setDouble(key, scrollPosition);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la sauvegarde de la position de scroll: $e');
    }
  }

  /// Restaure la position de scroll sauvegardée depuis SharedPreferences
  Future<void> _restoreScrollPosition() async {
    if (_controller == null || _currentChapter == null || _hasRestoredScroll) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'scroll_position_${widget.muId}_${_currentChapter}';
      final savedPosition = prefs.getDouble(key);
      
      if (savedPosition != null && savedPosition > 0) {
        // Attendre que la page soit prête, mais de manière non-bloquante
        // Utiliser un délai plus court et vérifier que le DOM est chargé
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Vérifier que le document est prêt avant de restaurer
        final readyScript = """
          (function() {
            return document.readyState === 'complete' || document.readyState === 'interactive';
          })();
        """;
        
        final isReady = await _controller?.evaluateJavascript(source: readyScript);
        if (isReady == true || isReady == 'true') {
          final scrollScript = 'window.scrollTo(0, $savedPosition);';
          await _controller?.evaluateJavascript(source: scrollScript);
          _hasRestoredScroll = true;
        } else {
          // Si pas prêt, réessayer après un court délai
          Future.delayed(const Duration(milliseconds: 200), () async {
            if (_controller != null && !_hasRestoredScroll && mounted) {
              final scrollScript = 'window.scrollTo(0, $savedPosition);';
              await _controller?.evaluateJavascript(source: scrollScript);
              _hasRestoredScroll = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la restauration de la position de scroll: $e');
    }
  }

  /// Démarre le timer de sauvegarde périodique de la position de scroll
  void _startScrollSaveTimer() {
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _saveScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollSaveTimer?.cancel();
    // Sauvegarder la position de scroll avant de fermer
    _saveScrollPosition();
    
    // NE PAS sauvegarder automatiquement le chapitre dans dispose()
    // La sauvegarde doit être gérée par _onWillPop() qui vérifie si l'utilisateur est proche de la fin
    // Si dispose() est appelé directement (par exemple lors d'un crash), on ne veut pas marquer
    // le chapitre comme lu si l'utilisateur n'était pas à la fin
    
    _urlTextController.dispose();
    super.dispose();
  }
}
