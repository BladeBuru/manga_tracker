import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/router/app_router.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/download/services/chapter_download_service.dart';
import 'package:mangatracker/features/download/services/download_batch.dart';
import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';

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

  /// Télécharge les chapitres sélectionnés, l'un après l'autre.
  ///
  /// Chemin HTTP direct d'abord (rapide quand le site le permet) ; au
  /// premier échec — Cloudflare, lecteur rendu en JavaScript, page sans
  /// image — toute la suite passe par le lecteur, qui attend que la page soit
  /// prête, télécharge et se ferme seul : la série enchaîne sans rien
  /// demander. Quitter le lecteur annule la série.
  Future<void> _startDownload() async {
    if (_selectedChapters.isEmpty) return;
    final batch = DownloadBatch(_selectedChapters);

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    var httpFastPath = true;
    for (final chapterNumber in batch.chapters) {
      if (!mounted || batch.cancelled) break;
      setState(() {
        _currentDownloadChapter = 'Chapitre $chapterNumber';
      });

      final chapterUrl = await ChapterLinkResolver.buildUrlForChapter(
        widget.baseUrl,
        chapterNumber,
      );
      if (chapterUrl == null) {
        // Compté comme un échec (il était sauté sans rien dire).
        debugPrint("⚠️ Impossible de construire l'URL pour le chapitre $chapterNumber");
        batch.recordFailure(chapterNumber);
        if (mounted) setState(() => _downloadProgress = batch.fraction);
        continue;
      }

      var ok = false;
      if (httpFastPath) {
        try {
          await _downloadService.downloadChapter(
            muId: widget.muId,
            chapterNumber: chapterNumber,
            chapterUrl: chapterUrl,
            mangaTitle: widget.mangaTitle,
          );
          ok = true;
        } catch (e) {
          debugPrint('📥 Chapitre $chapterNumber : chemin HTTP refusé ($e), passage par le lecteur');
          httpFastPath = false;
        }
      }

      if (!ok) {
        if (!mounted) break;
        final outcome = await _downloadViaReader(chapterNumber, chapterUrl);
        if (outcome == ReaderDownloadOutcome.cancelled) {
          batch.cancel();
          break;
        }
        ok = outcome == ReaderDownloadOutcome.success;
      }

      // Vérité terrain : le chapitre est-il réellement enregistré ?
      ok = ok && await _isDownloaded(chapterNumber);
      if (ok) {
        batch.recordSuccess(chapterNumber);
        _downloadedChapters[chapterNumber] = true;
      } else {
        batch.recordFailure(chapterNumber);
      }
      if (mounted) setState(() => _downloadProgress = batch.fraction);
    }

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      // Les échecs et les chapitres non traités restent sélectionnés : on
      // peut relancer d'un appui.
      _selectedChapters.removeAll(batch.done);
      _downloadProgress = 0.0;
      _currentDownloadChapter = null;
    });

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.downloadBatchSummary(batch.done.length, batch.failed.length) ??
              '${batch.done.length} chapitre(s) téléchargé(s), ${batch.failed.length} échec(s)',
        ),
      ),
    );
    if (batch.failed.isEmpty && !batch.cancelled) {
      Navigator.of(context).pop();
    }
  }

  /// Ouvre le lecteur en mode téléchargement pour [chapterNumber] et attend
  /// qu'il se ferme. Le lecteur se ferme lui-même avec le résultat ;
  /// quitté par l'utilisateur, il ne rend rien (annulation).
  Future<ReaderDownloadOutcome> _downloadViaReader(
    int chapterNumber,
    String chapterUrl,
  ) async {
    bool? reported;
    final popped = await context.push<bool>(
      '/manga/${widget.muId}/read',
      extra: ReaderWebExtras(
        mangaTitle: widget.mangaTitle,
        initialLastRead: chapterNumber - 1,
        initialUrl: chapterUrl,
        baseUserLink: widget.baseUrl,
        autoDownload: true,
        onDownloadComplete: (success) => reported ??= success,
      ),
    );
    return DownloadBatch.outcomeOf(popResult: popped, reported: reported);
  }

  Future<bool> _isDownloaded(int chapterNumber) async {
    final downloaded = await _downloadManager.getDownloadedChapters(widget.muId);
    return downloaded.any((c) => c.chapterNumber == chapterNumber);
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

