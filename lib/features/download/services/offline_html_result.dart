/// Résultat de la préparation hors ligne d'une page de chapitre.
class OfflineHtmlResult {
  const OfflineHtmlResult({
    required this.html,
    required this.imagesFound,
    required this.imagesSaved,
  });

  /// HTML réécrit vers les images locales.
  final String html;

  /// Images de la page dont une adresse réelle a été trouvée.
  final int imagesFound;

  /// Images réellement enregistrées sur l'appareil.
  final int imagesSaved;

  /// Un chapitre sans aucune image enregistrée n'est PAS un chapitre
  /// téléchargé : il ne doit jamais être marqué « terminé ».
  bool get hasContent => imagesSaved > 0;
}
