import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mangatracker/core/components/pastel_tile.dart';
import 'package:mangatracker/core/router/app_router.dart' show MangaDetailExtras;
import 'package:mangatracker/core/router/navigation_helpers.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/sharing/bloc/reading_groups_bloc.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/services/reading_group_progress_choices.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_action_row.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_progress_dialog.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// « Marquer ma progression » : ouvre la fenêtre « Ma progression », puis
/// confie l'enregistrement au [ReadingGroupDetailBloc] (qui relit le groupe
/// et affiche l'issue). Avant, la ligne ouvrait seulement la fiche du manga.
class ReadingGroupUpdateProgressRow extends StatelessWidget {
  final ReadingGroupDto group;
  final int? currentUserId;
  final bool isSaving;

  const ReadingGroupUpdateProgressRow({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.isSaving,
  });

  int? get _muId {
    final muId = int.tryParse(group.mangaMuId);
    return muId == null || muId <= 0 ? null : muId;
  }

  Future<void> _open(BuildContext context) async {
    final bloc = context.read<ReadingGroupDetailBloc>();
    final mine = ReadingGroupProgressChoices.myChapters(group, currentUserId) ??
        await _fromLibrary();
    if (!context.mounted) return;
    final chosen = await ReadingGroupProgressDialog.show(
      context,
      initialChapters: mine,
      targets: ReadingGroupProgressChoices.aheadOf(
        group,
        currentUserId: currentUserId,
        myChapters: mine,
      ),
    );
    if (chosen == null || bloc.isClosed) return;
    bloc.add(UpdateMyGroupProgress(chosen));
  }

  /// Identifiant inconnu (profil non chargé) : la bibliothèque dit où j'en
  /// suis — jamais un pré-remplissage à 0 qui ferait croire à une perte.
  Future<int> _fromLibrary() async {
    try {
      final entry = await getIt<LibraryService>().getLibraryEntry(_muId!);
      return entry?.readChapters?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mine = ReadingGroupProgressChoices.myChapters(group, currentUserId);
    final String subtitle;
    if (isSaving) {
      subtitle = l10n.readingGroupProgressSaving;
    } else if (mine != null && mine > 0) {
      subtitle = l10n.readingGroupMyProgressSubtitle(mine);
    } else {
      subtitle = l10n.readingGroupMyProgressEmpty;
    }
    return ReadingGroupActionRow(
      icon: Icons.bookmark_outline,
      color: PastelTileColor.green,
      title: l10n.readingGroupActionsMarkProgress,
      subtitle: subtitle,
      onTap: _muId == null || isSaving ? null : () => _open(context),
    );
  }
}

/// « Ouvrir le manga » — revient à la fiche si elle est juste en dessous
/// (`pushOrPop`), au lieu d'empiler une copie à chaque aller-retour.
class ReadingGroupOpenMangaRow extends StatelessWidget {
  final ReadingGroupDto group;

  const ReadingGroupOpenMangaRow({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muId = int.tryParse(group.mangaMuId);
    final canOpen = muId != null && muId > 0;
    return ReadingGroupActionRow(
      icon: Icons.menu_book_outlined,
      color: PastelTileColor.yellow,
      title: l10n.readingGroupOpenManga,
      subtitle: l10n.readingGroupOpenMangaSubtitle,
      onTap: canOpen
          ? () => pushOrPop<void>(
                context,
                '/manga/$muId',
                extra: MangaDetailExtras(title: group.mangaTitle),
              )
          : null,
    );
  }
}
