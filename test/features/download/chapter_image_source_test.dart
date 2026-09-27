import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/download/services/chapter_image_source.dart';

void main() {
  group('ChapterImageSource.pick', () {
    test('Madara : la vraie adresse de data-src bat l\'image d\'attente', () {
      expect(
        ChapterImageSource.pick({
          'src': 'https://site.com/wp-content/themes/madara/images/dflazy.jpg',
          'data-src': ' https://cdn.site.com/manga/95/01.webp ',
        }),
        'https://cdn.site.com/manga/95/01.webp',
      );
    });

    test('src en data: (pixel transparent) → attribut différé', () {
      expect(
        ChapterImageSource.pick({
          'src': 'data:image/gif;base64,R0lGODlhAQABAAAAACw=',
          'data-lazy-src': 'https://cdn.site.com/p2.jpg',
        }),
        'https://cdn.site.com/p2.jpg',
      );
    });

    test('image déjà chargée, sans attribut différé → src', () {
      expect(
        ChapterImageSource.pick({'src': 'https://cdn.site.com/p3.jpg'}),
        'https://cdn.site.com/p3.jpg',
      );
    });

    test('srcset : premier candidat, descripteur de taille retiré', () {
      expect(
        ChapterImageSource.pick({
          'src': 'https://site.com/placeholder.png',
          'srcset': 'https://cdn.site.com/p4-800.jpg 800w, https://cdn.site.com/p4-1600.jpg 1600w',
        }),
        'https://cdn.site.com/p4-800.jpg',
      );
    });

    test('uniquement des images d\'attente → aucune adresse', () {
      expect(
        ChapterImageSource.pick({
          'src': 'https://site.com/img/loading.gif',
          'data-src': '',
        }),
        isNull,
      );
      expect(ChapterImageSource.pick(const {}), isNull);
    });

    test('attribut différé qui est lui-même une image d\'attente → suivant', () {
      expect(
        ChapterImageSource.pick({
          'data-src': 'https://site.com/blank.gif',
          'data-original': 'https://cdn.site.com/p5.png',
        }),
        'https://cdn.site.com/p5.png',
      );
    });
  });

  group('ChapterImageSource.isPlaceholder', () {
    test('reconnaît les images d\'attente usuelles', () {
      for (final url in [
        null,
        '',
        'data:image/png;base64,AAA',
        'about:blank',
        'https://site.com/images/dflazy.jpg',
        'https://site.com/1x1.gif',
        '/assets/spacer.png',
      ]) {
        expect(ChapterImageSource.isPlaceholder(url), isTrue, reason: '$url');
      }
    });

    test('ne confond pas une vraie page avec une image d\'attente', () {
      for (final url in [
        'https://cdn.site.com/manga/95/01.webp',
        'https://i0.wp.com/site.com/chapitre-95/03.jpg?ssl=1',
      ]) {
        expect(ChapterImageSource.isPlaceholder(url), isFalse, reason: url);
      }
    });
  });
}
