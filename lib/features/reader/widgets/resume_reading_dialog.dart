import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Modale de reprise inter-appareils : « Reprendre votre lecture ? ».
///
/// Ne s'affiche **que** quand la lecture en cours porte sur un chapitre
/// différent de celui que l'application allait ouvrir (`dernier lu + 1`) —
/// typiquement après avoir avancé sur une tablette. Reprendre le chapitre
/// attendu, lui, se fait en silence : voir `ReadingResumePolicy` pour
/// l'arbitrage complet.
///
/// Les deux issues sont explicites et chiffrées, pour qu'aucune ne soit un
/// saut dans le vide : reprendre le chapitre en cours, ou ouvrir celui qui
/// suit le dernier chapitre terminé.
///
/// Retourne `true` (reprendre), `false` (ouvrir le chapitre suivant) ou `null`
/// si la modale a été fermée sans répondre — traité comme un refus.
class ResumeReadingDialog extends StatelessWidget {
  const ResumeReadingDialog({
    super.key,
    required this.resumeChapter,
    required this.declinedChapter,
  });

  /// Chapitre en cours, sur lequel porte la reprise.
  final int resumeChapter;

  /// Chapitre ouvert si l'utilisateur refuse : `dernier lu + 1`.
  final int declinedChapter;

  static Future<bool?> show(
    BuildContext context, {
    required int resumeChapter,
    required int declinedChapter,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ResumeReadingDialog(
        resumeChapter: resumeChapter,
        declinedChapter: declinedChapter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: const Icon(
        Icons.bookmark_outline,
        color: AppColors.info,
        size: AppSpacing.jumbo,
      ),
      title: Text(l10n?.resumeReadingTitle ?? 'Reprendre votre lecture ?'),
      content: Text(
        l10n?.resumeReadingMessage(resumeChapter.toString()) ??
            'Une lecture est en cours au chapitre $resumeChapter. '
                'Voulez-vous la reprendre là où vous vous étiez arrêté ?',
        style: textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            l10n?.resumeReadingDecline(declinedChapter.toString()) ??
                'Ouvrir le chapitre $declinedChapter',
          ),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.play_arrow, size: AppSpacing.m),
          label: Text(
            l10n?.resumeReadingConfirm(resumeChapter.toString()) ??
                'Reprendre le chapitre $resumeChapter',
          ),
        ),
      ],
    );
  }
}
