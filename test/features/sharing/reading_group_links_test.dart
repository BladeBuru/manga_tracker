import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/sharing/dto/reading_group.dto.dart';
import 'package:mangatracker/features/sharing/widgets/reading_group_links.dart';
import 'package:mangatracker/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReadingGroupMemberDto member(int id, {int? read, String? link}) =>
    ReadingGroupMemberDto(
      userId: id,
      username: 'user$id',
      readChapters: read,
      customLink: link,
      joinedAt: DateTime(2026),
    );

ReadingGroupDto group(List<ReadingGroupMemberDto> members) => ReadingGroupDto(
  id: 1,
  ownerId: 1,
  mangaMuId: '42',
  mangaTitle: 'One Piece',
  createdAt: DateTime(2026),
  members: members,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mon lien d\'abord : il est déjà sur mon prochain chapitre', () async {
    final links = ReadingGroupLinks(
      group: group([
        member(1, read: 10, link: 'https://moi.example/op/chapitre-11'),
        member(2, read: 30, link: 'https://ami.example/op/chapitre-31'),
      ]),
      currentUserId: 1,
    );
    expect(links.hasAnyLink, isTrue);
    expect(await links.linkToCopy(), 'https://moi.example/op/chapitre-11');
  });

  test(
    'sans lien à moi : celui de l\'ami, adapté à MON prochain chapitre',
    () async {
      final links = ReadingGroupLinks(
        group: group([
          member(1, read: 10),
          member(2, read: 30, link: 'https://ami.example/op/chapitre-31'),
        ]),
        currentUserId: 1,
      );
      expect(links.targetChapter(), 11);
      expect(await links.linkToCopy(), 'https://ami.example/op/chapitre-11');
    },
  );

  test(
    'lien de l\'ami non adaptable : copié brut, sans annoncer de chapitre',
    () async {
      final links = ReadingGroupLinks(
        group: group([
          member(1, read: 10),
          member(2, read: 30, link: 'https://ami.example/lecteur'),
        ]),
        currentUserId: 1,
      );
      final target = await links.copyTarget();
      expect(target?.link, 'https://ami.example/lecteur');
      expect(target?.adaptedToChapter, isFalse);
    },
  );

  test('personne n\'a de lien : action masquée', () {
    final links = ReadingGroupLinks(
      group: group([member(1), member(2)]),
      currentUserId: 1,
    );
    expect(links.hasAnyLink, isFalse);
  });

  testWidgets('« Copier le lien de lecture » remplit le presse-papiers', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final links = ReadingGroupLinks(
      group: group([
        member(1, read: 4),
        member(2, read: 9, link: 'https://ami.example/op/chapitre-10'),
      ]),
      currentUserId: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed: () => copyReadingGroupLink(context, links),
                  child: const Text('copier'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('copier'));
    await tester.pumpAndSettle();

    expect(copied, 'https://ami.example/op/chapitre-5');
    expect(find.text('Lien copié — chapitre 5'), findsOneWidget);
  });
  test('utilisateur non identifié : aucun chapitre visé (plus de « 1 » muet)',
      () async {
    final links = ReadingGroupLinks(
      group: group([
        member(1, read: 10),
        member(2, read: 30, link: 'https://ami.example/op/chapitre-31'),
      ]),
      currentUserId: null,
    );
    expect(links.isMeKnown, isFalse);
    expect(links.targetChapter(), isNull);
    expect(await links.copyTarget(), isNull);
    expect(await links.adaptedFriendLink(), isNull);
  });

  test('mon lien est recalé sur mon prochain chapitre', () async {
    // Progression mise à jour à 124 dans « Ma progression » : le lien
    // enregistré pointe encore sur l'ancien chapitre.
    final links = ReadingGroupLinks(
      group: group([
        member(1, read: 124, link: 'https://moi.example/op/chapitre-106'),
      ]),
      currentUserId: 1,
    );
    final target = await links.copyTarget();
    expect(target?.link, 'https://moi.example/op/chapitre-125');
    expect(target?.adaptedToChapter, isTrue);
  });

  Widget app(void Function(BuildContext) onTap) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('copier'),
        ),
      ),
    ),
  );

  testWidgets('groupe relu avant le calcul du chapitre visé', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    // Affiché : 4 lus (données vieilles de 30 s). Serveur : 9 lus.
    final stale = ReadingGroupLinks(
      group: group([
        member(1, read: 4),
        member(2, read: 12, link: 'https://ami.example/op/chapitre-13'),
      ]),
      currentUserId: 1,
    );
    final fresh = group([
      member(1, read: 9),
      member(2, read: 12, link: 'https://ami.example/op/chapitre-13'),
    ]);

    await tester.pumpWidget(app(
      (context) => copyReadingGroupLink(
        context,
        stale,
        refresh: () async => fresh,
      ),
    ));
    await tester.tap(find.text('copier'));
    await tester.pumpAndSettle();

    expect(copied, 'https://ami.example/op/chapitre-10');
    expect(find.text('Lien copié — chapitre 10'), findsOneWidget);
  });

  testWidgets('presse-papiers refusé : message d\'erreur et lien affiché',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'denied');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final links = ReadingGroupLinks(
      group: group([
        member(1, read: 4, link: 'https://moi.example/lecteur'),
      ]),
      currentUserId: 1,
    );

    await tester.pumpWidget(
      app((context) => copyReadingGroupLink(context, links)),
    );
    await tester.tap(find.text('copier'));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de copier le lien sur cet appareil.'),
      findsOneWidget,
    );
    expect(find.text('Copie impossible — voici le lien'), findsOneWidget);
    expect(find.text('https://moi.example/lecteur'), findsOneWidget);
  });
}
