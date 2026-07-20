import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifier/notifier.dart';
import '../../../core/service_locator/service_locator.dart';
import '../../library/services/library.service.dart';
import '../dto/author.dto.dart';
import '../dto/season_chapter.dto.dart';
import '../helpers/chapter_section.helper.dart';
import '../widgets/detail_chapter_section.dart';
import '../widgets/detail_info_card.dart';
import '../widgets/report_chapters_dialog.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/comments/widgets/comments_section.dart';
import 'package:mangatracker/features/sharing/widgets/shared_reading_section.dart';

class LateDetailView extends StatefulWidget {
  final String muId;
  final String mangaTitle;
  final String? mangaDescription;
  final String rating;
  final num? mangaTotalChapters;

  /// Total OFFICIEL (MU) pour la validation du dialog de signalement (borne
  /// serveur = officiel + 200). `null` → le dialog retombe sur le total
  /// effectif ([mangaTotalChapters]).
  final num? officialTotalChapters;
  final bool? isCompleted;
  final List<AuthorDto>? authors;
  final String year;
  final num readChapters;

  /// Le manga est-il dans la bibliothèque de l'utilisateur ? Pilote
  /// l'affichage du CTA « Signaler plus de chapitres » (chantier A) — y
  /// compris quand le total connu est 0 (données MU incomplètes).
  final bool inLibrary;
  final List<String>? genres;
  final Function(num)? onReadCountChanged;
  final VoidCallback? onAddToLibrary;
  final VoidCallback? onRemoveFromLibrary;
  final List<SeasonChapter>? seasonChapters;
  final List<SeasonChapter>? bonusChapters;
  final List<String>? associated;

  /// Slot optionnel pour injecter du contenu (généralement
  /// `DetailRatingSection`) **avant** la section "Noms associés" — permet
  /// au parent de placer le widget de notation dans le flux scrollable
  /// au lieu de le coller en bas en hors-scroll.
  final Widget? inlineRatingSlot;

