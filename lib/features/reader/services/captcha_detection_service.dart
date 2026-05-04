import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Service pour détecter et gérer les captchas dans les WebViews
class CaptchaDetectionService {
  /// Vérifie si l'URL contient des indices de captcha
  bool urlContainsCaptcha(String url) {
    final urlLower = url.toLowerCase();
    return urlLower.contains('challenge') ||
        urlLower.contains('cf_challenge') ||
        urlLower.contains('challenges.cloudflare.com') ||
        urlLower.contains('challenge-platform.cloudflare.com') ||
        urlLower.contains('recaptcha') ||
        urlLower.contains('hcaptcha');
  }

  /// Vérifie si un domaine est lié à un captcha (à ne pas bloquer)
  bool isCaptchaDomain(String host) {
    final hostLower = host.toLowerCase();
    return hostLower.contains('cloudflare.com') ||
        hostLower.contains('challenges.cloudflare.com') ||
        hostLower.contains('challenge-platform.cloudflare.com') ||
        (hostLower.contains('google.com') && hostLower.contains('recaptcha')) ||
        hostLower.contains('hcaptcha.com') ||
        hostLower.contains('recaptcha.net');
  }

  /// Détecte la présence d'un captcha dans le DOM
  /// Retourne le type de captcha détecté ('cloudflare', 'recaptcha', 'hcaptcha', 'url', 'none')
  Future<String?> detectCaptcha(InAppWebViewController controller) async {
    try {
      // Script pour détecter les captchas (Cloudflare, reCAPTCHA, etc.)
      final captchaDetectionScript = """
        (function() {
          // Détecter les iframes Cloudflare
          const cloudflareIframes = document.querySelectorAll('iframe[src*="challenges.cloudflare.com"], iframe[src*="challenge-platform.cloudflare.com"]');
          if (cloudflareIframes.length > 0) {
            return 'cloudflare';
          }
          
          // Détecter les éléments Cloudflare
          const cfElements = document.querySelectorAll('[id*="cf-"], [class*="cf-"], [id*="challenge"], [class*="challenge"], [id*="cf_challenge"], [class*="cf_challenge"]');
          if (cfElements.length > 0) {
            return 'cloudflare';
          }
          
          // Détecter reCAPTCHA
          const recaptchaElements = document.querySelectorAll('[id*="recaptcha"], [class*="recaptcha"], iframe[src*="recaptcha"], iframe[src*="google.com/recaptcha"]');
          if (recaptchaElements.length > 0) {
            return 'recaptcha';
          }
          
          // Détecter hCaptcha
          const hcaptchaElements = document.querySelectorAll('[id*="hcaptcha"], [class*="hcaptcha"], iframe[src*="hcaptcha"]');
          if (hcaptchaElements.length > 0) {
            return 'hcaptcha';
          }
          
          // Détecter dans l'URL
          if (window.location.href.includes('challenge') || window.location.href.includes('cf_challenge')) {
            return 'url';
          }
          
          return 'none';
        })();
      """;

      final result = await controller.evaluateJavascript(source: captchaDetectionScript);
      final captchaType = result?.toString().replaceAll('"', '') ?? 'none';
      
      if (captchaType != 'none') {
        debugPrint('🔒 CaptchaDetectionService - Captcha détecté: $captchaType');
        return captchaType;
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ CaptchaDetectionService - Erreur lors de la détection du captcha: $e');
      return null;
    }
  }

  /// Vérifie si un captcha a été résolu en vérifiant la présence de cookies de clearance
  Future<bool> isCaptchaResolved(InAppWebViewController controller, WebUri url) async {
    try {
      final cookieManager = CookieManager.instance();
      final cookies = await cookieManager.getCookies(url: url);
      final hasClearanceCookie = cookies.any((c) => 
        c.name.contains('cf_clearance') || c.name.contains('clearance')
      );
      
      if (hasClearanceCookie) {
        debugPrint('✅ CaptchaDetectionService - Captcha résolu (cookie de clearance détecté)');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('⚠️ CaptchaDetectionService - Erreur lors de la vérification de résolution: $e');
      return false;
    }
  }
}

