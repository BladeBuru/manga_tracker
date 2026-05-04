/// Stub web pour `ReaderWebView`.
///
/// Sur web, on ne peut pas embarquer un webview vers un site tiers (CSP +
/// X-Frame-Options). On propose à l'utilisateur d'ouvrir le lien dans un
/// nouvel onglet via `url_launcher`. Les call sites doivent idéalement
/// guarder avec `kIsWeb` et appeler directement `launchUrl()`.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReaderWebView extends StatelessWidget {
  final int muId;
  final String? mangaTitle;
  final int initialLastRead;
  final String initialUrl;
  final String baseUserLink;
  final bool autoDownload;
  final Function(bool)? onDownloadComplete;

  const ReaderWebView({
    super.key,
    required this.muId,
    this.mangaTitle,
    required this.initialLastRead,
    required this.initialUrl,
    required this.baseUserLink,
    this.autoDownload = false,
    this.onDownloadComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mangaTitle ?? 'Lecture')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_new, size: 64),
              const SizedBox(height: 16),
              const Text(
                'La lecture intégrée n\'est pas disponible sur le web.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(initialUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.launch),
                label: const Text('Ouvrir le chapitre'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
