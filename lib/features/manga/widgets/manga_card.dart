import 'package:flutter/material.dart';
import 'package:html/parser.dart';

import '../helpers/image.helper.dart';
import '../views/detail.dart';

class MangaCard extends StatelessWidget {
  final String mangaTitle;
  final String muId;
  final String mangaAuthor;
  final String? largeImgPath;
  final String rating;
  final Color themePage = const Color(0xffe0234f);

  const MangaCard({
    super.key,
    required this.mangaTitle,
    required this.muId,
    required this.mangaAuthor,
    this.largeImgPath,
    required this.rating,
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
                    coverPath: largeImgPath,
                  )),
        );
      },
      child: SizedBox(
          child: SizedBox(
              width: 130,
              child: Center(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.center,
                          child: ImageHelper.loadMangaImage(largeImgPath),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            parseFragment(mangaTitle).text!,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.fade,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          mangaAuthor,
                          style:Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      //Espace
                      const SizedBox(width: 10),

                      Text(
                        rating.toString(),
                        style: TextStyle(color: themePage),
                      ),
                    ],
                  )
                ],
              )))),
    );
  }
}
