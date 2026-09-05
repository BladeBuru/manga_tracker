import 'dart:convert';
import 'dart:io';

/// Charge une fixture JSON du contrat API depuis `test/fixtures/`.
///
/// `flutter test` s'execute depuis la racine du package : le chemin relatif
/// est stable quel que soit le fichier de test appelant.
String loadFixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

Map<String, dynamic> loadJsonFixture(String name) =>
    jsonDecode(loadFixture(name)) as Map<String, dynamic>;
