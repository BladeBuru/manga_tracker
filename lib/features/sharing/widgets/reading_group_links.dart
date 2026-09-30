import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Prochain chapitre à lire côté utilisateur (1 s'il n'a rien lu).
  int targetChapter() {
    final read = me()?.readChapters ?? 0;
    return read > 0 ? read + 1 : 1;
  }

  /// Lien de l'utilisateur, tel qu'enregistré (déjà sur son prochain
  /// chapitre : le lecteur le tient à jour).
  String? myLink() {
    final link = me()?.customLink;
    return link == null || link.isEmpty ? null : link;
  }

  bool get hasAnyLink => myLink() != null || friendWithLink() != null;

  /// Lien de l'ami adapté au prochain chapitre de l'utilisateur, `null` si
  /// son format n'est pas reconnu.
  Future<String?> adaptedFriendLink() async {
    final friend = friendWithLink();
    if (friend?.customLink == null) return null;
    final adapted = await ChapterLinkResolver.buildUrlForChapter(
      friend!.customLink!,
      targetChapter(),
    );
    return adapted == null || adapted.isEmpty ? null : adapted;
  }

  /// Lien à copier : le sien d'abord, sinon celui de l'ami adapté (ou brut
  /// si le format n'est pas reconnu — mieux vaut la page de l'ami que rien).
  Future<String?> linkToCopy() async => (await copyTarget())?.link;

  /// [linkToCopy] et s'il a été adapté au prochain chapitre de l'utilisateur
  /// (sinon le message ne doit pas annoncer « chapitre N »).
  Future<({String link, bool adaptedToChapter})?> copyTarget() async {
    final mine = myLink();
    if (mine != null) return (link: mine, adaptedToChapter: false);
    final adapted = await adaptedFriendLink();
    if (adapted != null) return (link: adapted, adaptedToChapter: true);
    final raw = friendWithLink()?.customLink;
    return raw == null ? null : (link: raw, adaptedToChapter: false);
  }
}

/// Copie le lien de lecture dans le presse-papiers.
Future<void> copyReadingGroupLink(
  BuildContext context,
  ReadingGroupLinks links,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final target = await links.copyTarget();
  if (target == null) return;
  await Clipboard.setData(ClipboardData(text: target.link));
  // « Chapitre N » seulement si le lien a vraiment été adapté : un lien brut
  // pointe encore sur le chapitre de l'ami.
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        target.adaptedToChapter
            ? l10n.readingGroupCopyLinkSuccess(links.targetChapter())
            : l10n.urlCopied,
      ),
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
  if (muId == null || muId <= 0) return;
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
      SnackBar(
        content: Text(l10n.readingGroupApplyLinkSuccess(links.targetChapter())),
      ),
    );
  } catch (_) {
    fail();
  }
}
