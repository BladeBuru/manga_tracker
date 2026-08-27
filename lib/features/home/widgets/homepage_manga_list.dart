import 'package:flutter/material.dart';
import 'package:mangatracker/core/components/app_empty_state.dart';
import 'package:mangatracker/core/components/app_error_state.dart';
import 'package:mangatracker/l10n/app_localizations.dart';

import '../../manga/dto/manga_quick_view.dto.dart';
import '../../manga/widgets/manga_row.dart';

class HomepageMangaList extends StatelessWidget {
  final Future<List<MangaQuickViewDto>> mangas;
  final VoidCallback? onDetailReturn;
  // Si fourni, MangaRow affiche le titre alternatif qui matche la query
  // (utile pour la page Recherche ; pas pertinent pour Trending/Latest).
  final String? searchQuery;

  const HomepageMangaList({
    super.key,
    required this.mangas,
    this.onDetailReturn,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MangaQuickViewDto>>(
        future: mangas,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final mangaList = snapshot.data!;
            if (mangaList.isEmpty) {
              return AppEmptyState(
                icon: Icons.menu_book_outlined,
                title: AppLocalizations.of(context)?.searchNoResults ??
                    'Aucun résultat trouvé',
              );
            } else {
              return ListView.builder(
                itemCount: mangaList.length,
                scrollDirection: Axis.vertical,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final manga = mangaList[index];
                  return MangaRow(
                    mangaName: manga.title,
                    muId: manga.muId.toString(),
                    mangaAuthor: manga.year,
                    mediumImgPath: manga.mediumCoverUrl,
                    lastChapter: manga.totalChapters,
                    readChapter: manga.readChapters,
                    rating: manga.rating,
                    onDetailReturn: onDetailReturn,
                    searchQuery: searchQuery,
                    associatedTitles: manga.associated,
                  );
                },
              );
            }
          } else if (snapshot.hasError) {
            return AppErrorState(
              message: AppLocalizations.of(context)?.networkError ??
                  'Veuillez vérifier votre connexion internet',
            );
          } else {
            return const SizedBox(
              height: 200.0,
              width: 200.0,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }
}
