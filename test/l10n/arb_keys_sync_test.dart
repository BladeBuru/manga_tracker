import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou i18n : les 7 fichiers ARB doivent exposer exactement le même
/// jeu de clés que la référence `app_fr.arb` (template de `l10n.yaml`).
///
/// Pourquoi : quand une clé manque dans un ARB non-français, `flutter gen-l10n`
/// ne lève aucune erreur — il comble silencieusement le getter généré avec le
/// texte du template, c'est-à-dire le FRANÇAIS. Un utilisateur allemand ou
/// japonais voit alors des phrases en français au milieu de son interface.
///
/// Les clés de métadonnées (`@...`) sont ignorées : elles sont optionnelles
/// dans les ARB traduits (seul le template en a besoin).
void main() {
  const referenceFile = 'app_fr.arb';
  const translatedFiles = [
    'app_en.arb',
    'app_de.arb',
    'app_es.arb',
    'app_ja.arb',
    'app_ko.arb',
    'app_pt.arb',
  ];

  Set<String> messageKeys(String fileName) {
    final file = File('lib/l10n/$fileName');
    if (!file.existsSync()) {
      fail('Fichier ARB introuvable : ${file.path}');
    }
    final Map<String, dynamic> json =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return json.keys.where((k) => !k.startsWith('@')).toSet();
  }

  for (final fileName in translatedFiles) {
    test('$fileName contient exactement les clés de $referenceFile', () {
      final referenceKeys = messageKeys(referenceFile);
      final keys = messageKeys(fileName);
      final missing = referenceKeys.difference(keys).toList()..sort();
      final extra = keys.difference(referenceKeys).toList()..sort();

      expect(
        missing,
        isEmpty,
        reason:
            '${missing.length} clé(s) de $referenceFile absente(s) de '
            '$fileName — gen-l10n les remplacerait par du FRANÇAIS. '
            'Traduire :\n${missing.join('\n')}',
      );
      expect(
        extra,
        isEmpty,
        reason:
            '${extra.length} clé(s) présente(s) dans $fileName mais pas dans '
            '$referenceFile (référence) — ajouter au template ou supprimer :\n'
            '${extra.join('\n')}',
      );
    });
  }
}
