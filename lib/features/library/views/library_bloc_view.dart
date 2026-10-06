import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mangatracker/core/components/offline_banner.dart';
import 'package:mangatracker/core/components/session_rejected_banner.dart';
import 'package:mangatracker/core/components/search_bar.dart'
    show CustomSearchBar;
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/library/bloc/library_bloc.dart';
import 'package:mangatracker/features/library/bloc/library_event.dart';
import 'package:mangatracker/features/library/bloc/library_state.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_colors.dart';
import 'package:mangatracker/features/library/widgets/library_action_banner.dart';
import 'package:mangatracker/features/library/widgets/library_error_state.dart';
import 'package:mangatracker/features/library/widgets/library_top_bar.dart';
import 'package:mangatracker/features/library/widgets/library_filtering.dart';
import 'package:mangatracker/features/library/widgets/library_grid_view.dart';
import 'package:mangatracker/features/library/widgets/library_list_view.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vue réactive de la bibliothèque utilisant BLoC.
///
/// **Refactor V1 « Refined Classic » 2026-05-18** :
/// - Sections : plus de border rouge agressive — `LibrarySection` hairline.
/// - Mode liste : `MangaRow(showProgressBar: true)` → barre de progression
///   à la place de la pill rouge.
/// - View splittée : helpers / states / banner / sections extraits dans
///   `lib/features/library/widgets/`.
class LibraryBlocView extends StatefulWidget {
  const LibraryBlocView({super.key});

  @override
  State<LibraryBlocView> createState() => _LibraryBlocViewState();
}

class _LibraryBlocViewState extends State<LibraryBlocView> {
  final LibraryBloc _libraryBloc = getIt<LibraryBloc>();
  final DownloadManagerService _downloadManager = DownloadManagerService();
  final LibraryGroupingCache _grouping = LibraryGroupingCache();
  final TextEditingController _searchController = TextEditingController();
  final Map<ReadingStatus, bool> _isExpanded = {
    ReadingStatus.reading: true,
    ReadingStatus.readLater: true,
    ReadingStatus.caughtUp: true,
    ReadingStatus.completed: true,
  };
  static bool? _cachedViewMode;
  bool _isCardView = false;
  String _searchQuery = '';
  bool _showDownloadedOnly = false;

  /// Mangas ayant au moins un chapitre téléchargé — lu UNE fois à
  /// l'activation du filtre, jamais pendant le rendu.
  Set<int>? _downloadedMuIds;

  @override
  void initState() {
    super.initState();
    _libraryBloc.add(const LoadLibrary());
    _searchController.addListener(_onSearchChanged);
    if (_cachedViewMode != null) _isCardView = _cachedViewMode!;
    _loadViewState();
  }

