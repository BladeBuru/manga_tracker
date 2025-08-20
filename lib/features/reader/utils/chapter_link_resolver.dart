import 'dart:core';

class ChapterLinkResolver {
  /// Essaie d'extraire le numéro de chapitre depuis une URL.
  /// Retourne null si introuvable.
  static int? extractChapter(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

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

  /// Construit une URL pour un chapitre donné, à partir d'une URL existante.
  /// - Remplace le numéro trouvé (path ou query) par `chapter`.
  /// - Si aucun pattern reconnu -> retourne null (pour éviter de générer un mauvais lien).
  static String? buildUrlForChapter(String baseUrl, int chapter) {

    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return null;
    final chStr = chapter.toString();

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

  /// Construit l'URL du chapitre suivant si possible.
  /// - Si `currentChapter` est fourni, on utilise `currentChapter+1`.
  /// - Sinon on tente d'extraire depuis l'URL et on ajoute +1.
  static String? buildNextUrl(String baseUrl, {int? currentChapter}) {
    final cur = currentChapter ?? extractChapter(baseUrl);
    if (cur == null) return null;
    return buildUrlForChapter(baseUrl, cur + 1);
  }

  /// Nettoyage simple pour extraire des chiffres d'une chaîne.
  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}
