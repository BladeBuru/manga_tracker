import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Fabrique les réglages de la WebView du lecteur.
///
/// ## Règle absolue
///
/// Ces réglages sont posés **une seule fois**, via `initialSettings`, à la
/// création de la WebView. **Ne jamais appeler `controller.setSettings(...)`**
/// sur la WebView du lecteur, même « juste pour changer une valeur » :
/// côté Android, `setSettings` remplace l'objet de réglages *entier* par un
/// objet neuf où tout ce qui n'est pas renseigné reprend sa valeur par
/// défaut. C'est ainsi qu'en v0.13.0 `useShouldOverrideUrlLoading` est
/// silencieusement repassé à `false`, rendant le garde anti-redirection
/// inerte (toutes les publicités passaient). Le test
/// `test/features/reader/reader_invariants_test.dart` verrouille cette règle.
class ReaderWebViewSettings {
  const ReaderWebViewSettings._();

  static InAppWebViewSettings build({
    required List<ContentBlocker> contentBlockers,
  }) {
    return InAppWebViewSettings(
      javaScriptEnabled: true,
      mediaPlaybackRequiresUserGesture: true,
      contentBlockers: contentBlockers,
      allowsInlineMediaPlayback: true,
      iframeAllow: 'camera; microphone',
      iframeAllowFullscreen: true,

      // --- Protection anti-redirection ---------------------------------
      // EXPLICITE, pas inféré : le plugin ne le déduit de la présence du
      // callback `shouldOverrideUrlLoading` que pour les réglages initiaux.
      // Sans ce `true`, `shouldOverrideUrlLoading` n'est jamais appelé et
      // `ReaderNavigationPolicy` ne protège plus rien.
      useShouldOverrideUrlLoading: true,

      // Pas de fenêtres surgissantes : un `window.open()` publicitaire
      // n'ouvre rien ; s'il navigue dans la vue courante, il repasse par
      // `shouldOverrideUrlLoading` et se fait annuler.
      supportMultipleWindows: false,
      javaScriptCanOpenWindowsAutomatically: false,

      // --- Vérifications anti-robot (Cloudflare & co.) -------------------
      // Le user-agent est celui de la plateforme, INCHANGÉ. Un user-agent
      // modifié qui ne contient plus le user-agent par défaut fait cesser
      // l'envoi des indices client (`Sec-CH-UA`) par la WebView Android :
      // un navigateur qui se dit Chrome sans envoyer ce que Chrome envoie
      // toujours est précisément ce que les vérifications anti-robot
      // signalent comme incohérent. Décision documentée dans
      // `.claude/memory-bank/decisions.md`.

      // La WebView Android ajoute à chaque requête l'en-tête
      // `X-Requested-With: <nom du paquet de l'app>`. Il ne sert à aucun site
      // de lecture, identifie l'application auprès de tiers, et Android
      // lui-même le retire progressivement (API d'opt-in par origine). Une
      // liste vide = envoyé à aucune origine. Sans effet sur les WebView qui
      // ne supportent pas la fonctionnalité (le plugin vérifie avant).
      requestedWithHeaderOriginAllowList: const <String>{},

      // --- Persistance du cookie d'autorisation ------------------------
      // Ces quatre réglages valent déjà `true` par défaut dans
      // flutter_inappwebview 6.x ; ils sont rendus explicites parce que le
      // cookie `cf_clearance` posé par une vérification réussie doit
      // survivre aux rechargements et aux navigations internes. Les
      // repasser à `false` ferait reboucler la vérification à chaque page.
      domStorageEnabled: true,
      databaseEnabled: true,
      thirdPartyCookiesEnabled: true,
      cacheEnabled: true,

      // iOS : par défaut `false`. Sans le magasin de cookies partagé, le
      // cookie d'autorisation ne survit pas d'une WebView à l'autre.
      sharedCookiesEnabled: true,

      // Explicites par sécurité : en navigation privée, le cookie
      // d'autorisation serait jeté à la fermeture et la vérification
      // recommencerait à chaque ouverture du lecteur.
      incognito: false,
      clearCache: false,
    );
  }
}