  Future<void> _loadViewState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getBool('library_view_mode');
    if (storedValue == null) return;
    _cachedViewMode = storedValue;
    // Pas de reconstruction si le mode mémorisé est déjà celui affiché.
    if (storedValue != _isCardView) {
      if (mounted) {
        setState(() => _isCardView = storedValue);
      } else {
        _isCardView = storedValue;
      }
    }
  }

  Future<void> _saveViewState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('library_view_mode', _isCardView);
    _cachedViewMode = _isCardView;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Le contrôleur notifie aussi les changements de sélection / de
  /// curseur (simple appui dans le champ) : on ne reconstruit que si le
  /// TEXTE recherché change.
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
  }

  Future<void> _toggleDownloadedOnly() async {
    if (_showDownloadedOnly) {
      setState(() => _showDownloadedOnly = false);
      return;
    }
    await _reloadDownloadedIds(enableFilter: true);
  }

  Future<void> _reloadDownloadedIds({bool enableFilter = false}) async {
    final chapters = await _downloadManager.getAllDownloadedChapters();
    if (!mounted) return;
    setState(() {
      _downloadedMuIds = chapters.keys.toSet();
      if (enableFilter) _showDownloadedOnly = true;
    });
  }

  /// Des téléchargements ont pu y être supprimés : le filtre « téléchargés »
  /// actif ne doit pas continuer à montrer ces titres.
  Future<void> _openDownloads() async {
    await context.push('/downloads');
    if (mounted && _showDownloadedOnly) await _reloadDownloadedIds();
  }

  /// Attend la fin réelle du rafraîchissement (au lieu d'un délai fixe) :
  /// l'indicateur de « tirer pour rafraîchir » disparaît avec les données,
  /// hors ligne compris.
  Future<void> _refresh() {
    final done = Completer<void>();
    _libraryBloc.add(RefreshLibrary(completer: done));
    return done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  String _displayNameOf(MangaQuickViewDto manga) =>
      LibraryFiltering.displayNameOf(manga, _searchQuery);

  void _toggleSection(ReadingStatus status) {
    setState(() {
      _isExpanded[status] = !(_isExpanded[status] ?? true);
    });
  }

  void _redirectToLoginPage() => context.push('/login');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      // **V1 refactor 2026-05-18** : AppBar Material 3 supprimée — remplacée
      // par `LibraryTopBar` inline (titre large 24/900 + 3 boutons 36×36
      // radius 10). Cohérent avec `screen-library.jsx` du design source.
      backgroundColor:
          brightness == Brightness.dark
              ? AppColors.dsBgDark
              : AppColors.dsBgLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LibraryTopBar(
              title: l10n?.library ?? 'Bibliothèque',
              showDownloadedOnly: _showDownloadedOnly,
              isCardView: _isCardView,
              onToggleDownloadedFilter: _toggleDownloadedOnly,
              onOpenDownloads: _openDownloads,
              onToggleView: () {
                setState(() {
                  _isCardView = !_isCardView;
                  _cachedViewMode = _isCardView;
                });
                _saveViewState();
              },
              toggleDownloadedTooltip:
                  _showDownloadedOnly
                      ? (l10n?.libraryShowAllMangas ??
                          'Afficher tous les mangas')
                      : (l10n?.libraryShowDownloadedOnly ??
                          'Afficher uniquement les téléchargés'),
              openDownloadsTooltip:
                  l10n?.manageDownloads ?? 'Gérer les téléchargements',
              toggleViewTooltip:
                  _isCardView
                      ? (l10n?.libraryToggleListView ?? 'Vue liste')
                      : (l10n?.libraryToggleCardView ?? 'Vue carte'),
            ),
            Expanded(
              child: BlocConsumer<LibraryBloc, LibraryState>(
                bloc: _libraryBloc,
                listener: (context, state) {
                  if (state is LibraryError) {
                    if (state.message.contains('InvalidCredentials') ||
                        state.message.contains('Expired session')) {
                      _redirectToLoginPage();
                    }
                  }
                },
                builder: (context, state) {
                  // Responsive (audit 2026-06-12) : branches locales 1200/600
                  // remplacées par le wrapper unifié AppContentWidth (max 1100)
                  // + paddings issus d'AppBreakpoints.
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final bp = AppBreakpoints.of(constraints.maxWidth);
                      final hPad =
                          bp.isWide
                              ? 32.0
                              : bp.isAtLeastTablet
                              ? 24.0
                              : 0.0;
                      return AppContentWidth(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: _buildBody(state),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LibraryState state) {
    // `LibraryInitial` = premier affichage, chargement pas encore commencé :
    // il affichait « Erreur » une fraction de seconde.
    if (state is LibraryLoading || state is LibraryInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is LibraryError) {
      return LibraryErrorState(error: state, bloc: _libraryBloc);
    }
    if (state is LibraryLoaded) return _buildLibraryContent(state);
    if (state is LibraryActionInProgress) return _buildActionInProgress(state);

    return Center(
      child: Text(AppLocalizations.of(context)?.error ?? 'État inconnu'),
    );
  }

  Widget _buildActionInProgress(LibraryActionInProgress state) {
    return Column(
      children: [
        _searchPadding(),
        if (state.isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: OfflineBanner(),
          ),
        if (state.requiresReauth) _reauthBanner(),
        LibraryActionBanner(action: state.action),
        Expanded(child: _buildList(state.mangas)),
      ],
    );
  }

  Widget _buildLibraryContent(LibraryLoaded state) {
    return Column(
      children: [
        _searchPadding(),
        if (state.isOffline)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OfflineBanner(pendingActions: state.pendingActions),
          )
        else if (state.pendingActions > 0 && !state.requiresReauth)
          // En ligne, mais des modifications faites hors ligne attendent :
          // on le dit (avant : rien) et on propose de les envoyer.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PendingSyncBanner(
              pendingActions: state.pendingActions,
              onSync: _refresh,
            ),
          ),
        if (state.requiresReauth) _reauthBanner(),
        Expanded(child: _buildList(state.mangas)),
      ],
    );
  }

  /// Invitation non bloquante a se reconnecter : la bibliotheque en cache
  /// reste affichee et navigable derriere.
  Widget _reauthBanner() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SessionRejectedBanner(onReconnect: () => context.push('/login')),
  );

  Widget _searchPadding() => Padding(
    padding: const EdgeInsets.all(16.0),
    child: CustomSearchBar(
      controller: _searchController,
      onChanged: (value) {},
    ),
  );

  /// Rendu SYNCHRONE : la liste reste à l'écran pendant toute
  /// reconstruction (plus de `FutureBuilder` recréé à chaque rendu, qui
  /// remplaçait la liste par un indicateur de chargement puis rechargeait
  /// toutes les couvertures).
  Widget _buildList(List<MangaQuickViewDto> mangas) {
    final grouped = _grouping.resolve(
      mangas: mangas,
      searchQuery: _searchQuery,
      downloadedMuIds: _showDownloadedOnly ? _downloadedMuIds : null,
    );
    return RefreshIndicator(
      onRefresh: _refresh,
      child:
          _isCardView
              ? LibraryGridView(
                grouped: grouped,
                isExpanded: _isExpanded,
                onToggleSection: _toggleSection,
                searchQuery: _searchQuery,
                showDownloadedOnly: _showDownloadedOnly,
                displayNameOf: _displayNameOf,
              )
              : LibraryListView(
                grouped: grouped,
                isExpanded: _isExpanded,
                onToggleSection: _toggleSection,
                searchQuery: _searchQuery,
                showDownloadedOnly: _showDownloadedOnly,
                libraryBloc: _libraryBloc,
                displayNameOf: _displayNameOf,
              ),
    );
  }
}
