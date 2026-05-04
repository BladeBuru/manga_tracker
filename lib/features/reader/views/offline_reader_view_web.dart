/// Stub web pour `OfflineReaderView`.
///
/// Le lecteur hors-ligne n'est pas disponible sur web (pas de cache FS).
/// Affiche un Scaffold qui informe l'utilisateur. Les call sites doivent
/// guarder avec `kIsWeb` pour éviter de naviguer ici sur web.
library;

import 'package:flutter/material.dart';

class OfflineReaderView extends StatelessWidget {
  final int muId;
  final int chapterNumber;
  final String mangaTitle;

  const OfflineReaderView({
    super.key,
    required this.muId,
    required this.chapterNumber,
    required this.mangaTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mangaTitle)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64),
              SizedBox(height: 16),
              Text(
                'Lecture hors-ligne non disponible sur le web',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
