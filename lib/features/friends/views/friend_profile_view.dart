import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_avatar.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/theme/app_breakpoints.dart';
import 'package:mangatracker/core/theme/app_spacing.dart';
import 'package:mangatracker/features/friends/services/friends.service.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/manga/widgets/manga_card.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

/// Profil d'un ami — sa bibliothèque (amitié acceptée requise côté API).
///
/// Accessible depuis la liste d'amis. Affiche un header (avatar + nom +
/// compteur) puis la bibliothèque de l'ami en grille responsive
/// ([AppBreakpoints]). RGPD : l'API renvoie 403 si l'amitié n'est pas
/// acceptée — l'acceptation vaut consentement de partage entre amis.
class FriendProfileView extends StatefulWidget {
  final int friendUserId;
  final String displayName;
  final String? avatarUrl;

  const FriendProfileView({
    super.key,
    required this.friendUserId,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  State<FriendProfileView> createState() => _FriendProfileViewState();
}

class _FriendProfileViewState extends State<FriendProfileView> {
  late Future<List<MangaQuickViewDto>> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = getIt<FriendsService>().getFriendLibrary(
      widget.friendUserId,
    );
  }

  void _retry() {
    setState(() {
      _libraryFuture = getIt<FriendsService>().getFriendLibrary(
        widget.friendUserId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.displayName)),
      body: AppContentWidth(
        child: FutureBuilder<List<MangaQuickViewDto>>(
          future: _libraryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AppErrorState(
                message:
                    l10n?.friendLibraryError ??
                    'Impossible de charger la bibliothèque de cet ami.',
                onRetry: _retry,
              );
            }
            final library = snapshot.data ?? const [];
            return _FriendLibraryContent(
              friendName: widget.displayName,
              avatarUrl: widget.avatarUrl,
              library: library,
            );
          },
        ),
      ),
    );
  }
}

/// Header ami + grille de sa bibliothèque (responsive).
class _FriendLibraryContent extends StatelessWidget {
  final String friendName;
  final String? avatarUrl;
  final List<MangaQuickViewDto> library;

  const _FriendLibraryContent({
    required this.friendName,
    required this.avatarUrl,
    required this.library,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = AppBreakpoints.of(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    AppAvatar(
                      url: avatarUrl,
                      fallback: friendName,
                      size: AppAvatarSize.large,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friendName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n?.friendLibraryCount(library.length) ??
                                '${library.length} mangas dans sa bibliothèque',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (library.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.collections_bookmark_outlined,
                  title:
                      l10n?.friendLibraryEmpty ??
                      "Sa bibliothèque est vide pour l'instant.",
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.m),
                sliver: _FriendLibraryGrid(
                  library: library,
                  columns: bp.gridColumns,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Grille de la bibliotheque de l'ami : cover 3:4 derivee de la largeur de
/// colonne et cellule calee sur la carte (bloc texte qui suit la taille de
/// texte). L'ancien ratio fixe (0.62) donnait, sur un ecran de 320, une
/// cellule plus courte que la cover de 160 : titres sur la rangee suivante.
class _FriendLibraryGrid extends StatelessWidget {
  static const double _crossSpacing = 10;

  final List<MangaQuickViewDto> library;
  final int columns;

  const _FriendLibraryGrid({required this.library, required this.columns});

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final coverHeight = MangaCard.coverHeightFor(
          MangaCard.gridCellWidth(
            constraints.crossAxisExtent,
            columns: columns,
            spacing: _crossSpacing,
          ),
        );
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: _crossSpacing,
            mainAxisSpacing: 14,
            mainAxisExtent:
                coverHeight +
                MangaCard.textBlockHeightFor(MediaQuery.textScalerOf(context)),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final manga = library[index];
            return MangaCard(
              muId: manga.muId.toString(),
              mangaTitle: manga.title,
              mangaAuthor: manga.year,
              mediumImgPath: manga.mediumCoverUrl,
              rating:
                  manga.rating != 'N/A' && manga.rating.isNotEmpty
                      ? manga.rating
                      : null,
              coverHeight: coverHeight,
            );
          }, childCount: library.length),
        );
      },
    );
  }
}
