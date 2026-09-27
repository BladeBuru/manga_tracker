import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mangatracker/features/download/models/downloaded_chapter.model.dart';
import 'package:mangatracker/features/download/services/download_manager_service.dart';
import 'package:mangatracker/features/download/services/chapter_image_source.dart';
import 'package:mangatracker/features/download/services/offline_html_result.dart';

export 'package:mangatracker/features/download/services/offline_html_result.dart';

/// En-têtes HTTP à joindre au téléchargement d'une image (Referer, cookies,
/// user-agent du navigateur qui a chargé la page).
typedef ImageRequestHeaders = Future<Map<String, String>> Function(Uri image);

/// Service pour télécharger les chapitres depuis les pages web
class ChapterDownloadService {
  final DownloadManagerService _downloadManager = DownloadManagerService();

  ChapterDownloadService();

  /// Télécharge un chapitre depuis son URL
  /// 
  /// [muId] : ID du manga
  /// [chapterNumber] : Numéro du chapitre
  /// [chapterUrl] : URL du chapitre à télécharger
  /// [mangaTitle] : Titre du manga (optionnel, utilise muId si non fourni)
  /// [onProgress] : Callback pour la progression (0.0 à 1.0)
  /// 
  /// Retourne le DownloadedChapter créé
  Future<DownloadedChapter> downloadChapter({
    required int muId,
    required int chapterNumber,
    required String chapterUrl,
    String? mangaTitle,
    Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('📥 ChapterDownloadService: Début du téléchargement du chapitre $chapterNumber depuis $chapterUrl');

      // Obtenir le chemin du dossier du chapitre (utiliser le nom du manga si disponible)
      final title = mangaTitle ?? muId.toString();
      final chapterPath = await _downloadManager.getChapterDownloadPath(title, chapterNumber);
      final dir = Directory(chapterPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Télécharger la page HTML entière
      final page = await _downloadHtmlPage(chapterUrl, chapterPath, onProgress: onProgress);

      if (page == null) {
        throw Exception('Échec du téléchargement de la page HTML');
      }

      // Créer le modèle DownloadedChapter
      final downloadedChapter = DownloadedChapter(
        muId: muId,
        chapterNumber: chapterNumber,
        downloadDate: DateTime.now(),
        imageCount: page.images,
        imagePaths: [],
        htmlPath: page.path,
        status: DownloadStatus.completed,
      );

      // Sauvegarder les métadonnées
      await _saveMetadata(downloadedChapter);

      // Enregistrer dans le DownloadManagerService
      await _downloadManager.addDownloadedChapter(downloadedChapter);

      debugPrint('✅ ChapterDownloadService: Chapitre $chapterNumber téléchargé avec succès (page HTML)');
      return downloadedChapter;
    } catch (e) {
      debugPrint('❌ ChapterDownloadService: Erreur lors du téléchargement: $e');
      rethrow;
    }
  }

  /// Télécharge la page HTML entière. `null` si la page est refusée ou ne
  /// contient aucune image enregistrable.
  Future<({String path, int images})?> _downloadHtmlPage(
    String url,
    String chapterPath, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      
      // Récupérer les cookies sauvegardés depuis le WebView (si disponibles)
      String? cookieString;
      try {
        final prefs = await SharedPreferences.getInstance();
        cookieString = prefs.getString('cookies_$domain');
        if (cookieString != null && cookieString.isNotEmpty) {
          debugPrint('🍪 ChapterDownloadService: Utilisation des cookies sauvegardés pour $domain');
        } else {
          debugPrint('⚠️ ChapterDownloadService: Aucun cookie sauvegardé pour $domain');
          debugPrint('   💡 Astuce: Ouvrez d\'abord le chapitre dans le lecteur en ligne pour résoudre le captcha.');
        }
      } catch (e) {
        debugPrint('⚠️ ChapterDownloadService: Erreur lors de la récupération des cookies: $e');
      }
      
      // Ajouter des headers pour simuler un navigateur réel et éviter les protections anti-bot
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
        'Accept-Encoding': 'gzip, deflate, br',
        'Referer': url, // Utiliser l'URL elle-même comme referer
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Cache-Control': 'max-age=0',
      };
      
      // Ajouter les cookies si disponibles
      if (cookieString != null && cookieString.isNotEmpty) {
        headers['Cookie'] = cookieString;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode != 200) {
        debugPrint('❌ ChapterDownloadService: Échec du chargement de la page: ${response.statusCode}');
        debugPrint('   URL: $url');
        debugPrint('   Headers de réponse: ${response.headers}');
        
        // Si c'est un 403, cela peut être dû à un captcha ou une protection anti-bot
        if (response.statusCode == 403) {
          debugPrint('⚠️ ChapterDownloadService: Erreur 403 - Possible captcha ou protection anti-bot');
          debugPrint('   Le site peut nécessiter une interaction utilisateur (captcha) pour accéder au contenu.');
          debugPrint('   💡 Astuce: Ouvrez le chapitre dans le lecteur en ligne pour résoudre le captcha, puis réessayez le téléchargement.');
        }
        
        return null;
      }

      // Sauvegarder le HTML dans un fichier
      final htmlFilePath = path.join(chapterPath, 'chapter.html');
      final htmlFile = File(htmlFilePath);
      
      // Traiter le HTML pour télécharger les images et remplacer les URLs par des chemins locaux
      final processed = await processHtmlForOfflineReport(
        response.body,
        url,
        chapterPath,
        onProgress: onProgress,
        headersFor: (_) async => {'Referer': url},
      );
      // Une réponse 200 sans image (page d'erreur, page de vérification
      // servie en 200, lecteur rendu en JavaScript) n'est pas un chapitre :
      // l'appelant repasse par le lecteur.
      if (!processed.hasContent) {
        debugPrint('❌ ChapterDownloadService: aucune image enregistrée '
            '(${processed.imagesFound} trouvée(s)) pour $url');
        return null;
      }
      await htmlFile.writeAsString(processed.html, encoding: utf8);

      debugPrint('✅ ChapterDownloadService: Page HTML téléchargée et traitée: $htmlFilePath');
      return (path: htmlFilePath, images: processed.imagesSaved);
    } catch (e) {
      debugPrint('❌ ChapterDownloadService: Erreur _downloadHtmlPage: $e');
      return null;
    }
  }

  /// Traite le HTML pour télécharger les images et remplacer les URLs par des chemins locaux (mode hors ligne)
  /// Méthode publique pour être utilisée depuis le WebView
  Future<String> processHtmlForOffline(
    String html,
    String baseUrl,
    String chapterPath, {
    Function(double progress)? onProgress,
  }) async =>
      (await processHtmlForOfflineReport(html, baseUrl, chapterPath,
              onProgress: onProgress))
          .html;

  /// Comme [processHtmlForOffline], avec le compte des images trouvées et
  /// réellement enregistrées. [headersFor] fournit les en-têtes de chaque
  /// image (Referer, cookies…) : sans eux, les serveurs d'images protégés
  /// contre le « hotlinking » répondent 403.
  Future<OfflineHtmlResult> processHtmlForOfflineReport(
    String html,
    String baseUrl,
    String chapterPath, {
    Function(double progress)? onProgress,
    ImageRequestHeaders? headersFor,
  }) async {
    var imagesFound = 0;
    var downloadedImages = 0;
    try {
      final uri = Uri.parse(baseUrl);
      final origin = '${uri.scheme}://${uri.host}';
      final basePath = baseUrl.substring(0, baseUrl.lastIndexOf('/') + 1);
      
      // Parser le HTML
      final document = html_parser.parse(html);
      
      // Fonction pour convertir une URL relative en absolue
      String toAbsoluteUrl(String url) {
        if (url.isEmpty) return url;
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:')) {
          return url;
        }
        if (url.startsWith('//')) {
          return '${uri.scheme}:$url';
        }
        if (url.startsWith('/')) {
          return '$origin$url';
        }
        return '$basePath$url';
      }
      
      // Créer un dossier pour les images
      final imagesDir = Directory(path.join(chapterPath, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Télécharger toutes les images et remplacer les URLs par des chemins locaux
      final images = document.querySelectorAll('img');
      final totalImages = images.length;

      for (final img in images) {
        // Adresse RÉELLE : l'attribut différé (data-src…) avant `src`, qui
        // ne contient souvent qu'une image d'attente (voir ChapterImageSource).
        final src = ChapterImageSource.pick({
          for (final entry in img.attributes.entries)
            entry.key.toString(): entry.value,
        });

        if (src != null) {
          imagesFound++;
          try {
            final absoluteSrc = toAbsoluteUrl(src);
            final imageUri = Uri.parse(absoluteSrc);

            // Nom préfixé par l'ordre : unique (deux « 01.jpg » de dossiers
            // différents ne s'écrasent plus) et trié comme les pages.
            final imageFileName =
                '${imagesFound.toString().padLeft(3, '0')}_${_getImageFileName(absoluteSrc, imagesFound)}';
            final localImagePath = path.join(imagesDir.path, imageFileName);
            final imageFile = File(localImagePath);

            // Télécharger l'image seulement si elle n'existe pas déjà
            if (!await imageFile.exists()) {
              final headers = headersFor == null
                  ? const <String, String>{}
                  : await headersFor(imageUri);
              final imageResponse = await http.get(imageUri, headers: headers);
              if (imageResponse.statusCode == 200 &&
                  imageResponse.bodyBytes.isNotEmpty) {
                await imageFile.writeAsBytes(imageResponse.bodyBytes);
              } else {
                debugPrint('⚠️ Image refusée (${imageResponse.statusCode}): $absoluteSrc');
                continue;
              }
            }

            // Remplacer l'URL par un chemin relatif local
            final relativePath = path.join('images', imageFileName).replaceAll('\\', '/');
            img.attributes['src'] = relativePath;

            // Supprimer les attributs de chargement différé : hors ligne,
            // seule l'image locale doit s'afficher.
            img.attributes.remove('loading');
            img.attributes.remove('srcset');
            img.attributes.remove('data-srcset');
            for (final name in ChapterImageSource.lazyAttributes) {
              img.attributes.remove(name);
            }

            downloadedImages++;
            
            // Mettre à jour la progression (50% pour HTML, 50% pour images)
            if (onProgress != null && totalImages > 0) {
              final imageProgress = downloadedImages / totalImages;
              onProgress(0.5 + (imageProgress * 0.5));
            }
          } catch (e) {
            debugPrint('⚠️ Erreur lors du téléchargement de l\'image $src: $e');
            // En cas d'erreur, garder l'URL originale
          }
        }
      }
      
      // Traiter les balises <source> pour les images responsives
      final sources = document.querySelectorAll('source');
      for (final source in sources) {
        final srcset = source.attributes['srcset'];
        if (srcset != null && srcset.isNotEmpty) {
          // Pour simplifier, on télécharge seulement la première image du srcset
          final srcsetParts = srcset.split(',');
          if (srcsetParts.isNotEmpty) {
            final firstPart = srcsetParts[0].trim();
            final spaceIndex = firstPart.indexOf(' ');
            final url = spaceIndex > 0 ? firstPart.substring(0, spaceIndex) : firstPart;
            final absoluteUrl = toAbsoluteUrl(url);
            
            try {
              final imageFileName = _getImageFileName(absoluteUrl, downloadedImages);
              final localImagePath = path.join(imagesDir.path, imageFileName);
              final imageFile = File(localImagePath);
              
              if (!await imageFile.exists()) {
                final sourceUri = Uri.parse(absoluteUrl);
                final imageResponse = await http.get(
                  sourceUri,
                  headers: headersFor == null
                      ? const <String, String>{}
                      : await headersFor(sourceUri),
                );
                if (imageResponse.statusCode == 200) {
                  await imageFile.writeAsBytes(imageResponse.bodyBytes);
                }
              }
              
              final relativePath = path.join('images', imageFileName).replaceAll('\\', '/');
              source.attributes['srcset'] = '$relativePath ${spaceIndex > 0 ? firstPart.substring(spaceIndex) : ''}';
            } catch (e) {
              debugPrint('⚠️ Erreur lors du téléchargement de l\'image srcset: $e');
            }
          }
        }
      }
      
      // Retourner le HTML traité en préservant la structure complète
      final htmlBody = document.body?.innerHtml ?? '';
      final htmlHead = document.head?.innerHtml ?? '';
      
      // Utiliser un baseUrl local au lieu de l'URL distante
      final localBaseUrl = 'file://$chapterPath/';
      final baseTag = '<base href="$localBaseUrl">';
      
      // Préserver le DOCTYPE et reconstruire le HTML complet
      final doctype = html.contains('<!DOCTYPE') ? '<!DOCTYPE html>' : '';
      return OfflineHtmlResult(
        html: '$doctype<html><head>$baseTag$htmlHead</head><body>$htmlBody</body></html>',
        imagesFound: imagesFound,
        imagesSaved: downloadedImages,
      );
    } catch (e) {
      debugPrint('⚠️ ChapterDownloadService: Erreur lors du traitement du HTML: $e');
      // HTML d'origine, mais aucune image comptée comme enregistrée : le
      // chapitre ne sera pas marqué « terminé » à tort.
      return OfflineHtmlResult(
        html: html,
        imagesFound: imagesFound,
        imagesSaved: 0,
      );
    }
  }

  /// Génère un nom de fichier pour une image téléchargée
  String _getImageFileName(String url, int index) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final originalName = pathSegments.last;
        // Nettoyer le nom du fichier
        final cleanName = originalName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        // Ajouter l'extension si elle manque
        if (!cleanName.contains('.')) {
          return 'image_$index.jpg';
        }
        return cleanName;
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'extraction du nom de fichier: $e');
    }
    return 'image_$index.jpg';
  }


  /// Sauvegarde les métadonnées du chapitre téléchargé
  Future<void> _saveMetadata(DownloadedChapter chapter) async {
    try {
      final metadataPath = chapter.metadataPath;
      final file = File(metadataPath);
      final jsonString = jsonEncode(chapter.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('❌ ChapterDownloadService: Erreur _saveMetadata: $e');
    }
  }
}

