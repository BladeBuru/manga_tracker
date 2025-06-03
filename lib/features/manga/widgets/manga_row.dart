import 'package:html/parser.dart';

import '../../../core/theme/app_colors.dart';
import '../helpers/image.helper.dart';
import '../views/detail.dart';
import 'package:flutter/material.dart';

class MangaRow extends StatelessWidget {
  final String mangaName;
  final String muId;
  final String mangaAuthor;
  final num? lastChapter;
  final num? readChapter;
  final String? largeImgPath;
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
    this.largeImgPath,
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
                    coverPath: largeImgPath,
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                spreadRadius: 4,
                blurRadius: 2,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 80,
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Align(
                      alignment: Alignment.center,
                      child: ImageHelper.loadMangaImage(largeImgPath),
                    ),
                  ),
                ),
                Flexible(
                  child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 15, right: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      parseFragment(mangaName).text!,
                                      overflow: TextOverflow.fade,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    mangaAuthor,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w300),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      color: Colors.grey[200],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 1, bottom: 1, right: 5, left: 5),
                                      child: Text(
                                        readChapter != null
                                            ? 'Chapitre $readChapter / $lastChapter'
                                            : 'Chapitre ${lastChapter ?? 0 }',
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                if (rating != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Row(
                      children: [
                         Icon(Icons.star, color: AppColors.primary, size: 14),
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
