/// Stub web pour `ChapterDownloadDialog`.
///
/// Le téléchargement de chapitres n'est pas supporté sur web.
library;

import 'package:flutter/material.dart';

class ChapterDownloadDialog extends StatelessWidget {
  final int muId;
  final String mangaTitle;
  final String baseUrl;
  final int totalChapters;
  final int? readChapters;

  const ChapterDownloadDialog({
    super.key,
    required this.muId,
    required this.mangaTitle,
    required this.baseUrl,
    required this.totalChapters,
    this.readChapters,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Téléchargement non disponible'),
      content: const Text(
        'Le téléchargement de chapitres n\'est pas disponible sur le web. '
        'Utilisez l\'application mobile pour télécharger des chapitres en local.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
