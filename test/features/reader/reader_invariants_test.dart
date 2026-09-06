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
  const policyPath =
      'lib/features/reader/services/chapter_commit_policy.dart';
  const offlineReaderPath =
      'lib/features/reader/views/offline_reader_view_io.dart';
  const scrollServicePath =
      'lib/features/reader/services/scroll_position_service.dart';
  const detailViewPath = 'lib/features/manga/views/detail_bloc_view.dart';

  late String reader;
  late String settings;
  late String offlineReader;
  late String scrollService;
  late String detailView;

  /// Les commentaires ont le droit de nommer un anti-pattern (c'est même
  /// souhaitable) ; seul le code est jugé.
  String withoutComments(String source) => source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  setUpAll(() {
    reader = File(readerPath).readAsStringSync();
    settings = File(settingsPath).readAsStringSync();
    offlineReader = File(offlineReaderPath).readAsStringSync();
    scrollService = File(scrollServicePath).readAsStringSync();
    detailView = File(detailViewPath).readAsStringSync();
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

  group('progression de lecture — décalage d\'un chapitre', () {
    test('le chapitre d\'ARRIVÉE n\'est jamais enregistré', () {
      // Le bug de cc586a0 (v0.8.0) : sur 133 → 134, le lecteur appelait
      // `_commitIfNeeded(prev)` PUIS `_commitIfNeeded(newCh)`. Arriver sur un
      // chapitre n'est pas l'avoir lu — l'app affichait « progression du
      // chapitre 134 » à la seconde où on l'ouvrait.
      final code = withoutComments(reader);
      for (final forbidden in [
        '_commitIfNeeded(newCh)',
        '_commitIfNeeded(newCh,',
        '_commitIfNeeded(newCh - 1',
        '_commitIfNeeded(result.newChapter',
      ]) {
        expect(
          code,
          isNot(contains(forbidden)),
          reason: 'Enregistrer le chapitre d\'arrivée décale la progression '
              'd\'un chapitre dans le futur (régression v0.8.0). Seul le '
              'chapitre QUITTÉ peut être enregistré.',
        );
      }
    });

    test('la décision passe par ChapterCommitPolicy', () {
      expect(
        reader,
        contains('ChapterCommitPolicy('),
        reason: 'La sémantique « dernier chapitre TERMINÉ » vit dans une '
            'classe pure testable, pas dans un switch de la vue.',
      );
      expect(reader, contains('_commitPolicy.onTransition('));
      expect(reader, contains('_commitPolicy.onExit('));
    });

    test('la garde de la modale de fin reste branchée', () {
      // Elle vit désormais dans la politique pure : c'est `shouldCommit`
      // (chapitre > dernier enregistré) qui remplace l'ancien
      // `if (c != null && _lastCommitted < c)`.
      final policy = File(policyPath).readAsStringSync();
      expect(
        withoutComments(policy),
        contains('shouldCommit(chapter, lastCommitted)'),
        reason: 'Sans cette garde, « Avez-vous fini le chapitre N ? » ne '
            's\'affiche plus jamais.',
      );
      expect(
        withoutComments(policy),
        contains('chapter > lastCommitted'),
        reason: 'La progression est monotone : elle ne recule jamais.',
      );
    });

    test('le saut de chapitres propose le chapitre QUITTÉ', () {
      final policy = withoutComments(File(policyPath).readAsStringSync());
      expect(
        policy,
        isNot(contains('newChapter - 1')),
        reason: 'Sauter du 134 au 140 et répondre « oui » enregistrait 139.',
      );
    });
  });

  group('modale de fin de chapitre — accessible sur tous les chemins', () {
    test('les lecteurs utilisent PopScope, jamais WillPopScope', () {
      // AndroidManifest déclare `enableOnBackInvokedCallback="true"` : sur
      // Android 13+, le retour prédictif IGNORE WillPopScope, ce qui rendait
      // la modale injoignable au geste retour.
      for (final entry in {
        readerPath: reader,
        offlineReaderPath: offlineReader,
      }.entries) {
        expect(
          withoutComments(entry.value),
          isNot(contains('WillPopScope')),
          reason: '${entry.key} : WillPopScope est ignoré par le geste '
              'retour prédictif Android 13+.',
        );
        expect(entry.value, contains('PopScope('));
        expect(entry.value, contains('canPop: false'));
        expect(entry.value, contains('onPopInvokedWithResult:'));
      }
    });

    test('la sortie est protégée contre la réentrance', () {
      for (final entry in {
        readerPath: reader,
        offlineReaderPath: offlineReader,
      }.entries) {
        expect(
          entry.value,
          contains('_exitFlowRunning'),
          reason: '${entry.key} : un double appui sur « retour » ouvrirait '
              'deux modales.',
        );
      }
    });

    test('la mesure « proche de la fin » est bornée dans le temps', () {
      for (final entry in {
        readerPath: reader,
        offlineReaderPath: offlineReader,
      }.entries) {
        expect(
          entry.value,
          contains('kNearEndMeasureTimeout'),
          reason: '${entry.key} : sans borne, une page figée donnerait '
              'l\'impression d\'un retour bloqué.',
        );
      }
    });

    test('le lecteur hors ligne n\'enregistre plus en silence dans dispose',
        () {
      final disposeStart = offlineReader.indexOf('void dispose()');
      expect(disposeStart, greaterThan(-1));
      final disposeBody = offlineReader.substring(
        disposeStart,
        offlineReader.indexOf('super.dispose();', disposeStart),
      );
      expect(
        disposeBody,
        isNot(contains('_commitChapter(')),
        reason: 'dispose() ne peut rien demander à l\'utilisateur : y '
            'enregistrer un chapitre revient à le marquer lu sans son avis.',
      );
    });
  });

  group('détection d\'URL — un seul traitement par navigation', () {
    test('les détections sont sérialisées et idempotentes', () {
      expect(reader, contains('_processingDetection'));
      expect(
        reader,
        contains('_lastHandledUrl'),
        reason: '_handleDetected est appelé jusqu\'à 3 fois par navigation '
            '(shouldOverrideUrlLoading, onLoadStart, '
            'onUpdateVisitedHistory) : sans mémorisation, une navigation '
            'produit plusieurs enregistrements et plusieurs notifications.',
      );
    });
  });

  group('cycle de vie', () {
    test('les deux lecteurs observent le cycle de vie de l\'app', () {
      for (final entry in {
        readerPath: reader,
        offlineReaderPath: offlineReader,
      }.entries) {
        expect(entry.value, contains('WidgetsBindingObserver'),
            reason: '${entry.key} : sans observateur, une mise en '
                'arrière-plan perd la position de lecture.');
        expect(entry.value, contains('didChangeAppLifecycleState'));
        expect(entry.value, contains('WidgetsBinding.instance.removeObserver'),
            reason: '${entry.key} : un observateur non retiré fuit.');
      }
    });
  });

  group('position de lecture — sauvegarde et restauration', () {
    test('la sauvegarde ne dépend PLUS de la profondeur de lecture', () {
      // Le service faisait `return` sans écrire dès que la position dépassait
      // kReadingEndThresholdPercent, « puisque la popup prend le relais ».
      // Depuis que « Non » est une réponse possible et respectée, ce retour
      // anticipé renvoyait l'utilisateur sur une position périmée.
      final code = withoutComments(scrollService);
      expect(
        code,
        isNot(contains('kReadingEndThresholdPercent')),
        reason: "ScrollPositionService ne doit plus se comparer au seuil "
            "de fin : c'est la SUPPRESSION de la position à la validation du "
            "chapitre qui garantit qu'on ne rouvre pas un chapitre terminé "
            "au milieu, pas un refus d'écriture.",
      );
    });

    test('les retours de la WebView passent par un parseur unique', () {
      // Les garde-fous découpaient le retour de evaluateJavascript comme du
      // texte, alors que le plugin Android rend une Map : la garde « ne pas
      // restaurer si l'utilisateur a déjà défilé » ne s'exécutait jamais.
      final probe = File(
        'lib/features/reader/services/reader_viewport_probe.dart',
      ).readAsStringSync();
      expect(withoutComments(probe), contains('WebViewResultParser'));

      final code = withoutComments(scrollService);
      expect(
        code,
        contains('_probe.measure('),
        reason: 'le service ne doit plus parler JavaScript lui-même : une '
            'seule sonde, un seul parseur.',
      );
      for (final source in [code, withoutComments(probe)]) {
        for (final forbidden in [
          "split('\"scrollY\":')",
          "contains('\"scrollY\":')",
          "split('\"maxScroll\":')",
        ]) {
          expect(
            source,
            isNot(contains(forbidden)),
            reason: 'lire un retour de WebView comme du texte le rend inerte '
                'sur la moitié des plateformes.',
          );
        }
      }
    });

    test("la sortie et l'arrière-plan forcent l'envoi au serveur", () {
      // Sans `immediate`, la dernière position resterait bloquée derrière le
      // throttle — exactement l'instant où l'utilisateur bascule d'appareil.
      expect(
        'immediate: true'.allMatches(reader).length,
        greaterThanOrEqualTo(3),
        reason: 'sortie (_onWillPop), arrière-plan '
            '(didChangeAppLifecycleState) et dispose().',
      );
      expect(offlineReader, contains('immediate: true'));
    });

    test('valider un chapitre efface sa position et coupe la synchro', () {
      final code = withoutComments(reader);
      expect(code, contains('deleteScrollPosition(widget.muId, chapter)'));
      expect(
        code,
        contains('_readingPositionService.forget(widget.muId)'),
        reason: "sans cet oubli, le tick suivant réenverrait une position "
            "au milieu d'un chapitre que le serveur vient de clore.",
      );
    });
  });

  group('reprise de lecture — ouverture du lecteur', () {
    test("« Lire en ligne » n'ouvre plus systématiquement dernier lu + 1",
        () {
      final code = withoutComments(detailView);
      expect(
        code,
        contains('resolveReadingResume('),
        reason: 'la reprise inter-appareils doit passer par la politique '
            'pure, pas par un calcul en dur dans la vue.',
      );
      expect(
        code,
        isNot(contains('final nextChapterNumber = lastRead + 1;')),
        reason: 'ce calcul en dur ignorait toute lecture en cours.',
      );
    });

    test('la décision vit dans une politique pure', () {
      final policy = File(
        'lib/features/reader/services/reading_resume_policy.dart',
      ).readAsStringSync();
      expect(policy, isNot(contains("import 'package:flutter")));
      expect(policy, isNot(contains('service_locator')));
      expect(
        withoutComments(policy),
        contains('candidate.chapter <= lastReadChapter'),
        reason: 'garde-fou : un chapitre terminé ne se rouvre jamais au '
            'milieu, même si le serveur renvoie une position pour lui.',
      );
    });

    test('la position de reprise est transmise au lecteur', () {
      expect(reader, contains('initialPositionPercent'));
      expect(detailView, contains('initialPositionPercent: resume.positionPercent'));
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
