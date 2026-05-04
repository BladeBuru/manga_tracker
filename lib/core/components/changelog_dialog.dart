import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/app_update_service.dart';
import '../services/translation_service.dart';
import '../services/language_service.dart';
import '../service_locator/service_locator.dart';

/// Widget réutilisable pour afficher les changelogs avec traduction automatique
class ChangelogDialog extends StatefulWidget {
  final ChangelogInfo changelogInfo;
  final bool barrierDismissible;
  final VoidCallback? onClose;

  const ChangelogDialog({
    super.key,
    required this.changelogInfo,
    this.barrierDismissible = false,
    this.onClose,
  });

  /// Méthode statique pour afficher facilement la dialog
  static Future<void> show(
    BuildContext context,
    ChangelogInfo changelogInfo, {
    bool barrierDismissible = false,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => ChangelogDialog(
        changelogInfo: changelogInfo,
        barrierDismissible: barrierDismissible,
        onClose: onClose,
      ),
    );
  }

  @override
  State<ChangelogDialog> createState() => _ChangelogDialogState();
}

class _ChangelogDialogState extends State<ChangelogDialog> {
  ChangelogInfo? _translatedChangelogInfo;
  bool _translationStarted = false;
  final TranslationService _translationService = getIt<TranslationService>();

  @override
  void initState() {
    super.initState();
    // Initialiser avec les changelogs originaux pour affichage immédiat
    _translatedChangelogInfo = widget.changelogInfo;
    _startTranslation();
  }

  Future<void> _startTranslation() async {
    if (_translationStarted) return;
    _translationStarted = true;

    try {
      // Obtenir la langue actuelle
      final languageService = await getIt.getAsync<LanguageService>();
      final currentLocale = languageService.getCurrentLocale();
      final targetLanguage = currentLocale.languageCode;

      // Ne traduire que si la langue n'est pas le français
      if (targetLanguage != 'fr') {
        _translateChangelogs(widget.changelogInfo, targetLanguage);
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }
  
  /// Traduit les changelogs et met à jour progressivement
  Future<void> _translateChangelogs(
    ChangelogInfo changelogInfo,
    String targetLanguage,
  ) async {
    try {
      // Créer une copie des changelogs originaux pour les modifier progressivement
      final translatedVersions = changelogInfo.newVersions.map((vc) {
        return VersionChanges(
          version: vc.version,
          notes: vc.notes.map((note) {
            if (note is String) return note;
            if (note is List) return note.map((e) => e.toString()).join('\n');
            return note.toString();
          }).toList(),
        );
      }).toList();
      
      // Mettre à jour immédiatement avec les originaux
      if (mounted) {
        setState(() {
          _translatedChangelogInfo = ChangelogInfo(translatedVersions);
        });
      }
      
      // Traduire chaque version progressivement
      for (int v = 0; v < changelogInfo.newVersions.length; v++) {
        final versionChanges = changelogInfo.newVersions[v];
        
        // Vérifier si toutes les notes de cette version sont déjà en cache
        bool allNotesCached = true;
        final cachedNotes = <String?>[];
        
        for (final note in versionChanges.notes) {
          String noteText = _normalizeNote(note);
          if (noteText.isNotEmpty) {
            final cached = await _translationService.getCachedChangelogTranslation(
              versionChanges.version,
              noteText,
              targetLanguage,
            );
            cachedNotes.add(cached);
            if (cached == null) {
              allNotesCached = false;
            }
          } else {
            cachedNotes.add(noteText);
          }
        }
        
        // Si toutes les notes sont en cache, les utiliser directement
        if (allNotesCached && cachedNotes.every((n) => n != null)) {
          translatedVersions[v] = VersionChanges(
            version: versionChanges.version,
            notes: cachedNotes.map((n) => n!).toList(),
          );
          if (mounted) {
            setState(() {
              _translatedChangelogInfo = ChangelogInfo(translatedVersions);
            });
          }
          continue;
        }
        
        // Sinon, traduire les notes manquantes
        final translatedNotes = <String>[];
        
        for (int n = 0; n < versionChanges.notes.length; n++) {
          final note = versionChanges.notes[n];
          String noteText = _normalizeNote(note);
          
          if (noteText.isNotEmpty) {
            // Utiliser la note en cache si disponible, sinon traduire
            String? translated = cachedNotes[n];
            
            if (translated == null) {
              translated = await _translationService.translateText(
                noteText,
                targetLanguage,
              );
              
              // Mettre en cache si la traduction a réussi
              if (translated != null && translated != noteText && translated.isNotEmpty) {
                await _translationService.cacheChangelogTranslation(
                  versionChanges.version,
                  noteText,
                  targetLanguage,
                  translated,
                );
              }
            }
            
            if (translated != null && translated != noteText && translated.isNotEmpty) {
              translatedNotes.add(translated);
            } else {
              translatedNotes.add(noteText);
            }
          } else {
            translatedNotes.add(noteText);
          }
          
          // Mettre à jour la dialog après chaque note traduite
          translatedVersions[v] = VersionChanges(
            version: versionChanges.version,
            notes: [
              ...translatedNotes,
              ...versionChanges.notes.skip(n + 1).map((n) => _normalizeNote(n)),
            ],
          );
          if (mounted) {
            setState(() {
              _translatedChangelogInfo = ChangelogInfo(translatedVersions);
            });
          }
          
          // Petite pause entre les notes
          if (n < versionChanges.notes.length - 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
        
        // Pause entre les versions
        if (v < changelogInfo.newVersions.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  /// Normalise une note (convertit en String et nettoie)
  String _normalizeNote(dynamic note) {
    String noteText;
    if (note is String) {
      noteText = note;
    } else if (note is List) {
      noteText = note.map((e) => e.toString()).join('\n');
    } else {
      noteText = note.toString();
    }

    noteText = noteText.trim();
    if (noteText.startsWith('- ')) noteText = noteText.substring(2);
    if (noteText.startsWith('* ')) noteText = noteText.substring(2);
    return noteText;
  }

  String _cleanVersion(String version) {
    return version.replaceAll('+', ' build ');
  }

  @override
  Widget build(BuildContext context) {
    final changelogToDisplay = _translatedChangelogInfo ?? widget.changelogInfo;

    return AlertDialog(
      title: const Text("Quoi de neuf ?"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: changelogToDisplay.newVersions.map((changes) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version ${_cleanVersion(changes.version)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...changes.notes.map((note) => MarkdownBody(
                        data: RegExp(r'^[#\-\*]').hasMatch("$note") ? "$note" : "- $note",
                        styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14)),
                      )),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onClose?.call();
          },
          child: const Text("Super !"),
        )
      ],
    );
  }
}

