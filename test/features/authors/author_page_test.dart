import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/core/service_locator/service_locator.dart';
import 'package:mangatracker/core/services/library_index_service.dart';
import 'package:mangatracker/features/authors/bloc/author_cubit.dart';
import 'package:mangatracker/features/authors/dto/author_details.dto.dart';
import 'package:mangatracker/features/authors/services/author.service.dart';
import 'package:mangatracker/features/authors/views/author_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/views/home_test_harness.dart';

class MockAuthorService extends Mock implements AuthorService {}

final Map<String, dynamic> odaJson = {
  'id': 7,
  'name': 'ODA Eiichiro',
  'actualName': '尾田 栄一郎',
  'associatedNames': ['Oda Eiichirou'],
  'bio': 'Auteur de One Piece.',
  'birthday': 'January 1, 1975',
  'birthplace': 'Kumamoto',
  'genres': ['Action', 'Adventure'],
  'works': [
    {
      'muId': 1,
      'title': 'One Piece',
      'year': 1997,
      'rating': 8.9,
      'type': 'Manga',
    },
    {'muId': 2, 'title': 'Wanted!', 'year': 1998},
  ],
  'worksComplete': true,
};

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test'));

  test('AuthorDetailsDto lit la fiche et ses œuvres', () {
    final author = AuthorDetailsDto.fromJson(odaJson);
    expect(author.name, 'ODA Eiichiro');
    expect(author.works.map((w) => w.title), ['One Piece', 'Wanted!']);
    expect(author.works.first.rating, '8.9');
    expect(author.works.last.rating, 'N/A');
    expect(author.worksComplete, isTrue);
  });

  group('AuthorCubit', () {
    late MockAuthorService service;

    setUp(() => service = MockAuthorService());

    test('fiche chargée depuis le réseau', () async {
      when(
        () => service.fetch(7),
      ).thenAnswer((_) async => AuthorDetailsDto.fromJson(odaJson));
      final cubit = AuthorCubit(authorId: 7, service: service);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state, isA<AuthorLoaded>());
    });

    test('auteur inconnu → introuvable, sans repli sur le cache', () async {
      when(
        () => service.fetch(7),
      ).thenThrow(const AuthorException(AuthorFailure.notFound));
      final cubit = AuthorCubit(authorId: 7, service: service);
      addTearDown(cubit.close);
      await cubit.load();
      expect((cubit.state as AuthorError).notFound, isTrue);
      verifyNever(() => service.cached(any()));
    });

    test('hors ligne → dernière fiche connue, marquée hors ligne', () async {
      when(() => service.fetch(7)).thenThrow(const SocketException('off'));
      when(
        () => service.cached(7),
      ).thenAnswer((_) async => AuthorDetailsDto.fromJson(odaJson));
      final cubit = AuthorCubit(authorId: 7, service: service);
      addTearDown(cubit.close);
      await cubit.load();
      final state = cubit.state as AuthorLoaded;
      expect(state.isOffline, isTrue);
    });
  });

  testWidgets('la page auteur montre la bio et les œuvres', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    getIt.registerSingleton<LibraryIndexService>(LibraryIndexService());
    addTearDown(getIt.reset);
    final service = MockAuthorService();
    when(
      () => service.fetch(7),
    ).thenAnswer((_) async => AuthorDetailsDto.fromJson(odaJson));
    final cubit = AuthorCubit(authorId: 7, service: service);
    addTearDown(cubit.close);

    useTallViewport(tester);
    await tester.pumpWidget(
      frRouterHarness(
        home: AuthorPage(authorId: 7, initialName: 'ODA', cubit: cubit),
      ),
    );
    await pumpFrames(tester);

    expect(find.text('ODA Eiichiro'), findsWidgets);
    expect(find.text('Auteur de One Piece.'), findsOneWidget);
    expect(find.text('2 œuvres'), findsOneWidget);
    expect(find.text('One Piece'), findsOneWidget);
    expect(find.text('Naissance : January 1, 1975'), findsOneWidget);
  });
}
