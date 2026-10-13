/// Heuristiques de secours pour les URLs dont le numéro de chapitre est un
/// segment de chemin isolé (ex: raijin-scans `/manga/<slug>/190/`).
///
/// Règles :
/// - seuls les segments de chemin ENTIÈREMENT numériques sont candidats
///   (`190` dans `/manga/slug-4000-years/190/` oui ; `4000` à l'intérieur
///   d'un slug avec tirets, jamais) ;
/// - si plusieurs segments candidats, le DERNIER gagne (le chapitre est plus
///   profond que l'id de série) — gère aussi `/190/chapter/blablabla` ;
/// - garde-fous anti-faux-positifs : les paires de segments ressemblant à une
///   date (`/2024/05/...`) et les segments de plus de 6 chiffres (ids
///   techniques) sont ignorés.
///
/// Fournit aussi [maskOpaqueIds] : les identifiants opaques (UUID, jetons
/// hexadécimaux) sont neutralisés avant toute recherche de motif.
class ChapterUrlHeuristics {
  ChapterUrlHeuristics._();

  static final RegExp _fullyNumeric = RegExp(r'^\d+$');

  /// UUID canonique (8-4-4-4-12 caractères hexadécimaux).
  static final RegExp _uuid = RegExp(
    r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    caseSensitive: false,
  );

  /// Jeton alphanumérique ASCII (entre deux séparateurs de l'URL).
  static final RegExp _alnumToken = RegExp(r'[0-9a-z]+', caseSensitive: false);
  static final RegExp _hexOnly = RegExp(r'^[0-9a-f]+$', caseSensitive: false);
  static final RegExp _hasDigit = RegExp(r'\d');
  static final RegExp _hasHexLetter = RegExp(r'[a-f]', caseSensitive: false);

  /// Longueur à partir de laquelle un jeton hexadécimal mêlant chiffres et
  /// lettres est un identifiant technique (ObjectId, hash…), jamais un mot.
  static const int _minOpaqueHexLength = 8;

  /// Copie de [url] **de même longueur** où chaque identifiant opaque (UUID,
  /// long jeton hexadécimal) est remplacé par des espaces.
  ///
  /// Un identifiant opaque n'est JAMAIS un numéro de chapitre. Sur aniverse.fr
  /// (`/read/chainsaw-man/56f9e3ca-e8f5-49fc-8116-da885090eaf3`), l'URL ne
  /// porte aucun numéro ; mais un UUID contenant `-c41b-` faisait lire
  /// « chapitre 41 » au motif `c(\d+)`, et le lien de lecture était ensuite
  /// réécrit en remplaçant ce morceau d'UUID — un lien cassé.
  ///
  /// Les index restent alignés avec [url] : un motif trouvé dans la copie
  /// masquée se remplace au même endroit dans l'URL d'origine. Les espaces
  /// n'appartiennent à aucun motif de chapitre (et `Uri.toString()` n'en
  /// contient jamais).
  static String maskOpaqueIds(String url) {
    final units = List<int>.of(url.codeUnits);
    void blank(int start, int end) {
      for (var i = start; i < end; i++) {
        units[i] = 0x20;
      }
    }

    for (final m in _uuid.allMatches(url)) {
      blank(m.start, m.end);
    }
    for (final m in _alnumToken.allMatches(url)) {
      final token = m.group(0)!;
      if (token.length >= _minOpaqueHexLength &&
          _hexOnly.hasMatch(token) &&
          _hasDigit.hasMatch(token) &&
          _hasHexLetter.hasMatch(token)) {
        blank(m.start, m.end);
      }
    }
    return String.fromCharCodes(units);
  }

  /// `true` si [value] contient un identifiant opaque (voir [maskOpaqueIds]).
  static bool containsOpaqueId(String value) => maskOpaqueIds(value) != value;

  /// Nombre de chiffres maximum d'un candidat (au-delà : id technique).
  static const int _maxCandidateDigits = 6;

  /// Extrait le numéro de chapitre depuis un segment numérique isolé.
  /// Retourne null si aucun candidat valide.
  static int? extractIsolatedNumericSegment(Uri uri) {
    final segments = _nonEmptySegments(uri);
    final index = _candidateIndex(segments);
    if (index == null) return null;
    return int.tryParse(segments[index]);
  }

  /// Remplace le segment numérique isolé par [chapter] et retourne la
  /// nouvelle URL. Retourne null si aucun candidat valide (pour ne pas
  /// fabriquer une fausse route).
  static String? replaceIsolatedNumericSegment(String baseUrl, int chapter) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null) return null;
    final segments = _nonEmptySegments(uri);
    final index = _candidateIndex(segments);
    if (index == null) return null;

    final updated = List<String>.from(segments);
    updated[index] = chapter.toString();
    final trailingSlash = uri.path.endsWith('/');
    final newPath = '/${updated.join('/')}${trailingSlash ? '/' : ''}';
    return uri.replace(path: newPath).toString();
  }

  static List<String> _nonEmptySegments(Uri uri) =>
      uri.pathSegments.where((s) => s.isNotEmpty).toList();

  /// Index du DERNIER segment entièrement numérique valide, ou null.
  static int? _candidateIndex(List<String> segments) {
    final excluded = _datePairIndexes(segments);
    int? found;
    for (var i = 0; i < segments.length; i++) {
      if (excluded.contains(i)) continue;
      final segment = segments[i];
      if (!_fullyNumeric.hasMatch(segment)) continue;
      if (segment.length > _maxCandidateDigits) continue;
      found = i;
    }
    return found;
  }

  /// Indexes des paires `/année/mois/` (ex: `/2024/05/...`) à exclure :
  /// segment de 4 chiffres entre 1900 et 2100 immédiatement suivi d'un
  /// segment de 1-2 chiffres compris entre 1 et 12.
  static Set<int> _datePairIndexes(List<String> segments) {
    final excluded = <int>{};
    for (var i = 0; i < segments.length - 1; i++) {
      final year = segments[i];
      final month = segments[i + 1];
      if (year.length != 4 || !_fullyNumeric.hasMatch(year)) continue;
      final y = int.parse(year);
      if (y < 1900 || y > 2100) continue;
      if (month.length > 2 || !_fullyNumeric.hasMatch(month)) continue;
      final m = int.parse(month);
      if (m < 1 || m > 12) continue;
      excluded
        ..add(i)
        ..add(i + 1);
    }
    return excluded;
  }
}
