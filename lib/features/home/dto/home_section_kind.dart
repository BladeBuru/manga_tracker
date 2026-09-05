/// Nature d'une section de l'accueil catalogue (`kind` du contrat
/// `GET /mangas/home/sections`).
///
/// Le serveur ne renvoie **pas** de titre : c'est le client qui le deduit du
/// couple `kind` + `params` (cf. `home_section_l10n.dart`). Un `kind` inconnu
/// (ajoute cote API apres cette version de l'app) est ignore sans planter :
/// [HomeSectionKind.tryParse] renvoie `null` et la section est ecartee.
enum HomeSectionKind {
  /// Dernieres sorties du catalogue.
  latest('latest'),

  /// Ce qui marche le mieux (popularite).
  popular('popular'),

  /// Les mieux notes.
  topRated('top_rated'),

  /// Filtre par type d'oeuvre (`params.type` : Manga / Manhwa / Manhua…).
  type('type'),

  /// Filtre par genre (`params.genre` : Action / Romance…).
  genre('genre'),

  /// Sorties d'une annee donnee (`params.year`).
  year('year'),

  /// Le choix de la communaute Manga Tracker.
  community('community'),

  /// Pepites cachees : bien notees mais peu visibles.
  hiddenGems('hidden_gems');

  /// Valeur de fil, telle que renvoyee par l'API.
  final String wireValue;

  const HomeSectionKind(this.wireValue);

  /// `null` si la valeur n'est pas connue de cette version de l'app.
  static HomeSectionKind? tryParse(Object? raw) {
    if (raw is! String) return null;
    for (final kind in HomeSectionKind.values) {
      if (kind.wireValue == raw) return kind;
    }
    return null;
  }
}
