import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/manga/widgets/manga_card.dart';

void addMangaCardStory(Dashbook dashbook) {
  dashbook.storiesOf('Manga/MangaCard').add('Par défaut', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('MangaCard')),
        body: Center(
          child: SizedBox(
            height: 200,
            child: MangaCard(
              mangaTitle: 'One Piece',
              muId: 'onepiece',
              mangaAuthor: 'Eiichiro Oda',
              largeImgPath: 'https://cdn.mangaupdates.com/image/i477158.jpg',
              rating: '4.9',
            ),
          ),
        ),
      ),
    );
  }).add('Image not find', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('MangaCard')),
        body: Center(
          child: SizedBox(
            height: 200,
            child: MangaCard(
              mangaTitle: 'One Piece',
              muId: 'onepiece',
              mangaAuthor: 'Eiichiro Oda',
              largeImgPath: 'https://cdn.mangaupcom/image/i477158.jpg',
              rating: '4.9',
            ),
          ),
        ),
      ),
    );
  });
}
