/// Sélection de chapitres à télécharger, par intervalle — pur, sans Flutter.
///
/// Avec des centaines de chapitres, cocher un par un n'est pas praticable :
/// on coche le 125, on descend, on coche le 145, et l'intervalle se remplit
/// (bouton, appui long ou glisser le doigt).
class ChapterRangeSelection {
  const ChapterRangeSelection._();

  /// Chapitres de [from] à [to] inclus, dans un sens comme dans l'autre,
  /// sans ceux de [excluded] (déjà téléchargés : rien à refaire).
  static Set<int> range(int from, int to, {Set<int> excluded = const {}}) {
    final low = from < to ? from : to;
    final high = from < to ? to : from;
    return {
      for (var chapter = low; chapter <= high; chapter++)
        if (!excluded.contains(chapter)) chapter,
    };
  }

  /// Intervalle que propose le bouton « Sélectionner tout l'intervalle » :
  /// entre les deux derniers chapitres cochés ([anchors], du plus ancien au
  /// plus récent), s'il reste entre eux au moins un chapitre à cocher.
  /// `null` sinon (pas de bouton).
  static ({int from, int to})? pendingInterval({
    required List<int> anchors,
    required Set<int> selected,
    Set<int> excluded = const {},
  }) {
    final live = anchors.where(selected.contains).toList();
    if (live.length < 2) return null;
    final a = live[live.length - 2];
    final b = live.last;
    final from = a < b ? a : b;
    final to = a < b ? b : a;
    final missing = range(from, to, excluded: excluded).difference(selected);
    return missing.isEmpty ? null : (from: from, to: to);
  }

  /// Retient les deux derniers chapitres cochés (le plus récent en dernier).
  static List<int> pushAnchor(List<int> anchors, int chapter) {
    final next = [...anchors.where((a) => a != chapter), chapter];
    return next.length <= 2 ? next : next.sublist(next.length - 2);
  }

  /// Chapitre (1 à [itemCount]) sous le doigt, dans une liste de lignes de
  /// hauteur fixe [itemExtent] défilée de [scrollOffset].
  static int chapterAt({
    required double dy,
    required double scrollOffset,
    required double itemExtent,
    required int itemCount,
  }) {
    if (itemCount <= 0) return 1;
    final index = ((dy + scrollOffset) / itemExtent).floor();
    return index.clamp(0, itemCount - 1) + 1;
  }

  /// Chapitre montré en haut à l'ouverture : le premier NON LU (plus besoin
  /// de descendre depuis le chapitre 1 quand on en a lu 200).
  static int firstUnread({required int? readChapters, required int total}) {
    if (total <= 0) return 1;
    return ((readChapters ?? 0) + 1).clamp(1, total);
  }
}
