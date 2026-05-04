import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Construit une Uri vers l'API en utilisant l'URL de base définie dans les variables d'environnement.
/// Le protocole (http/https) est inclus dans MT_API_URL, ce qui permet de switcher
/// automatiquement entre http en développement et https en production.
Uri buildApiUri(String path, [Map<String, String>? queryParameters]) {
  final baseUrl = dotenv.env['MT_API_URL']!;
  final uri = Uri.parse('$baseUrl$path');
  if (queryParameters != null) {
    return uri.replace(queryParameters: queryParameters);
  }
  return uri;
}
