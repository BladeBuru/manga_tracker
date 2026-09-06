import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Modale de fin de lecture : « Avez-vous fini le chapitre N ? ».
///
/// Extraite du lecteur pour deux raisons :
/// 1. elle est partagée par le lecteur en ligne et le lecteur hors ligne, qui
///    doivent poser exactement la même question (le lecteur hors ligne
///    enregistrait auparavant en silence) ;
/// 2. elle est testable sans WebView
///    (`test/features/reader/chapter_completion_dialog_test.dart`).
///
/// Retourne `true` (chapitre terminé), `false` (pas terminé) ou `null` si la
/// modale a été fermée sans répondre — les deux derniers n'enregistrent rien.
class ChapterCompletionDialog extends StatelessWidget {
  const ChapterCompletionDialog({super.key, required this.chapter});

  /// Numéro du chapitre en cours de lecture.
  final int chapter;

  /// Affiche la modale. `barrierDismissible: false` : la question doit
  /// recevoir une réponse explicite, pas être balayée par accident.
  static Future<bool?> show(BuildContext context, {required int chapter}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChapterCompletionDialog(chapter: chapter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: const Icon(
        Icons.check_circle_outline,
        color: AppColors.success,
        size: AppSpacing.jumbo,
      ),
      title: Text(l10n?.validateReading ?? 'Valider la lecture'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.validateReadingMessage(chapter.toString()) ??
                'Avez-vous fini le chapitre $chapter ?',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: AppSpacing.paddingAllM,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: AppRadius.circularMd,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: AppSpacing.l,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    l10n?.validateReadingHint ??
                        'Votre progression sera sauvegardée automatiquement.',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n?.no ?? 'Non'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check, size: AppSpacing.m),
          label: Text(l10n?.yesValidate ?? 'Oui, valider'),
        ),
      ],
    );
  }
}
