import 'package:flutter/material.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/library/services/library.service.dart';
import 'package:mangatracker/features/manga/dto/reading_status.enum.dart';
import 'package:mangatracker/features/manga/widgets/manga_row.dart';
import '../../auth/exceptions/invalid_credentials.exception.dart';
import '../../auth/views/login.view.dart';
import '../../manga/dto/manga_quick_view.dto.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final LibraryService libraryService = getIt<LibraryService>();
  late Future<List<MangaQuickViewDto>> savedMangas;
  final Map<ReadingStatus, bool> _isExpanded = {
    ReadingStatus.reading: true,
    ReadingStatus.readLater: true,
    ReadingStatus.caughtUp: true,
    ReadingStatus.completed: true,
  };

  @override
  void initState() {
    super.initState();
    try {
      savedMangas = libraryService.getUserSavedMangas();
    } on InvalidCredentialsException {
      if (context.mounted) {
        redirectToLoginPage();
      }
    }
  }

  void reloadMangas() {
    setState(() {
      savedMangas = libraryService.getUserSavedMangas();
    });
  }

  void redirectToLoginPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginView()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MangaQuickViewDto>>(
      future: savedMangas,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erreur lors du chargement des mangas.'));
        }

        final mangas = snapshot.data ?? [];

        final groupedMangas = <ReadingStatus, List<MangaQuickViewDto>>{};
        for (var status in ReadingStatus.values) {
          groupedMangas[status] = mangas.where((m) => m.readingStatus == status).toList();
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children:[
          const SizedBox(height: 50.0),
          ...groupedMangas.entries.map((entry) {
            final status = entry.key;
            final items = entry.value;
            final isExpanded = _isExpanded[status] ?? true;

            return ExpansionTile(
              title: Text(status.label),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (value) {
                setState(() {
                  _isExpanded[status] = value;
                });
              },
              children: items.isNotEmpty
                  ? items.map((manga) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: MangaRow(
                  muId: manga.muId.toString(),
                  mangaName: manga.title,
                  mangaAuthor: manga.year,
                   lastChapter: manga.totalChapters,
                  readChapter: manga.readChapters,
                  largeImgPath: manga.largeCoverUrl,
                  rating: manga.rating,
                   onDetailReturn: reloadMangas
                ),
              )).toList()
                  : [const Padding(padding: EdgeInsets.all(8.0), child: Text("Aucun manga."))],
            );
          }).toList(),
          ],
        );
      },
    );
  }
}