  const LateDetailView({
    super.key,
    required this.muId,
    required this.mangaTitle,
    this.mangaDescription,
    required this.rating,
    this.mangaTotalChapters,
    this.officialTotalChapters,
    this.isCompleted,
    this.authors,
    required this.year,
    required this.readChapters,
    this.inLibrary = false,
    this.genres,
    this.onReadCountChanged,
    this.onAddToLibrary,
    this.onRemoveFromLibrary,
    this.seasonChapters,
    this.bonusChapters,
    this.associated,
    this.inlineRatingSlot,
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
    
    setState(() {
      _expandedSections = {};
      
      if (sections.isNotEmpty) {
        // Trouver la section contenant le dernier chapitre lu
        final currentSection = ChapterSectionHelper.findSectionForChapter(
          readChapters > 0 ? readChapters : 1,
          sections,
        );
        
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
      }
      
      _isStateLoaded = true;
    });
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

  /// Helper pour construire une row chapitre V1 (sans saison/parent card).
  ///
  /// Utilisé dans le cas d'affichage linéaire (< 100 chapitres sans saison) :
  /// les rows sont rendues directement dans une card commune au-dessus.
  Widget _buildLinearChapterRow(int chapNum) {
    return DetailChapterRow(
      chapterNumber: chapNum,
      isRead: chapNum <= (_currentReadCount ?? 0),
      isSaving: _isSaving,
      onTap: () => _handleSaveChapter(widget.muId, chapNum),
    );
  }

  /// Header du bloc chapitres : titre + CTA « Signaler plus de chapitres »
  /// (chantier A — visible seulement si le manga est en bibliothèque).
  Widget _buildChaptersHeader(BuildContext context, String headerTitle, int total) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            headerTitle,
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (widget.inLibrary)
          TextButton.icon(
            onPressed: () => ReportChaptersDialog.show(
              context,
              muId: int.tryParse(widget.muId) ?? 0,
              currentTotal: total,
              officialTotal: widget.officialTotalChapters?.toInt(),
              readChapters: _currentReadCount?.toInt() ?? 0,
            ),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: Text(
              l10n?.reportMoreChaptersCta ?? 'Signaler plus de chapitres',
            ),
          ),
      ],
    );
  }

  /// Construit le bloc « chapitres » du détail manga.
  ///
  /// - Si `ChapterSectionHelper` produit des sections (saisons ou tranches de
  ///   100) → liste de `DetailChapterSection` collapsibles V1.
  /// - Sinon (< 100 chapitres sans saisons) → liste linéaire dans une seule
  ///   card V1 avec rows compactes.
  ///
  /// La logique de groupement (saisons, bonus chapters, tranches de 100) reste
  /// gérée par `ChapterSectionHelper` — on ne change QUE le rendu.
  Widget _buildChaptersBlock(BuildContext context, int total) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final sections = ChapterSectionHelper.calculateSections(
      totalChapters: total,
      seasonChapters: widget.seasonChapters,
      bonusChapters: widget.bonusChapters,
    );

    final headerTitle =
        l10n?.chaptersCount(total) ?? '$total ${l10n?.chapters ?? "chapitres"}';

    if (sections.isNotEmpty) {
      // Ordre : la plus récente en haut (comme avant).
      final reversedSections = sections.reversed.toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChaptersHeader(context, headerTitle, total),
          const SizedBox(height: AppSpacing.s),
          ...reversedSections.map((section) {
            final isExpanded = _isStateLoaded
                ? (_expandedSections[section.title] ?? false)
                : false;
            final chapterCount =
                section.endChapter - section.startChapter + 1;
            final readCount = section.chapterNumbers
                .where((n) => n <= (_currentReadCount ?? 0))
                .length;

            return DetailChapterSection(
              title: section.title,
              chapterNumbers: section.chapterNumbers,
              totalCount: chapterCount,
              readCount: readCount,
              isExpanded: isExpanded,
              currentReadCount: _currentReadCount ?? 0,
              isSaving: _isSaving,
              onExpansionChanged: (expanded) =>
                  _handleSectionExpansion(section.title, expanded),
              onChapterTap: (chapNum) =>
                  _handleSaveChapter(widget.muId, chapNum),
            );
          }),
        ],
      );
    }

    // Affichage linéaire — < 100 chapitres, pas de saisons.
    if (total <= 0) {
      // Finding 4a : total inconnu (0). Si le manga est en bibliothèque, on
      // affiche quand même le header pour exposer le CTA « Signaler plus de
      // chapitres » (données MU incomplètes → l'utilisateur peut corriger).
      if (widget.inLibrary) {
        return _buildChaptersHeader(context, headerTitle, total);
      }
      return const SizedBox.shrink();
    }
    final chapters = List.generate(total, (i) => total - i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChaptersHeader(context, headerTitle, total),
        const SizedBox(height: AppSpacing.s),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.dsSurfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(
              color: AppColors.dsHairline(brightness),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A140A0A), // rgba(20,10,10,0.04)
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < chapters.length; i++) ...[
                _buildLinearChapterRow(chapters[i]),
                if (i < chapters.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Container(
                      height: 1,
                      color: AppColors.dsHairline(brightness),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSaveChapter(String mangaId, num chapterNumber) async {
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
      
      // Appeler le callback pour déclencher la mise à jour via le BLoC
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

    Future<void> handleLinkTap(String url) async {
      // Finding 4b : capturer l10n AVANT l'await (pas de BuildContext au travers
      // d'un gap async) + garde `mounted` après l'await (c'est un State).
      final l10n = AppLocalizations.of(context);
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
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
            // Phase 8.3 (2026-05-18) : section "Lecture partagée" si l'user
            // fait partie d'un reading group pour ce manga (sinon invisible).
            SharedReadingSection(muId: int.tryParse(widget.muId) ?? 0),
            // Informations principales V1 (chapitres · note · statut · année ·
            // auteur · artiste) regroupées dans une seule card hairline avec
            // rows label-uppercase / valeur. Remplace l'ancienne grille 6-cells
            // Material 2 (cf. profile_edit_sections.dart pour le pattern).
            DetailInfoCard(
              totalChapters: widget.mangaTotalChapters,
              rating: widget.rating,
              isCompleted: widget.isCompleted,
              year: widget.year,
              authors: authors,
              artists: artists,
            ),

            const SizedBox(height: AppSpacing.s),

            // **Slot inline rating (2026-05-19)** : si le parent fournit un
            // widget de notation utilisateur, on l'injecte ICI dans le flux
            // scrollable (entre stats grid et Noms associés). Avant on
            // l'avait collé en bas hors-scroll → ça pinnait l'écran.
            if (widget.inlineRatingSlot != null) ...[
              widget.inlineRatingSlot!,
              const SizedBox(height: 8),
            ],

            // Noms associés (ExpansionTile)
            if (widget.associated != null && widget.associated!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppRadius.circularXl,
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
                            final theme = Theme.of(context);
                            final chipColor = theme.colorScheme.primary;
                            final textColor = theme.colorScheme.onPrimary;

                            return Container(
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: AppRadius.circularMd,
                                boxShadow: [
                                  BoxShadow(
                                    color: chipColor.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                  color: chipColor.withValues(alpha: 0.8),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  letterSpacing: 0.1,
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

                    // La traduction est désormais fournie par l'API
                    // (`translated_description`) — le parent passe déjà la
                    // bonne version dans `mangaDescription`.
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

            // Sections de chapitres V1 — cards collapsibles hairline alignées
            // sur LibrarySection (cf. library_section.dart). Remplace l'ancien
            // ExpansionTile rouge agressif (border primary + shadow primary)
            // par une card neutre + AnimatedCrossFade 250ms et rows compactes.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: _buildChaptersBlock(context, total),
            ),
            // Phase 7.1 : section commentaires en bas du détail manga.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: CommentsSection(muId: int.tryParse(widget.muId) ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}
