import 'package:flutter_test/flutter_test.dart';

import 'package:mangatracker/features/manga/services/custom_selectors.service.dart';
import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';

/// Fake service : renvoie des patterns d'URL fixes par domaine,
/// sans toucher à SharedPreferences.
class _FakeSelectorsService extends CustomSelectorsService {
  _FakeSelectorsService(this._patternsByDomain);

  final Map<String, List<CustomSelector>> _patternsByDomain;

  @override
  Future<List<CustomSelector>> getUrlPatternsForDomain(String domain) async =>
      _patternsByDomain[domain] ?? const [];
}

CustomSelector _urlPattern(String domain, String selector) => CustomSelector(
      id: 'test-$domain',
      domain: domain,
      selector: selector,
      type: SelectorType.urlPattern,
    );

void main() {
  const raijinUrl =
      'https://raijin-scans.fr/manga/the-great-mage-returns-after-4000-years/190/';

  setUp(() => ChapterLinkResolver.init(null));

  group('extractChapter — fallback segment numérique isolé', () {
    test('raijin-scans : /manga/<slug-4000-years>/190/ -> 190', () async {
      expect(await ChapterLinkResolver.extractChapter(raijinUrl), 190);
    });

    test('raijin-scans (sync) : /manga/<slug-4000-years>/190/ -> 190', () {
      expect(ChapterLinkResolver.extractChapterSync(raijinUrl), 190);
    });

    test('piège slug : page série sans segment numérique -> null (jamais 4000)',
        () async {
      const seriesUrl =
          'https://raijin-scans.fr/manga/the-great-mage-returns-after-4000-years/';
      expect(await ChapterLinkResolver.extractChapter(seriesUrl), isNull);
      expect(ChapterLinkResolver.extractChapterSync(seriesUrl), isNull);
    });

    test('nombre pas en fin d\'URL : /190/chapter/blablabla -> 190', () async {
      const url = 'https://scan.example.com/190/chapter/blablabla';
      expect(await ChapterLinkResolver.extractChapter(url), 190);
    });

    test('plusieurs segments numériques : le DERNIER gagne', () async {
      const url = 'https://scan.example.com/lecture/42/777';
      expect(await ChapterLinkResolver.extractChapter(url), 777);
    });
  });

  group('extractChapter — ordre de détection', () {
    test('sélecteur custom prioritaire sur le fallback', () async {
      ChapterLinkResolver.init(_FakeSelectorsService({
        'custom.site': [_urlPattern('custom.site', r'lecture/(\d+)')],
      }));
      // Le fallback donnerait 777 (dernier segment) ; le custom doit gagner.
      const url = 'https://custom.site/lecture/42/777';
      expect(await ChapterLinkResolver.extractChapter(url), 42);
    });

    test('patterns connus prioritaires sur le fallback', () async {
      // Le fallback donnerait 5 (segment isolé) ; le pattern connu doit gagner.
      const url = 'https://scan.example.com/5/spyxfamily-chapitre-113';
      expect(await ChapterLinkResolver.extractChapter(url), 113);
    });
  });

  group('extractChapter — non-régression patterns connus', () {
    test('sushiscan : spyxfamily-chapitre-113 -> 113', () async {
      const url = 'https://sushiscan.net/spyxfamily-chapitre-113/';
      expect(await ChapterLinkResolver.extractChapter(url), 113);
      expect(ChapterLinkResolver.extractChapterSync(url), 113);
    });

    test('webtoons : ?episode_no=3 -> 3', () async {
      const url =
          'https://www.webtoons.com/fr/fantasy/tower-of-god/ep-3/viewer?title_no=95&episode_no=3';
      expect(await ChapterLinkResolver.extractChapter(url), 3);
    });

    test('/manga/22 -> 22', () async {
      const url = 'https://scan.example.com/manga/22';
      expect(await ChapterLinkResolver.extractChapter(url), 22);
    });

    test('c120 -> 120', () async {
      const url = 'https://lelscan.net/scan-one-piece-c120/';
      expect(await ChapterLinkResolver.extractChapter(url), 120);
    });
  });

  group('extractChapter — négatifs (anti-faux-positifs)', () {
    test('URL de blog datée /2024/05/mon-article -> null', () async {
      const url = 'https://blog.example.com/2024/05/mon-article';
      expect(await ChapterLinkResolver.extractChapter(url), isNull);
      expect(ChapterLinkResolver.extractChapterSync(url), isNull);
    });

    test('URL sans nombre -> null', () async {
      const url = 'https://example.com/about';
      expect(await ChapterLinkResolver.extractChapter(url), isNull);
    });

    test('segment de plus de 6 chiffres (id technique) -> null', () async {
      const url = 'https://scan.example.com/view/1234567';
      expect(await ChapterLinkResolver.extractChapter(url), isNull);
    });
  });

  group('buildUrlForChapter — remplacement du segment isolé', () {
    test('raijin-scans : /190/ devient /191/', () async {
      expect(
        await ChapterLinkResolver.buildUrlForChapter(raijinUrl, 191),
        'https://raijin-scans.fr/manga/the-great-mage-returns-after-4000-years/191/',
      );
    });

    test('raijin-scans (sync) : /190/ devient /191/', () {
      expect(
        ChapterLinkResolver.buildUrlForChapterSync(raijinUrl, 191),
        'https://raijin-scans.fr/manga/the-great-mage-returns-after-4000-years/191/',
      );
    });

    test('nombre pas en fin d\'URL : /190/chapter/blablabla -> /191/...', () async {
      const url = 'https://scan.example.com/190/chapter/blablabla';
      expect(
        await ChapterLinkResolver.buildUrlForChapter(url, 191),
        'https://scan.example.com/191/chapter/blablabla',
      );
    });

    test('URL datée sans candidat -> null (pas de fausse route)', () async {
      const url = 'https://blog.example.com/2024/05/mon-article';
      expect(await ChapterLinkResolver.buildUrlForChapter(url, 2), isNull);
    });

    test('non-régression : chapitre-113 -> chapitre-114', () async {
      const url = 'https://sushiscan.net/spyxfamily-chapitre-113/';
      expect(
        await ChapterLinkResolver.buildUrlForChapter(url, 114),
        'https://sushiscan.net/spyxfamily-chapitre-114/',
      );
    });

    test('non-régression : ?episode_no=3 -> ?episode_no=4', () async {
      const url =
          'https://www.webtoons.com/fr/fantasy/tower-of-god/ep-3/viewer?title_no=95&episode_no=3';
      final result = await ChapterLinkResolver.buildUrlForChapter(url, 4);
      expect(result, contains('episode_no=4'));
      expect(result, contains('title_no=95'));
    });
  });
}
