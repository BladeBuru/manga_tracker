import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Presentation d'une section d'accueil deduite de `kind` + `params` : le
/// serveur ne renvoie ni titre, ni icone (cf. contrat `/mangas/home/sections`).
///
/// Tout passe par les ARB : aucun texte en dur ici, le repli sur la valeur
/// brute (genre ou type inconnu, `kind` inconnu) est la seule exception,
/// assumee — mieux vaut « Novel » que rien.
class HomeSectionL10n {
  HomeSectionL10n._();

  /// Genres MangaUpdates les plus frequents → cle ARB. Comparaison
  /// insensible a la casse et aux tirets/espaces (`Sci-fi`, `Sci-Fi`,
  /// `Slice of Life`, `slice_of_life`…).
  static final Map<String, String Function(AppLocalizations)> _genres = {
    'romance': (l) => l.genreRomance,
    'drama': (l) => l.genreDrama,
    'fantasy': (l) => l.genreFantasy,
    'comedy': (l) => l.genreComedy,
    'sliceoflife': (l) => l.genreSliceOfLife,
    'action': (l) => l.genreAction,
    'schoollife': (l) => l.genreSchoolLife,
    'supernatural': (l) => l.genreSupernatural,
    'adventure': (l) => l.genreAdventure,
    'historical': (l) => l.genreHistorical,
    'mystery': (l) => l.genreMystery,
    'psychological': (l) => l.genrePsychological,
    'scifi': (l) => l.genreSciFi,
    'horror': (l) => l.genreHorror,
    'martialarts': (l) => l.genreMartialArts,
  };

  /// Genres couverts par une traduction (forme normalisee).
  static Iterable<String> get knownGenres => _genres.keys;

  static String _normalize(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

  /// Nom traduit d'un genre, ou le nom brut s'il n'est pas dans la table.
  static String genre(AppLocalizations l10n, String raw) {
    final resolve = _genres[_normalize(raw)];
    return resolve == null ? raw : resolve(l10n);
  }

  /// Nom traduit d'un type d'oeuvre (Manga / Manhwa / Manhua), sinon brut.
  static String mangaType(AppLocalizations l10n, String raw) {
    switch (_normalize(raw)) {
      case 'manga':
        return l10n.homeSectionTypeManga;
      case 'manhwa':
        return l10n.homeSectionTypeManhwa;
      case 'manhua':
        return l10n.homeSectionTypeManhua;
      default:
        return raw;
    }
  }

  /// Titre d'une section. [fallback] (l'identifiant brut) ne sert que si le
  /// `kind` est inconnu ou si le parametre attendu manque.
  static String title(
    AppLocalizations l10n, {
    required HomeSectionKind? kind,
    HomeSectionParams params = HomeSectionParams.none,
    required String fallback,
  }) {
    switch (kind) {
      case HomeSectionKind.latest:
        return l10n.homeSectionLatest;
      case HomeSectionKind.popular:
        return l10n.homeSectionPopular;
      case HomeSectionKind.topRated:
        return l10n.homeSectionTopRated;
      case HomeSectionKind.type:
        final type = params.type;
        return type == null ? fallback : mangaType(l10n, type);
      case HomeSectionKind.genre:
        final genreName = params.genre;
        return genreName == null
            ? fallback
            : l10n.homeSectionGenre(genre(l10n, genreName));
      case HomeSectionKind.year:
        final year = params.year;
        return year == null ? fallback : l10n.homeSectionYear(year.toString());
      case HomeSectionKind.community:
        return l10n.homeSectionCommunity;
      case HomeSectionKind.hiddenGems:
        return l10n.homeSectionHiddenGems;
      case null:
        return fallback;
    }
  }

  /// Titre d'une section deja parsee.
  static String titleOf(AppLocalizations l10n, HomeSectionDto section) => title(
        l10n,
        kind: section.kind,
        params: section.params,
        fallback: section.id,
      );

  /// Icone Material (outlined) par nature de section.
  static IconData icon(HomeSectionKind? kind) {
    switch (kind) {
      case HomeSectionKind.latest:
        return Icons.new_releases_outlined;
      case HomeSectionKind.popular:
        return Icons.local_fire_department_outlined;
      case HomeSectionKind.topRated:
        return Icons.workspace_premium_outlined;
      case HomeSectionKind.type:
        return Icons.menu_book_outlined;
      case HomeSectionKind.genre:
        return Icons.interests_outlined;
      case HomeSectionKind.year:
        return Icons.calendar_month_outlined;
      case HomeSectionKind.community:
        return Icons.groups_outlined;
      case HomeSectionKind.hiddenGems:
        return Icons.diamond_outlined;
      case null:
        return Icons.auto_stories_outlined;
    }
  }

  /// Couleur pastel du tile d'en-tete (design system V1).
  static PastelTileColor tileColor(HomeSectionKind? kind) {
    switch (kind) {
      case HomeSectionKind.latest:
        return PastelTileColor.blue;
      case HomeSectionKind.popular:
        return PastelTileColor.red;
      case HomeSectionKind.topRated:
        return PastelTileColor.yellow;
      case HomeSectionKind.type:
        return PastelTileColor.teal;
      case HomeSectionKind.genre:
        return PastelTileColor.purple;
      case HomeSectionKind.year:
        return PastelTileColor.green;
      case HomeSectionKind.community:
        return PastelTileColor.pink;
      case HomeSectionKind.hiddenGems:
        return PastelTileColor.yellow;
      case null:
        return PastelTileColor.blue;
    }
  }
}
