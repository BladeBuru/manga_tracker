import 'package:flutter/material.dart';
import 'package:html/parser.dart';

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

  const MangaCard({
    super.key,
    required this.mangaTitle,
    required this.muId,
    required this.mangaAuthor,
    this.mediumImgPath,
    this.rating,
    this.lastChapter,
    this.readChapter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                      fontSize: lastChapter != null ? 11 : 12,
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
                    borderRadius: BorderRadius.circular(6.0),
                    color: Colors.grey[200],
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
