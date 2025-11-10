// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'Content de vous revoir';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get login => 'Se connecter';

  @override
  String get back => 'Retour';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get invalidCredentials => 'Identifiants invalides';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get trending => 'Tendances';

  @override
  String get popular => 'Populaires';

  @override
  String get newMangas => 'Nouveau';

  @override
  String get offlineMode => 'Mode hors ligne';

  @override
  String get offlineModeNoCache => 'Mode hors ligne - Aucune donnée en cache';

  @override
  String get offlineModeActionQueued => 'Mode hors ligne - Action en queue';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return '$count action$_temp0 en attente';
  }

  @override
  String get retry => 'Réessayer';

  @override
  String get error => 'Erreur';

  @override
  String get library => 'Bibliothèque';

  @override
  String get search => 'Recherche';

  @override
  String get profile => 'Mon compte';

  @override
  String get account => 'Compte';

  @override
  String get settings => 'Paramètres';

  @override
  String get actions => 'Actions';

  @override
  String get changePassword => 'Modifier le mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Changez votre mot de passe de connexion';

  @override
  String get accountInformation => 'Informations du compte';

  @override
  String get email => 'Email';

  @override
  String get notifications => 'Notifications';

  @override
  String get manageNotifications => 'Gérer les notifications';

  @override
  String get theme => 'Thème';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutSubtitle => 'Déconnectez-vous de votre compte';

  @override
  String get confirmLogout => 'Se déconnecter';

  @override
  String get confirmLogoutMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle => 'Action irréversible';

  @override
  String get confirmDeleteAccount => 'Supprimer le compte';

  @override
  String get confirmDeleteAccountMessage =>
      'Cette action est irréversible. Toutes vos données seront définitivement supprimées et ne pourront pas être récupérées.';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get passwordChangedSuccess => 'Mot de passe modifié avec succès';

  @override
  String get passwordChangeError =>
      'Erreur lors de la modification du mot de passe';

  @override
  String get accountDeletedSuccess => 'Compte supprimé avec succès';

  @override
  String get accountDeleteError => 'Erreur lors de la suppression du compte';

  @override
  String get userInfoLoadError =>
      'Impossible de charger les informations utilisateur';

  @override
  String get user => 'Utilisateur';

  @override
  String get comingSoon => 'Fonctionnalité à venir';

  @override
  String get comingSoonAvatar =>
      'Fonctionnalité à venir : changement d\'avatar';

  @override
  String get whatsNew => 'Quoi de neuf ?';

  @override
  String get version => 'Version';

  @override
  String get newFeaturesAvailable => 'Nouvelles fonctionnalités disponibles';

  @override
  String get currentVersion => 'Version actuelle';

  @override
  String get great => 'Super !';

  @override
  String get authorizationRequired => 'Autorisation requise';

  @override
  String get modifyLink => 'Modifier le lien';

  @override
  String get removeLink => 'Supprimer le lien';

  @override
  String get chapterSkip => 'Saut de chapitres';

  @override
  String get validateReading => 'Valider la lecture';

  @override
  String get addToLibrary => 'Ajouter à la bibliothèque';

  @override
  String get removeFromLibrary => 'Retirer de la bibliothèque';

  @override
  String get updateStatus => 'Mettre à jour le statut';

  @override
  String get reading => 'En cours';

  @override
  String get completed => 'Terminé';

  @override
  String get onHold => 'En pause';

  @override
  String get dropped => 'Abandonné';

  @override
  String get planToRead => 'Prévu';

  @override
  String get reReading => 'Relecture';

  @override
  String get chapters => 'Chapitres';

  @override
  String get readChapters => 'Chapitres lus';

  @override
  String get totalChapters => 'Total de chapitres';

  @override
  String get associatedNames => 'Noms associés';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count noms',
      one: '$count nom',
      zero: 'Aucun nom',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => 'Enregistrer la progression';

  @override
  String get description => 'Description';

  @override
  String get authors => 'Auteurs';

  @override
  String get genres => 'Genres';

  @override
  String get recommendations => 'Recommandations';

  @override
  String get loading => 'Chargement...';

  @override
  String get noData => 'Aucune donnée disponible';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get home => 'Accueil';

  @override
  String get myAccount => 'Mon compte';

  @override
  String get offlineModeCached => 'Mode hors ligne - Données en cache';

  @override
  String get biometricAuthFailed => 'Échec de l\'authentification biométrique';

  @override
  String get biometricAuth => 'Connexion biométrique';

  @override
  String get addLink => 'Ajouter un lien';

  @override
  String get addOrModifyLink => 'Ajouter ou modifier un lien';

  @override
  String get linkUrlPlaceholder => 'https://exemple.com';

  @override
  String get validate => 'Valider';

  @override
  String get invalidLink =>
      'Lien invalide. Le lien doit commencer par http:// ou https://';

  @override
  String get linkSaved => 'Lien enregistré !';

  @override
  String get linkRemoved => 'Lien supprimé !';

  @override
  String get readOnline => 'Lire en ligne';

  @override
  String get manageLink => 'Gérer le lien';

  @override
  String get recommendedMangas => 'Mangas recommandés';

  @override
  String get noRecommendationsAvailable => 'Aucune recommandation disponible.';

  @override
  String get close => 'Fermer';

  @override
  String get changeStatus => 'Changer le statut';

  @override
  String get mangaAddedToLibrary => 'Manga ajouté à la bibliothèque';

  @override
  String get mangaMarkedAs => 'Manga marqué comme';

  @override
  String get readLater => 'À lire plus tard';

  @override
  String get upToDate => 'À jour';

  @override
  String get addToReadLater => 'Ajouter à \"À lire plus tard\"';

  @override
  String get mangaRemovedFromLibrary => 'Manga retiré de la bibliothèque';

  @override
  String get searchPlaceholder => 'Rechercher Mangas, Manwhas, ...';

  @override
  String get year => 'Année';

  @override
  String get status => 'Statut';

  @override
  String get author => 'Auteur';

  @override
  String get artist => 'Artiste';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get seeMore => 'Voir plus';

  @override
  String get seeLess => 'Voir moins';

  @override
  String get all => 'Tous';

  @override
  String get newReleases => 'Nouveautés';

  @override
  String get chapter => 'Chapitre';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapitres',
      one: '$count chapitre',
      zero: 'Aucun chapitre',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return 'Chapitre $chapter enregistré';
  }

  @override
  String get chapterRead => 'lu';

  @override
  String get chapterUnread => 'non lu';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title a été ajouté à la bibliothèque !';
  }

  @override
  String get errorAddingToLibrary =>
      'Erreur lors de l\'ajout à la bibliothèque.';

  @override
  String get errorUpdatingChapter =>
      'Erreur lors de la mise à jour du chapitre.';

  @override
  String cannotOpenLink(String url) {
    return 'Impossible d\'ouvrir le lien : $url';
  }

  @override
  String get searchHistoryTitle => 'Historique de recherche';

  @override
  String get searchEmptyStateMessage => 'Recherchez un manga, manhwa ou manhua';

  @override
  String get clear => 'Effacer';

  @override
  String get biometricAuthTitle => 'Authentification biométrique';

  @override
  String get biometricAuthSubtitle =>
      'Utiliser l\'empreinte digitale ou le Face ID pour se connecter rapidement';

  @override
  String get enableBiometricAuth => 'Activer l\'authentification biométrique';

  @override
  String get disableBiometricAuth => 'Authentification biométrique désactivée';

  @override
  String get biometricAuthEnabled => 'Activée';

  @override
  String get biometricAuthDisabled => 'Désactivée';

  @override
  String get biometricAuthFirstTimeTitle =>
      'Activer l\'authentification biométrique ?';

  @override
  String get biometricAuthFirstTimeMessage =>
      'Souhaitez-vous utiliser votre empreinte digitale ou Face ID pour vous connecter rapidement à l\'avenir ?';

  @override
  String get biometricAuthNotAvailable =>
      'L\'authentification biométrique n\'est pas disponible sur cet appareil';

  @override
  String get biometricAuthRequiresReconnect =>
      'Pour activer l\'authentification biométrique, veuillez vous reconnecter';

  @override
  String get or => 'Ou';

  @override
  String get startTrackingNow => 'Commencez à suivre votre lecture maintenant';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get confirmPassword => 'Confirmation';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get validationEmailRequired => 'Veuillez entrer votre adresse e-mail';

  @override
  String get validationEmailInvalid =>
      'Veuillez entrer une adresse e-mail valide';

  @override
  String get validationPasswordRequired => 'Veuillez entrer votre mot de passe';

  @override
  String get validationPasswordLength =>
      'Votre mot de passe doit comporter entre 8 et 64 caractères';

  @override
  String get validationPasswordComplexity =>
      'Votre mot de passe doit contenir au moins une lettre minuscule, une lettre majuscule et un caractère spécial';

  @override
  String get validationConfirmPasswordRequired =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get validationPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get emailAlreadyUsed => 'Cette adresse e-mail est déjà utilisée';

  @override
  String get networkError => 'Veuillez vérifier votre connexion internet';

  @override
  String get timeoutError =>
      'Le serveur met trop de temps à répondre. Veuillez réessayer.';

  @override
  String get passwordStrengthLabel => 'Robustesse du mot de passe';

  @override
  String get passwordStrengthWeak => 'Faible';

  @override
  String get passwordStrengthMedium => 'Moyen';

  @override
  String get passwordStrengthStrong => 'Fort';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get yesValidate => 'Oui, valider';

  @override
  String chapterSkipMessage(String prev, String next) {
    return 'Vous passez du chapitre $prev au $next.\nMarquer $prev comme lu ?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return 'Avez-vous fini le chapitre $chapter ?';
  }

  @override
  String get validateReadingHint =>
      'Votre progression sera sauvegardée automatiquement.';

  @override
  String get adBlockerTitle => 'Bloqueur de publicités';

  @override
  String get adBlockerDescription =>
      'Le bloqueur de publicités bloque automatiquement les publicités sur les sites de lecture.\n\nSi vous souhaitez ajouter des liens ou suggérer des améliorations pour le blocage de publicités, rejoignez notre serveur Discord !';

  @override
  String get adBlockerTooltip => 'Informations sur le bloqueur de pub';

  @override
  String get joinDiscord => 'Rejoindre Discord';

  @override
  String get joinDiscordSubtitle =>
      'Partagez vos suggestions et signalez des problèmes';

  @override
  String get contactUs => 'Nous contacter';

  @override
  String get discordLinkError => 'Impossible d\'ouvrir le lien Discord';

  @override
  String get urlCopied => 'URL copiée dans le presse-papiers';

  @override
  String get urlCopyError => 'Erreur lors de la copie de l\'URL';

  @override
  String get copyUrl => 'Copier l\'URL';

  @override
  String get progressUpdated => 'Progression mise à jour';

  @override
  String get invalidUrl => 'URL invalide';

  @override
  String get webModeProgressTracking => 'Mode Web - Suivi de progression';

  @override
  String get webModeProgressDescription =>
      'Pour suivre votre progression, collez l\'URL du chapitre que vous êtes en train de lire.';

  @override
  String get chapterUrlLabel => 'URL du chapitre';

  @override
  String get updateProgress => 'Mettre à jour la progression';

  @override
  String get openInNewTab => 'Ouvrir dans un nouvel onglet';

  @override
  String get linkUrlLabel => 'URL du site de scan';

  @override
  String get linkFormatInfo => 'Format de chapitre requis';

  @override
  String get linkFormatDescription =>
      'Incluez le numéro de chapitre dans l\'URL pour permettre la sauvegarde automatique de progression.\n\nFormats acceptés :\n• /chapitre-23/ ou /chapter-23/\n• /c23/ ou /ch23/\n• /ep-23/ ou /episode-23/\n• ?chapter=23 ou ?num=24';

  @override
  String get linkFormatWarning =>
      'Aucun format de chapitre détecté. Le lien redirigera vers la page du manga (pas un chapitre spécifique).';

  @override
  String get linkFormatDetected =>
      'Format de chapitre détecté ! La progression sera sauvegardée automatiquement.';
}
