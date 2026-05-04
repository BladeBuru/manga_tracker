import 'dart:core';
import 'package:mangatracker/features/manga/services/custom_selectors.service.dart';

class ChapterLinkResolver {
  static CustomSelectorsService? _selectorsService;
  
  /// Initialise le service de sélecteurs personnalisés
  static void init(CustomSelectorsService? service) {
    _selectorsService = service;
  }

  /// Essaie d'extraire le numéro de chapitre depuis une URL.
  /// Retourne null si introuvable.
  static Future<int?> extractChapter(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // 0) Patterns d'URL personnalisés par domaine (priorité)
    if (_selectorsService != null) {
      final domain = uri.host;
      // Récupérer les patterns spécifiques au domaine ET les patterns globaux (*)
      final customPatterns = await _selectorsService!.getUrlPatternsForDomain(domain);
      final globalPatterns = await _selectorsService!.getUrlPatternsForDomain('*');
      final allPatterns = [...customPatterns, ...globalPatterns];
      
      for (final customSelector in allPatterns) {
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
    }

    // 1) Paramètres de requête (ex: Webtoons ?episode_no=3)
    for (final key in const [
      'chapter', 'chapitre', 'ch', 'ep', 'episode', 'episode_no', 'num', 'no'
    ]) {
      final v = uri.queryParameters[key];
      if (v != null) {
        final n = int.tryParse(_onlyDigits(v));
        if (n != null) return n;
      }
    }

    // 2) Patterns dans le chemin / slug
    final whole = uri.toString();

    final patterns = <RegExp>[
      // /manga/22 ou /manga/22/ (format simple avec nombre après slash)
      RegExp(r'/manga/(\d+)(?:/|$)', caseSensitive: false),
      // /chapitre-616/  | /chapter-616/ | -chapitre_616 | _chapter616
      RegExp(r'(?:^|[\/\-_])chap(?:itre|ter)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // /c120/ | -c120 | _c120
      RegExp(r'(?:^|[\/\-_])c(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // /ch120/ | /chap120/
      RegExp(r'(?:^|[\/\-_])ch(?:ap)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // /ep-10/ | /episode_10/
      RegExp(r'(?:^|[\/\-_])ep(?:isode)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // slug-chapitre-113 (ex: sushiscan.net/spyxfamily-chapitre-113/)
      RegExp(r'(?:^|[\/\-_])[a-z0-9]+-chap(?:itre|ter)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
    ];

    for (final rx in patterns) {
      final m = rx.firstMatch(whole);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null) return n;
      }
    }

    return null;
  }

  /// Version synchrone pour compatibilité (utilise les patterns par défaut uniquement)
  static int? extractChapterSync(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Paramètres de requête
    for (final key in const [
      'chapter', 'chapitre', 'ch', 'ep', 'episode', 'episode_no', 'num', 'no'
    ]) {
      final v = uri.queryParameters[key];
      if (v != null) {
        final n = int.tryParse(_onlyDigits(v));
        if (n != null) return n;
      }
    }

    final whole = uri.toString();
    final patterns = <RegExp>[
      RegExp(r'/manga/(\d+)(?:/|$)', caseSensitive: false),
      RegExp(r'(?:^|[\/\-_])chap(?:itre|ter)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'(?:^|[\/\-_])c(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'(?:^|[\/\-_])ch(?:ap)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'(?:^|[\/\-_])ep(?:isode)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'(?:^|[\/\-_])[a-z0-9]+-chap(?:itre|ter)?[\/\-_]?(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
    ];

    for (final rx in patterns) {
      final m = rx.firstMatch(whole);
      if (m != null) {
        final n = int.tryParse(m.group(1)!);
        if (n != null) return n;
      }
    }

    return null;
  }

  /// Construit une URL pour un chapitre donné, à partir d'une URL existante.
  /// - Remplace le numéro trouvé (path ou query) par `chapter`.
  /// - Si aucun pattern reconnu -> retourne null (pour éviter de générer un mauvais lien).
  static Future<String?> buildUrlForChapter(String baseUrl, int chapter) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return null;
    final chStr = chapter.toString();

    // 0) Patterns d'URL personnalisés par domaine (priorité)
    if (_selectorsService != null) {
      final domain = uri.host;
      // Récupérer les patterns spécifiques au domaine ET les patterns globaux (*)
      final customPatterns = await _selectorsService!.getUrlPatternsForDomain(domain);
      final globalPatterns = await _selectorsService!.getUrlPatternsForDomain('*');
      final allPatterns = [...customPatterns, ...globalPatterns];
      
      for (final customSelector in allPatterns) {
        try {
          // Le "selector" contient le pattern regex pour le remplacement
          // Format attendu : pattern avec groupe de capture pour le numéro
          final pattern = RegExp(customSelector.selector, caseSensitive: false);
          final match = pattern.firstMatch(baseUrl);
          if (match != null && match.groupCount >= 1) {
            // Remplacer le numéro dans l'URL
            final replaced = baseUrl.replaceFirstMapped(pattern, (m) {
              // Si le pattern a un groupe de capture pour le préfixe, l'utiliser
              if (match.groupCount >= 2) {
                return '${match.group(1)}$chStr${match.group(2) ?? ''}';
              } else {
                // Sinon, remplacer juste le numéro
                return baseUrl.replaceFirst(match.group(1)!, chStr);
              }
            });
            return replaced;
          }
        } catch (e) {
          // Ignorer les patterns invalides
        }
      }
    }

    // 1) Si l'URL a un paramètre de chapitre -> on le remplace
    final qp = Map<String, String>.from(uri.queryParameters);
    for (final key in const [
      'chapter', 'chapitre', 'ch', 'ep', 'episode', 'episode_no', 'num', 'no'
    ]) {
      if (qp.containsKey(key)) {
        qp[key] = chStr;
        return uri.replace(queryParameters: qp).toString();
      }
    }

    // 2) Sinon on tente de remplacer dans le chemin/slug selon patterns courants
    final replacements = <RegExp>[
      // /manga/22 -> /manga/23
      RegExp(r'(/manga/)(\d+)(?:/|$)', caseSensitive: false),
      // /chapitre-616/  | /chapter-616/
      RegExp(r'((?:^|[\/\-_])chap(?:itre|ter)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // /c120/
      RegExp(r'((?:^|[\/\-_])c)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // /ch120/ | /chap120/
      RegExp(r'((?:^|[\/\-_])ch(?:ap)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // /ep-10/ | /episode_10/
      RegExp(r'((?:^|[\/\-_])ep(?:isode)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      // slug-chapitre-113
      RegExp(r'((?:^|[\/\-_])[a-z0-9]+-chap(?:itre|ter)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
    ];

    var s = baseUrl;
    for (final rx in replacements) {
      final m = rx.firstMatch(s);
      if (m != null) {
        // conserve le préfixe et remplace UNIQUEMENT le groupe numérique
        s = s.replaceFirstMapped(rx, (mm) => '${mm.group(1)}$chStr');
        return s;
      }
    }

    // Aucun motif reconnu -> on ne fabrique pas d'URL pour éviter une fausse route.
    return null;
  }

  /// Version synchrone pour compatibilité
  static String? buildUrlForChapterSync(String baseUrl, int chapter) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return null;
    final chStr = chapter.toString();

    final qp = Map<String, String>.from(uri.queryParameters);
    for (final key in const [
      'chapter', 'chapitre', 'ch', 'ep', 'episode', 'episode_no', 'num', 'no'
    ]) {
      if (qp.containsKey(key)) {
        qp[key] = chStr;
        return uri.replace(queryParameters: qp).toString();
      }
    }

    final replacements = <RegExp>[
      RegExp(r'(/manga/)(\d+)(?:/|$)', caseSensitive: false),
      RegExp(r'((?:^|[\/\-_])chap(?:itre|ter)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'((?:^|[\/\-_])c)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'((?:^|[\/\-_])ch(?:ap)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'((?:^|[\/\-_])ep(?:isode)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
      RegExp(r'((?:^|[\/\-_])[a-z0-9]+-chap(?:itre|ter)?[\/\-_]?)(\d+)(?=[\/\-_]?|$)', caseSensitive: false),
    ];

    var s = baseUrl;
    for (final rx in replacements) {
      final m = rx.firstMatch(s);
      if (m != null) {
        s = s.replaceFirstMapped(rx, (mm) => '${mm.group(1)}$chStr');
        return s;
      }
    }

    return null;
  }

  /// Construit l'URL du chapitre suivant si possible.
  /// - Si `currentChapter` est fourni, on utilise `currentChapter+1`.
  /// - Sinon on tente d'extraire depuis l'URL et on ajoute +1.
  static Future<String?> buildNextUrl(String baseUrl, {int? currentChapter}) async {
    final cur = currentChapter ?? await extractChapter(baseUrl);
    if (cur == null) return null;
    return await buildUrlForChapter(baseUrl, cur + 1);
  }

  /// Nettoyage simple pour extraire des chiffres d'une chaîne.
  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}
