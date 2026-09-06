import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mangatracker/core/network/http_service.dart';
import 'package:mangatracker/core/network/network_compat.dart';
import 'package:mangatracker/features/reader/services/reading_position.service.dart';
import 'package:mocktail/mocktail.dart';

import '../../fixtures/fixtures.dart';

class MockHttpService extends Mock implements HttpService {}

/// Synchronisation serveur de la position de lecture.
///
/// Deux exigences dominent : **ne jamais gêner la lecture** (aucun échec ne
/// remonte, rien n'est relancé en boucle) et **ne pas saturer le quota**
/// (60 requêtes/min/utilisateur côté serveur, contre une mesure toutes les
/// 5 s côté lecteur).
void main() {
  late MockHttpService http_;
  late DateTime now;
  late ReadingPositionService service;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'MT_API_URL=https://api.test');
    registerFallbackValue(Uri.parse('https://api.test'));
  });

  setUp(() {
    http_ = MockHttpService();
    now = DateTime.utc(2026, 9, 6, 12);
    service = ReadingPositionService(
      httpService: http_,
      throttle: const Duration(seconds: 10),
      clock: () => now,
    );
  });

  void stubPut(int statusCode, [String body = '']) {
    when(() => http_.putWithAuthTokens(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => http.Response(body, statusCode));
  }

  void stubGet(int statusCode, [String body = '']) {
    when(() => http_.getWithAuthTokens(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, statusCode));
  }

  List<dynamic> capturePut() => verify(() => http_.putWithAuthTokens(
        captureAny(),
        headers: any(named: 'headers'),
        body: captureAny(named: 'body'),
      )).captured;

  group('savePosition — contrat de la requête', () {
    test('PUT /library/reading-position avec muId, chapitre et pourcentage',
        () async {
      stubPut(HttpStatus.ok, loadFixture('reading_position_saved.json'));

      await service.savePosition(12345, 42, 37.5);

      final captured = capturePut();
      expect((captured[0] as Uri).path, '/library/reading-position');
      expect(
        jsonDecode(captured[1] as String),
        {'muId': 12345, 'chapter': 42, 'positionPercent': 37.5},
      );
    });

    test('une position hors bornes ne part même pas sur le réseau', () async {
      stubPut(HttpStatus.ok);

      await service.savePosition(12345, 42, 140);
      await service.savePosition(12345, 42, -1);
      await service.savePosition(12345, -3, 50);
      await service.savePosition(0, 42, 50);

      verifyNever(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
    });
  });

  group('throttle', () {
    test('plusieurs mesures rapprochées ne produisent qu\'un seul envoi',
        () async {
      stubPut(HttpStatus.ok);

      for (var i = 1; i <= 5; i++) {
        await service.savePosition(12345, 42, 10.0 * i);
        now = now.add(const Duration(seconds: 2)); // le lecteur mesure aux 5 s
      }

      verify(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
    });

    test('la fenêtre écoulée, l\'envoi suivant repart', () async {
      stubPut(HttpStatus.ok);

      await service.savePosition(12345, 42, 10);
      now = now.add(const Duration(seconds: 11));
      await service.savePosition(12345, 42, 20);

      verify(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).called(2);
    });

    test('le throttle est par manga, pas global', () async {
      stubPut(HttpStatus.ok);

      await service.savePosition(111, 42, 10);
      await service.savePosition(222, 7, 20);

      verify(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).called(2);
    });

    test('flush envoie immédiatement la dernière position (sortie du lecteur)',
        () async {
      stubPut(HttpStatus.ok);

      await service.savePosition(12345, 42, 10); // envoyée
      await service.savePosition(12345, 42, 20); // retenue
      await service.savePosition(12345, 42, 30); // retenue, écrase la 20
      await service.flush(12345);

      final captured = capturePut();
      expect(captured.length, 4, reason: '2 envois × (uri + body)');
      expect(jsonDecode(captured[3] as String)['positionPercent'], 30,
          reason: 'seule la DERNIÈRE position part, pas les intermédiaires');
    });

    test('flush sans rien en attente ne déclenche aucune requête', () async {
      stubPut(HttpStatus.ok);

      await service.flush(12345);

      verifyNever(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('une position inchangée n\'est pas réenvoyée', () async {
      stubPut(HttpStatus.ok);

      await service.savePosition(12345, 42, 30);
      now = now.add(const Duration(seconds: 30));
      await service.savePosition(12345, 42, 30);

      verify(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).called(1);
    });
  });

  group('hors ligne et erreurs — jamais bloquant, jamais bruyant', () {
    test('un échec réseau ne lève pas et garde la position pour plus tard',
        () async {
      when(() => http_.putWithAuthTokens(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(const SocketException('hors ligne'));

      await expectLater(service.savePosition(12345, 42, 30), completes);
      expect(service.pendingFor(12345)?.positionPercent, 30);
    });

    test('vingt minutes hors ligne ne gardent QUE la dernière position',
        () async {
      when(() => http_.putWithAuthTokens(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(const SocketException('hors ligne'));

      for (var i = 1; i <= 40; i++) {
        await service.savePosition(12345, 42, i.toDouble());
        now = now.add(const Duration(seconds: 30));
      }

      // Une seule position retenue, la plus récente : pas de file d'attente.
      expect(service.pendingFor(12345)?.positionPercent, 40);
    });

    test('429 (quota) garde la position pour un nouvel essai', () async {
      stubPut(HttpStatus.tooManyRequests);

      await service.savePosition(12345, 42, 30);

      expect(service.pendingFor(12345)?.positionPercent, 30);
    });

    test('400 (hors bornes serveur) abandonne au lieu de boucler', () async {
      stubPut(HttpStatus.badRequest);

      await service.savePosition(12345, 42, 30);

      expect(service.pendingFor(12345), isNull);
    });

    test('404 (manga hors bibliothèque) abandonne aussi', () async {
      stubPut(HttpStatus.notFound);

      await service.savePosition(12345, 42, 30);

      expect(service.pendingFor(12345), isNull);
    });

    test('500 garde la position — le serveur peut revenir', () async {
      stubPut(500);

      await service.savePosition(12345, 42, 30);

      expect(service.pendingFor(12345)?.positionPercent, 30);
    });
  });

  group('fetchPosition', () {
    test('200 → position parsée depuis le contrat', () async {
      stubGet(HttpStatus.ok, loadFixture('reading_position.json'));

      final position = await service.fetchPosition(12345);

      expect(position, isNotNull);
      expect(position!.chapter, 42);
      expect(position.positionPercent, 37.5);
      expect(position.updatedAt, DateTime.utc(2026, 9, 6, 10));

      final captured = verify(() => http_.getWithAuthTokens(captureAny(),
          headers: any(named: 'headers'))).captured;
      expect((captured.first as Uri).path, '/library/12345/reading-position');
    });

    test('204 (aucune position) → null, pas un DTO vide', () async {
      stubGet(HttpStatus.noContent);

      expect(await service.fetchPosition(12345), isNull);
    });

    test('404 → null', () async {
      stubGet(HttpStatus.notFound, '{"message":"not in library"}');

      expect(await service.fetchPosition(12345), isNull);
    });

    test('corps illisible → null au lieu d\'une exception', () async {
      stubGet(HttpStatus.ok, 'pas du json');

      expect(await service.fetchPosition(12345), isNull);
    });

    test('serveur injoignable → null, silencieusement', () async {
      when(() => http_.getWithAuthTokens(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('hors ligne'));

      expect(await service.fetchPosition(12345), isNull);
    });
  });

  group('forget / clear', () {
    test('forget empêche de réenvoyer la position d\'un chapitre validé',
        () async {
      when(() => http_.putWithAuthTokens(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(const SocketException('hors ligne'));
      await service.savePosition(12345, 42, 30);
      expect(service.pendingFor(12345), isNotNull);

      service.forget(12345);
      stubPut(HttpStatus.ok);
      clearInteractions(http_); // on ne juge que ce qui suit l'oubli
      await service.flush(12345);

      expect(service.pendingFor(12345), isNull);
      verifyNever(() => http_.putWithAuthTokens(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('clear vide tout — déconnexion sur un appareil partagé', () async {
      when(() => http_.putWithAuthTokens(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenThrow(const SocketException('hors ligne'));
      await service.savePosition(111, 42, 30);
      await service.savePosition(222, 7, 60);

      service.clear();

      expect(service.pendingFor(111), isNull);
      expect(service.pendingFor(222), isNull);
    });
  });
}
