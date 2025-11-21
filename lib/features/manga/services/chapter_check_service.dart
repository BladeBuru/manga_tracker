import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../reader/utils/chapter_link_resolver.dart';

/// Service pour vérifier si un chapitre existe sur un site de scan
class ChapterCheckService {

  /// Vérifie si un chapitre existe en testant l'URL
  /// Retourne true si le chapitre existe, false sinon
  /// 
  /// [baseUrl] : URL de base du manga (ex: https://site.com/manga/chapitre-22)
  /// [chapterNumber] : Numéro du chapitre à vérifier
  /// 
  /// La méthode détecte si l'URL redirige vers la page principale du manga
  /// (ce qui indique que le chapitre n'existe pas)
  Future<bool> checkChapterExists(String baseUrl, int chapterNumber) async {
    try {
      // Construire l'URL du chapitre à vérifier
      final chapterUrl = await ChapterLinkResolver.buildUrlForChapter(
        baseUrl,
        chapterNumber,
      );

      if (chapterUrl == null) {
        debugPrint('⚠️ ChapterCheckService: Impossible de construire l\'URL pour le chapitre $chapterNumber');
        return false;
      }

      debugPrint('🔍 ChapterCheckService: Vérification du chapitre $chapterNumber: $chapterUrl');

      // Faire une requête HEAD pour vérifier si la page existe
      // HEAD est plus léger que GET car il ne télécharge pas le contenu
      final uri = Uri.parse(chapterUrl);
      
      // Essayer d'abord avec HEAD
      try {
        final headResponse = await http.head(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Timeout lors de la vérification HEAD');
          },
        );

        // Si la réponse est 200 OK, le chapitre existe
        if (headResponse.statusCode == 200) {
          // Vérifier si l'URL finale est différente (redirection)
          final finalUrl = headResponse.request?.url.toString() ?? chapterUrl;
          if (_isRedirectedToMainPage(chapterUrl, finalUrl)) {
            debugPrint('❌ ChapterCheckService: Redirection vers la page principale détectée');
            return false;
          }
          debugPrint('✅ ChapterCheckService: Chapitre $chapterNumber existe (HEAD 200)');
          return true;
        }

        // Si HEAD retourne 405 (Method Not Allowed) ou 404, essayer avec GET
        if (headResponse.statusCode == 405 || headResponse.statusCode == 404) {
          debugPrint('⚠️ ChapterCheckService: HEAD non supporté ou 404, essai avec GET...');
          return await _checkWithGet(uri, chapterUrl, chapterNumber);
        }

        // Autres codes d'erreur
        debugPrint('❌ ChapterCheckService: Code de réponse ${headResponse.statusCode}');
        return false;
      } catch (e) {
        // Si HEAD échoue, essayer avec GET
        debugPrint('⚠️ ChapterCheckService: Erreur HEAD, essai avec GET: $e');
        return await _checkWithGet(uri, chapterUrl, chapterNumber);
      }
    } catch (e) {
      debugPrint('❌ ChapterCheckService: Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// Vérifie avec une requête GET (plus lourd mais plus fiable)
  Future<bool> _checkWithGet(Uri uri, String originalUrl, int chapterNumber) async {
    try {
      final getResponse = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Timeout lors de la vérification GET');
        },
      );

      // Vérifier le code de statut
      if (getResponse.statusCode != 200) {
        debugPrint('❌ ChapterCheckService: GET retourne ${getResponse.statusCode}');
        return false;
      }

      // Vérifier si l'URL finale est différente (redirection)
      final finalUrl = getResponse.request?.url.toString() ?? originalUrl;
      if (_isRedirectedToMainPage(originalUrl, finalUrl)) {
        debugPrint('❌ ChapterCheckService: Redirection vers la page principale détectée (GET)');
        return false;
      }

      // Vérifier le contenu de la page pour détecter les redirections
      // Certains sites redirigent vers la page principale mais retournent 200
      final body = getResponse.body.toLowerCase();
      if (_isMainPageContent(body, originalUrl)) {
        debugPrint('❌ ChapterCheckService: Contenu de page principale détecté');
        return false;
      }

      debugPrint('✅ ChapterCheckService: Chapitre $chapterNumber existe (GET 200)');
      return true;
    } catch (e) {
      debugPrint('❌ ChapterCheckService: Erreur GET: $e');
      return false;
    }
  }

