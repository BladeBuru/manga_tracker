import 'package:dashbook/dashbook.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/manga/widgets/manga_row.dart';

void addMangaRowStory(Dashbook dashbook) {
  dashbook.storiesOf('Manga/MangaRow').add('Par défaut', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('MangaRow')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MangaRow(
            mangaName: 'One piece',
            muId: 'mha123',
            mangaAuthor: 'Kohei Horikoshi',
            largeImgPath: 'https://cdn.mangaupdates.com/image/i477158.jpg',
          ),
        ),
      ),
    );
  }).add('Avec un chapitre', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('MangaRow')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MangaRow(
            mangaName: 'One piece',
            muId: 'mha123',
            mangaAuthor: 'Kohei Horikoshi',
            lastChapter: 421,
            largeImgPath: 'https://cdn.mangaupdates.com/image/i477158.jpg',
          ),
        ),
      ),
    );
  }).add('Lue + note', (_) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('MangaRow')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: MangaRow(
            mangaName: 'One piece',
            muId: 'mha123',
            mangaAuthor: 'Kohei Horikoshi',
            lastChapter: 421,
            readChapter: 300,
            rating: '8.59',
            largeImgPath: 'https://cdn.mangaupdates.com/image/i477158.jpg',
          ),
        ),
      ),
    );
  });
}
