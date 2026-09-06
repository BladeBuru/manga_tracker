/// Constantes partagées du suivi de lecture (hotfix-v0-10-1 US-4).
///
/// Avant, deux seuils incohérents coexistaient sur deux échelles inversées :
///  - popup « Avez-vous fini ? » si `percentageFromEnd <= 15` (≈ position ≥ 85 %)
///  - rejet de la sauvegarde du scroll si `position > 95 %`
/// → trou entre 85 et 95 % où l'utilisateur n'était ni sauvegardé ni détecté
/// en fin de chapitre.
///
/// Désormais UNE seule échelle (% de position depuis le haut) et UN seul
/// seuil :
///  - position < [kReadingEndThresholdPercent] → zone « lecture en cours » :
///    sauvegarde + restauration du scroll ;
///  - position ≥ [kReadingEndThresholdPercent] → zone « fin de chapitre » :
///    pas de sauvegarde, popup de validation au retour.
///
/// Pourquoi 85 : la fin d'un scan contient commentaires/credits (~10-15 % de
/// la page) — 85 % couvre la fin réelle de lecture sans faux positifs en
/// milieu de chapitre. Ajustable ici en une seule ligne.
const int kReadingEndThresholdPercent = 85;

/// Délai maximal accordé à la mesure « suis-je proche de la fin ? » avant de
/// conclure « non » et de laisser l'utilisateur sortir.
///
/// La mesure s'exécute dans la page (JavaScript) : une page figée, un défi
/// anti-robot ou une WebView en cours de destruction peuvent ne jamais
/// répondre. Sans borne, le retour paraîtrait bloqué. En cas d'expiration on
/// préfère un faux négatif (pas de question) à une sortie qui ne réagit pas.
const Duration kNearEndMeasureTimeout = Duration(seconds: 3);

/// Préfixe des positions de défilement **en pixels**, par manga et chapitre
/// (`scroll_position_<muId>_<chapitre>`), dans `SharedPreferences`.
///
/// Mesurées sur CET appareil, donc plus fidèles qu'un pourcentage pour y
/// revenir : c'est la valeur utilisée quand on rouvre le même chapitre sur le
/// même téléphone.
const String kScrollPositionKeyPrefix = 'scroll_position_';

/// Préfixe du « marque-page » local, un par manga
/// (`reading_position_<muId>`), dans `SharedPreferences`.
///
/// Même forme que la réponse du serveur (chapitre + pourcentage +
/// horodatage) : c'est ce qui permet d'arbitrer entre la lecture locale et
/// celle d'un autre appareil sans avoir à convertir des pixels.
const String kReadingBookmarkKeyPrefix = 'reading_position_';
