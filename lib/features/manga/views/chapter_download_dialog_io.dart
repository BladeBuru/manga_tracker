import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/download/services/chapter_download_service.dart';
import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';
import 'package:mangatracker/features/manga/views/web_view.dart';

/// Dialog pour sélectionner et télécharger des chapitres
class ChapterDownloadDialog extends StatefulWidget {
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
  State<ChapterDownloadDialog> createState() => _ChapterDownloadDialogState();
}

class _ChapterDownloadDialogState extends State<ChapterDownloadDialog> {
  final Set<int> _selectedChapters = {};
  final DownloadManagerService _downloadManager = DownloadManagerService();
  final ChapterDownloadService _downloadService = ChapterDownloadService();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _currentDownloadChapter;
  final Map<int, bool> _downloadedChapters = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadedChapters();
  }

  Future<void> _loadDownloadedChapters() async {
    final downloaded = await _downloadManager.getDownloadedChapters(widget.muId);
    setState(() {
      for (final chapter in downloaded) {
        _downloadedChapters[chapter.chapterNumber] = true;
      }
    });
  }

  void _toggleChapter(int chapterNumber) {
    setState(() {
      if (_selectedChapters.contains(chapterNumber)) {
        _selectedChapters.remove(chapterNumber);
      } else {
        _selectedChapters.add(chapterNumber);
      }
    });
  }

  Future<void> _startDownload() async {
    if (_selectedChapters.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final chaptersToDownload = _selectedChapters.toList()..sort();
    int completedCount = 0;
    bool useWebView = true; // Utiliser la webview pour le premier chapitre

    try {
      for (int index = 0; index < chaptersToDownload.length; index++) {
        final chapterNumber = chaptersToDownload[index];
        if (!mounted) break;
        
        setState(() {
          _currentDownloadChapter = 'Chapitre $chapterNumber';
        });

        try {
          // Construire l'URL du chapitre
          final chapterUrl = await ChapterLinkResolver.buildUrlForChapter(
            widget.baseUrl,
            chapterNumber,
          );

          if (chapterUrl == null) {
            debugPrint('⚠️ Impossible de construire l\'URL pour le chapitre $chapterNumber');
            continue;
          }

          bool downloadSuccess = false;

          // Si c'est le premier chapitre ou si les cookies ne sont pas disponibles, utiliser la webview
          if (useWebView) {
            // Créer un Completer pour attendre le téléchargement
            final completer = Completer<bool>();
            bool downloadCompleted = false;
            
            // Ouvrir la webview et attendre que l'utilisateur télécharge
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReaderWebView(
                  muId: widget.muId,
                  mangaTitle: widget.mangaTitle,
                  initialLastRead: chapterNumber - 1,
                  initialUrl: chapterUrl,
                  baseUserLink: widget.baseUrl,
                  autoDownload: true, // Mode téléchargement automatique
                  onDownloadComplete: (success) {
                    downloadCompleted = success;
                    if (!completer.isCompleted) {
                      completer.complete(success);
                    }
                  },
                ),
              ),
            );

            // Attendre que le téléchargement soit terminé
            // Le callback est appelé AVANT la fermeture de la WebView, donc on devrait recevoir le résultat
            try {
              downloadSuccess = await completer.future.timeout(
                const Duration(minutes: 5), // Timeout de 5 minutes par chapitre
                onTimeout: () {
                  debugPrint('⚠️ Timeout pour le chapitre $chapterNumber');
                  return false;
                },
              );
            } catch (e) {
              debugPrint('⚠️ Erreur lors de l\'attente du téléchargement: $e');
              downloadSuccess = false;
            }

            // Si le completer n'a pas été complété mais que la webview s'est fermée,
            // vérifier si le téléchargement a réussi en vérifiant les fichiers
            if (!downloadCompleted) {
              await Future.delayed(const Duration(milliseconds: 500)); // Attendre un peu pour que le téléchargement se termine
              final downloaded = await _downloadManager.getDownloadedChapters(widget.muId);
              downloadSuccess = downloaded.any((c) => c.chapterNumber == chapterNumber);
            }

            // Si le téléchargement a réussi, les cookies sont maintenant disponibles pour les suivants
            if (downloadSuccess) {
              useWebView = false; // Utiliser le service automatique pour les suivants
              debugPrint('✅ Chapitre $chapterNumber téléchargé avec succès, passage au mode automatique pour les suivants');
            }
          } else {
            // Utiliser le service de téléchargement automatique avec les cookies sauvegardés
            debugPrint('📥 Téléchargement automatique du chapitre $chapterNumber...');
            try {
              await _downloadService.downloadChapter(
                muId: widget.muId,
                chapterNumber: chapterNumber,
                chapterUrl: chapterUrl,
                mangaTitle: widget.mangaTitle,
                onProgress: (progress) {
                  setState(() {
                    _downloadProgress = (completedCount + progress) / chaptersToDownload.length;
                  });
                },
              );
              downloadSuccess = true;
              debugPrint('✅ Chapitre $chapterNumber téléchargé automatiquement avec succès');
            } catch (e) {
              debugPrint('❌ Erreur lors du téléchargement automatique du chapitre $chapterNumber: $e');
              
              // Si c'est une erreur 403 ou autre erreur de téléchargement, revenir à la webview pour ce chapitre
              if (e.toString().contains('403') || 
                  e.toString().contains('Échec du téléchargement') ||
                  e.toString().contains('Exception')) {
                debugPrint('⚠️ Erreur pour le chapitre $chapterNumber, retour à la webview');
                
                // Ouvrir directement la WebView pour ce chapitre
                final completer = Completer<bool>();
                bool downloadCompleted = false;
                
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReaderWebView(
                      muId: widget.muId,
                      mangaTitle: widget.mangaTitle,
                      initialLastRead: chapterNumber - 1,
                      initialUrl: chapterUrl,
                      baseUserLink: widget.baseUrl,
                      autoDownload: true, // Mode téléchargement automatique
                      onDownloadComplete: (success) {
                        downloadCompleted = success;
                        if (!completer.isCompleted) {
                          completer.complete(success);
                        }
                      },
                    ),
                  ),
                );

                // Attendre que le téléchargement soit terminé
                try {
                  downloadSuccess = await completer.future.timeout(
                    const Duration(minutes: 5),
                    onTimeout: () {
                      debugPrint('⚠️ Timeout pour le chapitre $chapterNumber');
                      return false;
                    },
                  );
                } catch (e) {
                  debugPrint('⚠️ Erreur lors de l\'attente du téléchargement: $e');
                  downloadSuccess = false;
                }

                // Si le completer n'a pas été complété mais que la webview s'est fermée,
                // vérifier si le téléchargement a réussi en vérifiant les fichiers
                if (!downloadCompleted) {
                  await Future.delayed(const Duration(milliseconds: 500));
                  final downloaded = await _downloadManager.getDownloadedChapters(widget.muId);
                  downloadSuccess = downloaded.any((c) => c.chapterNumber == chapterNumber);
                }
                
                // Si le téléchargement a réussi, continuer en mode automatique
                // Sinon, rester en mode WebView pour les suivants
                if (!downloadSuccess) {
                  useWebView = true;
                }
                
                // Sortir du bloc try-catch pour traiter le résultat
                // On continue avec le code après le bloc else
              } else {
                downloadSuccess = false;
                useWebView = true; // Revenir à la webview en cas d'autre erreur
              }
            }
          }

          // Vérifier si le téléchargement a réussi
          final downloaded = await _downloadManager.getDownloadedChapters(widget.muId);
          final isDownloaded = downloaded.any((c) => c.chapterNumber == chapterNumber);
          
          // Pour le téléchargement automatique, vérifier aussi que le fichier existe
          if (!useWebView && downloadSuccess) {
            final title = widget.mangaTitle;
            final chapterPath = await _downloadManager.getChapterDownloadPath(title, chapterNumber);
            final htmlFile = File(path.join(chapterPath, 'chapter.html'));
            if (!await htmlFile.exists()) {
              debugPrint('⚠️ Le fichier HTML n\'existe pas pour le chapitre $chapterNumber');
              downloadSuccess = false;
            }
          }
          
          if (isDownloaded || downloadSuccess) {
            completedCount++;
            _downloadedChapters[chapterNumber] = true;
            debugPrint('✅ Chapitre $chapterNumber téléchargé avec succès');
          } else {
            debugPrint('⚠️ Le chapitre $chapterNumber n\'a pas été téléchargé');
            // Si le téléchargement a échoué, revenir à la webview pour les suivants
            useWebView = true;
          }

          // Mettre à jour la progression
          setState(() {
            _downloadProgress = completedCount / chaptersToDownload.length;
          });

        } catch (e) {
          debugPrint('❌ Erreur lors du téléchargement du chapitre $chapterNumber: $e');
          // En cas d'erreur, revenir à la webview pour les suivants
          useWebView = true;
        }
      }

      setState(() {
        _isDownloading = false;
        _selectedChapters.clear();
        _downloadProgress = 0.0;
        _currentDownloadChapter = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$completedCount chapitre(s) téléchargé(s) avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
        _currentDownloadChapter = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text('Télécharger des chapitres'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isDownloading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentDownloadChapter != null)
                    Text(
                      'Téléchargement: $_currentDownloadChapter',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _downloadProgress),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Boutons de sélection rapide
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.select_all, size: 18),
                            label: const Text('Tout sélectionner'),
                            onPressed: () {
                              setState(() {
                                _selectedChapters.clear();
                                for (int i = 1; i <= widget.totalChapters; i++) {
                                  if (!(_downloadedChapters[i] ?? false)) {
                                    _selectedChapters.add(i);
                                  }
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.deselect, size: 18),
                            label: const Text('Tout désélectionner'),
                            onPressed: () {
                              setState(() {
                                _selectedChapters.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (widget.readChapters != null && widget.readChapters! > 0) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 18),
                        label: Text('Sélectionner les non lus (${widget.totalChapters - widget.readChapters!})'),
                        onPressed: () {
                          setState(() {
                            _selectedChapters.clear();
                            for (int i = (widget.readChapters! + 1); i <= widget.totalChapters; i++) {
                              if (!(_downloadedChapters[i] ?? false)) {
                                _selectedChapters.add(i);
                              }
                            }
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Sélectionnez les chapitres à télécharger:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Liste des chapitres disponibles
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.totalChapters,
                        itemBuilder: (context, index) {
                          final chapterNumber = index + 1;
                          final isDownloaded = _downloadedChapters[chapterNumber] ?? false;
                          final isSelected = _selectedChapters.contains(chapterNumber);

                          return CheckboxListTile(
                            title: Text('Chapitre $chapterNumber'),
                            subtitle: isDownloaded
                                ? Text(
                                    'Déjà téléchargé',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            value: isSelected,
                            onChanged: isDownloaded
                                ? null
                                : (value) => _toggleChapter(chapterNumber),
                            secondary: isDownloaded
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isDownloading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n?.close ?? 'Annuler'),
        ),
        if (!_isDownloading)
          FilledButton(
            onPressed: _selectedChapters.isEmpty ? null : _startDownload,
            child: Text('Télécharger (${_selectedChapters.length})'),
          ),
      ],
    );
  }
}

