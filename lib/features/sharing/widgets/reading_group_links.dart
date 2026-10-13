import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangatracker/core/router/app_modals.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Liens de lecture d'une « lecture à deux » : le sien, celui d'un ami, et
/// le chapitre à viser (le prochain à lire par l'utilisateur).
class ReadingGroupLinks {
  final ReadingGroupDto group;
  final int? currentUserId;

  const ReadingGroupLinks({required this.group, required this.currentUserId});

  /// Premier ami du groupe qui a un lien sur ce titre.
  ReadingGroupMemberDto? friendWithLink() {
    for (final m in group.members) {
      if (m.userId == currentUserId) continue;
      final link = m.customLink;
      if (link != null && link.isNotEmpty) return m;
    }
    return null;
  }

  ReadingGroupMemberDto? me() {
    if (currentUserId == null) return null;
    for (final m in group.members) {
      if (m.userId == currentUserId) return m;
    }
    return null;
  }

  /// L'utilisateur est identifié parmi les membres : sans ça, impossible de
  /// savoir quel chapitre viser.
  bool get isMeKnown => me() != null;

  /// Prochain chapitre à lire côté utilisateur (1 s'il n'a rien lu), `null`
  /// s'il n'est pas identifié — avant, ce cas visait le chapitre 1 en
  /// silence.
  int? targetChapter() {
    final mine = me();
    if (mine == null) return null;
    final read = mine.readChapters ?? 0;
    return read > 0 ? read + 1 : 1;
  }

  /// Lien de l'utilisateur, tel qu'enregistré.
  String? myLink() {
    final link = me()?.customLink;
    return link == null || link.isEmpty ? null : link;
  }

  bool get hasAnyLink => myLink() != null || friendWithLink() != null;

  /// Lien de l'ami adapté au prochain chapitre de l'utilisateur, `null` si
  /// son format n'est pas reconnu ou si l'utilisateur n'est pas identifié.
  Future<String?> adaptedFriendLink() async {
    final friend = friendWithLink();
    final target = targetChapter();
    if (friend?.customLink == null || target == null) return null;
    return _adapt(friend!.customLink!, target);
  }

  /// Lien à copier : le sien d'abord, sinon celui de l'ami adapté (ou brut
  /// si le format n'est pas reconnu — mieux vaut la page de l'ami que rien).
  Future<String?> linkToCopy() async => (await copyTarget())?.link;

  /// [linkToCopy] et s'il a été adapté au prochain chapitre de l'utilisateur
  /// (sinon le message ne doit pas annoncer « chapitre N »). `null` si
  /// l'utilisateur n'est pas identifié.
  ///
  /// Son propre lien est lui aussi recalé sur son prochain chapitre : après
  /// une mise à jour de la progression (fenêtre « Ma progression »), le lien
  /// enregistré pointe encore sur l'ancien chapitre.
  Future<({String link, bool adaptedToChapter})?> copyTarget() async {
    final target = targetChapter();
    if (target == null) return null;
    final mine = myLink();
    if (mine != null) {
      final adapted = await _adapt(mine, target);
      return adapted == null
          ? (link: mine, adaptedToChapter: false)
          : (link: adapted, adaptedToChapter: true);
    }
    final adapted = await adaptedFriendLink();
    if (adapted != null) return (link: adapted, adaptedToChapter: true);
    final raw = friendWithLink()?.customLink;
    return raw == null ? null : (link: raw, adaptedToChapter: false);
  }

  static Future<String?> _adapt(String link, int chapter) async {
    final adapted = await ChapterLinkResolver.buildUrlForChapter(link, chapter);
    return adapted == null || adapted.isEmpty ? null : adapted;
  }
}

/// Relit le groupe juste avant de calculer un lien (la progression affichée
/// peut dater du dernier rafraîchissement, 30 s plus tôt). Bref délai : sur
/// le web, le presse-papiers exige un geste récent.
Future<ReadingGroupLinks> _fresh(
  ReadingGroupLinks links,
  Future<ReadingGroupDto> Function()? refresh,
) async {
  if (refresh == null) return links;
  try {
    final group = await refresh().timeout(const Duration(seconds: 3));
    return ReadingGroupLinks(group: group, currentUserId: links.currentUserId);
  } catch (_) {
    return links;
  }
}

/// Copie le lien de lecture dans le presse-papiers. [refresh] relit le
/// groupe avant le calcul du chapitre visé.
Future<void> copyReadingGroupLink(
  BuildContext context,
  ReadingGroupLinks links, {
  Future<ReadingGroupDto> Function()? refresh,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;
  final current = await _fresh(links, refresh);
  final target = await current.copyTarget();
  if (target == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.readingGroupProgressUnknown)),
    );
    return;
  }
  try {
    await Clipboard.setData(ClipboardData(text: target.link));
  } catch (_) {
    // Presse-papiers refusé (navigateur sans geste récent, plateforme) : le
    // lien s'affiche pour une copie à la main au lieu d'échouer en silence.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.readingGroupCopyLinkClipboardFailed,
          style: TextStyle(color: scheme.onError),
        ),
        backgroundColor: scheme.error,
      ),
    );
    if (context.mounted) await _showLinkForManualCopy(context, target.link);
    return;
  }
  // « Chapitre N » seulement si le lien a vraiment été adapté : un lien brut
  // pointe encore sur le chapitre de l'ami.
  final chapter = current.targetChapter();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        target.adaptedToChapter && chapter != null
            ? l10n.readingGroupCopyLinkSuccess(chapter)
            : l10n.urlCopied,
      ),
    ),
  );
}

Future<void> _showLinkForManualCopy(BuildContext context, String link) {
  final l10n = AppLocalizations.of(context)!;
  return showAppDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(l10n.readingGroupCopyLinkManualTitle),
      content: SelectableText(link),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

/// Enregistre le lien de l'ami, adapté au prochain chapitre, comme lien de
/// l'utilisateur pour ce titre.
Future<void> applyReadingGroupFriendLink(
  BuildContext context,
  ReadingGroupLinks links,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final scheme = Theme.of(context).colorScheme;
  final muId = int.tryParse(links.group.mangaMuId);
  final target = links.targetChapter();
  if (muId == null || muId <= 0) return;
  if (target == null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.readingGroupProgressUnknown)),
    );
    return;
  }
  final adapted = await links.adaptedFriendLink();
  void fail() => messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.readingGroupCopyLinkFailed),
      backgroundColor: scheme.error,
    ),
  );
  if (adapted == null) {
    fail();
    return;
  }
  try {
    // Le retour était ignoré : un refus (titre absent de la bibliothèque)
    // affichait quand même « Lien enregistré ».
    final saved = await getIt<LibraryService>().updateCustomLink(muId, adapted);
    if (!saved) {
      fail();
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.readingGroupApplyLinkSuccess(target))),
    );
  } catch (_) {
    fail();
  }
}
