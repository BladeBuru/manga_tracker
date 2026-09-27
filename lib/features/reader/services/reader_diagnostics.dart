import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Journal de diagnostic du lecteur en ligne.
///
/// Sert à comprendre, sur un vrai téléphone, pourquoi une page de lecture ne
/// s'affiche pas ou pourquoi une vérification anti-robot boucle : chaque
/// navigation (autorisée ou annulée, et pourquoi), chaque erreur réseau ou
/// HTTP, la console JavaScript de la page, l'état des cookies d'autorisation
/// et ce que le bloqueur de publicités retire de la page.
///
/// Activé en debug, et en release avec `--dart-define=MT_READER_DIAG=true`.
/// Désactivé, il ne coûte qu'un test de booléen constant.
///
/// Lecture sur l'appareil :
/// `adb logcat -v time -s flutter | findstr MT-READER`
///
/// ❌ Ne journalise JAMAIS la valeur d'un cookie ni d'un jeton : seulement des
/// noms, des URL de pages et des codes (règle RGPD de CLAUDE.md).
class ReaderDiagnostics {
  const ReaderDiagnostics._();

  static const bool enabled =
      bool.fromEnvironment('MT_READER_DIAG', defaultValue: kDebugMode);

  static const String tag = '[MT-READER]';

  /// Au-delà, logcat tronque la ligne : on coupe nous-mêmes, proprement.
  static const int _maxLineLength = 900;

  static void log(String event, [Map<String, Object?> fields = const {}]) {
    if (!enabled) return;
    final buffer = StringBuffer('$tag $event');
    fields.forEach((key, value) {
      if (value == null) return;
      buffer.write(' $key=${_clean(value)}');
    });
    var line = buffer.toString();
    if (line.length > _maxLineLength) {
      line = '${line.substring(0, _maxLineLength)}…';
    }
    debugPrint(line);
  }

  static String _clean(Object value) =>
      value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Noms des cookies posés pour [url] — jamais leurs valeurs.
  static Future<void> logCookies(WebUri url, String stage) async {
    if (!enabled) return;
    try {
      final cookies = await CookieManager.instance().getCookies(url: url);
      final names = cookies.map((c) => c.name).toList()..sort();
      log('cookies', {
        'stage': stage,
        'host': url.host,
        'count': names.length,
        'cf_clearance': names.contains('cf_clearance'),
        'names': names.join(','),
      });
    } catch (e) {
      log('cookies.error', {'stage': stage, 'error': e});
    }
  }

  /// Version du moteur WebView et user-agent par défaut de l'appareil.
  static Future<void> logEnvironment() async {
    if (!enabled) return;
    try {
      final package = await InAppWebViewController.getCurrentWebViewPackage();
      final userAgent = await InAppWebViewController.getDefaultUserAgent();
      log('env', {
        'webview': '${package?.packageName} ${package?.versionName}',
        'defaultUA': userAgent,
      });
    } catch (e) {
      log('env.error', {'error': e});
    }
  }

  /// Rend la WebView inspectable depuis `chrome://inspect` (build de
  /// diagnostic uniquement).
  static Future<void> enableRemoteInspection() async {
    if (!enabled || kIsWeb) return;
    try {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    } catch (e) {
      log('inspect.error', {'error': e});
    }
  }

  /// Photographie de la page chargée : ce que voit l'utilisateur.
  ///
  /// Distingue une page vide, une page de défi Cloudflare (marqueurs
  /// officiels `_cf_chl_opt` / `#challenge-form`), une page sans images de
  /// chapitre, et liste précisément les éléments qui déclenchent la
  /// détection de captcha de l'app (sélecteurs larges de
  /// `CaptchaDetectionService`).
  static Future<void> probePage(
    InAppWebViewController controller,
    String stage,
  ) async {
    if (!enabled) return;
    try {
      final raw = await controller.evaluateJavascript(source: _probeScript);
      log('page', {'stage': stage, 'probe': _decode(raw)});
    } catch (e) {
      log('page.error', {'stage': stage, 'error': e});
    }
  }

  static String _decode(dynamic raw) {
    if (raw == null) return 'null';
    if (raw is String) return raw;
    try {
      return jsonEncode(raw);
    } catch (_) {
      return raw.toString();
    }
  }

  static const String _probeScript = r'''
(function() {
  function describe(el) {
    if (!el) return null;
    var cls = (typeof el.className === 'string') ? el.className : '';
    return el.tagName.toLowerCase() + (el.id ? '#' + el.id : '') +
      (cls ? '.' + cls.trim().split(/\s+/).slice(0, 3).join('.') : '');
  }
  function firstMatch(sel) {
    try {
      var list = document.querySelectorAll(sel);
      return list.length ? (list.length + ' ' + describe(list[0])) : null;
    } catch (e) { return 'err'; }
  }
  var imgs = Array.prototype.slice.call(document.images || []);
  var bigLoaded = imgs.filter(function(i) {
    return i.naturalWidth > 200 && i.naturalHeight > 200;
  }).length;
  var bigVisible = imgs.filter(function(i) {
    var r = i.getBoundingClientRect();
    return r.width > 200 && r.height > 200;
  }).length;
  var ua = navigator.userAgentData;
  var body = document.body;
  return JSON.stringify({
    title: document.title,
    ready: document.readyState,
    textLen: body ? (body.innerText || '').length : -1,
    imgs: imgs.length,
    bigLoaded: bigLoaded,
    bigVisible: bigVisible,
    scrollH: document.documentElement ? document.documentElement.scrollHeight : -1,
    cfChlOpt: typeof window._cf_chl_opt !== 'undefined',
    challengeForm: !!document.querySelector('#challenge-form, #challenge-stage, #challenge-running'),
    turnstile: typeof window.turnstile !== 'undefined',
    cfIframe: firstMatch('iframe[src*="challenges.cloudflare.com"]'),
    captchaTriggers: {
      cfId: firstMatch('[id*="cf-"]'),
      cfClass: firstMatch('[class*="cf-"]'),
      challengeId: firstMatch('[id*="challenge"]'),
      challengeClass: firstMatch('[class*="challenge"]'),
      recaptcha: firstMatch('[id*="recaptcha"], [class*="recaptcha"], iframe[src*="recaptcha"]'),
      hcaptcha: firstMatch('[id*="hcaptcha"], [class*="hcaptcha"], iframe[src*="hcaptcha"]')
    },
    webdriver: navigator.webdriver === true,
    brands: ua && ua.brands ? ua.brands.map(function(b) { return b.brand + '/' + b.version; }).join(',') : null,
    bridge: typeof window.flutter_inappwebview !== 'undefined',
    adBlockRunning: !!window.__mtAdBlock
  });
})();
''';
}
