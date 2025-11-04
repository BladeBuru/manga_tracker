import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/notifier/notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../library/services/library.service.dart';
import '../dto/author.dto.dart';
import 'row_chapter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

class LateDetailView extends StatefulWidget {
  final String muId;
  final String mangaTitle;
  final String? mangaDescription;
  final String rating;
  final List mangaChapters;
  final num? mangaTotalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final String year;
  final num readChapters;
  final Function(num)? onReadCountChanged;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onRemoveFromLibrary;

  const LateDetailView({
    super.key,
    required this.muId,
    required this.mangaTitle,
    this.mangaDescription,
    required this.rating,
    required this.mangaChapters,
    this.mangaTotalChapters,
    this.isCompleted,
    this.authors,
    required this.year,
    required this.readChapters,
    this.onReadCountChanged,
    this.onAddToLibrary,
    this.onRemoveFromLibrary,
  });

  @override
  State<LateDetailView> createState() => _LateDetailViewState();
}

class _LateDetailViewState extends State<LateDetailView> {
  bool _isExpanded = false;
  num? _currentReadCount;
  bool _isSaving = false;
  final LibraryService _libraryService = getIt<LibraryService>();
  final Notifier _notifier = getIt<Notifier>();
  int? _pendingChapterUpdate; // Pour tracker la mise à jour en cours

  @override
  void initState() {
    super.initState();
    _currentReadCount = widget.readChapters;
  }
  
