import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/features/reader/utils/page_chapter_parser.dart';
import 'package:mangatracker/features/reader/utils/webview_result_parser.dart';

/// Relève, en UN appel JavaScript, les signaux qui disent quel chapitre la
/// page affiche (voir [PageChapterParser], qui décide). Lecture seule : rien
/// n'est modifié dans la page.
///
/// Ce qui est lu, et seulement ça :
/// - `location.href` (même instant que le contenu) ;
/// - `document.title` et `<meta property="og:title">` ;
/// - le `name` des nœuds JSON-LD `@type: Chapter` de PREMIER niveau (racine,
///   `@graph`, ou `mainEntity` d'un nœud racine). Un `Chapter` imbriqué
///   ailleurs (`nextItem`, `hasPart`…) décrit un autre chapitre : ignoré ;
/// - le dernier élément du fil d'Ariane (JSON-LD `BreadcrumbList`, sinon
///   `nav[aria-label*=readcrumb]` / `.breadcrumb`).
///
/// Jamais le texte des liens ni le corps de la page : « Chapitre suivant »
/// et l'aperçu du chapitre 3 y côtoient le chapitre 2 qu'on lit.
class PageChapterProbe {
  const PageChapterProbe();

  /// Relectures après une navigation interne du site (`pushState`) : le
  /// titre et les données de la page suivent l'adresse avec retard. Jamais
  /// au défilement.
  static const List<Duration> retryDelays = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
  ];

  /// Script du relevé. [titleSelector] : sélecteur CSS propre au site dont
  /// le texte est le titre du chapitre (crochet pour un réglage futur ; le
  /// sélecteur « contenu du chapitre » existant désigne le conteneur des
  /// images, dont le texte n'est pas un titre — il n'est donc pas réutilisé).
  static String script({String? titleSelector}) => '''
(function() {
  function txt(s) {
    return (s == null ? '' : String(s)).replace(/\\s+/g, ' ').trim().slice(0, 300);
  }
  function types(n) {
    var t = n && n['@type'];
    return Array.isArray(t) ? t : (t ? [t] : []);
  }
  var chapters = [], crumb = '', custom = '';
  var scripts = document.querySelectorAll('script[type="application/ld+json"]');
  for (var i = 0; i < scripts.length && i < 20; i++) {
    var data;
    try { data = JSON.parse(scripts[i].textContent || ''); } catch (e) { continue; }
    var roots = Array.isArray(data) ? data : [data];
    var nodes = [];
    for (var r = 0; r < roots.length && r < 50; r++) {
      var root = roots[r];
      if (!root || typeof root !== 'object') continue;
      nodes.push(root);
      if (Array.isArray(root['@graph'])) nodes = nodes.concat(root['@graph']);
    }
    var top = nodes.length;
    for (var m = 0; m < top && m < 100; m++) {
      var main = nodes[m] && nodes[m].mainEntity;
      if (main && typeof main === 'object' && !Array.isArray(main)) nodes.push(main);
    }
    for (var k = 0; k < nodes.length && k < 200; k++) {
      var n = nodes[k];
      if (!n || typeof n !== 'object') continue;
      var t = types(n);
      if (t.indexOf('Chapter') >= 0 && n.name) chapters.push(txt(n.name));
      if (t.indexOf('BreadcrumbList') >= 0 && Array.isArray(n.itemListElement)) {
        var items = n.itemListElement.slice().sort(function(a, b) {
          return ((a && a.position) || 0) - ((b && b.position) || 0);
        });
        var last = items[items.length - 1];
        if (last) crumb = txt(last.name || (last.item && last.item.name));
      }
    }
  }
  if (!crumb) {
    var el = document.querySelector('nav[aria-label*="readcrumb"] li:last-child, .breadcrumb li:last-child, .breadcrumbs li:last-child');
    if (el) crumb = txt(el.textContent);
  }
  var sel = ${jsonEncode(titleSelector)};
  if (sel) {
    try { var c = document.querySelector(sel); if (c) custom = txt(c.textContent); } catch (e) {}
  }
  var og = document.querySelector('meta[property="og:title"]');
  return JSON.stringify({
    url: String(location.href),
    title: txt(document.title),
    og: og ? txt(og.getAttribute('content')) : '',
    chapters: chapters.slice(0, 10),
    crumb: crumb,
    custom: custom
  });
})();
''';

  /// Signaux de la page, `null` si elle n'a rien rendu d'exploitable.
  Future<PageChapterSignals?> read(
    InAppWebViewController controller, {
    String? titleSelector,
  }) async =>
      decode(await controller.evaluateJavascript(
        source: script(titleSelector: titleSelector),
      ));

  /// Décodage du retour (`Map` sur Android, chaîne JSON ailleurs) — pur,
  /// testable sans WebView.
  static PageChapterSignals? decode(Object? raw) {
    final map = WebViewResultParser.asMap(raw);
    if (map == null) return null;
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value : null;
    final chapters = map['chapters'];
    return PageChapterSignals(
      url: text(map['url']),
      title: text(map['title']),
      ogTitle: text(map['og']),
      jsonLdChapterNames: [
        if (chapters is List)
          for (final name in chapters)
            if (text(name) != null) name as String,
      ],
      breadcrumb: text(map['crumb']),
      customText: text(map['custom']),
    );
  }
}
