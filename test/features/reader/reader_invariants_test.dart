import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fil de détente (« tripwire ») contre la disparition silencieuse des
/// protections du lecteur en ligne.
///
/// Ces tests lisent le SOURCE du lecteur. C'est volontairement inhabituel :
/// la WebView ne s'instancie pas en test unitaire, et la régression de
/// v0.13.0 (protection anti-redirection rendue inerte par un
/// `controller.setSettings(...)`) n'aurait été détectée par aucun test de
/// comportement. Si l'un de ces tests échoue, ce n'est pas le test qu'il faut
/// adapter : c'est l'invariant qu'on est en train de casser.
void main() {
  const readerPath = 'lib/features/manga/views/web_view_io.dart';
  const settingsPath =
      'lib/features/reader/services/reader_web_view_settings.dart';

  late String reader;
  late String settings;

  setUpAll(() {
    reader = File(readerPath).readAsStringSync();
    settings = File(settingsPath).readAsStringSync();
  });

  group('protection anti-redirection du lecteur', () {
    test('le garde shouldOverrideUrlLoading est branché sur la WebView', () {
      expect(
        reader,
        contains('shouldOverrideUrlLoading:'),
        reason: 'Sans ce callback, aucune redirection publicitaire n\'est '
            'annulée pendant la lecture.',
      );
    });

    test('la décision passe par ReaderNavigationPolicy', () {
      expect(reader, contains('ReaderNavigationPolicy('));
      expect(reader, contains('_navigationPolicy.decide('));
    });

    test('useShouldOverrideUrlLoading est explicitement à true', () {
      expect(
        settings,
        matches(RegExp(r'useShouldOverrideUrlLoading:\s*true')),
        reason: 'Le plugin n\'infère ce réglage que pour les réglages '
            'initiaux ; il doit être explicite pour ne dépendre de rien.',
      );
    });

    test('le lecteur ne rappelle JAMAIS setSettings sur sa WebView', () {
      // Les commentaires ont le droit d'en parler (c'est même souhaitable) ;
      // seul le code est jugé.
      String withoutComments(String source) => source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      for (final entry in {readerPath: reader, settingsPath: settings}.entries) {
        expect(
          withoutComments(entry.value),
          isNot(contains('setSettings(')),
          reason: '${entry.key} : côté Android, setSettings remplace '
              'l\'objet de réglages entier — useShouldOverrideUrlLoading '
              'repasse à false et le garde anti-redirection devient inerte '
              '(régression v0.13.0).',
        );
      }
    });

    test('le chargement initial passe par initialUrlRequest', () {
      expect(
        reader,
        contains('initialUrlRequest:'),
        reason: 'Charger via controller.loadUrl() après coup a été le '
            'prétexte au setSettings fautif. La première requête doit '
            'partir avec les réglages initiaux.',
      );
    });
  });

  group('bloqueur de publicités', () {
    test('activé par défaut', () {
      expect(
        reader,
        matches(RegExp(r'bool _adBlockerEnabled\s*=\s*true')),
      );
      expect(
        reader,
        contains("prefs.getBool('ad_blocker_enabled') ?? true"),
        reason: 'Sans préférence enregistrée, le bloqueur doit être actif.',
      );
    });

    test('se coupe de lui-même quand une vérification anti-robot apparaît',
        () {
      expect(reader, contains('_detectAndHandleCaptcha('));
      expect(
        reader,
        contains('stopAdBlockScript('),
        reason: 'Le script injecté doit être arrêté dans la page, sinon il '
            'continue de nettoyer le DOM du défi.',
      );
    });
  });
}
