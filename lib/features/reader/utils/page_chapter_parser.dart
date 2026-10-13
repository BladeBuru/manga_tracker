/// Numéro de chapitre lu dans la PAGE (titre, données structurées), pour les
/// sites dont l'URL n'en porte aucun — **pur** (ni Flutter, ni GetIt, ni
/// WebView). Testé par `test/features/reader/page_chapter_parser_test.dart`.
///
/// Cas fondateur, aniverse.fr (vérifié le 2026-10-13) : l'URL
/// `/read/chainsaw-man/<uuid>` n'a pas de numéro, mais la page dit
/// « Chainsaw Man Chapitre 1 Scan VF | Aniverse » (titre et `og:title`), et
/// ses données JSON-LD contiennent `{"@type": "Chapter", "name": "Chapitre 1"}`.
///
/// ## Règles (« aucun faux positif, à aucun prix »)
///
/// - On ne lit QUE des signaux qui décrivent la page elle-même : nom du
///   `Chapter` JSON-LD, `og:title`, `document.title`, dernier élément du fil
///   d'Ariane. Jamais le texte des liens ni du corps de la page : un lecteur
///   affiche souvent le chapitre suivant (« Chapitre 3 ») pendant qu'on lit le
///   chapitre 2.
/// - Tout morceau de texte qui parle d'un AUTRE chapitre (suivant, précédent,
///   next, previous…) est ignoré.
/// - Deux sources fortes (JSON-LD, titres) en désaccord → `null` : pendant un
///   changement de page côté site, le titre peut déjà être à jour et les
///   données pas encore ; le lecteur relit la page un peu plus tard.
/// - Chapitre décimal (`271.5`), intervalle (`12-13`), année (1900–2100) ou
///   valeur absurde (> 99999) → `null`. L'application compte des chapitres
///   ENTIERS : un chapitre 271.5 n'est pas suivi, le passage 271 → 272 l'est.
/// - Le `position` du JSON-LD est un rang dans une liste, pas un numéro de
///   chapitre : il n'est jamais lu.
library;

/// Signaux bruts d'une page, tels que les relève `PageChapterProbe`.
class PageChapterSignals {
  const PageChapterSignals({
    this.url,
    this.title,
    this.ogTitle,
    this.jsonLdChapterNames = const [],
    this.breadcrumb,
    this.customText,
  });

  /// `location.href` au moment du relevé : le contenu et l'adresse viennent
  /// du même instant (pas d'URL d'une page avec le titre d'une autre).
  final String? url;
  final String? title;
  final String? ogTitle;

  /// `name` des nœuds JSON-LD `@type: Chapter` de premier niveau.
  final List<String> jsonLdChapterNames;

  /// Dernier élément du fil d'Ariane.
  final String? breadcrumb;

  /// Texte d'un sélecteur propre au site, s'il en existe un : prioritaire,
  /// c'est un réglage explicite.
  final String? customText;
}

class PageChapterParser {
  const PageChapterParser._();

  /// Valeur maximale crédible d'un numéro de chapitre.
  static const int maxChapter = 99999;

  /// « Chapitre 12 », « Ch. 12 », « Capítulo 12 », « Episode n° 12 »…
  static final RegExp _latin = RegExp(
    r'(?<![\p{L}\p{N}])'
    r'(?:chapitre|chapter|chap\.?|ch\.?|cap[ií]tulo|cap\.?|kapitel|kap\.?'
    r'|[eéÉE]pisode|episodio|ep\.?|scan)'
    r'\s*[:#]?\s*(?:n[°º]\s*|no\.\s*)?'
    r'(\d+(?:[.,]\d+)?)(\s*[-–~]\s*\d+)?(?![\p{L}\p{N}])',
    caseSensitive: false,
    unicode: true,
  );

  /// « 第12話 » (japonais, chinois), « 12화 » / « 제12화 » (coréen).
  static final RegExp _cjk = RegExp(
    r'第\s*(\d+)\s*[話话章回]|(?<!\p{N})(\d+)\s*화',
    unicode: true,
  );

  /// Morceaux d'un titre : « Série - Chapitre 2 | Site (suivant : 3) ». Un
  /// tiret n'est un séparateur qu'entouré d'espaces : « 12-13 » reste un
  /// intervalle, donc refusé.
  static final RegExp _separators = RegExp(r'[|•·»«›‹()\[\]]|\s[-–—]\s');

  /// Mots qui désignent un AUTRE chapitre que celui affiché.
  static final RegExp _otherChapterWords = RegExp(
    r'(?<!\p{L})(?:suivante?s?|pr[ée]c[ée]dente?s?|prochaine?s?|next|previous'
    r'|prev|siguiente|anterior|pr[óo]ximo|seguinte|n[äa]e?chste[nrs]?'
    r'|vorherige[nrs]?|weiter|zur[üu]ck)(?!\p{L})|次|前|다음|이전',
    caseSensitive: false,
    unicode: true,
  );

  static final RegExp _bareNumber = RegExp(r'^\s*(\d+)\s*$');

  /// Numéro du chapitre affiché, ou `null` s'il n'est pas CERTAIN.
  static int? parse(PageChapterSignals signals) {
    final custom = _read(signals.customText);
    if (custom.unusable) return null;
    if (custom.value != null) return custom.value;

    final strong = [
      for (final name in signals.jsonLdChapterNames)
        _read(name, allowBareNumber: true),
      _read(signals.ogTitle),
      _read(signals.title),
    ];
    if (strong.any((r) => r.unusable)) return null;
    final values = {
      for (final r in strong)
        if (r.value != null) r.value!,
    };
    if (values.length > 1) return null;
    if (values.length == 1) return values.single;

    // Fil d'Ariane : seulement à défaut de source forte.
    return _read(signals.breadcrumb).value;
  }

  /// Lecture d'un texte isolé (exposée pour les tests).
  static int? numberIn(String? text) => _read(text).value;

  static _Reading _read(String? text, {bool allowBareNumber = false}) {
    if (text == null || text.trim().isEmpty) return _Reading.none;
    if (allowBareNumber) {
      final bare = _bareNumber.firstMatch(text);
      if (bare != null) return _Reading.of(int.parse(bare.group(1)!));
    }
    final found = <int>{};
    for (final segment in text.split(_separators)) {
      if (_otherChapterWords.hasMatch(segment)) continue;
      for (final m in _latin.allMatches(segment)) {
        final raw = m.group(1)!;
        // Décimal (271.5) ou intervalle (12-13) : pas un chapitre entier.
        if (raw.contains('.') || raw.contains(',') || m.group(2) != null) {
          return _Reading.unusableReading;
        }
        found.add(int.parse(raw));
      }
      for (final m in _cjk.allMatches(segment)) {
        found.add(int.parse(m.group(1) ?? m.group(2)!));
      }
    }
    if (found.isEmpty) return _Reading.none;
    if (found.length > 1) return _Reading.unusableReading;
    return _Reading.of(found.single);
  }
}

/// Résultat de la lecture d'une source : rien, une valeur, ou inutilisable
/// (ambigu, décimal, année…) — ce dernier cas annule toute la détection.
class _Reading {
  const _Reading._(this.value, this.unusable);

  static const none = _Reading._(null, false);
  static const unusableReading = _Reading._(null, true);

  factory _Reading.of(int value) {
    final isYear = value >= 1900 && value <= 2100;
    if (isYear || value > PageChapterParser.maxChapter) return unusableReading;
    return _Reading._(value, false);
  }

  final int? value;
  final bool unusable;
}
