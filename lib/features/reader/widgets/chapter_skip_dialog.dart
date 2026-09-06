import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Modale de saut de chapitres : « Vous passez du chapitre {prev} au {next}.
/// Marquer {prev} comme lu ? ».
///
/// INVARIANT : la question porte sur [previousChapter] — le chapitre QUITTÉ —
/// et un « oui » n'enregistre que celui-là. Le code enregistrait autrefois
/// `next - 1`, si bien que sauter du 134 au 140 et répondre « oui »
/// enregistrait 139 chapitres lus.
class ChapterSkipDialog extends StatelessWidget {
  const ChapterSkipDialog({
    super.key,
    required this.previousChapter,
    required this.nextChapter,
  });

  /// Chapitre que l'utilisateur vient de quitter — le seul concerné par la
  /// question.
  final int previousChapter;

  /// Chapitre d'arrivée — jamais enregistré, il vient d'être ouvert.
  final int nextChapter;

  /// Affiche la modale et retourne `true` si l'utilisateur confirme.
  static Future<bool?> show(
    BuildContext context, {
    required int previousChapter,
    required int nextChapter,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChapterSkipDialog(
        previousChapter: previousChapter,
        nextChapter: nextChapter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      icon: const Icon(
        Icons.skip_next,
        color: AppColors.warning,
        size: AppSpacing.jumbo,
      ),
      title: Text(l10n?.chapterSkip ?? 'Saut de chapitres'),
      content: Text(
        l10n?.chapterSkipMessage(
              previousChapter.toString(),
              nextChapter.toString(),
            ) ??
            'Vous passez du chapitre $previousChapter au $nextChapter.\n'
                'Marquer $previousChapter comme lu ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.no ?? 'Non'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n?.yes ?? 'Oui'),
        ),
      ],
    );
  }
}
