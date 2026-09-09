/// Pagination des recommandations personnalisées — source unique de vérité.
///
/// ## Pourquoi une constante partagée
///
/// `GET /recommendations` ne garantit **pas** que la réponse pour `limit=10`
/// soit le préfixe de la réponse pour `limit=50` : côté serveur, `limit` et
/// `offset` font partie de la clé de cache, si bien que deux tailles de page
/// déclenchent **deux calculs complets et indépendants** du classement. Ce
/// calcul n'étant pas déterministe (tris sans départage secondaire, ordre
/// d'insertion produit par des requêtes concurrentes, et surtout des
/// écritures en base déclenchées en tâche de fond par la requête précédente,
/// dont le champ `type` qui pilote l'entrelacement par type d'œuvre), les
/// deux réponses n'ont aucune raison de coïncider.
///
/// Conséquence observée : le carrousel de l'accueil (`limit=10`) et la page
/// « Tout voir » (`limit=50`) affichaient les mêmes titres dans un ordre
/// différent, ce qui donnait l'impression d'un bug de cache.
///
/// Tant que le serveur ne sait pas produire un classement canonique, la
/// seule parade côté application est de **ne demander qu'une seule liste**
/// et d'en dériver les deux écrans : l'accueil affiche les
/// [kHomeRecommendationsPreview] premiers éléments de la page canonique de
/// [kRecommendationsPageSize] éléments, que la page « Tout voir » réutilise
/// telle quelle depuis le cache local (TTL 2 h).
///
/// ## Pourquoi une page canonique aussi grande
///
/// L'accueil demandait 10 éléments, il en demande désormais
/// [kRecommendationsPageSize]. Le surcoût est faible et le bilan est
/// favorable :
///
/// - le **calcul serveur ne dépend pas de `limit`** (le vivier de candidats
///   est dimensionné par la bibliothèque de l'utilisateur et par des
///   constantes, jamais par la taille de page demandée) — seule la
///   sérialisation de 40 objets supplémentaires change, soit quelques Ko
///   compressés, très loin derrière les couvertures déjà téléchargées par le
///   carrousel ;
/// - le parcours complet passe de **deux calculs serveur à un seul** :
///   ouvrir « Tout voir » après l'accueil ne coûte plus aucune requête (cache
///   local), là où il déclenchait auparavant un second classement complet ;
/// - chaque page supplémentaire étant un calcul indépendant — donc une
///   nouvelle occasion de doublon ou de trou à la frontière — une **grande**
///   première page réduit mécaniquement l'incohérence visible.
library;

/// Taille de la page canonique demandée au serveur, pour les deux écrans.
const int kRecommendationsPageSize = 50;

/// Nombre de recommandations montrées dans le carrousel de l'accueil.
const int kHomeRecommendationsPreview = 10;

/// Aperçu affiché sur l'accueil : les premiers éléments de la page canonique.
///
/// Volontairement une simple troncature — c'est *l'invariant* du chantier :
/// ce que l'utilisateur voit sur l'accueil est le **début** de ce qu'il voit
/// en dépliant. Toute logique supplémentaire ici (re-tri, filtre, mélange)
/// casserait cette propriété.
List<T> homeRecommendationsPreview<T>(List<T> canonicalPage) =>
    canonicalPage.length <= kHomeRecommendationsPreview
        ? List<T>.unmodifiable(canonicalPage)
        : List<T>.unmodifiable(
            canonicalPage.take(kHomeRecommendationsPreview),
          );
