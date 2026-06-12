import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangatracker/features/reader/utils/reading_constants.dart';

/// Helper partagé pour gérer la progression de lecture (en ligne et hors ligne)
class ReadingProgressHelper {
  /// Vérifie si l'utilisateur est proche de la fin du chapitre
  /// (position ≥ [kReadingEndThresholdPercent] % — hotfix-v0-10-1 US-4).
  ///
  /// Fallback conteneur scrollable : certains lecteurs scrollent une div
  /// interne (ou un contenu iframe same-origin) au lieu de la window —
  /// `window.scrollY` reste alors à 0 et produisait un faux négatif. Si la
  /// window ne scrolle pas, on cherche le plus grand conteneur scrollable.
  /// En cas d'échec total de mesure → `false` (préférer un faux négatif à
  /// un faux « chapitre fini »).
  static Future<bool> isNearEndOfChapter(InAppWebViewController? controller) async {
    if (controller == null) return false;

    try {
      final scrollInfoScript = """
        (function() {
          const docEl = document.scrollingElement || document.documentElement;
          let scrollY = window.scrollY || window.pageYOffset || docEl.scrollTop || 0;
          let viewport = window.innerHeight || docEl.clientHeight || 0;
          let total = Math.max(
            document.body.scrollHeight,
            document.body.offsetHeight,
            docEl.scrollHeight,
            docEl.offsetHeight
          );
          // Fallback : la window ne scrolle pas → lecteur qui scrolle un
          // conteneur interne (div overflow ou iframe same-origin).
          if (total <= viewport + 1) {
            let best = null;
            try {
              const els = document.querySelectorAll('div, main, section, article');
              for (const el of els) {
                if (el.scrollHeight > el.clientHeight + 50 &&
                    el.clientHeight > viewport * 0.5) {
                  if (!best || el.scrollHeight > best.scrollHeight) best = el;
                }
              }
            } catch (e) { /* cross-origin ou DOM exotique → mesure window */ }
            if (best) {
              scrollY = best.scrollTop;
              viewport = best.clientHeight;
              total = best.scrollHeight;
            }
          }
          if (!total || total <= 0) {
            return { measurable: false, positionPercent: 0, isNearEnd: false };
          }
          const positionPercent = ((scrollY + viewport) / total) * 100;
          return {
            measurable: true,
            positionPercent: positionPercent,
            isNearEnd: positionPercent >= $kReadingEndThresholdPercent
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
          scrollInfo = Map<String, dynamic>.from(result);
        } else {
          return false;
        }

        if (scrollInfo['measurable'] != true) return false;
        final isNearEnd = scrollInfo['isNearEnd'] == true;
        final positionPercent =
            (scrollInfo['positionPercent'] as num?)?.toDouble() ?? 0.0;

        debugPrint('📊 Position dans le chapitre: ${positionPercent.toStringAsFixed(1)}% (fin: $isNearEnd)');
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

