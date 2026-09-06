/// Position de lecture en cours d'un manga — le « marque-page » synchronisé.
///
/// Contrat serveur (`GET /library/:muId/reading-position`, 200) :
/// ```json
/// { "chapter": 42, "positionPercent": 37.5, "updatedAt": "2026-09-06T10:00:00.000Z" }
/// ```
/// Un `204` sans corps signifie « aucune position en cours » — le service rend
/// alors `null`, jamais un DTO vide.
///
/// Le serveur remet ces champs à `null` de lui-même quand le chapitre en cours
/// devient terminé : le client ne réimplémente pas cette règle, il se contente
/// de ne plus rien envoyer pour un chapitre validé.
class ReadingPositionDto {
  const ReadingPositionDto({
    required this.chapter,
    required this.positionPercent,
    this.updatedAt,
  });

  /// Chapitre en cours de lecture (jamais un chapitre déjà terminé).
  final int chapter;

  /// Progression dans le chapitre, 0..100 — voir `ReadingPositionCalculator`
  /// pour l'échelle exacte.
  final double positionPercent;

  /// Horodatage serveur, seul juge quand la position locale et la position
  /// distante divergent. `null` pour une position locale héritée d'une
  /// version antérieure à cette fonctionnalité, qui perd donc l'arbitrage.
  final DateTime? updatedAt;

  factory ReadingPositionDto.fromJson(Map<String, dynamic> json) {
    return ReadingPositionDto(
      chapter: (json['chapter'] as num).toInt(),
      positionPercent: (json['positionPercent'] as num).toDouble(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'positionPercent': positionPercent,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  @override
  bool operator ==(Object other) =>
      other is ReadingPositionDto &&
      other.chapter == chapter &&
      other.positionPercent == positionPercent &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(chapter, positionPercent, updatedAt);

  @override
  String toString() => 'ReadingPositionDto(chapitre: $chapter, '
      'position: $positionPercent%, maj: $updatedAt)';
}
