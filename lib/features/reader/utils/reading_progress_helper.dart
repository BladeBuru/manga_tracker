import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Helper partagé pour gérer la progression de lecture (en ligne et hors ligne)
class ReadingProgressHelper {
  /// Vérifie si l'utilisateur est proche de la fin du chapitre (dans les 15% de la fin)
  static Future<bool> isNearEndOfChapter(InAppWebViewController? controller) async {
    if (controller == null) return false;
    
    try {
      final scrollInfoScript = """
        (function() {
          const scrollY = window.scrollY || window.pageYOffset || document.documentElement.scrollTop || 0;
          const windowHeight = window.innerHeight || document.documentElement.clientHeight || 0;
          const documentHeight = Math.max(
            document.body.scrollHeight,
            document.body.offsetHeight,
            document.documentElement.clientHeight,
            document.documentElement.scrollHeight,
            document.documentElement.offsetHeight
          );
          const scrollBottom = scrollY + windowHeight;
          const totalHeight = documentHeight;
          const distanceFromEnd = totalHeight - scrollBottom;
          const percentageFromEnd = (distanceFromEnd / totalHeight) * 100;
          
          return {
            scrollY: scrollY,
            windowHeight: windowHeight,
            documentHeight: documentHeight,
            scrollBottom: scrollBottom,
            distanceFromEnd: distanceFromEnd,
            percentageFromEnd: percentageFromEnd,
            isNearEnd: percentageFromEnd <= 15
          };
        })();
      """;
      
      final result = await controller.evaluateJavascript(source: scrollInfoScript);
      if (result != null) {
        Map<String, dynamic> scrollInfo;
        
        // Le résultat peut être une chaîne JSON ou déjà un objet selon la plateforme
        if (result is String) {
          try {
            scrollInfo = jsonDecode(result) as Map<String, dynamic>;
          } catch (e) {
            debugPrint('⚠️ Erreur lors du parsing JSON: $e');
            return false;
          }
        } else if (result is Map) {
          scrollInfo = result as Map<String, dynamic>;
        } else {
          return false;
        }
        
        final isNearEnd = scrollInfo['isNearEnd'] == true;
        final percentageFromEnd = scrollInfo['percentageFromEnd'] as double? ?? 100.0;
        
        debugPrint('📊 Position dans le chapitre: ${percentageFromEnd.toStringAsFixed(1)}% de la fin (proche: $isNearEnd)');
        return isNearEnd;
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la vérification de la position: $e');
    }
    
    return false;
  }

  /// Récupère la position de scroll actuelle
  static Future<double?> getScrollPosition(InAppWebViewController? controller) async {
    if (controller == null) return null;
    
    try {
      final scrollScript = """
        (function() {
          return window.scrollY || window.pageYOffset || document.documentElement.scrollTop || 0;
        })();
      """;
      
      final scrollResult = await controller.evaluateJavascript(source: scrollScript);
      final scrollPosition = scrollResult != null ? double.tryParse(scrollResult.toString()) : null;
      
      return scrollPosition;
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la récupération de la position de scroll: $e');
      return null;
    }
  }

  /// Restaure la position de scroll
  static Future<void> restoreScrollPosition(
    InAppWebViewController? controller,
    double scrollPosition,
  ) async {
    if (controller == null || scrollPosition <= 0) return;
    
    try {
      // Attendre un peu pour que le DOM soit prêt
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Essayer plusieurs fois au cas où le DOM n'est pas encore prêt
      for (int i = 0; i < 3; i++) {
        await controller.evaluateJavascript(source: 'window.scrollTo(0, $scrollPosition);');
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      debugPrint('✅ Position de scroll restaurée: $scrollPosition');
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la restauration de la position de scroll: $e');
    }
  }
}

