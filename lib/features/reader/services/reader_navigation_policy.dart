/// Politique de navigation du lecteur en ligne.
///
/// ## Invariant produit (NON NÉGOCIABLE)
///
/// Pendant la lecture, **toute navigation de la frame principale vers un
/// domaine autre que celui du lien saisi par l'utilisateur est annulée**.
/// C'est la protection anti-redirection publicitaire : sans elle, un clic
/// (ou un script) suffit à envoyer le lecteur sur une page de publicité, et
/// le bouton « retour » ne ramène pas toujours au chapitre.
///
/// Cette classe est **pure** (deux prédicats injectés, aucune dépendance
/// Flutter ni GetIt) afin que l'invariant soit verrouillé par des tests
/// unitaires : `test/features/reader/reader_navigation_policy_test.dart`.
///
/// ⚠️ Elle ne sert à rien si la WebView ne l'interroge pas. Le réglage
/// `useShouldOverrideUrlLoading` doit rester à `true` (voir
/// [ReaderWebViewSettings]) et `controller.setSettings(...)` ne doit jamais
/// être appelé sur la WebView du lecteur — c'est exactement ce qui a
/// désactivé cette protection en v0.13.0.
class ReaderNavigationPolicy {
  const ReaderNavigationPolicy({
    required this.blocksRequest,
    required this.allowsHost,
  });

  /// `true` si l'URL appartient à l'infrastructure publicitaire
  /// (typiquement `AdBlockerService.shouldBlockRequest`).
  final bool Function(String url) blocksRequest;

  /// `true` si l'hôte est autorisé pour la frame principale : même site que
  /// le lien de l'utilisateur, ou infrastructure de défi anti-robot
  /// (typiquement `AdBlockerService.isAllowedDomain` lié à l'hôte d'origine).
  final bool Function(String host) allowsHost;

  /// Décide du sort d'une navigation.
  ///
  /// Ordre des règles, du plus strict au plus permissif :
  ///  1. URL absente → laisser faire (rien à juger) ;
  ///  2. URL publicitaire → annuler, quelle que soit la frame ;
  ///  3. frame principale vers un hôte non autorisé → annuler ;
  ///  4. sinon → autoriser (les sous-frames restent libres : images, CDN,
  ///     widget de défi…).
  ReaderNavigationDecision decide({
    required Uri? url,
    required bool isForMainFrame,
  }) {
    if (url == null) return ReaderNavigationDecision.allow;
    if (blocksRequest(url.toString())) return ReaderNavigationDecision.cancel;
    if (isForMainFrame && !allowsHost(url.host)) {
      return ReaderNavigationDecision.cancel;
    }
    return ReaderNavigationDecision.allow;
  }
}

/// Résultat de [ReaderNavigationPolicy.decide].
enum ReaderNavigationDecision {
  /// La navigation peut avoir lieu.
  allow,

  /// La navigation est bloquée : la page courante reste affichée.
  cancel,
}