  @override
  void didUpdateWidget(LateDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si les chapitres ont changé et correspondent à notre mise à jour en attente
    if (widget.readChapters != oldWidget.readChapters) {
      if (_pendingChapterUpdate != null && widget.readChapters == _pendingChapterUpdate) {
        // La mise à jour est terminée, on peut réactiver les boutons
        setState(() {
          _currentReadCount = widget.readChapters;
          _isSaving = false;
          _pendingChapterUpdate = null;
        });
      } else {
        // Mise à jour externe (pas initiée par nous)
        setState(() {
          _currentReadCount = widget.readChapters;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {


    final authors =
        widget.authors
            ?.where((a) => a.type.toLowerCase() == 'author')
            .map((a) => a.name)
            .toList() ??
            [];
    final artists =
        widget.authors
            ?.where((a) => a.type.toLowerCase() == 'artist')
            .map((a) => a.name)
            .toList() ??
            [];

    Future<void> handleSaveChapter(String mangaId, num chapterNumber) async {
      if (_isSaving) return;
      setState(() => _isSaving = true);

      // NE PLUS appeler handleAddToLibrary ici car le BLoC gère maintenant
      // automatiquement l'ajout à la bibliothèque dans _onSaveChapterProgress

      int newCount;
      
      // Calculer le nouveau compte de chapitres
      if (_currentReadCount! >= chapterNumber) {
        newCount = chapterNumber.toInt() - 1;
      } else {
        newCount = chapterNumber.toInt();
      }

      // Utiliser le callback BLoC si disponible (mise à jour réactive)
      if (widget.onReadCountChanged != null) {
        // Marquer la mise à jour comme en attente
        setState(() {
          _currentReadCount = newCount;
          _pendingChapterUpdate = newCount;
          // _isSaving reste à true jusqu'à ce que didUpdateWidget détecte le changement
        });
        
        // Appeler le callback BLoC
        widget.onReadCountChanged!(newCount);
        
        // _isSaving sera remis à false dans didUpdateWidget quand le BLoC aura terminé
        return;
      }

      // Sinon, fallback sur l'ancien comportement
      bool success;
      if (_currentReadCount! >= chapterNumber) {
        if (newCount == 0) {
          success = await _libraryService.removeMangaFromLibrary(int.parse(mangaId));
        } else {
          success = await _libraryService.saveChapterProgress(int.parse(mangaId), newCount);
        }
      } else {
        success = await _libraryService.saveChapterProgress(int.parse(mangaId), newCount);
      }

      if (!success && mounted) {
        setState(() => _isSaving = false);
        final l10n = AppLocalizations.of(context);
        _notifier.error(l10n?.errorUpdatingChapter ?? 'Erreur lors de la mise à jour du chapitre.');
        return;
      }

      if (mounted) {
        setState(() {
          _currentReadCount = (newCount == 0) ? -1 : newCount;
          _isSaving = false;
        });

        final l10n = AppLocalizations.of(context);
        final message = newCount == 0
            ? (l10n?.mangaRemovedFromLibrary ?? 'Manga retiré de la bibliothèque')
            : '${l10n?.chapter ?? "Chapitre"} $chapterNumber ${_currentReadCount! >= chapterNumber
            ? (l10n?.chapterRead ?? 'lu')
            : (l10n?.chapterUnread ?? 'non lu')}';

        _notifier.info(message);
      }
    }

    Future<void> handleLinkTap(String url) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        final l10n = AppLocalizations.of(context);
        _notifier.error(l10n?.cannotOpenLink(url) ?? "Impossible d'ouvrir le lien : $url");
      }
    }

    final total = widget.mangaTotalChapters?.toInt() ?? 0;
    final chapNumbers = List<int>.generate(total, (i) => i + 1)
      ..sort((a, b) => b.compareTo(a)); // tri décroissant

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titres, chapitres & note
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.chaptersCount(widget.mangaTotalChapters?.toInt() ?? 0) ?? '${widget.mangaTotalChapters ?? 0} ${l10n?.chapters ?? "Chapitres"}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  Wrap(
                    children: [
                      Icon(Icons.star, color: Theme
                          .of(context)
                          .colorScheme
                          .primary, size: 25),
                      Text(
                        widget.rating,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 20),
                          fontWeight: FontWeight.bold,
                          color: Theme
                              .of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statut & Année sur la même ligne
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Text(
                          '${l10n?.status ?? "Statut"} : ${widget.isCompleted == true
                              ? (l10n?.completed ?? "Terminé")
                              : (l10n?.reading ?? "En cours")}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Text(
                          '${l10n?.year ?? "Année"} : ${widget.year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Auteur & Artiste sur la même ligne
            if (authors.isNotEmpty || artists.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (authors.isNotEmpty)
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  '${l10n?.author ?? "Auteur"} :',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            ...authors.map(
                                  (n) => Text(n, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    if (artists.isNotEmpty)
                      Flexible(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                  '${l10n?.artist ?? "Artiste"} :',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            ...artists.map(
                                  (n) => Text(n, textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // SYNOPSIS avec Voir plus / Voir moins
            if (widget.mangaDescription != null && widget.mangaDescription!.isNotEmpty)
              ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.synopsis ?? 'Synopsis',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(fontSize: 18),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: AnimatedContainer(
                    constraints: BoxConstraints(
                      maxHeight: _isExpanded ? 1000 : 70.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,

                    child: SingleChildScrollView(

                      physics: const NeverScrollableScrollPhysics(),
                      child: MarkdownBody(
                        data: widget.mangaDescription!,
                        onTapLink: (text, href, title) {
                          if (href != null) handleLinkTap(href);
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Le bouton "Voir plus / Voir moins" ne change pas
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    label: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(_isExpanded 
                          ? (l10n?.seeLess ?? 'Voir moins') 
                          : (l10n?.seeMore ?? 'Voir plus'));
                      },
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n?.chaptersCount(total) ?? '$total ${l10n?.chapters ?? "chapitres"}',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: chapNumbers.map((chapNum) {
                      final line = chapNum.toString().padLeft(2, '0');
                      final isRead = chapNum <= _currentReadCount!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.white, // couleur de fond de la ligne
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isSaving
                                ? null
                                : () => handleSaveChapter(widget.muId, chapNum),
                            child: AnimatedScale(
                              scale: _isSaving ? 1.0 : 1.0,
                              duration: const Duration(milliseconds: 100),
                              child: RowChapter(
                                line: line,
                                chapter: chapNum.toString(),
                                read: isRead,
                                enabled: !_isSaving,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
