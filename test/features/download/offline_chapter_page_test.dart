import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mangatracker/features/download/services/offline_chapter_page.dart';

void main() {
  group('OfflineChapterPage.chapterImages', () {
    test('Madara : seules les pages du chapitre, dans l\'ordre (pas le logo)',
        () {
      final doc = html_parser.parse('''
        <html><body>
          <header><img src="images/001_logo.png"></header>
          <div class="reading-content">
            <div class="page-break"><img src="images/002_01.webp"></div>
            <div class="page-break"><img src="images/003_02.webp"></div>
            <div class="page-break"><img src="images/004_03.webp"></div>
            <div class="page-break"><img src="images/005_04.webp"></div>
          </div>
          <div class="comments"><img src="images/006_avatar.jpg"></div>
        </body></html>''');

      expect(OfflineChapterPage.chapterImages(doc), [
        'images/002_01.webp',
        'images/003_02.webp',
        'images/004_03.webp',
        'images/005_04.webp',
      ]);
    });

    test('les images non enregistrées (distantes) sont ignorées', () {
      final doc = html_parser.parse('''
        <div id="reader">
          <img src="images/001_a.jpg"><img src="https://cdn/x.jpg">
          <img src="images/002_b.jpg"><img src="images/003_c.jpg">
        </div>''');
      expect(OfflineChapterPage.chapterImages(doc),
          ['images/001_a.jpg', 'images/002_b.jpg', 'images/003_c.jpg']);
    });

    test('roman / page textuelle (moins de 3 images) → HTML complet gardé',
        () {
      final doc = html_parser.parse('''
        <article><p>Chapitre en texte…</p><img src="images/001_cover.jpg"></article>''');
      expect(OfflineChapterPage.chapterImages(doc), isNull);
    });
  });

  group('OfflineChapterPage.build', () {
    test('page minimale : les images et rien d\'autre', () {
      final html = OfflineChapterPage.build(
        title: 'Chapitre 95',
        baseHref: 'file:///data/chap95/',
        images: ['images/001_a.jpg', 'images/002_b.jpg'],
      );
      expect(html, contains('<base href="file:///data/chap95/">'));
      expect(html, contains('<img src="images/001_a.jpg"'));
      expect(html, contains('<img src="images/002_b.jpg"'));
      expect(html.indexOf('001_a'), lessThan(html.indexOf('002_b')));
      expect(html, isNot(contains('<script')));
    });

    test('les valeurs sont échappées', () {
      final html = OfflineChapterPage.build(
        title: 'A & B "<x>"',
        baseHref: 'file:///d/',
        images: ['images/a"b.jpg'],
      );
      expect(html, contains('A &amp; B &quot;&lt;x&gt;&quot;'));
      expect(html, contains('images/a&quot;b.jpg'));
    });
  });
}
