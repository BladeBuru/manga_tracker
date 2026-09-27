/// Adresse RÉELLE d'une image de chapitre — pur, sans Flutter.
///
/// Les sites de lecture chargent leurs pages en différé (lazy-loading) :
/// `src` contient d'abord une image d'attente (Madara : `dflazy.jpg`, pixel
/// transparent, `data:`…) et la vraie adresse vit dans `data-src` ou un
/// attribut voisin. L'ancien code lisait `src` EN PREMIER : il téléchargeait
/// l'image d'attente et jetait la vraie adresse — chapitres « vides ».
class ChapterImageSource {
  const ChapterImageSource._();

  /// Attributs de chargement différé, par ordre de préférence.
  static const List<String> lazyAttributes = [
    'data-src',
    'data-lazy-src',
    'data-original',
    'data-url',
    'data-image',
    'data-lazy',
  ];

  /// Attributs `srcset` (le premier candidat est retenu).
  static const List<String> srcsetAttributes = ['data-srcset', 'srcset'];

  /// Tous les attributs utiles à [pick] (pour les relever dans la page).
  static const List<String> relevantAttributes = [
    ...lazyAttributes,
    ...srcsetAttributes,
    'src',
  ];

  /// Jetons de nom de fichier trahissant une image d'attente.
  static const List<String> _placeholderTokens = [
    'lazy',
    'placeholder',
    'loading',
    'loader',
    'blank',
    'spacer',
    'transparent',
    'pixel',
    '1x1',
  ];

  /// L'adresse est-elle absente ou une image d'attente ?
  static bool isPlaceholder(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty || value.startsWith('data:') || value == 'about:blank') {
      return true;
    }
    final path = Uri.tryParse(value)?.path ?? value;
    final file = path.split('/').last.toLowerCase();
    return _placeholderTokens.any(file.contains);
  }

  /// La meilleure adresse d'image parmi [attributes] (nom → valeur), ou
  /// `null` s'il n'y en a aucune de réelle.
  ///
  /// Ordre : attributs différés, puis `srcset`, puis `src` — une image
  /// d'attente n'est jamais retenue.
  static String? pick(Map<String, String> attributes) {
    for (final name in lazyAttributes) {
      final value = attributes[name]?.trim();
      if (!isPlaceholder(value)) return value;
    }
    for (final name in srcsetAttributes) {
      final first = _firstSrcsetCandidate(attributes[name]);
      if (!isPlaceholder(first)) return first;
    }
    final src = attributes['src']?.trim();
    return isPlaceholder(src) ? null : src;
  }

  /// A-t-elle un attribut de chargement différé ? (image de contenu, pas un
  /// logo : les sites ne diffèrent que les pages du chapitre).
  static bool hasLazyAttribute(Map<String, String> attributes) =>
      lazyAttributes.any((name) => attributes[name]?.trim().isNotEmpty ?? false);

  static String? _firstSrcsetCandidate(String? srcset) {
    final first = srcset?.split(',').first.trim();
    if (first == null || first.isEmpty) return null;
    return first.split(RegExp(r'\s+')).first;
  }
}
