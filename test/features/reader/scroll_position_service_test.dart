import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangatracker/features/reader/services/reading_position.service.dart';
import 'package:mangatracker/features/reader/services/scroll_position_service.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockWebViewController extends Mock implements InAppWebViewController {}

class MockReadingPositionService extends Mock
    implements ReadingPositionService {}

/// Fiabilité de la position de lecture locale.
///
/// Deux défauts confirmés le 2026-09-06 sont verrouillés ici :
///  1. **la zone « fin de chapitre » n'était pas sauvegardée** (retour anticipé
///     au-delà de 85 %), si bien qu'un « Non » à la question de fin renvoyait
///     l'utilisateur sur une position périmée ;
///  2. **les garde-fous de restauration étaient inertes sur Android**, parce
///     qu'ils lisaient le retour de `evaluateJavascript` comme du texte alors
///     que le plugin y rend une `Map`.
void main() {
  late MockWebViewController controller;
  late MockReadingPositionService remote;
  late ScrollPositionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = MockWebViewController();
    remote = MockReadingPositionService();
    service = ScrollPositionService(positionService: remote);

    when(() => remote.savePosition(any(), any(), any()))
        .thenAnswer((_) async {});
    when(() => remote.flush(any())).thenAnswer((_) async {});
    when(() => remote.forget(any())).thenReturn(null);
  });

  /// Réponses de la WebView, dans les DEUX formes que produisent les
  /// plateformes : `asMap` pour Android, `asJsonString` pour iOS / web.
  void stubMeasure({
    required double scrollY,
    required double viewportHeight,
    required double documentHeight,
    required bool asJsonString,
    bool ready = true,
  }) {
    final payload = <String, dynamic>{
      'scrollY': scrollY,
      'viewportHeight': viewportHeight,
      'documentHeight': documentHeight,
      'ready': ready,
    };
    when(() => controller.evaluateJavascript(
          source: any(named: 'source'),
          contentWorld: any(named: 'contentWorld'),
        )).thenAnswer((invocation) async {
      final source = invocation.namedArguments[#source] as String;
      if (source.startsWith('window.scrollTo')) return null;
      if (source.contains('querySelectorAll')) return true;
      return asJsonString ? jsonEncode(payload) : payload;
    });
  }

  group('sauvegarde — quelle que soit la profondeur', () {
    for (final asJsonString in [false, true]) {
      final platform = asJsonString ? 'iOS / web (chaîne JSON)' : 'Android (Map)';

      test('$platform : la position est mesurée et écrite', () async {
        stubMeasure(
          scrollY: 2000,
          viewportHeight: 800,
          documentHeight: 4800,
          asJsonString: asJsonString,
        );

        final percent = await service.saveScrollPosition(controller, 12345, 42);

        expect(percent, 50, reason: '2000 / (4800 - 800)');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_42'), 2000);
      });

      test('$platform : la position part au serveur', () async {
        stubMeasure(
          scrollY: 2000,
          viewportHeight: 800,
          documentHeight: 4800,
          asJsonString: asJsonString,
        );

        await service.saveScrollPosition(controller, 12345, 42);

        verify(() => remote.savePosition(12345, 42, 50)).called(1);
      });
    }

    test('au-delà de 85 %, la position est DÉSORMAIS sauvegardée', () async {
      // Non-régression : le service faisait demi-tour « puisque la popup prend
      // le relais ». Depuis que « Non » est une réponse possible, ce retour
      // anticipé renvoyait l'utilisateur bien plus haut à la réouverture.
      stubMeasure(
        scrollY: 3840, // 96 % de la course de défilement
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      final percent = await service.saveScrollPosition(controller, 12345, 42);

      expect(percent, greaterThan(kReadingEndThresholdPercent.toDouble()));
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getDouble('${kScrollPositionKeyPrefix}12345_42'),
        3840,
        reason: 'la sauvegarde ne doit plus dépendre de la profondeur',
      );
      verify(() => remote.savePosition(12345, 42, 96)).called(1);
    });

    test('le marque-page local reprend la forme du contrat serveur', () async {
      stubMeasure(
        scrollY: 2000,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      await service.saveScrollPosition(controller, 12345, 42);

      final stored = await service.readLocalPosition(12345);
      expect(stored, isNotNull);
      expect(stored!.chapter, 42);
      expect(stored.positionPercent, 50);
      expect(stored.updatedAt, isNotNull,
          reason: 'sans horodatage, impossible d\'arbitrer avec le serveur');
    });

    test('immediate: true force l\'envoi (sortie, arrière-plan)', () async {
      stubMeasure(
        scrollY: 2000,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      await service.saveScrollPosition(controller, 12345, 42,
          immediate: true);
      // La remontée serveur est volontairement non bloquante : on laisse la
      // boucle d'événements tourner avant de vérifier.
      await Future<void>.delayed(Duration.zero);

      verify(() => remote.flush(12345)).called(1);
    });

    test('sans immediate, on laisse le throttle décider', () async {
      stubMeasure(
        scrollY: 2000,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      await service.saveScrollPosition(controller, 12345, 42);

      verifyNever(() => remote.flush(any()));
    });

    test('page non mesurable → rien n\'est écrit, aucune exception', () async {
      when(() => controller.evaluateJavascript(
            source: any(named: 'source'),
            contentWorld: any(named: 'contentWorld'),
          )).thenAnswer((_) async => 'undefined');

      final percent = await service.saveScrollPosition(controller, 12345, 42);

      expect(percent, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_42'), isNull);
      verifyNever(() => remote.savePosition(any(), any(), any()));
    });

    test('haut de page (scrollY = 0) : rien à mémoriser', () async {
      stubMeasure(
        scrollY: 0,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      expect(await service.saveScrollPosition(controller, 12345, 42), isNull);
      verifyNever(() => remote.savePosition(any(), any(), any()));
    });

    test('une WebView qui lève ne fait pas échouer la sauvegarde', () async {
      when(() => controller.evaluateJavascript(
            source: any(named: 'source'),
            contentWorld: any(named: 'contentWorld'),
          )).thenThrow(Exception('WebView détruite'));

      await expectLater(
        service.saveScrollPosition(controller, 12345, 42),
        completion(isNull),
      );
    });
  });

  group('suppression — le vrai garde-fou du chapitre terminé', () {
    setUp(() {
      stubMeasure(
        scrollY: 2000,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );
    });

    test('valider le chapitre efface sa position et coupe la synchro',
        () async {
      await service.saveScrollPosition(controller, 12345, 42);

      await service.deleteScrollPosition(12345, 42);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_42'), isNull);
      expect(await service.readLocalPosition(12345), isNull);
      verify(() => remote.forget(12345)).called(1);
    });

    test('libérer un AUTRE chapitre ne touche pas au marque-page en cours',
        () async {
      await service.saveScrollPosition(controller, 12345, 42);

      await service.deleteScrollPosition(12345, 41);

      final stored = await service.readLocalPosition(12345);
      expect(stored?.chapter, 42);
      verifyNever(() => remote.forget(any()));
    });

    test('une seule position de défilement survit par manga', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${kScrollPositionKeyPrefix}12345_40', 111);
      await prefs.setDouble('${kScrollPositionKeyPrefix}12345_41', 222);
      await prefs.setDouble('${kScrollPositionKeyPrefix}999_41', 333);

      await service.saveScrollPosition(controller, 12345, 42);

      expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_40'), isNull);
      expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_41'), isNull);
      expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_42'), 2000);
      expect(prefs.getDouble('${kScrollPositionKeyPrefix}999_41'), 333,
          reason: 'le nettoyage est borné au manga concerné');
    });
  });

  group('restauration — les garde-fous doivent RÉELLEMENT s\'exécuter', () {
    for (final asJsonString in [false, true]) {
      final platform =
          asJsonString ? 'iOS / web (chaîne JSON)' : 'Android (Map)';

      test('$platform : rien n\'est restauré si l\'utilisateur a déjà défilé',
          () async {
        // Le cœur du défaut 2 : sur Android la garde était inerte et la page
        // sautait sous les doigts de l'utilisateur.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('${kScrollPositionKeyPrefix}12345_42', 2000);
        stubMeasure(
          scrollY: 900, // bien au-delà des 100 px de tolérance
          viewportHeight: 800,
          documentHeight: 4800,
          asJsonString: asJsonString,
        );

        final restored =
            await service.restoreScrollPosition(controller, 12345, 42);

        expect(restored, isFalse);
        verifyNever(() => controller.evaluateJavascript(
              source: any(named: 'source', that: startsWith('window.scrollTo')),
              contentWorld: any(named: 'contentWorld'),
            ));
      });
    }

    test('une position venue d\'un autre appareil est transposée en pixels',
        () async {
      // 50 % mesurés sur un téléphone doivent atterrir au milieu de la course
      // de défilement de CETTE page, quelle que soit sa hauteur ici.
      stubMeasure(
        scrollY: 0,
        viewportHeight: 1200,
        documentHeight: 12000,
        asJsonString: false,
      );

      final restored = await service.restoreScrollPosition(
        controller,
        12345,
        42,
        fallbackPercent: 50,
      );

      expect(restored, isTrue);
      final scripts = verify(() => controller.evaluateJavascript(
            source: captureAny(named: 'source'),
            contentWorld: any(named: 'contentWorld'),
          )).captured.cast<String>();
      expect(
        scripts.where((s) => s.startsWith('window.scrollTo')),
        contains('window.scrollTo(0, 5400.0);'), // (12000 - 1200) / 2
      );
    });

    test('la position locale en pixels prime sur celle du serveur', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${kScrollPositionKeyPrefix}12345_42', 1234);
      stubMeasure(
        scrollY: 0,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      await service.restoreScrollPosition(
        controller,
        12345,
        42,
        fallbackPercent: 90,
      );

      final scripts = verify(() => controller.evaluateJavascript(
            source: captureAny(named: 'source'),
            contentWorld: any(named: 'contentWorld'),
          )).captured.cast<String>();
      expect(
        scripts.where((s) => s.startsWith('window.scrollTo')),
        contains('window.scrollTo(0, 1234.0);'),
      );
    });

    test('hasRestoredScroll: true ne rejoue pas la restauration', () async {
      final restored = await service.restoreScrollPosition(
        controller,
        12345,
        42,
        hasRestoredScroll: true,
        fallbackPercent: 50,
      );

      expect(restored, isFalse);
      verifyNever(() => controller.evaluateJavascript(
            source: any(named: 'source'),
            contentWorld: any(named: 'contentWorld'),
          ));
    });

    test('une restauration en cours suspend les écritures du timer', () async {
      // Sans ce verrou, le tick périodique mesurait la page encore en haut et
      // écrasait la position qu'on était en train de restaurer.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${kScrollPositionKeyPrefix}12345_42', 2000);
      stubMeasure(
        scrollY: 0,
        viewportHeight: 800,
        documentHeight: 4800,
        asJsonString: false,
      );

      final restoring =
          service.restoreScrollPosition(controller, 12345, 42);
      // Le tick tombe pendant la restauration : il ne doit rien écrire.
      final duringRestore =
          await service.saveScrollPosition(controller, 12345, 42);
      await restoring;

      expect(duringRestore, isNull);
      expect(prefs.getDouble('${kScrollPositionKeyPrefix}12345_42'), 2000,
          reason: 'la position restaurée ne doit pas être écrasée par 0');
    });
  });
}
