import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Construit une Uri vers l'API en utilisant l'URL de base définie dans les
/// variables d'environnement.
///
/// **Robustesse** : si `MT_API_URL` n'a pas de protocole (`https://...` ou
/// `http://...`), on force `https://` automatiquement. Sans ça, sur **web**,
/// `Uri.parse('api.bladeburu.com/auth/login')` est interprété comme une URL
/// relative et le navigateur le préfixe avec l'origine courante
/// (ex: `https://app.bladeburu.com/api.bladeburu.com/auth/login` → 404).
/// Sur mobile, `package:http` arrivait à s'en sortir, mais le web non.
Uri buildApiUri(String path, [Map<String, String>? queryParameters]) {
  String baseUrl = dotenv.env['MT_API_URL']!.trim();

  // Normalisation : ajoute https:// si protocole manquant
  if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
    baseUrl = 'https://$baseUrl';
  }
  // Évite les double slashes ("https://api.bladeburu.com/" + "/auth/login")
  if (baseUrl.endsWith('/') && path.startsWith('/')) {
    baseUrl = baseUrl.substring(0, baseUrl.length - 1);
  }

  final uri = Uri.parse('$baseUrl$path');
  if (queryParameters != null) {
    return uri.replace(queryParameters: queryParameters);
  }
  return uri;
}
