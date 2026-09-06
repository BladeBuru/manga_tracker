import 'package:flutter/widgets.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/reader/services/reading_resume_policy.dart';
import 'package:mangatracker/features/reader/services/reading_resume_service.dart';
import 'package:mangatracker/features/reader/widgets/resume_reading_dialog.dart';

/// Chapitre à ouvrir et position à y restaurer.
class ReadingResumeTarget {
  const ReadingResumeTarget({required this.chapter, this.positionPercent});

  final int chapter;

  /// `null` = ouvrir le chapitre en haut de page.
  final double? positionPercent;
}

/// Décide ce que doit ouvrir « Lire en ligne », en posant la question à
/// l'utilisateur quand la décision ne va pas de soi.
///
/// Sert de trait d'union entre `ReadingResumePolicy` (pure, qui décide) et la
/// vue de détail (qui navigue) : celle-ci n'a ainsi qu'un appel à faire, et
/// aucune règle de reprise ne fuit dans un fichier de 1 300 lignes.
///
/// Ne lève jamais : le pire scénario reste l'ancien comportement, ouvrir
/// `dernier lu + 1` en haut de page.
Future<ReadingResumeTarget> resolveReadingResume(
  BuildContext context, {
  required int muId,
  required int lastRead,
}) async {
  final fallback = ReadingResumeTarget(chapter: lastRead + 1);
  try {
    final decision = await getIt<ReadingResumeService>().resolve(
      muId: muId,
      lastReadChapter: lastRead,
    );

    switch (decision.mode) {
      case ReadingResumeMode.fromStart:
        return ReadingResumeTarget(chapter: decision.chapter);

      case ReadingResumeMode.resumeSilently:
        // Chapitre attendu, simplement pas au tout début : aucune surprise,
        // donc aucune question.
        return ReadingResumeTarget(
          chapter: decision.chapter,
          positionPercent: decision.positionPercent,
        );

      case ReadingResumeMode.askUser:
        // La lecture en cours porte sur un AUTRE chapitre : les deux issues
        // ont un coût, c'est à l'utilisateur de trancher.
        if (!context.mounted) return fallback;
        final resume = await ResumeReadingDialog.show(
          context,
          resumeChapter: decision.chapter,
          declinedChapter: decision.declinedChapter,
        );
        if (resume != true) {
          return ReadingResumeTarget(chapter: decision.declinedChapter);
        }
        return ReadingResumeTarget(
          chapter: decision.chapter,
          positionPercent: decision.positionPercent,
        );
    }
  } catch (e) {
    debugPrint('resolveReadingResume: reprise indisponible ($e)');
    return fallback;
  }
}
