/// Liste blanche des ressources d'infrastructure « défi anti-robot ».
///
/// Objectif : garantir qu'aucune règle du bloqueur de publicités (filtrage
/// réseau, `ContentBlocker` CSS ou nettoyage DOM en JavaScript) ne puisse
/// couper les ressources dont une page de vérification a besoin pour
/// s'afficher et aboutir.
///
/// Ce module ne résout AUCUN défi : il se contente de ne pas casser le défi
/// légitime affiché à l'utilisateur. La résolution reste 100 % manuelle.
///
/// Toutes les méthodes sont `static` et pures : testables sans GetIt.
class ChallengeAllowlist {
  const ChallengeAllowlist._();

  /// Domaines servant l'infrastructure des défis (et eux seuls).
  ///
  /// La correspondance est faite par **suffixe de domaine** et non par
  /// `contains`, afin qu'un hôte hostile du type
  /// `challenges.cloudflare.com.pub-malveillante.net` ne soit pas autorisé.
  static const Set<String> challengeDomains = {
    // Cloudflare — Turnstile et « Managed Challenge »
    'cloudflare.com',
    'challenges.cloudflare.com',
    'cloudflareinsights.com',
    // hCaptcha
    'hcaptcha.com',
    // reCAPTCHA (domaine dédié, sans dépendre de google.com en entier)
    'recaptcha.net',
  };

  /// Préfixes de chemin réservés à l'infrastructure, servis par le site
  /// d'origine lui-même (le défi « Un instant… » est servi sur l'origine).
  static const Set<String> challengePathPrefixes = {
    '/cdn-cgi/',
  };

  /// Chemins de défi hébergés sur des domaines par ailleurs génériques.
  ///
  /// `www.google.com` et `www.gstatic.com` ne sont PAS autorisés en entier :
  /// seuls leurs chemins reCAPTCHA le sont.
  static const Map<String, Set<String>> challengePathsByDomain = {
    'google.com': {'/recaptcha/'},
    'gstatic.com': {'/recaptcha/'},
  };

  /// `true` si `host` appartient à l'infrastructure de défi.
  ///
  /// Correspondance stricte : égalité, ou sous-domaine véritable
  /// (`foo.cloudflare.com` oui, `cloudflare.com.evil.net` non).
  static bool isChallengeHost(String host) {
    final h = _normalizeHost(host);
    if (h.isEmpty) return false;
    return challengeDomains.any((d) => h == d || h.endsWith('.$d'));
  }

  /// `true` si l'URL doit être préservée coûte que coûte.
  ///
  /// Couvre trois cas :
  ///  1. l'hôte est un domaine d'infrastructure de défi ;
  ///  2. le chemin est un endpoint d'infrastructure (`/cdn-cgi/…`), quel que
  ///     soit le domaine — c'est ainsi que le défi est servi sur l'origine ;
  ///  3. l'hôte est générique mais le chemin est celui d'un défi
  ///     (`www.google.com/recaptcha/…`).
  static bool isChallengeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    if (isChallengeHost(uri.host)) return true;

    final path = uri.path.isEmpty ? '/' : uri.path;
    if (challengePathPrefixes.any(path.startsWith)) return true;

    final h = _normalizeHost(uri.host);
    for (final entry in challengePathsByDomain.entries) {
      final domain = entry.key;
      final matchesDomain = h == domain || h.endsWith('.$domain');
      if (matchesDomain && entry.value.any(path.startsWith)) return true;
    }

    return false;
  }

  /// Sélecteurs CSS identifiant les éléments d'un défi dans le DOM.
  ///
  /// Injectés côté JavaScript pour que le nettoyage des publicités saute
  /// systématiquement ces éléments et leurs ancêtres.
  static const List<String> challengeSelectors = [
    '#challenge-form',
    '#challenge-stage',
    '#challenge-running',
    '#challenge-error-text',
    '#challenge-success-text',
    '#cf-challenge-running',
    '#turnstile-wrapper',
    '.cf-turnstile',
    '.cf-browser-verification',
    '.cf-im-under-attack',
    '[data-sitekey]',
    '[data-cf-turnstile-response]',
    'iframe[src*="challenges.cloudflare.com"]',
    'iframe[src*="/cdn-cgi/"]',
    'iframe[src*="hcaptcha.com"]',
    'iframe[src*="recaptcha"]',
    'iframe[title*="challenge"]',
    'iframe[title*="Widget contenant"]',
    'iframe[title*="checkbox"]',
  ];

  /// Le sélecteur groupé, prêt à passer à `closest()` / `querySelector()`.
  static String get challengeSelectorGroup => challengeSelectors.join(', ');

  static String _normalizeHost(String host) {
    var h = host.trim().toLowerCase();
    if (h.endsWith('.')) h = h.substring(0, h.length - 1);
    return h;
  }
}
