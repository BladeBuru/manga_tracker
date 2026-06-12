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
