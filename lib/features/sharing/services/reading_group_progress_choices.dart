import 'package:equatable/equatable.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';

/// Raccourci « Me caler sur `membre` (ch. X) » de la fenêtre « Ma
/// progression ».
class ReadingGroupProgressTarget extends Equatable {
  final String name;
  final int chapter;

  const ReadingGroupProgressTarget({required this.name, required this.chapter});

  @override
  List<Object?> get props => [name, chapter];
}

/// Choix proposés dans la fenêtre « Ma progression ». **Pure** : ni Flutter,
/// ni réseau.
class ReadingGroupProgressChoices {
  const ReadingGroupProgressChoices._();

  /// Mon dernier chapitre terminé d'après le groupe, `null` si je n'y suis
  /// pas identifié (identifiant inconnu) — jamais un « 0 » ou un « 1 » par
  /// défaut, qui ferait croire à une progression perdue.
  static int? myChapters(ReadingGroupDto group, int? currentUserId) {
    if (currentUserId == null) return null;
    for (final m in group.members) {
      if (m.userId == currentUserId) return m.readChapters ?? 0;
    }
    return null;
  }

  /// Membres en avance sur [myChapters], du plus avancé au moins avancé.
  /// Je n'y figure jamais (exclu par identifiant, et de toute façon jamais
  /// « en avance » sur moi-même).
  static List<ReadingGroupProgressTarget> aheadOf(
    ReadingGroupDto group, {
    required int? currentUserId,
    required int myChapters,
  }) {
    final targets = <ReadingGroupProgressTarget>[
      for (final m in group.members)
        if (m.userId != currentUserId && (m.readChapters ?? 0) > myChapters)
          ReadingGroupProgressTarget(
            name: m.effectiveDisplayName,
            chapter: m.readChapters!,
          ),
    ];
    targets.sort((a, b) => b.chapter.compareTo(a.chapter));
    return targets;
  }
}
