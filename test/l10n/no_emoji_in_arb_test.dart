import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou anti-régression : plus aucun émoji dans les textes affichés à
/// l'utilisateur. Le produit doit utiliser de vraies icônes Material, pas
/// des émojis (voir `chore/emojis-vers-icones`).
///
/// Un caractère « pictographique étendu » (`Extended_Pictographic`, incluant
/// les variation selectors U+FE0F et le ZWJ U+200D des séquences composées)
/// dans une valeur ARB (hors clés de métadonnées `@...`) fait échouer ce
/// test.
void main() {
  final emojiPattern = RegExp(
    r'\p{Extended_Pictographic}|\u{FE0F}|\u{200D}',
    unicode: true,
  );

  const arbFiles = [
    'app_fr.arb',
    'app_en.arb',
    'app_de.arb',
    'app_ja.arb',
    'app_ko.arb',
    'app_pt.arb',
    'app_es.arb',
  ];

  for (final fileName in arbFiles) {
    test('$fileName ne contient aucun émoji dans ses valeurs', () {
      final file = File('lib/l10n/$fileName');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Fichier ARB introuvable : ${file.path}',
      );

      final Map<String, dynamic> json =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final offenders = <String>[];
      for (final entry in json.entries) {
        final key = entry.key;
        final value = entry.value;
        // Les clés `@xxx` sont des métadonnées ICU (descriptions,
        // placeholders...), pas du texte affiché à l'utilisateur.
        if (key.startsWith('@')) continue;
        if (value is! String) continue;
        if (emojiPattern.hasMatch(value)) {
          offenders.add('$key = "$value"');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Émoji(s) trouvé(s) dans $fileName — remplacer par une vraie '
            'icône Material dans le widget concerné et nettoyer le texte '
            'ARB dans les 7 langues :\n${offenders.join('\n')}',
      );
    });
  }
}
