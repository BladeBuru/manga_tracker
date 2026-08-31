/// Normalise le user-agent de la WebView Android.
///
/// ## Pourquoi
///
/// La WebView Android annonce par défaut un UA du type :
///
/// ```text
/// Mozilla/5.0 (Linux; Android 13; Pixel 7 Build/TQ3A.230805; wv)
/// AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0
/// Chrome/116.0.5845.114 Mobile Safari/537.36
/// ```
///
/// Deux jetons y sont *incohérents avec les capacités réelles du moteur* :
///
///  * `; wv` — marqueur « WebView » hérité ;
///  * `Version/4.0` — vestige de l'ancienne WebView WebKit (antérieure à
///    Chromium), alors que le moteur exécuté est bien Chromium.
///
/// Les défis anti-robot traitent ces deux jetons comme le signe d'un moteur
/// ancien et bridé, et servent alors une vérification que le moteur n'a
/// aucune chance de réussir.
///
/// ## Ce que fait (et ne fait pas) ce module
///
/// On **conserve la version de Chrome réellement embarquée** et la version
/// d'Android réelle : le UA produit décrit donc honnêtement le moteur qui
/// exécute la page. On retire uniquement les jetons trompeurs, plus le
/// `Build/…` du modèle d'appareil (qu'aucun Chrome mobile n'envoie et qui
/// n'est qu'une donnée d'empreinte).
///
/// On ne fabrique **jamais** un UA de toutes pièces : si le UA par défaut est
/// illisible ou n'est pas un UA de WebView Android, [normalize] renvoie
/// `null` et l'appelant laisse la valeur par défaut intacte.
class WebViewUserAgent {
  const WebViewUserAgent._();

  /// Retire de [defaultUserAgent] les jetons qui décrivent mal le moteur.
  ///
  /// Renvoie `null` si l'entrée est vide, illisible, ou ne contient aucun des
  /// jetons visés (dans ce cas il n'y a rien à corriger et il vaut mieux ne
  /// pas toucher au UA).
  static String? normalize(String? defaultUserAgent) {
    final source = defaultUserAgent?.trim();
    if (source == null || source.isEmpty) return null;

    // On n'intervient que sur un UA de WebView Android reconnaissable.
    if (!source.contains('Android')) return null;

    var ua = source;
    final hadWebViewToken =
        ua.contains('; wv)') || ua.contains(' wv)') || ua.contains('Version/4.0');
    if (!hadWebViewToken) return null;

    // 1) Marqueur WebView : « ; wv » juste avant la parenthèse fermante.
    ua = ua.replaceAll('; wv)', ')').replaceAll(' wv)', ')');

    // 2) Vestige « Version/4.0 » (ou toute variante Version/X.Y) précédant
    //    le jeton Chrome.
    ua = ua.replaceAll(RegExp(r'\bVersion/\d+(?:\.\d+)*\s+(?=Chrome/)'), '');

    // 3) Identifiant de build de l'appareil : absent de Chrome mobile et
    //    purement identifiant.
    ua = ua.replaceAll(RegExp(r'\s+Build/[^;)]+'), '');

    // Normalisation des espaces résiduels.
    ua = ua.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

    // Garde-fou : si la transformation a cassé le UA, on ne renvoie rien.
    if (!ua.contains('Chrome/') || !ua.contains('Mozilla/')) return null;
    if (ua == source) return null;

    return ua;
  }
}
