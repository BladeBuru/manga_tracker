import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer la sauvegarde et la restauration de la position de scroll
/// dans les WebViews de lecture (en ligne et hors ligne)
class ScrollPositionService {
  Timer? _scrollSaveTimer;
  InAppWebViewController? _currentController;
  int? _currentMuId;
  int? _currentChapter;

  /// Sauvegarde la position de scroll actuelle dans SharedPreferences
  /// Sauvegarde uniquement pour le chapitre en cours et supprime les autres
  Future<void> saveScrollPosition(
    InAppWebViewController controller,
    int muId,
    int chapter,
  ) async {
    debugPrint('🔍 ScrollPositionService.saveScrollPosition - Début pour chapitre $chapter (muId: $muId)');
    try {
      final scrollScript = """
        (function() {
          return {
            scrollY: window.scrollY || 0,
            pageYOffset: window.pageYOffset || 0,
            documentScrollTop: document.documentElement.scrollTop || 0,
            scrollHeight: document.documentElement.scrollHeight || 0,
            windowHeight: window.innerHeight || 0
          };
        })();
      """;

      final scrollResult = await controller.evaluateJavascript(source: scrollScript);
      debugPrint('🔍 ScrollPositionService.saveScrollPosition - Résultat JavaScript: $scrollResult');

      // Extraire la position et la hauteur du document
      double? scrollPosition;
      double? documentHeight;
      double? windowHeight;

      if (scrollResult != null) {
        final scrollStr = scrollResult.toString();
        debugPrint('🔍 ScrollPositionService.saveScrollPosition - Chaîne de résultat: $scrollStr');
        
        // Parser scrollY (peut être avec ou sans guillemets)
        final scrollYPattern = RegExp(r'scrollY["\s]*:\s*([0-9.]+)');
        final scrollYMatch = scrollYPattern.firstMatch(scrollStr);
        if (scrollYMatch != null) {
          scrollPosition = double.tryParse(scrollYMatch.group(1)!);
          debugPrint('🔍 ScrollPositionService.saveScrollPosition - scrollPosition parsé: $scrollPosition');
        } else {
          debugPrint('⚠️ ScrollPositionService.saveScrollPosition - scrollY non trouvé dans: $scrollStr');
        }
        
        // Parser scrollHeight (peut être avec ou sans guillemets)
        final scrollHeightPattern = RegExp(r'scrollHeight["\s]*:\s*([0-9.]+)');
        final scrollHeightMatch = scrollHeightPattern.firstMatch(scrollStr);
        if (scrollHeightMatch != null) {
          documentHeight = double.tryParse(scrollHeightMatch.group(1)!);
          debugPrint('🔍 ScrollPositionService.saveScrollPosition - documentHeight parsé: $documentHeight');
        } else {
          debugPrint('⚠️ ScrollPositionService.saveScrollPosition - scrollHeight non trouvé dans: $scrollStr');
        }
        
        // Parser windowHeight (peut être avec ou sans guillemets)
        final windowHeightPattern = RegExp(r'windowHeight["\s]*:\s*([0-9.]+)');
        final windowHeightMatch = windowHeightPattern.firstMatch(scrollStr);
        if (windowHeightMatch != null) {
          windowHeight = double.tryParse(windowHeightMatch.group(1)!);
          debugPrint('🔍 ScrollPositionService.saveScrollPosition - windowHeight parsé: $windowHeight');
        } else {
          debugPrint('⚠️ ScrollPositionService.saveScrollPosition - windowHeight non trouvé dans: $scrollStr');
        }
      } else {
        debugPrint('⚠️ ScrollPositionService.saveScrollPosition - scrollResult est null');
      }

      if (scrollPosition != null && scrollPosition > 0) {
        debugPrint('🔍 ScrollPositionService.saveScrollPosition - Position valide: $scrollPosition');
        // Zone « fin de chapitre » (≥ kReadingEndThresholdPercent) : pas de
        // sauvegarde — c'est la popup « Avez-vous fini ? » qui prend le
        // relais. Seuil UNIFIÉ avec ReadingProgressHelper (hotfix-v0-10-1
        // US-4) — avant, 95 ici vs 85 côté popup laissait un trou où on
        // n'était ni sauvegardé ni détecté en fin.
        if (documentHeight != null && documentHeight > 0 && windowHeight != null) {
          final maxScroll = documentHeight - windowHeight;
          if (maxScroll > 0) {
            final percentage = (scrollPosition / maxScroll) * 100;
            debugPrint('🔍 ScrollPositionService.saveScrollPosition - Pourcentage: ${percentage.toStringAsFixed(1)}%');
            if (percentage >= kReadingEndThresholdPercent) {
              debugPrint('🔍 ScrollPositionService - Zone fin de chapitre ($percentage%), sauvegarde annulée');
              return;
            }
          }
        }

        final prefs = await SharedPreferences.getInstance();
        final key = 'scroll_position_${muId}_$chapter';
        debugPrint('🔍 ScrollPositionService.saveScrollPosition - Clé: $key');
        final saved = await prefs.setDouble(key, scrollPosition);
        debugPrint('🔍 ScrollPositionService.saveScrollPosition - setDouble résultat: $saved');
        debugPrint('🔍 ScrollPositionService - Position sauvegardée pour chapitre $chapter: $scrollPosition (clé: $key)');
        
        // Vérifier que la sauvegarde a bien fonctionné
        final verify = prefs.getDouble(key);
        debugPrint('🔍 ScrollPositionService.saveScrollPosition - Vérification après sauvegarde: $verify');

        // Supprimer les positions des autres chapitres (on ne garde que celle du chapitre actuel)
        await cleanOldPositions(muId, chapter);
      } else {
        debugPrint('⚠️ ScrollPositionService.saveScrollPosition - Position invalide: scrollPosition=$scrollPosition');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ ScrollPositionService - Erreur lors de la sauvegarde de la position de scroll: $e');
      debugPrint('⚠️ Stack trace: $stackTrace');
    }
  }

  /// Restaure la position de scroll sauvegardée depuis SharedPreferences
  Future<bool> restoreScrollPosition(
    InAppWebViewController controller,
    int muId,
    int chapter, {
    bool hasRestoredScroll = false,
  }) async {
    if (hasRestoredScroll) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'scroll_position_${muId}_$chapter';
      final savedPosition = prefs.getDouble(key);

      debugPrint('🔍 ScrollPositionService - Chapitre: $chapter, Position sauvegardée: $savedPosition');

      // Vérifier la position actuelle AVANT toute manipulation
      final currentScrollScript = """
        (function() {
          return {
            scrollY: window.scrollY || 0,
            pageYOffset: window.pageYOffset || 0,
            documentScrollTop: document.documentElement.scrollTop || 0,
            bodyScrollTop: document.body.scrollTop || 0,
            documentHeight: document.documentElement.scrollHeight || 0,
            windowHeight: window.innerHeight || 0
          };
        })();
      """;
      final currentScrollResult = await controller.evaluateJavascript(source: currentScrollScript);
      debugPrint('🔍 ScrollPositionService - Position actuelle AVANT restauration: $currentScrollResult');

      // Extraire la position actuelle pour vérifier si l'utilisateur a déjà interagi
      double? currentScrollY;
      if (currentScrollResult != null) {
        final currentScrollStr = currentScrollResult.toString();
        if (currentScrollStr.contains('"scrollY":')) {
          try {
            final scrollYStr = currentScrollStr.split('"scrollY":')[1].split(',')[0].trim();
            currentScrollY = double.tryParse(scrollYStr);
          } catch (e) {
            debugPrint('🔍 ScrollPositionService - Erreur parsing currentScrollY: $e');
          }
        }
      }

      // Si l'utilisateur a déjà scrollé manuellement (position > 100px), ne pas restaurer
      // Cela signifie qu'il a déjà interagi avec la page (zoom + scroll)
      if (currentScrollY != null && currentScrollY > 100) {
        debugPrint('🔍 ScrollPositionService - Utilisateur a déjà scrollé manuellement ($currentScrollY px), restauration annulée pour préserver sa position');
        return false;
      }

      if (savedPosition != null && savedPosition > 0) {
        debugPrint('🔍 ScrollPositionService - Restauration de la position sauvegardée: $savedPosition');

        // Attendre que la page soit prête et que le zoom se stabilise
        await Future.delayed(const Duration(milliseconds: 500));

        // Vérifier à nouveau la position actuelle APRÈS le délai
        // L'utilisateur peut avoir scrollé pendant ce temps
        final currentScrollAfterDelay = await controller.evaluateJavascript(source: currentScrollScript);
        debugPrint('🔍 ScrollPositionService - Position actuelle APRÈS délai: $currentScrollAfterDelay');

        // Extraire la position actuelle après le délai
        double? currentScrollYAfterDelay;
        if (currentScrollAfterDelay != null) {
          final currentScrollStr = currentScrollAfterDelay.toString();
          if (currentScrollStr.contains('"scrollY":')) {
            try {
              final scrollYStr = currentScrollStr.split('"scrollY":')[1].split(',')[0].trim();
              currentScrollYAfterDelay = double.tryParse(scrollYStr);
            } catch (e) {
              debugPrint('🔍 ScrollPositionService - Erreur parsing currentScrollYAfterDelay: $e');
            }
          }
        }

        // Si l'utilisateur a scrollé pendant le délai (> 100px), ne pas restaurer
        if (currentScrollYAfterDelay != null && currentScrollYAfterDelay > 100) {
          debugPrint('🔍 ScrollPositionService - Utilisateur a scrollé pendant le délai ($currentScrollYAfterDelay px), restauration annulée');
          return false;
        }

        // Vérifier que le document est prêt avant de restaurer
        final readyScript = """
          (function() {
            return document.readyState === 'complete' || document.readyState === 'interactive';
          })();
        """;

        final isReady = await controller.evaluateJavascript(source: readyScript);
        debugPrint('🔍 ScrollPositionService - Document prêt: $isReady');

        if (isReady == true || isReady == 'true') {
          // Vérifier la hauteur actuelle du document pour valider la position
          final documentHeightScript = """
            (function() {
              return {
                scrollHeight: document.documentElement.scrollHeight || 0,
                clientHeight: document.documentElement.clientHeight || 0,
                maxScroll: Math.max(0, (document.documentElement.scrollHeight || 0) - (window.innerHeight || 0))
              };
            })();
          """;

          final docHeightResult = await controller.evaluateJavascript(source: documentHeightScript);
          debugPrint('🔍 ScrollPositionService - Dimensions du document: $docHeightResult');

          // Extraire la hauteur maximale de scroll
          double? maxScroll;
          if (docHeightResult != null) {
            final docHeightStr = docHeightResult.toString();
            if (docHeightStr.contains('"maxScroll":')) {
              try {
                final maxScrollStr = docHeightStr.split('"maxScroll":')[1].split(',')[0].trim();
                maxScroll = double.tryParse(maxScrollStr);
              } catch (e) {
                debugPrint('🔍 ScrollPositionService - Erreur parsing maxScroll: $e');
              }
            }
          }

          // Valider et ajuster la position sauvegardée
          double targetPosition = savedPosition;

          if (maxScroll != null && maxScroll > 0) {
            // Si la position sauvegardée dépasse la hauteur maximale, la limiter
            if (targetPosition > maxScroll) {
              debugPrint('🔍 ScrollPositionService - Position sauvegardée ($targetPosition) dépasse maxScroll ($maxScroll), limitation');
              targetPosition = maxScroll;
            }

            // Zone « fin de chapitre » : ne pas restaurer — seuil unifié
            // avec ReadingProgressHelper (hotfix-v0-10-1 US-4).
            final percentage = (targetPosition / maxScroll) * 100;
            if (percentage >= kReadingEndThresholdPercent) {
              debugPrint('🔍 ScrollPositionService - Zone fin de chapitre ($percentage%), restauration annulée');
              return false;
            }

            debugPrint('🔍 ScrollPositionService - Position validée: $targetPosition (${percentage.toStringAsFixed(1)}% de la hauteur)');
          }

          final scrollScript = 'window.scrollTo(0, $targetPosition);';
          await controller.evaluateJavascript(source: scrollScript);

          // Vérifier la position APRÈS restauration
          await Future.delayed(const Duration(milliseconds: 200));
          final afterScrollResult = await controller.evaluateJavascript(source: currentScrollScript);
          debugPrint('🔍 ScrollPositionService - Position APRÈS restauration: $afterScrollResult');
          return true;
        } else {
          // Si pas prêt, réessayer après un court délai
          Future.delayed(const Duration(milliseconds: 200), () async {
            try {
              final scrollScript = 'window.scrollTo(0, $savedPosition);';
              await controller.evaluateJavascript(source: scrollScript);
              final afterScrollResult = await controller.evaluateJavascript(source: currentScrollScript);
              debugPrint('🔍 ScrollPositionService - Position APRÈS restauration (retry): $afterScrollResult');
            } catch (e) {
              debugPrint('⚠️ ScrollPositionService - Erreur lors de la restauration (retry): $e');
            }
          });
          return true;
        }
      } else {
        debugPrint('🔍 ScrollPositionService - Nouveau chapitre (pas de position sauvegardée), attente du chargement complet');

        // Script pour vérifier si toutes les images sont chargées
        final checkImagesLoadedScript = """
          (function() {
            const images = document.querySelectorAll('img');
            if (images.length === 0) return true; // Pas d'images, considérer comme chargé
            
            let loadedCount = 0;
            let totalImages = images.length;
            
            for (let i = 0; i < images.length; i++) {
              const img = images[i];
              // Vérifier si l'image est déjà chargée
              if (img.complete && img.naturalHeight !== 0) {
                loadedCount++;
              } else {
                // Attendre que l'image se charge
                return false;
              }
            }
            
            return loadedCount === totalImages;
          })();
        """;

        // Attendre que les images soient chargées (avec timeout).
        // 50 tentatives = 10s max (hotfix-v0-10-1 US-4 : 5s ne suffisait pas
        // sur les lecteurs lents → restauration de scroll ratée).
        bool imagesLoaded = false;
        int attempts = 0;
        const maxAttempts = 50;

        while (!imagesLoaded && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 200));
          final imagesLoadedResult = await controller.evaluateJavascript(source: checkImagesLoadedScript);
          imagesLoaded = imagesLoadedResult == true || imagesLoadedResult == 'true';
          attempts++;

          if (!imagesLoaded && attempts % 5 == 0) {
            debugPrint('🔍 ScrollPositionService - Images en cours de chargement... (tentative $attempts/$maxAttempts)');
          }
        }

        if (imagesLoaded) {
          debugPrint('🔍 ScrollPositionService - Toutes les images sont chargées pour le nouveau chapitre');
        } else {
          debugPrint('🔍 ScrollPositionService - Timeout: certaines images ne sont pas encore chargées après 10 secondes');
        }

        // Attendre un peu plus pour que le layout se stabilise après le chargement des images
        await Future.delayed(const Duration(milliseconds: 500));

        debugPrint('🔍 ScrollPositionService - Nouveau chapitre prêt, l\'utilisateur peut lire normalement');

        // Vérifier la position actuelle pour les logs
        final finalScrollResult = await controller.evaluateJavascript(source: currentScrollScript);
        debugPrint('🔍 ScrollPositionService - Position finale après chargement: $finalScrollResult');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ ScrollPositionService - Erreur lors de la restauration de la position de scroll: $e');
      return false;
    }
  }

  /// Démarre le timer de sauvegarde périodique de la position de scroll
  void startSaveTimer(
    InAppWebViewController controller,
    int muId,
    int chapter, {
    Duration interval = const Duration(seconds: 5),
  }) {
    stopSaveTimer();
    _currentController = controller;
    _currentMuId = muId;
    _currentChapter = chapter;

    debugPrint('🔍 ScrollPositionService - Démarrage du timer pour chapitre $chapter (muId: $muId)');

    _scrollSaveTimer = Timer.periodic(interval, (timer) {
      if (_currentController != null && _currentMuId != null && _currentChapter != null) {
        debugPrint('🔍 ScrollPositionService - Timer: sauvegarde automatique pour chapitre $_currentChapter');
        saveScrollPosition(_currentController!, _currentMuId!, _currentChapter!);
      } else {
        debugPrint('⚠️ ScrollPositionService - Timer: arrêt car paramètres manquants');
        timer.cancel();
      }
    });
  }

  /// Arrête le timer de sauvegarde
  void stopSaveTimer() {
    _scrollSaveTimer?.cancel();
    _scrollSaveTimer = null;
    _currentController = null;
    _currentMuId = null;
    _currentChapter = null;
  }

  /// Supprime la position sauvegardée d'un chapitre spécifique
  Future<void> deleteScrollPosition(int muId, int chapterNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'scroll_position_${muId}_$chapterNumber';
      await prefs.remove(key);
      debugPrint('🔍 ScrollPositionService - Position supprimée pour chapitre $chapterNumber');
    } catch (e) {
      debugPrint('⚠️ ScrollPositionService - Erreur lors de la suppression de la position: $e');
    }
  }

  /// Supprime toutes les positions sauvegardées sauf celle du chapitre actuel
  Future<void> cleanOldPositions(int muId, int currentChapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // Supprimer toutes les positions sauvegardées pour ce manga sauf celle du chapitre actuel
      for (final key in allKeys) {
        if (key.startsWith('scroll_position_${muId}_') &&
            key != 'scroll_position_${muId}_$currentChapter') {
          await prefs.remove(key);
          debugPrint('🔍 ScrollPositionService - Position supprimée: $key');
        }
      }
    } catch (e) {
      debugPrint('⚠️ ScrollPositionService - Erreur lors du nettoyage des anciennes positions: $e');
    }
  }

  /// Dispose des ressources
  void dispose() {
    stopSaveTimer();
  }
}

