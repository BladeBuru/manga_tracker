import 'package:html/parser.dart';
import '../helpers/image.helper.dart';
import '../views/detail.dart';
import 'package:flutter/material.dart';
import 'package:mangatracker/core/theme/app_radius.dart';

class MangaRow extends StatelessWidget {
  final String mangaName;
  final String muId;
  final String mangaAuthor;
  final num? lastChapter;
  final num? readChapter;
  final String? mediumImgPath;
  final String? rating;
  final VoidCallback? onDetailReturn;

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
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
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
                  child: SizedBox(
                    width: 80,
                    height: 100,
                    child: ImageHelper.loadMangaImage(
                      mediumImgPath,
                      width: 80,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
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
