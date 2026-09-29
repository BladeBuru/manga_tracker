import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/manga/dto/manga_quick_view.dto.dart';
import 'package:mangatracker/features/reader/services/last_site_link_policy.dart';

MangaQuickViewDto entry(num muId, {String? link, DateTime? readAt}) =>
    MangaQuickViewDto(
      muId: muId,
      title: 'Titre $muId',
      year: '2020',
      rating: '8',
      customLink: link,
      currentPositionUpdatedAt: readAt,
    );

void main() {
  const policy = LastSiteLinkPolicy();

  test('prend la lecture la plus récente qui a un lien', () {
    final pick = policy.pick([
      entry(
        1,
        link: 'https://www.scans.example/manga/a/chapitre-3',
        readAt: DateTime(2026, 9, 1),
      ),
      entry(
        2,
        link: 'https://autre.example/b/12',
        readAt: DateTime(2026, 9, 20),
      ),
      entry(3, readAt: DateTime(2026, 9, 29)),
    ], excludeMuId: 99);

    expect(pick?.sourceTitle, 'Titre 2');
    expect(pick?.link, 'https://autre.example/b/12');
    expect(pick?.siteRoot, 'https://autre.example/');
    expect(pick?.host, 'autre.example');
  });

  test('sans position de lecture : ordre de la bibliothèque', () {
    final pick = policy.pick([
      entry(1),
      entry(2, link: 'https://www.scans.example/x'),
      entry(3, link: 'https://z.example/y'),
    ]);
    expect(pick?.host, 'scans.example');
    expect(pick?.siteRoot, 'https://www.scans.example/');
  });

  test(
    'ignore le titre en cours et les liens qui ne sont pas des adresses web',
    () {
      expect(
        policy.pick([
          entry(1, link: 'https://site.example/a'),
          entry(2, link: 'pas un lien'),
          entry(3, link: 'ftp://site.example/a'),
        ], excludeMuId: 1),
        isNull,
      );
    },
  );

  test('le lien est lu depuis le cache de la bibliothèque (customLink)', () {
    final dto = MangaQuickViewDto.fromJson({
      'muId': 5,
      'title': 't',
      'year': 2020,
      'customLink': 'https://site.example/t/1',
    });
    expect(dto.customLink, 'https://site.example/t/1');
    expect(
      MangaQuickViewDto.fromJson(dto.toJson()).customLink,
      'https://site.example/t/1',
    );
    expect(
      dto.copyWith(hasNewChapters: true).customLink,
      'https://site.example/t/1',
    );
  });
}
