import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/chapter_commit_policy.dart';
import 'package:mangatracker/features/reader/services/webview_navigation_service.dart';
import 'package:mangatracker/features/reader/utils/chapter_link_resolver.dart';

void main() {
  const classifier = ChapterChangeClassifier();

  group('ChapterChangeClassifier.classify', () {
    test('aucun chapitre suivi : premier chapitre détecté', () {
      final r = classifier.classify(12, null);
      expect(r.changeType, ChapterChangeType.firstDetected);
      expect(r.newChapter, 12);
      expect(r.previousChapter, isNull);
    });

    test('N -> N+1 : chapitre suivant', () {
      final r = classifier.classify(134, 133);
      expect(r.changeType, ChapterChangeType.nextChapter);
      expect(r.previousChapter, 133);
    });

    test('N -> N+k (k > 1) : saut vers l\'avant', () {
      expect(classifier.classify(140, 134).changeType,
          ChapterChangeType.jumpForward);
    });

    test('N -> M < N : retour en arrière', () {
      expect(classifier.classify(3, 7).changeType,
          ChapterChangeType.jumpBackward);
    });

    test('même chapitre : aucun changement', () {
      expect(classifier.classify(7, 7).changeType, ChapterChangeType.noChange);
    });

    test('se traduit dans le vocabulaire de ChapterCommitPolicy', () {
      expect(ChapterChangeType.nextChapter.asTransition,
          ChapterTransition.nextChapter);
      expect(ChapterChangeType.firstDetected.asTransition,
          ChapterTransition.firstDetected);
    });
  });

  group('WebViewNavigationService — chapitre lu dans la page', () {
    final service = WebViewNavigationService();
    const origin = 'aniverse.fr';
    final aniverse2 = Uri.parse(
        'https://aniverse.fr/read/chainsaw-man/0b7f3d2e-9a41-4c55-8d1e-7f6a5b4c3d2e');

    setUp(() => ChapterLinkResolver.init(null));

    test('URL sans numéro : le chapitre de la page est classé', () async {
      final r = await service.detectPageChapterChange(
        aniverse2,
        origin,
        pageChapter: 2,
        currentChapter: 1,
      );
      expect(r?.changeType, ChapterChangeType.nextChapter);
      expect(r?.previousChapter, 1);
    });

    test('URL avec numéro : la page est ignorée (l\'URL reste prioritaire)',
        () async {
      final r = await service.detectPageChapterChange(
        Uri.parse('https://sushiscan.net/spyxfamily-chapitre-113/'),
        'sushiscan.net',
        pageChapter: 999,
        currentChapter: 112,
      );
      expect(r, isNull);
    });

    test('autre domaine : rien', () async {
      final r = await service.detectPageChapterChange(
        Uri.parse('https://ads.example.com/read/x'),
        origin,
        pageChapter: 2,
        currentChapter: 1,
      );
      expect(r, isNull);
    });

    test('la détection par URL ne voit aucun chapitre dans un UUID', () async {
      expect(await service.detectChapterChange(aniverse2, origin, 1), isNull);
    });
  });
}
