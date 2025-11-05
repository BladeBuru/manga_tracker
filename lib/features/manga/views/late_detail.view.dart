import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifier/notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../library/services/library.service.dart';
import '../dto/author.dto.dart';
import '../dto/season_chapter.dto.dart';
import '../helpers/chapter_section.helper.dart';
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
  final List<String>? genres;
  final Function(num)? onReadCountChanged;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onRemoveFromLibrary;
  final List<SeasonChapter>? seasonChapters;
  final List<SeasonChapter>? bonusChapters;
  final List<String>? associated;

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
    this.genres,
    this.onReadCountChanged,
    this.onAddToLibrary,
    this.onRemoveFromLibrary,
    this.seasonChapters,
    this.bonusChapters,
    this.associated,
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
  
  // État d'ouverture des sections
  Map<String, bool> _expandedSections = {};
  bool _associatedExpanded = false;
  bool _isStateLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentReadCount = widget.readChapters;
    _loadExpandedState();
  }
  
  Future<void> _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'manga_${widget.muId}_expanded_seasons';
    final jsonString = prefs.getString(key);
    
    if (jsonString != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        final expandedList = (data['expandedSeasons'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        
        setState(() {
          // Initialiser toutes les sections comme fermées
          _expandedSections = {};
          // Marquer celles sauvegardées comme ouvertes
          for (final season in expandedList) {
            _expandedSections[season] = true;
          }
          _associatedExpanded = data['associatedExpanded'] ?? false;
          _isStateLoaded = true;
        });
      } catch (e) {
        debugPrint('Erreur lors du chargement de l\'état: $e');
        _initializeExpandedState();
      }
    } else {
      // Pas de sauvegarde, déterminer l'état initial
      _initializeExpandedState();
    }
  }
  
  void _initializeExpandedState() {
    final totalChapters = widget.mangaTotalChapters?.toInt() ?? 0;
    final readChapters = widget.readChapters.toInt();
    
    // Calculer les sections
    final sections = ChapterSectionHelper.calculateSections(
      totalChapters: totalChapters,
      seasonChapters: widget.seasonChapters,
      bonusChapters: widget.bonusChapters,
    );
    
    if (sections.isNotEmpty) {
      // Trouver la section contenant le dernier chapitre lu
      final currentSection = ChapterSectionHelper.findSectionForChapter(
        readChapters > 0 ? readChapters : 1,
        sections,
      );
      
      setState(() {
        _expandedSections = {};
        
        if (currentSection != null) {
          // Ouvrir la section actuelle
          _expandedSections[currentSection] = true;
          
          // Fermer les sections précédentes (si on est dans une saison supérieure)
          final currentIndex = sections.indexWhere((s) => s.title == currentSection);
          if (currentIndex > 0) {
            // Fermer toutes les sections avant la section actuelle
            for (int i = 0; i < currentIndex; i++) {
              _expandedSections[sections[i].title] = false;
            }
          }
        }
        _isStateLoaded = true;
      });
    } else {
      _initializeExpandedState();
      _isStateLoaded = true;
    }
  }
  
  Future<void> _saveExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'manga_${widget.muId}_expanded_seasons';
    
    final expandedList = _expandedSections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    
    final data = {
      'expandedSeasons': expandedList,
      'associatedExpanded': _associatedExpanded,
    };
    
    await prefs.setString(key, jsonEncode(data));
  }
  
  void _handleSectionExpansion(String sectionTitle, bool isExpanded) {
    setState(() {
      _expandedSections[sectionTitle] = isExpanded;
      
      // Si on ouvre une section, fermer les sections plus récentes (qui sont au-dessus dans l'affichage inversé)
      if (isExpanded) {
        final sections = ChapterSectionHelper.calculateSections(
          totalChapters: widget.mangaTotalChapters?.toInt() ?? 0,
          seasonChapters: widget.seasonChapters,
          bonusChapters: widget.bonusChapters,
        );
        final reversedSections = sections.reversed.toList();
        
        final currentIndex = reversedSections.indexWhere((s) => s.title == sectionTitle);
        if (currentIndex != -1 && currentIndex > 0) {
          // Fermer toutes les sections plus récentes (au-dessus dans l'affichage)
          for (int i = 0; i < currentIndex; i++) {
            _expandedSections[reversedSections[i].title] = false;
          }
        }
      }
      // Si on ferme une section, on ne fait rien de spécial
    });
    _saveExpandedState();
  }
  
  void _handleAssociatedExpansion(bool isExpanded) {
    setState(() {
      _associatedExpanded = isExpanded;
    });
    _saveExpandedState();
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

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations principales (Chapitres, Note, Statut, Année) - Layout 2x2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Première ligne : Chapitres et Note
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.menu_book,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n?.chaptersCount(widget.mangaTotalChapters?.toInt() ?? 0) ?? 
                                      '${widget.mangaTotalChapters ?? 0} ${l10n?.chapters ?? "Chapitres"}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.rating,
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Deuxième ligne : Statut et Année
                  Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            final statusText = widget.isCompleted == true
                                ? (l10n?.completed ?? "Terminé")
                                : (l10n?.reading ?? "En cours");
                            final statusLabel = l10n?.status ?? "État";
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$statusLabel : ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextSpan(
                                            text: statusText,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.year,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Auteur & Artiste
            if (authors.isNotEmpty || artists.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (authors.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Builder(
                                      builder: (context) {
                                        final l10n = AppLocalizations.of(context);
                                        return Text(
                                          l10n?.author ?? "Auteur",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...authors.map((name) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                      if (authors.isNotEmpty && artists.isNotEmpty)
                        const SizedBox(width: 10),
                      if (artists.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.palette,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Builder(
                                      builder: (context) {
                                        final l10n = AppLocalizations.of(context);
                                        return Text(
                                          l10n?.artist ?? "Artiste",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...artists.map((name) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Noms associés (ExpansionTile)
            if (widget.associated != null && widget.associated!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    collapsedShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    leading: Icon(
                      Icons.translate,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          l10n?.associatedNames ?? 'Noms associés',
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ),
                    subtitle: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        final count = widget.associated!.length;
                        return Text(
                          l10n?.associatedNamesCount(count) ?? '$count ${count > 1 ? "noms" : "nom"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                    initiallyExpanded: _associatedExpanded,
                    onExpansionChanged: _handleAssociatedExpansion,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          alignment: WrapAlignment.start,
                          children: widget.associated!.map((name) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
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

            // Sections de chapitres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  
                  // Calculer les sections
                  final sections = ChapterSectionHelper.calculateSections(
                    totalChapters: total,
                    seasonChapters: widget.seasonChapters,
                    bonusChapters: widget.bonusChapters,
                  );
                  
                  // Si on a des sections, les afficher avec ExpansionTile
                  if (sections.isNotEmpty) {
                    // Inverser l'ordre : la plus récente en haut
                    final reversedSections = sections.reversed.toList();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.chaptersCount(total) ?? '$total ${l10n?.chapters ?? "chapitres"}',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...reversedSections.map<Widget>((section) {
                          // Utiliser l'état chargé ou false par défaut
                          final isExpanded = _isStateLoaded 
                              ? (_expandedSections[section.title] ?? false)
                              : false;
                          final chapterCount = section.endChapter - section.startChapter + 1;
                          final readCount = section.chapterNumbers
                              .where((n) => n <= _currentReadCount!)
                              .length;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isExpanded
                                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                width: isExpanded ? 1.5 : 1,
                              ),
                              boxShadow: isExpanded
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ExpansionTile(
                              key: ValueKey('${section.title}_${isExpanded}'),
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              collapsedShape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.list_alt,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                section.title,
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    Icons.numbers,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${section.startChapter}-${section.endChapter}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$readCount/$chapterCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              initiallyExpanded: isExpanded,
                              onExpansionChanged: (expanded) {
                                _handleSectionExpansion(section.title, expanded);
                              },
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    children: section.chapterNumbers.map((chapNum) {
                                      final line = chapNum.toString().padLeft(2, '0');
                                      final isRead = chapNum <= _currentReadCount!;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 3,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(8),
                                            onTap: _isSaving
                                                ? null
                                                : () => handleSaveChapter(widget.muId, chapNum),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }
                  // Sinon, affichage linéaire (cas < 100 chapitres sans saisons)
                  else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.chaptersCount(total) ?? '$total ${l10n?.chapters ?? "chapitres"}',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: List.generate(total, (i) => total - i).map((chapNum) {
                            final line = chapNum.toString().padLeft(2, '0');
                            final isRead = chapNum <= _currentReadCount!;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Material(
                                color: Colors.white,
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
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
