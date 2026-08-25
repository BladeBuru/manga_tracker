import 'dart:core';
import 'package:mangatracker/features/manga/services/custom_selectors.service.dart';
import 'package:mangatracker/features/reader/utils/chapter_url_heuristics.dart';

/// Résout le numéro de chapitre depuis une URL de lecture et construit les
/// URLs de navigation entre chapitres.
///
/// Ordre de détection (extraction comme remplacement) :
/// 0) patterns regex personnalisés (par domaine, puis globaux `*`) ;
/// 1) paramètres de requête connus (`?chapter=`, `?episode_no=`, ...) ;
/// 2) patterns de chemin connus (`chapitre-616`, `c120`, `/manga/22`, ...) ;
/// 3) fallback : segment de chemin entièrement numérique
///    (voir [ChapterUrlHeuristics]).
class ChapterLinkResolver {
  static CustomSelectorsService? _selectorsService;

  /// Initialise le service de sélecteurs personnalisés
  static void init(CustomSelectorsService? service) {
    _selectorsService = service;
  }

  /// Clés de paramètres de requête connues pour un numéro de chapitre.
  static const List<String> _chapterQueryKeys = [
    'chapter', 'chapitre', 'ch', 'ep', 'episode', 'episode_no', 'num', 'no',
  ];

