import 'package:mangatracker/features/reader/dto/reading_position.dto.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';
import 'package:mangatracker/features/reader/utils/reading_position_calculator.dart';

/// Décide **quel chapitre ouvrir et à quelle position** quand l'utilisateur
/// appuie sur « Lire en ligne » — **classe pure** (ni Flutter, ni GetIt, ni
/// réseau), sur le modèle de `ChapterCommitPolicy`. La vue exécute, elle ne
/// décide pas.
///
/// ## Deux principes qui se contredisent, et l'arbitrage retenu
///
/// 1. **Ne jamais faire perdre à l'utilisateur ce qu'il a lu.** S'il s'est
///    arrêté au milieu du chapitre 42 sur sa tablette, rouvrir le 42 en haut
///    sur son téléphone lui refait relire la moitié d'un chapitre.
/// 2. **Ne jamais lui faire relire — ni sauter — sans le vouloir.** Ouvrir
///    d'autorité un chapitre plus avancé que sa progression locale peut lui
///    faire manquer des chapitres.
///
/// L'arbitrage est donc **la surprise, pas la position** :
///
/// - Si la position en cours porte sur le chapitre que l'application allait de
///   toute façon ouvrir (`dernier lu + 1`), la reprise est **silencieuse**.
///   Rien de surprenant : c'est le chapitre attendu, simplement pas au tout
///   début. Demander à chaque ouverture serait une modale de plus, pour
///   confirmer ce que l'utilisateur vient déjà de demander — et le défilement
///   vers le haut reste toujours possible.
/// - Si elle porte sur un chapitre **différent** (typiquement : on a avancé
///   sur un autre appareil), l'application **demande**. Les deux issues
///   possibles ont un coût — sauter des chapitres, ou perdre l'avancée de
///   l'autre appareil — et aucune n'est devinable : c'est précisément le cas
///   où une question vaut mieux qu'un pari.
///
/// ## Garde-fou de sémantique
///
/// Un chapitre **déjà enregistré comme terminé** n'est jamais rouvert au
/// milieu : la garde `chapitre > dernier lu` s'ajoute à la suppression de la
/// position au moment de la validation. Deux verrous valent mieux qu'un, et
/// celui-ci est pur, donc vérifiable sans WebView.
class ReadingResumePolicy {
  const ReadingResumePolicy({
    this.minPercent = ReadingPositionCalculator.minResumablePercent,
    this.maxPercent = kReadingEndThresholdPercent,
  });

  /// En deçà, l'utilisateur n'a fait qu'effleurer le chapitre : l'ouvrir en
  /// haut ne lui coûte rien.
  final num minPercent;

  /// Au-delà, il est en zone « fin de chapitre » : le reprendre à 97 % le
  /// poserait devant les commentaires, pas devant sa lecture. Il vaut mieux
  /// rouvrir le chapitre en haut (et la question de fin de chapitre a de toute
  /// façon déjà été posée à la sortie).
  final num maxPercent;

  /// [lastReadChapter] : dernier chapitre TERMINÉ, tel que l'entend
  /// `ChapterCommitPolicy`.
  /// [local] : position mémorisée sur cet appareil. [remote] : position
  /// renvoyée par le serveur. L'une comme l'autre peut être absente.
  ReadingResumeDecision decide({
    required int lastReadChapter,
    ReadingPositionDto? local,
    ReadingPositionDto? remote,
  }) {
    final defaultChapter = lastReadChapter + 1;

    final candidates = <ReadingPositionDto>[
      for (final candidate in [local, remote])
        if (candidate != null && _isResumable(candidate, lastReadChapter))
          candidate,
    ];

    if (candidates.isEmpty) {
      return ReadingResumeDecision._(
        mode: ReadingResumeMode.fromStart,
        chapter: defaultChapter,
      );
    }

    final winner = candidates.reduce(_mostRecent);

    return ReadingResumeDecision._(
      mode: winner.chapter == defaultChapter
          ? ReadingResumeMode.resumeSilently
          : ReadingResumeMode.askUser,
      chapter: winner.chapter,
      positionPercent: winner.positionPercent,
      fallbackChapter: defaultChapter,
    );
  }

  bool _isResumable(ReadingPositionDto candidate, int lastReadChapter) {
    // Un chapitre déjà terminé ne se rouvre pas au milieu.
    if (candidate.chapter <= lastReadChapter) return false;
    final percent = candidate.positionPercent;
    if (!percent.isFinite) return false;
    return percent >= minPercent && percent < maxPercent;
  }

  /// Le plus récent des deux. Une position **sans** horodatage (héritée d'une
  /// version antérieure à cette fonctionnalité) perd systématiquement
  /// l'arbitrage : on ne sait pas si elle date d'une minute ou d'un mois.
  ///
  /// À horodatage égal, le **second** candidat l'emporte. Les candidats sont
  /// réduits dans l'ordre `[local, serveur]` : c'est donc le serveur qui
  /// tranche, la vue partagée par tous les appareils. Si aucun des deux n'est
  /// horodaté, c'est le local qui reste — au moins il a été mesuré ici.
  static ReadingPositionDto _mostRecent(
    ReadingPositionDto a,
    ReadingPositionDto b,
  ) {
    final dateA = a.updatedAt;
    final dateB = b.updatedAt;
    if (dateA == null && dateB == null) return a;
    if (dateA == null) return b;
    if (dateB == null) return a;
    return dateA.isAfter(dateB) ? a : b;
  }
}

/// Ce que le lecteur doit ouvrir.
enum ReadingResumeMode {
  /// Aucune position exploitable : ouvrir `dernier lu + 1` en haut de page.
  fromStart,

  /// Reprendre le chapitre attendu à la position mémorisée, sans rien
  /// demander.
  resumeSilently,

  /// Une lecture est en cours sur un **autre** chapitre : demander avant de
  /// s'y rendre.
  askUser,
}

/// Résultat de [ReadingResumePolicy.decide].
class ReadingResumeDecision {
  const ReadingResumeDecision._({
    required this.mode,
    required this.chapter,
    this.positionPercent,
    int? fallbackChapter,
  }) : _fallbackChapter = fallbackChapter;

  /// Ce qu'il faut faire.
  final ReadingResumeMode mode;

  /// Chapitre proposé par la décision.
  final int chapter;

  /// Position à restaurer dans ce chapitre, `null` si on l'ouvre en haut.
  final double? positionPercent;

  final int? _fallbackChapter;

  /// Chapitre à ouvrir si l'utilisateur **refuse** la reprise proposée :
  /// `dernier lu + 1`, exactement le comportement d'avant cette
  /// fonctionnalité.
  int get declinedChapter => _fallbackChapter ?? chapter;

  /// `true` si l'application doit poser la question avant d'ouvrir.
  bool get needsConfirmation => mode == ReadingResumeMode.askUser;

  @override
  bool operator ==(Object other) =>
      other is ReadingResumeDecision &&
      other.mode == mode &&
      other.chapter == chapter &&
      other.positionPercent == positionPercent &&
      other.declinedChapter == declinedChapter;

  @override
  int get hashCode =>
      Object.hash(mode, chapter, positionPercent, declinedChapter);

  @override
  String toString() => 'ReadingResumeDecision(${mode.name}, '
      'chapitre: $chapter, position: $positionPercent)';
}