  /// Vérifie si l'URL a été redirigée vers la page principale du manga
  /// 
  /// Une redirection vers la page principale indique que le chapitre n'existe pas
  /// Exemples de redirections :
  /// - https://site.com/manga/chapitre-23 → https://site.com/manga/
  /// - https://site.com/manga/23 → https://site.com/manga/
  /// Note: Certains sites gardent le numéro de chapitre dans l'URL mais redirigent quand même
  bool _isRedirectedToMainPage(String originalUrl, String finalUrl) {
    if (originalUrl == finalUrl) return false;

    final originalUri = Uri.tryParse(originalUrl);
    final finalUri = Uri.tryParse(finalUrl);

    if (originalUri == null || finalUri == null) return false;

    // Vérifier si on est sur le même domaine
    if (originalUri.host != finalUri.host) return false;

    // Extraire le numéro de chapitre de l'URL originale
    final originalChapter = ChapterLinkResolver.extractChapterSync(originalUrl);
    if (originalChapter == null) return false;

    // Extraire le numéro de chapitre de l'URL finale
    final finalChapter = ChapterLinkResolver.extractChapterSync(finalUrl);

    // Si l'URL finale n'a plus de numéro de chapitre, c'est une redirection vers la page principale
    if (finalChapter == null) {
      // Vérifier si le chemin ressemble à une page principale (ex: /manga/ ou /manga)
      final finalPath = finalUri.path.toLowerCase();
      final originalPath = originalUri.path.toLowerCase();
      
      // Si le chemin final est plus court et ne contient plus le numéro, c'est probablement une redirection
      if (finalPath.length < originalPath.length) {
        // Vérifier si le chemin final est juste "/manga" ou "/manga/"
        if (finalPath == '/manga' || finalPath == '/manga/' || finalPath.endsWith('/manga') || finalPath.endsWith('/manga/')) {
          return true;
        }
      }
    } else {
      // Même si l'URL garde le numéro de chapitre, vérifier si le chemin a changé significativement
      // (certains sites redirigent vers la page principale mais gardent le numéro dans l'URL)
      final originalPath = originalUri.path.toLowerCase();
      final finalPath = finalUri.path.toLowerCase();
      
      // Si le chemin final est beaucoup plus court, c'est probablement une redirection
      // Ex: /manga/titre/chapitre-60 → /manga/titre ou /manga/titre/
      if (finalPath.length < originalPath.length - 10) {
        // Vérifier si le chemin final ressemble à une page principale
        if (finalPath.endsWith('/') && !originalPath.endsWith('/')) {
          // Le chemin final se termine par / mais pas l'original, possible redirection
          final originalBase = originalPath.substring(0, originalPath.lastIndexOf('/'));
          if (finalPath == originalBase + '/' || finalPath == originalBase) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Vérifie si le contenu HTML correspond à une page principale plutôt qu'à un chapitre
  /// 
  /// Certains sites redirigent vers la page principale mais retournent 200 OK
  /// On peut détecter cela en analysant le contenu HTML
  bool _isMainPageContent(String htmlBody, String originalUrl) {
    // Indicateurs qu'on est sur une page principale :
    // - Présence de "liste des chapitres" ou équivalent
    // - Absence d'images de chapitre
    // - Présence de liens vers plusieurs chapitres

    final lowerBody = htmlBody.toLowerCase();
    
    // Mots-clés indiquant une page principale
    final mainPageIndicators = [
      'liste des chapitres',
      'chapitres disponibles',
      'table des matières',
      'chapter list',
      'all chapters',
      'tous les chapitres',
    ];

    for (final indicator in mainPageIndicators) {
      if (lowerBody.contains(indicator)) {
        return true;
      }
    }

    // Si le contenu contient beaucoup de liens vers d'autres chapitres, c'est probablement la page principale
    final chapterLinkPattern = RegExp(r'(chapitre|chapter|chap|ch|episode|ep)[\s\-_]?\d+', caseSensitive: false);
    final matches = chapterLinkPattern.allMatches(lowerBody);
    
    // Si on trouve plus de 5 liens vers d'autres chapitres, c'est probablement la page principale
    if (matches.length > 5) {
      return true;
    }

    return false;
  }

  /// Vérifie le chapitre suivant pour un manga donné
  /// 
  /// [muId] : ID du manga
  /// [baseUrl] : URL de base du manga
  /// [currentChapter] : Numéro du dernier chapitre lu
  /// 
  /// Retourne true si le chapitre suivant existe, false sinon
  Future<bool> checkNextChapter(int muId, String baseUrl, int currentChapter) async {
    final nextChapter = currentChapter + 1;
    return await checkChapterExists(baseUrl, nextChapter);
  }
}

