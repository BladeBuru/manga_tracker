/// Issue du téléchargement d'un chapitre par le lecteur.
enum ReaderDownloadOutcome {
  success,
  failure,

  /// L'utilisateur a quitté le lecteur : la série s'arrête.
  cancelled,
}

/// Suivi d'une série de téléchargements de chapitres — pur.
class DownloadBatch {
  DownloadBatch(Iterable<int> chapters)
      : chapters = List.unmodifiable(chapters.toList()..sort());

  /// Chapitres demandés, dans l'ordre.
  final List<int> chapters;

  final List<int> done = [];
  final List<int> failed = [];
  bool _cancelled = false;

  bool get cancelled => _cancelled;
  int get processed => done.length + failed.length;

  /// Avancement (0 à 1).
  double get fraction => chapters.isEmpty ? 1 : processed / chapters.length;

  void recordSuccess(int chapter) => done.add(chapter);
  void recordFailure(int chapter) => failed.add(chapter);
  void cancel() => _cancelled = true;

  /// Issue d'un passage par le lecteur, à partir de ce qu'il a rendu.
  ///
  /// [popResult] : valeur de fermeture du lecteur (`true`/`false` quand il
  /// se ferme lui-même au terme du téléchargement, `null` quand
  /// l'utilisateur le quitte). [reported] : valeur du rappel, s'il a été
  /// appelé. Un lecteur quitté sans aucun résultat est une ANNULATION :
  /// l'ancien code attendait alors 5 minutes, puis enchaînait sur le
  /// chapitre suivant.
  static ReaderDownloadOutcome outcomeOf({
    required bool? popResult,
    required bool? reported,
  }) {
    final result = popResult ?? reported;
    if (result == null) return ReaderDownloadOutcome.cancelled;
    return result ? ReaderDownloadOutcome.success : ReaderDownloadOutcome.failure;
  }
}
