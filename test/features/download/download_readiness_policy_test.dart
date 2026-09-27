import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/download/services/download_readiness_policy.dart';

ProbedImage _lazyPage(int n) => ProbedImage(
      attributes: {
        'src': 'https://site.com/dflazy.jpg',
        'data-src': 'https://cdn.site.com/95/$n.webp',
      },
      width: 0,
    );

const _logo = ProbedImage(
  attributes: {'src': 'https://site.com/logo.png'},
  width: 120,
);

DownloadPageProbe _probe({
  String readyState = 'complete',
  int? urlChapter = 95,
  List<ProbedImage> images = const [],
}) =>
    DownloadPageProbe(
      readyState: readyState,
      urlChapter: urlChapter,
      images: images,
    );

void main() {
  const policy = DownloadReadinessPolicy();
  const early = Duration(seconds: 2);

  test('le logo et les avatars ne sont pas des pages de chapitre', () {
    expect(_probe(images: [_logo]).chapterImageCount, 0);
    expect(
      _probe(images: [
        _logo,
        const ProbedImage(
            attributes: {'src': 'https://cdn.site.com/p1.jpg'}, width: 448),
        _lazyPage(2),
      ]).chapterImageCount,
      2,
    );
  });

  test('page de vérification ou page vide → on attend (plus de chapitre vide)',
      () {
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(images: [_logo]),
        previous: _probe(images: [_logo]),
        elapsed: early,
      ),
      DownloadReadiness.wait,
    );
  });

  test('page encore en chargement → on attend', () {
    final images = [_lazyPage(1), _lazyPage(2)];
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(readyState: 'interactive', images: images),
        previous: _probe(readyState: 'interactive', images: images),
        elapsed: early,
      ),
      DownloadReadiness.wait,
    );
  });

  test('nombre de pages encore en hausse → on attend qu\'il se stabilise', () {
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(images: [_lazyPage(1), _lazyPage(2), _lazyPage(3)]),
        previous: _probe(images: [_lazyPage(1)]),
        elapsed: early,
      ),
      DownloadReadiness.wait,
    );
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(images: [_lazyPage(1)]),
        previous: null,
        elapsed: early,
      ),
      DownloadReadiness.wait,
      reason: 'Un seul relevé ne prouve pas la stabilité.',
    );
  });

  test('page complète, pages stables → prête', () {
    final images = [_lazyPage(1), _lazyPage(2), _lazyPage(3)];
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(images: images),
        previous: _probe(images: images),
        elapsed: early,
      ),
      DownloadReadiness.ready,
    );
  });

  test('redirigé vers un autre chapitre → échec, jamais enregistré à tort',
      () {
    final images = [_lazyPage(1)];
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(urlChapter: 96, images: images),
        previous: _probe(urlChapter: 96, images: images),
        elapsed: early,
      ),
      DownloadReadiness.wrongChapter,
    );
  });

  test('délai dépassé : ce qu\'il y a si au moins une page, sinon abandon', () {
    final late = policy.timeout;
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(readyState: 'interactive', images: [_lazyPage(1)]),
        previous: null,
        elapsed: late,
      ),
      DownloadReadiness.ready,
    );
    expect(
      policy.decide(
        expectedChapter: 95,
        current: _probe(images: [_logo]),
        previous: _probe(images: [_logo]),
        elapsed: late,
      ),
      DownloadReadiness.timedOut,
    );
  });
}
