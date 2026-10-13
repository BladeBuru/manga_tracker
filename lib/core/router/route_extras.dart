/// Données passées avec une navigation (`extra:` de go_router).
///
/// Elles ne servent qu'à **pré-remplir** l'écran : chaque page doit rester
/// reconstructible depuis son URL seule (F5, lien partagé, retour du
/// navigateur), où ces données sont absentes. Celles qui sont sérialisables
/// survivent à l'historique du navigateur grâce à `RouteExtrasCodec`.
library;

import 'package:mangatracker/features/home/dto/home_section.dto.dart';
import 'package:mangatracker/features/home/dto/home_section_kind.dart';

/// Extras passés via `context.push('/manga/:muId', extra: ...)` — purement
/// pour pré-remplir l'UI avant que le BLoC charge les vraies données.
class MangaDetailExtras {
  final String? title;
  final String? coverPath;
  const MangaDetailExtras({this.title, this.coverPath});
}

/// Extras passés via `context.push('/home/section/:id', extra: ...)` —
/// titre + icône affichés immédiatement, avant la réponse de l'API (sur
/// F5 web sans extras, la page les déduit de la réponse elle-même).
class HomeSectionExtras {
  final HomeSectionKind kind;
  final HomeSectionParams params;
  const HomeSectionExtras({
    required this.kind,
    this.params = HomeSectionParams.none,
  });
}

/// Extras passés via `context.push('/authors/:authorId', extra: ...)` — le
/// nom s'affiche dans la barre avant la réponse de l'API.
class AuthorPageExtras {
  final String name;
  const AuthorPageExtras({required this.name});
}

/// Extras passés via `context.push('/friends/:userId', extra: ...)` —
/// affichage immédiat du header (nom + avatar) pendant le fetch. Sans eux
/// (lien direct), la page retrouve le nom dans la liste d'amis.
class FriendProfileExtras {
  final String displayName;
  final String? avatarUrl;
  const FriendProfileExtras({required this.displayName, this.avatarUrl});
}

/// Extras passés via `context.push('/manga/:muId/read', extra: ...)`.
///
/// Non sérialisable (rappel [onDownloadComplete]) : sans eux, la route
/// retombe sur la fiche du titre.
class ReaderWebExtras {
  final String? mangaTitle;
  final int initialLastRead;
  final String initialUrl;
  final String baseUserLink;
  final bool autoDownload;
  final void Function(bool)? onDownloadComplete;

  /// Position (0..100) a laquelle reprendre le chapitre ouvert, quand elle
  /// vient du serveur ou d'un autre appareil. `null` = ouvrir en haut de page.
  /// Ignoree si cet appareil a deja une position en pixels pour ce chapitre,
  /// forcement plus fidele.
  final double? initialPositionPercent;

  /// Mode « recherche de lien » : le lecteur s'ouvre sur le site d'une
  /// autre lecture pour y trouver ce titre ; il n'enregistre rien tant que
  /// l'utilisateur n'a pas choisi « Ceci est le nouveau lien ».
  final bool linkDiscovery;

  const ReaderWebExtras({
    this.mangaTitle,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
    this.autoDownload = false,
    this.onDownloadComplete,
    this.initialPositionPercent,
    this.linkDiscovery = false,
  });
}

/// Extras passés via `context.push('/manga/:muId/read-offline', extra: ...)`.
class OfflineReaderExtras {
  final String mangaTitle;
  const OfflineReaderExtras({required this.mangaTitle});
}