  /// Patterns de chemin connus (extraction).
  static final List<RegExp> _knownExtractPatterns = <RegExp>[
    // /manga/22 ou /manga/22/ (format simple avec nombre après slash)
    RegExp(r'/manga/(\d+)(?:/|$)', caseSensitive: false),
    // /chapitre-616/  | /chapter-616/ | -chapitre_616 | _chapter616
    RegExp(r'(?:^|[\/\-_])chap(?:itre|ter)?[\/\-_]?(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
    // /c120/ | -c120 | _c120
    RegExp(r'(?:^|[\/\-_])c(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
    // /ch120/ | /chap120/
    RegExp(r'(?:^|[\/\-_])ch(?:ap)?[\/\-_]?(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
    // /ep-10/ | /episode_10/
    RegExp(r'(?:^|[\/\-_])ep(?:isode)?[\/\-_]?(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
    // slug-chapitre-113 (ex: sushiscan.net/spyxfamily-chapitre-113/)
    RegExp(r'(?:^|[\/\-_])[a-z0-9]+-chap(?:itre|ter)?[\/\-_]?(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
  ];

  /// Patterns de chemin connus (remplacement — préfixe capturé en groupe 1).
  static final List<RegExp> _knownReplacePatterns = <RegExp>[
    // /manga/22 -> /manga/23
    RegExp(r'(/manga/)(\d+)(?:/|$)', caseSensitive: false),
    // /chapitre-616/  | /chapter-616/
    RegExp(r'((?:^|[\/\-_])chap(?:itre|ter)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
    // /c120/
    RegExp(r'((?:^|[\/\-_])c)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
    // /ch120/ | /chap120/
    RegExp(r'((?:^|[\/\-_])ch(?:ap)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
    // /ep-10/ | /episode_10/
    RegExp(r'((?:^|[\/\-_])ep(?:isode)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
    // slug-chapitre-113
    RegExp(r'((?:^|[\/\-_])[a-z0-9]+-chap(?:itre|ter)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)',
        caseSensitive: false),
  ];

  /// Essaie d'extraire le numéro de chapitre depuis une URL.
  /// Retourne null si introuvable.
  static Future<int?> extractChapter(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // 0) Patterns d'URL personnalisés par domaine (priorité)
    final custom = await _extractFromCustomPatterns(url, uri.host);
    if (custom != null) return custom;

    // 1) -> 3) Étapes communes (query, patterns connus, fallback)
    return extractChapterSync(url);
  }

  /// Version synchrone pour compatibilité (sans les patterns personnalisés)
  static int? extractChapterSync(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // 1) Paramètres de requête (ex: Webtoons ?episode_no=3)
    for (final key in _chapterQueryKeys) {
      final v = uri.queryParameters[key];
      if (v != null) {
        final n = int.tryParse(_onlyDigits(v));
        if (n != null) return n;
      }
    }

    // 2) Patterns connus dans le chemin / slug
    final whole = uri.toString();
    for (final rx in _knownExtractPatterns) {
      final m = rx.firstMatch(whole);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null) return n;
      }
    }

    // 3) Fallback : segment de chemin entièrement numérique
    //    (ex: raijin-scans /manga/<slug>/190/ -> 190, jamais le 4000 du slug)
    return ChapterUrlHeuristics.extractIsolatedNumericSegment(uri);
  }

  /// Construit une URL pour un chapitre donné, à partir d'une URL existante.
  /// - Remplace le numéro trouvé (custom, query, path ou segment isolé).
  /// - Si aucun pattern reconnu -> retourne null (évite un mauvais lien).
  static Future<String?> buildUrlForChapter(String baseUrl, int chapter) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return null;

    // 0) Patterns d'URL personnalisés par domaine (priorité)
    final custom = await _replaceWithCustomPatterns(baseUrl, uri.host, chapter);
    if (custom != null) return custom;

    // 1) -> 3) Étapes communes (query, patterns connus, fallback)
    return buildUrlForChapterSync(baseUrl, chapter);
  }

  /// Version synchrone pour compatibilité (sans les patterns personnalisés)
  static String? buildUrlForChapterSync(String baseUrl, int chapter) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return null;
    final chStr = chapter.toString();

    // 1) Si l'URL a un paramètre de chapitre -> on le remplace
    final qp = Map<String, String>.from(uri.queryParameters);
    for (final key in _chapterQueryKeys) {
      if (qp.containsKey(key)) {
        qp[key] = chStr;
        return uri.replace(queryParameters: qp).toString();
      }
    }

    // 2) Sinon on remplace dans le chemin/slug selon les patterns connus
    for (final rx in _knownReplacePatterns) {
      final m = rx.firstMatch(baseUrl);
      if (m != null) {
        // conserve le préfixe et remplace UNIQUEMENT le groupe numérique
        return baseUrl.replaceFirstMapped(rx, (mm) => '${mm.group(1)}$chStr');
      }
    }

    // 3) Fallback : remplace le segment numérique isolé (ex: /190/ -> /191/)
    return ChapterUrlHeuristics.replaceIsolatedNumericSegment(baseUrl, chapter);
  }

  /// Construit l'URL du chapitre suivant si possible.
  /// - Si `currentChapter` est fourni, on utilise `currentChapter+1`.
  /// - Sinon on tente d'extraire depuis l'URL et on ajoute +1.
  static Future<String?> buildNextUrl(String baseUrl,
      {int? currentChapter}) async {
    final cur = currentChapter ?? await extractChapter(baseUrl);
    if (cur == null) return null;
    return await buildUrlForChapter(baseUrl, cur + 1);
  }

  /// 0) Extraction via les patterns personnalisés (domaine puis globaux `*`).
  static Future<int?> _extractFromCustomPatterns(String url, String host) async {
    for (final customSelector in await _customPatternsFor(host)) {
      try {
        // Le "selector" contient le pattern regex personnalisé
        final pattern = RegExp(customSelector.selector, caseSensitive: false);
        final match = pattern.firstMatch(url);
        if (match != null && match.groupCount >= 1) {
          final chapterStr = match.group(1);
          if (chapterStr != null) {
            final chapter = int.tryParse(_onlyDigits(chapterStr));
            if (chapter != null) return chapter;
          }
        }
      } catch (e) {
        // Ignorer les patterns invalides
      }
    }
    return null;
  }

  /// 0) Remplacement via les patterns personnalisés (domaine puis globaux `*`).
  static Future<String?> _replaceWithCustomPatterns(
      String baseUrl, String host, int chapter) async {
    final chStr = chapter.toString();
    for (final customSelector in await _customPatternsFor(host)) {
      try {
        // Format attendu : pattern avec groupe de capture pour le numéro
        final pattern = RegExp(customSelector.selector, caseSensitive: false);
        final match = pattern.firstMatch(baseUrl);
        if (match != null && match.groupCount >= 1) {
          // Remplacer le numéro dans l'URL
          return baseUrl.replaceFirstMapped(pattern, (m) {
            // Si le pattern a un groupe de capture pour le préfixe, l'utiliser
            if (match.groupCount >= 2) {
              return '${match.group(1)}$chStr${match.group(2) ?? ''}';
            } else {
              // Sinon, remplacer juste le numéro
              return baseUrl.replaceFirst(match.group(1)!, chStr);
            }
          });
        }
      } catch (e) {
        // Ignorer les patterns invalides
      }
    }
    return null;
  }

  /// Patterns personnalisés du domaine + patterns globaux (`*`).
  static Future<List<CustomSelector>> _customPatternsFor(String host) async {
    final service = _selectorsService;
    if (service == null) return const [];
    final customPatterns = await service.getUrlPatternsForDomain(host);
    final globalPatterns = await service.getUrlPatternsForDomain('*');
    return [...customPatterns, ...globalPatterns];
  }

  /// Nettoyage simple pour extraire des chiffres d'une chaîne.
  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}
