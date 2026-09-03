/// Raison pour laquelle l'utilisateur écarte un titre de ses recommandations.
///
/// La raison est **obligatoire** côté API : c'est le seul signal négatif
/// explicite du produit. Elle distingue « déjà lu, j'ai aimé » (affinité
/// positive, mais plus rien à découvrir) de « pas intéressé » (vrai signal
/// négatif de goût) — deux informations qu'un simple bouton « masquer »
/// confondrait définitivement.
///
/// [wireValue] doit rester aligné sur l'enum `DismissalReason` de l'API
/// (`already_read` / `not_interested` / `seen_elsewhere`).
enum DismissalReason {
  /// Déjà lu, en papier ou en scan.
  alreadyRead('already_read'),

  /// Ne correspond pas aux goûts de l'utilisateur.
  notInterested('not_interested'),

  /// Connu par un autre média : animé, drama, film.
  ///
  /// C'est le cas d'usage fondateur de la fonctionnalité : « je les ai vus
  /// en animé et je n'ai pas forcément envie de les relire ». Cette
  /// information n'existe dans aucune source de données.
  seenElsewhere('seen_elsewhere');

  const DismissalReason(this.wireValue);

  /// Valeur envoyée à l'API dans le champ `reason`.
  final String wireValue;
}
