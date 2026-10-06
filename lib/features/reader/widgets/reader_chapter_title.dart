import 'package:flutter/material.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Titre du lecteur hors ligne : « Chapitre N » d'abord, l'œuvre en dessous.
///
/// En une seule ligne « titre - Chapitre N », un titre long faisait
/// disparaître le numéro de chapitre derrière « … » sur petit écran.
class ReaderChapterTitle extends StatelessWidget {
  final String mangaTitle;
  final Object chapterNumber;

  const ReaderChapterTitle({
    super.key,
    required this.mangaTitle,
    required this.chapterNumber,
  });

  @override
  Widget build(BuildContext context) {
    final chapter = AppLocalizations.of(context)?.chapter ?? 'Chapitre';
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$chapter $chapterNumber',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium,
        ),
        if (mangaTitle.trim().isNotEmpty)
          Text(
            mangaTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
