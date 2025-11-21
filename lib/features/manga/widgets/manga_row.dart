import 'package:html/parser.dart';
import '../helpers/image.helper.dart';
import '../views/detail.dart';
import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/reader/views/offline_reader_view.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/features/manga/services/manga.service.dart';

class MangaRow extends StatelessWidget {
  final String mangaName;
  final String muId;
  final String mangaAuthor;
  final num? lastChapter;
  final num? readChapter;
  final String? mediumImgPath;
  final String? rating;
  final VoidCallback? onDetailReturn;
  final bool hasNewChapters;
  final int? newChaptersCount;
  final bool showDownloadedOnly; // Nouveau paramètre

  const MangaRow({
    super.key,
    required this.mangaName,
    required this.muId,
    required this.mangaAuthor,
    this.lastChapter,
    this.readChapter,
    this.rating,
    this.mediumImgPath,
    this.onDetailReturn,
    this.hasNewChapters = false,
    this.newChaptersCount,
    this.showDownloadedOnly = false, // Par défaut false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Vérifier s'il y a des chapitres téléchargés ET si le filtre est activé
        if (showDownloadedOnly) {
          final downloadManager = DownloadManagerService();
          final downloadedChapters = await downloadManager.getDownloadedChapters(int.parse(muId));
          
          if (downloadedChapters.isNotEmpty && context.mounted) {
            // Ouvrir directement le premier chapitre téléchargé
            final sortedChapters = downloadedChapters.toList()..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
            final firstChapter = sortedChapters.first;
            
            // Récupérer le titre du manga
            final mangaService = getIt<MangaService>();
            String mangaTitle = mangaName;
            try {
              final mangaDetail = await mangaService.getMangaDetail(muId);
              mangaTitle = mangaDetail.title;
            } catch (e) {
              // Utiliser le nom fourni si erreur
            }
            
            if (context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OfflineReaderView(
                    muId: int.parse(muId),
                    chapterNumber: firstChapter.chapterNumber,
                    mangaTitle: mangaTitle,
                  ),
                ),
              );
              if (onDetailReturn != null) {
                onDetailReturn!();
              }
              return;
            }
          }
        }
        
        // Sinon, aller sur le détail normal
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Detail(
                    muId: muId,
                    mangaTitle: mangaName,
                    coverPath: mediumImgPath,
                  )),
        );
        if (onDetailReturn != null) {
          onDetailReturn!();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 0.0, bottom: 20.0, right: 2.0, left: 2.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.circularXl,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200.withValues(alpha: 0.8),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.grey.shade100.withValues(alpha: 0.5),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl),
                    bottomLeft: Radius.circular(AppRadius.xl),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 100,
                        child: ImageHelper.loadMangaImage(
                          mediumImgPath,
                          width: 80,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Badge pour nouveaux chapitres
                      if (hasNewChapters)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fiber_new,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                if (newChaptersCount != null && newChaptersCount! > 0) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    newChaptersCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          parseFragment(mangaName).text!,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          mangaAuthor,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        if (lastChapter != null) ...[
                          const SizedBox(height: 7),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.circularLg,
                              color: Colors.grey[200],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              child: Text(
                                readChapter != null
                                    ? '$readChapter / ${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}'
                                    : '${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (rating != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              rating!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
