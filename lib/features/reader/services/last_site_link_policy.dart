import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';

/// Lien d'une lecture récente, proposé pour trouver un titre qui n'a pas
/// encore de lien sur la même plateforme de lecture.
class LastSiteLink {
  /// Titre de l'œuvre dont vient le lien.
  final String sourceTitle;

  /// Lien personnel de cette œuvre (tel qu'enregistré).
  final String link;

  /// Accueil du site (`https://hote/`) : c'est là qu'on cherche un titre.
  final String siteRoot;

  /// Nom d'hôte affiché (`www.` retiré).
  final String host;

  const LastSiteLink({
    required this.sourceTitle,
    required this.link,
    required this.siteRoot,
    required this.host,
  });
}

/// Choisit « le dernier manga lu qui a un lien » — **pure** (ni Flutter, ni
/// GetIt, ni réseau).
///
/// Ordre de préférence : la position de lecture la plus récente
/// (`currentPositionUpdatedAt`, écrite par le lecteur), puis l'ordre de la
/// bibliothèque tel que renvoyé par l'API (dernière activité d'abord). Le
/// titre en cours ([excludeMuId]) et les liens qui ne sont pas des adresses
/// web complètes sont ignorés.
class LastSiteLinkPolicy {
  const LastSiteLinkPolicy();

  LastSiteLink? pick(List<MangaQuickViewDto> library, {num? excludeMuId}) {
    MangaQuickViewDto? best;
    Uri? bestUri;
    DateTime? bestAt;
    for (final manga in library) {
      if (excludeMuId != null && manga.muId == excludeMuId) continue;
      final uri = _webUri(manga.customLink);
      if (uri == null) continue;
      final at = manga.currentPositionUpdatedAt;
      final better =
          best == null ||
          (at != null && (bestAt == null || at.isAfter(bestAt)));
      if (better) {
        best = manga;
        bestUri = uri;
        bestAt = at;
      }
    }
    if (best == null || bestUri == null) return null;
    return LastSiteLink(
      sourceTitle: best.title,
      link: best.customLink!.trim(),
      siteRoot:
          '${bestUri.scheme}://${bestUri.host}'
          '${bestUri.hasPort ? ':${bestUri.port}' : ''}/',
      host: bestUri.host.replaceFirst(RegExp(r'^www\.'), ''),
    );
  }

  static Uri? _webUri(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }
}
