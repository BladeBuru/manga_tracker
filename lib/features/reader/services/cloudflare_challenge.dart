/// Signaux de la vérification anti-robot de Cloudflare — **pur**, sans
/// Flutter ni WebView, entièrement testable.
///
/// ## Pourquoi un signal HTTP plutôt qu'une inspection de la page
///
/// La page de défi actuelle (« Un instant… » / « Just a moment... ») ne porte
/// plus les marqueurs que `CaptchaDetectionService` cherche dans le DOM :
/// mesuré le 2026-09-27, la détection par le DOM concluait « aucune
/// vérification » à chaque tour de boucle. Cloudflare pose en revanche un
/// en-tête stable sur la réponse qui sert un défi, `cf-mitigated: challenge`.
/// Il arrive avec la réponse du document, AVANT que le moindre script du défi
/// ne s'exécute — ce qui laisse le temps de confier le défi ailleurs
/// (voir `ChallengeHandoffView`).
class CloudflareChallenge {
  const CloudflareChallenge._();

  /// En-tête posé par Cloudflare sur une réponse atténuée.
  static const String mitigatedHeader = 'cf-mitigated';

  /// Valeur de [mitigatedHeader] quand la réponse est une page de défi.
  static const String challengeValue = 'challenge';

  /// Cookie d'autorisation posé quand le défi est validé.
  static const String clearanceCookie = 'cf_clearance';

  /// La réponse est-elle une page de défi servie à la place du document
  /// principal ?
  ///
  /// Les ressources secondaires (favicon, images…) reçoivent elles aussi un
  /// 403 atténué pendant un défi : seules les réponses de la frame
  /// principale comptent.
  static bool isChallengeResponse({
    required bool isForMainFrame,
    required int? statusCode,
    required Map<String, String>? headers,
  }) {
    if (!isForMainFrame || headers == null) return false;
    if (statusCode == null || statusCode < 400) return false;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == mitigatedHeader) {
        return entry.value.trim().toLowerCase() == challengeValue;
      }
    }
    return false;
  }

  /// Le défi a-t-il été validé depuis que [before] a été relevé ?
  ///
  /// Cloudflare pose un nouveau [clearanceCookie] quand il valide un défi.
  /// [before] est la valeur relevée avant de lancer le défi (`null` si le
  /// cookie était absent). Les valeurs ne sont comparées qu'en mémoire : ce
  /// sont des jetons d'autorisation, jamais journalisés.
  static bool isClearanceRenewed({
    required String? before,
    required String? after,
  }) =>
      after != null && after.isNotEmpty && after != before;
}
