import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:mangatracker/core/theme/app_radius.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/reader/views/offline_reader_view.dart';

import '../helpers/image.helper.dart';
import '../views/detail.dart';

class MangaCard extends StatelessWidget {
  final String mangaTitle;
  final String muId;
  final String mangaAuthor;
  final String? mediumImgPath;
  final String? rating;
  final num? lastChapter;
  final num? readChapter;
  final bool showDownloadedOnly; // Nouveau paramètre

  const MangaCard({
    super.key,
    required this.mangaTitle,
    required this.muId,
    required this.mangaAuthor,
    this.mediumImgPath,
    this.rating,
    this.lastChapter,
    this.readChapter,
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
            // Trier les chapitres téléchargés par numéro
            final sortedChapters = downloadedChapters.toList()..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
            
            // Déterminer le chapitre à ouvrir : priorité au prochain chapitre non lu ou reprise de lecture
            int targetChapterNumber;
            if (readChapter != null && readChapter! > 0) {
              final lastReadChapterNum = readChapter!.toInt();
              
              // Vérifier d'abord si le dernier chapitre lu est téléchargé et a une position de scroll sauvegardée
              final lastReadChapter = sortedChapters.where(
                (ch) => ch.chapterNumber == lastReadChapterNum && ch.scrollPosition != null && ch.scrollPosition! > 0,
              ).firstOrNull;
              
              if (lastReadChapter != null) {
                // Reprendre la lecture du dernier chapitre lu là où on s'est arrêté
                targetChapterNumber = lastReadChapterNum;
              } else {
                // Chercher le prochain chapitre non lu (dernier lu + 1)
                final nextChapter = lastReadChapterNum + 1;
                final nextChapterDownloaded = sortedChapters.where(
                  (ch) => ch.chapterNumber == nextChapter,
                ).firstOrNull;
                
                if (nextChapterDownloaded != null) {
                  // Le prochain chapitre est téléchargé, l'utiliser
                  targetChapterNumber = nextChapter;
                } else {
                  // Sinon, chercher le chapitre téléchargé le plus proche après le dernier lu
                  final nextAvailable = sortedChapters.where(
                    (ch) => ch.chapterNumber > lastReadChapterNum,
                  ).firstOrNull;
                  targetChapterNumber = nextAvailable?.chapterNumber ?? sortedChapters.first.chapterNumber;
                }
              }
            } else {
              // Aucun chapitre lu, ouvrir le premier téléchargé
              targetChapterNumber = sortedChapters.first.chapterNumber;
            }
            
            // En mode téléchargé uniquement, utiliser directement le titre fourni
            // pour éviter toute requête réseau qui pourrait ralentir ou échouer
            if (context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OfflineReaderView(
                    muId: int.parse(muId),
                    chapterNumber: targetChapterNumber,
                    mangaTitle: mangaTitle, // Utiliser directement le titre fourni
                  ),
                ),
              );
              return;
            }
          }
        }
        
        // Sinon, aller sur le détail normal
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Detail(
                    muId: muId,
                    mangaTitle: mangaTitle,
                    coverPath: mediumImgPath,
                  )),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: AppRadius.circularXl,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.circularXl,
                child: ImageHelper.loadMangaImage(
                  mediumImgPath,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: lastChapter != null ? 5 : 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    parseFragment(mangaTitle).text!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: lastChapter != null ? 12 : 14,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
            if (lastChapter != null) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.circularSm,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    child: Text(
                      readChapter != null
                          ? '$readChapter / ${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}'
                          : '${lastChapter ?? 0} ${lastChapter! > 1 ? "chapitres" : "chapitre"}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: lastChapter != null ? 3 : 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      mangaAuthor,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: lastChapter != null ? 9 : 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (rating != null && rating!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                      size: lastChapter != null ? 10 : 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: lastChapter != null ? 9 : 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
