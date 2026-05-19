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
  String get googleLoginFailed => 'Échec de la connexion avec Google';

  @override
  String get loginWithGoogle => 'Se connecter avec Google';

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
  String get newChapterNotifications => 'Notifications nouveaux chapitres';

  @override
  String get newChapterNotificationsEnabled => 'Activées';

  @override
  String get newChapterNotificationsDisabled => 'Désactivées';

  @override
  String get manageNotifications => 'Gérer les notifications';

  @override
  String get notifSectionApp => 'Notifications de l\'application';

  @override
  String get notifSectionInfo => 'Informations';

  @override
  String get notifNewChaptersTitle => 'Nouveaux chapitres';

  @override
  String get notifNewChaptersSubtitle =>
      'Soyez alerté quand vos mangas suivis publient de nouveaux chapitres';

  @override
  String get notifFriendReqTitle => 'Demandes d\'ami';

  @override
  String get notifFriendReqSubtitle => 'Quelqu\'un veut vous ajouter en ami';

  @override
  String get notifSharesTitle => 'Recommandations reçues';

  @override
  String get notifSharesSubtitle => 'Un ami vous partage un manga';

  @override
  String get notifPermissionExplanation =>
      'Les notifications s\'affichent uniquement quand l\'application a la permission système. Si vous n\'en recevez aucune, activez-les depuis les réglages de votre téléphone.';

  @override
  String get notifOpenSystemSettings => 'Ouvrir les réglages système';

  @override
  String get pushNotifFriendRequestTitle => 'Nouvelle demande d\'ami';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsername veut vous ajouter en ami';
  }

  @override
  String get pushNotifShareTitle => 'Nouveau manga partagé';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsername vous recommande $mangaTitle';
  }

  @override
  String get theme => 'Thème';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get systemMode => 'Système';

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
  String get searchTitle => 'Rechercher';

  @override
  String get searchEmptyHistory => 'Aucune recherche récente';

  @override
  String get searchPopularGenres => 'Genres populaires';

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
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

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

  @override
  String get linkAddCustomPattern =>
      'Ajouter un pattern personnalisé pour ce format';

  @override
  String get customSelectors => 'Sélecteurs personnalisés';

  @override
  String get manageCustomSelectors => 'Gérer les sélecteurs';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Ajoutez des sélecteurs CSS personnalisés pour bloquer des publicités ou identifier le contenu';

  @override
  String get addCustomSelector => 'Ajouter un sélecteur';

  @override
  String get selectorDomainLabel => 'Domaine (ex: exemple.com)';

  @override
  String get selectorCssLabel => 'Sélecteur CSS';

  @override
  String get selectorTypeLabel => 'Type de sélecteur';

  @override
  String get selectorTypeUrlPattern => 'Pattern d\'URL';

  @override
  String get selectorUrlPatternLabel => 'Pattern d\'URL (regex)';

  @override
  String get selectorUrlPatternHint =>
      'Exemple : /chapter-(\\d+)/ pour détecter /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'Exemples de patterns d\'URL :';

  @override
  String get selectorExampleUrlPattern => 'Exemple : /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'Si votre site utilise \"/chapter-22\" dans l\'URL et que le système ne le détecte pas automatiquement :';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Utilisez une expression régulière (regex) avec (\\d+) pour capturer le numéro du chapitre.\n\nCe pattern sera appliqué à TOUS les sites.\n\nExemples de patterns :\n• /chapter-(\\d+)/ → détecte /chapter-22\n• /chapppter-(\\d+)/ → détecte /chapppter-22 (avec 3 p)\n• /manga/chapter-(\\d+)/ → détecte /manga/chapter-22\n• /episode-(\\d+)/ → détecte /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'ℹ️ Le pattern sera appliqué à TOUS les sites. Pas besoin de spécifier un domaine.';

  @override
  String get selectorTypeAdBlocker => 'Bloqueur de publicités';

  @override
  String get selectorTypeChapterContent => 'Contenu du chapitre';

  @override
  String get selectorDescriptionLabel => 'Description (optionnel)';

  @override
  String get selectorDescriptionHint => 'Description du sélecteur';

  @override
  String get selectorRequiredFields => 'Tous les champs sont requis';

  @override
  String get selectorAdded => 'Sélecteur ajouté';

  @override
  String get deleteSelector => 'Supprimer le sélecteur';

  @override
  String get deleteSelectorConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce sélecteur ?';

  @override
  String get selectorDeleted => 'Sélecteur supprimé';

  @override
  String get selectorsExported => 'Sélecteurs exportés dans le presse-papiers';

  @override
  String get importSelectors => 'Importer des sélecteurs';

  @override
  String get selectorsJsonLabel => 'JSON des sélecteurs';

  @override
  String get import => 'Importer';

  @override
  String selectorsImported(String count) {
    return '$count sélecteur(s) importé(s)';
  }

  @override
  String get selectorsReadyToShare =>
      'Sélecteurs prêts à être partagés ! Collez le JSON dans Discord.';

  @override
  String get exportSelectors => 'Exporter';

  @override
  String get shareSelectors => 'Partager';

  @override
  String get noCustomSelectors => 'Aucun sélecteur personnalisé';

  @override
  String get addFirstSelector =>
      'Ajoutez votre premier sélecteur pour commencer';

  @override
  String get selectorExamples => 'Exemples';

  @override
  String get selectorExamplesAdBlocker =>
      'Exemples pour bloquer des publicités :';

  @override
  String get selectorExampleAd1 => 'Bannière publicitaire';

  @override
  String get selectorExampleAd2 => 'Publicité par ID';

  @override
  String get selectorExampleAd3 => 'Iframe publicitaire';

  @override
  String get selectorExampleAd4 => 'Script publicitaire';

  @override
  String get selectorExamplesChapter =>
      'Exemples pour identifier le contenu du chapitre :';

  @override
  String get selectorExampleChapter1 => 'Conteneur de chapitre';

  @override
  String get selectorExampleChapter2 => 'Lecteur de manga';

  @override
  String get selectorExampleChapter3 => 'Images du chapitre';

  @override
  String get selectorExampleChapter4 => 'Contenu de lecture';

  @override
  String get selectorExampleChapter5 => 'Format manga/chapitre-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Exemple concret : Si votre URL est \"monsite.com/manga/chapitre-22\"';

  @override
  String get selectorUrlFormatDetected =>
      '✅ BONNE NOUVELLE : Le format \"/manga/chapitre-22\" dans l\'URL est déjà détecté automatiquement par le système !\n\nVous n\'avez PAS besoin d\'ajouter un sélecteur CSS si votre site utilise uniquement ce format dans l\'URL.';

  @override
  String get selectorWhenNeeded => 'Quand ajouter un sélecteur CSS ?';

  @override
  String get selectorPracticalExample => 'Exemple pratique :';

  @override
  String get selectorExampleScenario =>
      'Cas : Votre site utilise \"/chapppter-22\" (avec 3 p) au lieu de \"/chapter-22\"';

  @override
  String get selectorStep1 =>
      'Ouvrez la page du chapitre dans votre navigateur';

  @override
  String get selectorStep2 =>
      'Appuyez sur F12 pour ouvrir les outils de développement';

  @override
  String get selectorStep3 =>
      'Cliquez sur l\'icône \"Inspecter\" (ou Ctrl+Shift+C)';

  @override
  String get selectorStep4 =>
      'Cliquez sur le conteneur qui contient les images du chapitre';

  @override
  String get selectorStep5 =>
      'Dans le code HTML, trouvez la classe ou l\'ID du conteneur';

  @override
  String get selectorFillForm => 'Remplissez le formulaire :';

  @override
  String get selectorCssWhenNeededDesc =>
      '⚠️ UNIQUEMENT si votre site a besoin d\'un sélecteur spécifique pour identifier le contenu HTML de la page.\n\nSi le système détecte déjà bien votre chapitre via l\'URL, vous n\'avez PAS besoin d\'ajouter un sélecteur CSS.\n\nAjoutez un sélecteur CSS SEULEMENT si :\n• Le système ne détecte pas correctement le contenu du chapitre\n• Vous voulez bloquer des publicités spécifiques à ce site\n• Le site utilise des classes/IDs particuliers pour le contenu\n\nPour trouver le sélecteur : Ouvrez la page (F12 → Inspecter), trouvez le conteneur des images du chapitre, et utilisez sa classe ou ID (ex: .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Mettez uniquement le nom de domaine (sans http://, sans www, sans le chemin /manga/chapitre-22)';

  @override
  String get selectorOtherExamples => 'Autres exemples courants :';

  @override
  String get selectorExampleChapter5Desc =>
      'Pour les sites utilisant le format manga/chapitre-22 dans leurs URLs. Exemple : si votre URL est \"site.com/manga/chapitre-22\", utilisez ces sélecteurs pour identifier le contenu.';

  @override
  String get selectorExamplesHint =>
      'Astuce : Utilisez les outils de développement de votre navigateur (F12) pour inspecter les éléments et trouver les sélecteurs CSS appropriés.';

  @override
  String get captchaDetected =>
      'Captcha détecté - Le bloqueur de pub a été temporairement désactivé';

  @override
  String get captchaResolved =>
      'Captcha résolu - Le bloqueur de pub a été réactivé';

  @override
  String get scrollPositionSaved => 'Position de scroll sauvegardée';

  @override
  String get chapterProgressSaved => 'Progression du chapitre sauvegardée';

  @override
  String get readingOffline => 'Lecture hors ligne';

  @override
  String get chapterDownloaded => 'Chapitre téléchargé';

  @override
  String get offlineReadingMode => 'Mode lecture hors ligne';

  @override
  String get deleteChapterTitle => 'Supprimer le chapitre';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return 'Voulez-vous vraiment supprimer le chapitre $chapterNumber ?';
  }

  @override
  String get deleteAllChaptersTitle => 'Supprimer tous les chapitres';

  @override
  String get deleteAllChaptersMessage =>
      'Voulez-vous vraiment supprimer tous les chapitres téléchargés pour ce manga ?';

  @override
  String get deleteAllDownloadsTitle => 'Supprimer tous les téléchargements';

  @override
  String get deleteAllDownloadsMessage =>
      'Voulez-vous vraiment supprimer TOUS les téléchargements ? Cette action est irréversible.';

  @override
  String get deleteAll => 'Supprimer tout';

  @override
  String get chapterDeleted => 'Chapitre supprimé';

  @override
  String get allChaptersDeleted => 'Tous les chapitres supprimés';

  @override
  String get allDownloadsDeleted => 'Tous les téléchargements supprimés';

  @override
  String get noChaptersDownloaded => 'Aucun chapitre téléchargé';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapitres téléchargés',
      one: '1 chapitre téléchargé',
      zero: 'Aucun chapitre téléchargé',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => 'Lire';

  @override
  String get deleteAllChaptersAction => 'Supprimer tous les chapitres';

  @override
  String get deleteAllDownloadsTooltip => 'Supprimer tous les téléchargements';

  @override
  String get recommendedForYou => 'Recommandé pour toi';

  @override
  String get recommendedForYouEmpty =>
      'Ajoutez des mangas à votre bibliothèque\npour obtenir des recommandations personnalisées.';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangas',
      one: '1 manga',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached =>
      'Recommandations en cache (mode hors ligne)';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return 'Parce que vous avez aimé $titles';
  }

  @override
  String get yourRating => 'Votre note';

  @override
  String get myDataTitle => 'Mes données';

  @override
  String get myDataSubtitle => 'Voir, exporter ou supprimer mes données (RGPD)';

  @override
  String get gdprIntro =>
      'Conformément au RGPD, vous disposez de droits sur vos données personnelles. Cette page vous permet de les exercer simplement.';

  @override
  String get gdprAccessTitle => 'Voir mes données';

  @override
  String get gdprAccessSubtitle =>
      'Article 15 — résumé des informations stockées';

  @override
  String get gdprExportTitle => 'Exporter mes données';

  @override
  String get gdprExportSubtitle =>
      'Article 20 — JSON complet copié dans le presse-papier';

  @override
  String get gdprLegalDocs => 'Documents légaux';

  @override
  String get gdprDeleteHint =>
      'Pour supprimer définitivement votre compte, rendez-vous dans Profil → Supprimer mon compte. Cette action est irréversible.';

  @override
  String get privacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get termsOfServiceTitle => 'Conditions d\'utilisation';

  @override
  String get myDataInfoBanner =>
      'Conformément au RGPD, vous avez le droit d\'accéder à vos données, de les exporter et de demander leur suppression.';

  @override
  String get myDataSectionPersonalData => 'Données personnelles';

  @override
  String get myDataSectionMyRights => 'Mes droits';

  @override
  String get myDataSectionDeletion => 'Suppression';

  @override
  String get myDataSummaryTitle => 'Résumé de mes données';

  @override
  String get myDataSummarySubtitle => 'Voir un aperçu de mes données stockées';

  @override
  String get myDataExportSubtitle =>
      'Télécharger un fichier JSON complet (article 20)';

  @override
  String get privacyPolicySubtitle => 'Lire le document complet';

  @override
  String get termsOfServiceSubtitle => 'Voir les CGU';

  @override
  String get myDataDeleteAccountSubtitle => 'Action irréversible';

  @override
  String get gdprExportSuccessSnack =>
      'Vos données ont été copiées dans le presse-papier (JSON).';

  @override
  String get gdprExportFailedSnack => 'Échec de l\'export';

  @override
  String get gdprSummaryLoadFailed => 'Erreur de chargement';

  @override
  String get myDataBackLabel => 'Profil';

  @override
  String get tosShortVersion =>
      'Manga Tracker est fourni en l\'état, sans garantie. L\'éditeur décline toute responsabilité pour l\'utilisation non conforme par l\'utilisateur (contenu illégal, scraping, etc.).\n\nDocument complet sur le site officiel.';

  @override
  String get privacyShortVersion =>
      'Données collectées : email, mot de passe (hashé), bibliothèque manga, préférences. Aucune donnée n\'est vendue à des tiers. Vous pouvez exporter ou supprimer vos données à tout moment.\n\nDocument complet sur le site officiel.';

  @override
  String get iAcceptTos => 'J\'accepte les Conditions d\'utilisation';

  @override
  String get iAcceptPrivacy => 'J\'accepte la Politique de confidentialité';

  @override
  String get iAccept => 'Accepter';

  @override
  String get consentRequired =>
      'Vous devez accepter les CGU et la Politique de confidentialité.';

  @override
  String get consentRefreshTitle => 'Mise à jour de nos conditions';

  @override
  String get consentRefreshIntro =>
      'Nos conditions d\'utilisation et notre politique de confidentialité ont été mises à jour. Veuillez les accepter pour continuer.';

  @override
  String get refuseAndLogout => 'Refuser et se déconnecter';

  @override
  String get versionLabel => 'Version';

  @override
  String get welcomeTitle => 'Bienvenue !';

  @override
  String get loginSubtitle => 'Connectez-vous à votre compte';

  @override
  String get createAccountTitle => 'Créer un compte';

  @override
  String get registerSubtitle => 'Commencez à suivre vos lectures';

  @override
  String get orLoginWith => 'ou se connecter avec';

  @override
  String get orSignUpWith => 'ou s\'inscrire avec';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get loadingApp => 'Chargement…';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get forgotPasswordIntro =>
      'Entrez votre email. Si un compte existe, vous recevrez un lien pour définir un nouveau mot de passe.';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetEmailSentTitle => 'Vérifiez votre boîte mail';

  @override
  String resetEmailSentMessage(String email) {
    return 'Si un compte existe pour $email, un email contenant un lien pour définir un nouveau mot de passe vient d\'être envoyé.\n\nLe lien expire dans 30 minutes.';
  }

  @override
  String get resetPasswordTitle => 'Nouveau mot de passe';

  @override
  String get resetPasswordIntro =>
      'Définissez un nouveau mot de passe pour votre compte. Une fois validé, vous serez automatiquement connecté.';

  @override
  String get confirmReset => 'Confirmer';

  @override
  String get resetTokenExpired =>
      'Lien invalide ou expiré. Refaites une demande.';

  @override
  String get resetPasswordSuccess => 'Mot de passe modifié';

  @override
  String get resetPasswordSuccessHint =>
      'Vous êtes maintenant connecté. Redirection en cours…';

  @override
  String get verifyingEmail => 'Vérification en cours…';

  @override
  String get emailVerifiedSuccess => 'Email vérifié !';

  @override
  String get emailVerifiedHint => 'Connexion en cours…';

  @override
  String get emailVerifyFailedTitle => 'Lien invalide ou expiré';

  @override
  String get emailVerifyFailedHint =>
      'Le lien que vous avez utilisé n\'est plus valide. Connectez-vous et demandez un nouveau lien depuis votre profil.';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get verifyEmailBannerMessage =>
      'Vérifiez votre adresse email pour activer toutes les fonctionnalités.';

  @override
  String get emailSentShort => 'Envoyé';

  @override
  String get resendEmailShort => 'Renvoyer';

  @override
  String get recommendedForYouHome => 'Recommandés pour vous';

  @override
  String get seeMoreByGenre => 'Voir plus par genre';

  @override
  String get recommendationsByGenreTitle => 'Recommandations par genre';

  @override
  String get recommendationsByGenreEmpty =>
      'Pas encore de recommandations. Ajoutez des mangas à votre bibliothèque pour en obtenir.';

  @override
  String get recommendationsAllTitle => 'Toutes les recommandations';

  @override
  String get recommendationsAllEmpty =>
      'Pas encore de recommandations pour vous.';

  @override
  String get seeAllRecommendations => 'Tout voir';

  @override
  String get browseByGenre => 'Par genre';

  @override
  String get recommendationsTabAll => 'Tout';

  @override
  String get recommendationsTabByGenre => 'Par genre';

  @override
  String get statsTitle => 'Mes statistiques';

  @override
  String get statsTotalMangas => 'mangas dans votre bibliothèque';

  @override
  String statsMemberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get statsTotalChapters => 'Chapitres lus';

  @override
  String get statsReadingTime => 'Temps de lecture estimé';

  @override
  String get statsCompletionRate => 'Taux de complétion';

  @override
  String get statsLastRead => 'Dernière lecture';

  @override
  String get statsByStatusTitle => 'Répartition par statut';

  @override
  String get statsByStatusEmpty =>
      'Aucun manga dans votre bibliothèque pour le moment.';

  @override
  String get statsTopGenresTitle => 'Genres préférés';

  @override
  String get statsTopGenresEmpty =>
      'Ajoutez des mangas pour découvrir vos genres préférés.';

  @override
  String statsMinutesShort(int count) {
    return '$count min';
  }

  @override
  String statsHoursAndMinutesShort(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statsDaysAndHoursShort(int days, int hours) {
    return '$days j $hours h';
  }

  @override
  String get statusReadLater => 'À lire';

  @override
  String get statusReading => 'En cours';

  @override
  String get statusCaughtUp => 'À jour';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statsSectionOverview => 'Vue d\'ensemble';

  @override
  String get statsSectionBreakdown => 'Mangas par statut';

  @override
  String get statsSectionGenres => 'Genres préférés';

  @override
  String get statsLibraryTotal => 'Mangas dans la bibliothèque';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Membre depuis $count mois',
      one: 'Membre depuis 1 mois',
      zero: 'Membre depuis moins d\'\'un mois',
    );
    return '$_temp0';
  }

  @override
  String statsHeroBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mangas',
      one: '1 manga',
    );
    return '$_temp0';
  }

  @override
  String get profileMyStats => 'Mes statistiques';

  @override
  String get profileEditTitle => 'Modifier mon profil';

  @override
  String get profileEditBackLabel => 'Profil';

  @override
  String get profileEditMenuTitle => 'Modifier le profil';

  @override
  String get profileEditMenuSubtitle => 'Photo, pseudo, bio, confidentialité';

  @override
  String get profileFieldAvatarUrl => 'URL de l\'avatar';

  @override
  String get profileFieldDisplayName => 'Nom à afficher';

  @override
  String get profileFieldBio => 'Bio';

  @override
  String get profileFieldDateOfBirth => 'Date de naissance';

  @override
  String get profileFieldGender => 'Genre';

  @override
  String get profileGenderNotSet => 'Non renseigné';

  @override
  String get profileGenderMale => 'Homme';

  @override
  String get profileGenderFemale => 'Femme';

  @override
  String get profileGenderNonBinary => 'Non-binaire';

  @override
  String get profileGenderPreferNotToSay => 'Préfère ne pas dire';

  @override
  String get profileFieldIsPublic => 'Profil public';

  @override
  String get profileFieldIsPublicSubtitle =>
      'Visible par les autres utilisateurs';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get profileSaveFailed => 'Échec de l\'enregistrement';

  @override
  String get friendsTitle => 'Amis';

  @override
  String get friendsTabAccepted => 'Amis';

  @override
  String get friendsTabPending => 'Demandes';

  @override
  String get friendsSearchLabel => 'Trouver un ami';

  @override
  String get friendsSearchHint => 'Tapez un pseudo (min 2 caractères)';

  @override
  String get friendsAddRequest => 'Envoyer une demande';

  @override
  String get friendsAccept => 'Accepter';

  @override
  String get friendsReject => 'Refuser';

  @override
  String get friendsRemove => 'Supprimer';

  @override
  String get friendsRequestSent => 'Demande envoyée';

  @override
  String get friendsError => 'Erreur';

  @override
  String get friendsEmptyAccepted => 'Aucun ami pour l\'instant';

  @override
  String get friendsEmptyAcceptedSubtitle =>
      'Recherche des utilisateurs pour les ajouter.';

  @override
  String get friendsEmptyPending => 'Aucune demande en attente';

  @override
  String get friendsEmptyPendingSubtitle =>
      'Les demandes reçues s\'afficheront ici.';

  @override
  String get friendsSectionAccepted => 'Mes amis';

  @override
  String get friendsSectionPending => 'Demandes reçues';

  @override
  String get friendsSearchClear => 'Effacer';

  @override
  String get friendsSearchResults => 'Résultats';

  @override
  String get friendsSearchEmpty => 'Aucun utilisateur trouvé.';

  @override
  String get profileMyFriends => 'Mes amis';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get commentsEmpty =>
      'Aucun commentaire pour le moment. Soyez le premier !';

  @override
  String get commentsSortRecent => 'Récent';

  @override
  String get commentsSortTop => 'Populaire';

  @override
  String get commentsInputHint => 'Partagez votre avis (3-2000 caractères)';

  @override
  String get commentsPost => 'Publier';

  @override
  String get commentsDelete => 'Supprimer';

  @override
  String get commentsLoadMore => 'Voir plus';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses',
      one: '1 réponse',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get shareTitle => 'Partager ce manga';

  @override
  String get shareMessageHint => 'Ajouter un message (optionnel)';

  @override
  String get shareCancel => 'Annuler';

  @override
  String get shareSend => 'Envoyer';

  @override
  String get shareSuccess => 'Manga partagé';

  @override
  String get shareFailed => 'Échec du partage';

  @override
  String get shareLoadError => 'Impossible de charger vos amis';

  @override
  String get shareNoFriends =>
      'Vous n\'avez pas encore d\'amis avec qui partager. Ajoutez-en depuis la page Amis.';

  @override
  String get inboxTitle => 'Recommandations reçues';

  @override
  String get inboxEmpty => 'Aucune recommandation pour l\'instant.';

  @override
  String get inboxBadgeNew => 'NOUVEAU';

  @override
  String inboxSenderRecommends(String sender) {
    return '$sender vous recommande';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$sender vous a partagé';
  }

  @override
  String get inboxFilterAll => 'Toutes';

  @override
  String get inboxFilterUnread => 'Non lues';

  @override
  String get inboxFilterRead => 'Lues';

  @override
  String get inboxGroupToday => 'Aujourd\'hui';

  @override
  String get inboxGroupYesterday => 'Hier';

  @override
  String get inboxGroupThisWeek => 'Cette semaine';

  @override
  String get inboxGroupOlder => 'Plus tôt';

  @override
  String get inboxEmptyTitle => 'Aucune recommandation';

  @override
  String get inboxEmptySubtitle =>
      'Demande à tes amis de te partager leurs lectures préférées.';

  @override
  String get inboxEmptyFilteredUnread => 'Aucune recommandation non lue.';

  @override
  String get inboxEmptyFilteredRead => 'Aucune recommandation lue.';

  @override
  String get profileMyInbox => 'Recommandations reçues';

  @override
  String get readingGroupsTitle => 'Lectures à deux';

  @override
  String get readingGroupsEmpty =>
      'Aucun groupe de lecture pour le moment. Crée-en un depuis la fiche d\'un manga.';

  @override
  String get readingGroupDetailTitle => 'Groupe de lecture';

  @override
  String get readingGroupMembersTitle => 'Membres';

  @override
  String get readingGroupOwnerBadge => 'OWNER';

  @override
  String get readingGroupOpenManga => 'Ouvrir le manga';

  @override
  String get readingGroupNotStarted => 'Pas commencé';

  @override
  String readingGroupChaptersRead(int count) {
    return 'Chap. $count';
  }

  @override
  String get readingGroupChaptersReadLabel => 'lus';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => 'Lectures à deux';

  @override
  String get profileSectionPublicInfo => 'Informations publiques';

  @override
  String get profileSectionAbout => 'À propos de vous';

  @override
  String get profileSectionPrivacy => 'Confidentialité';

  @override
  String get profileNotSet => 'Non renseigné';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileEditAvatarHeroHint =>
      'L\'aperçu se met à jour quand tu colles une URL d\'image.';

  @override
  String get profileEditPickPhoto => 'Choisir une photo';

  @override
  String get profileEditClearAvatar => 'Effacer';

  @override
  String get profileEditPhotoPickFailed =>
      'Impossible de sélectionner la photo';

  @override
  String get profileGenderClear => 'Effacer';

  @override
  String get avatarUrlLabel => 'URL de l\'avatar';

  @override
  String get avatarUrlInvalid =>
      'L\'URL doit commencer par http:// ou https://';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileFieldUsername => 'Nom d\'utilisateur';

  @override
  String get profileFieldEmail => 'Adresse e-mail';

  @override
  String get profileFieldReadOnly => 'Non modifiable';

  @override
  String get profileChangePhoto => 'Modifier la photo';

  @override
  String get changelogCardTitle => 'Notes de version';

  @override
  String get readingGroupCreateTitle => 'Lire à deux';

  @override
  String get readingGroupCreateNameLabel => 'Nom du groupe (optionnel)';

  @override
  String get readingGroupCreateNameHint => 'ex: Berserk avec Léa';

  @override
  String get readingGroupCreateInviteSection => 'Inviter des amis';

  @override
  String get readingGroupCreateConfirm => 'Créer le groupe';

  @override
  String get readingGroupCreateFailed => 'Création du groupe échouée';

  @override
  String get readingGroupCreateInviteRequired =>
      'Sélectionne au moins un ami pour créer le groupe';

  @override
  String get readingGroupDelete => 'Supprimer le groupe';

  @override
  String get readingGroupDeleteConfirmTitle => 'Supprimer ce groupe ?';

  @override
  String get readingGroupDeleteConfirm =>
      'Cette action est irréversible. Tous les membres perdront l\'accès au groupe.';

  @override
  String get readingGroupDeleteSuccess => 'Groupe supprimé';

  @override
  String get readingGroupDeleteFailed => 'Suppression du groupe échouée';

  @override
  String get readingGroupSharedReading => 'Lecture partagée';

  @override
  String get readingGroupViewGroup => 'Voir le groupe';

  @override
  String get readingGroupChapterShort => 'ch.';

  @override
  String get profileHighlightTitle => 'Nouvelles fonctionnalités';

  @override
  String get profileNewBadge => 'Nouveau';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => 'Mes groupes';

  @override
  String readingGroupWithLabel(String name) {
    return 'Avec $name';
  }

  @override
  String get readingGroupYouLabel => 'Toi';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return 'Toi : ch. $you · $friend : ch. $their';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => 'Lecture en cours';

  @override
  String get readingGroupSectionProgress => 'Progression';

  @override
  String get readingGroupSectionActions => 'Actions';

  @override
  String get readingGroupActionsMarkProgress => 'Marquer ma progression';

  @override
  String get readingGroupActionsMarkProgressSubtitle =>
      'Ouvrir la fiche du manga pour avancer';

  @override
  String get readingGroupActionsInvite => 'Inviter un ami';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return 'Copier le lien de $friend';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return 'Adapté au chapitre $chapter';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return 'Lien enregistré sur le chapitre $chapter';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return 'Lien copié — chapitre $chapter';
  }

  @override
  String get readingGroupCopyLinkFailed =>
      'Impossible d\'adapter ce lien (format non reconnu)';

  @override
  String get readingGroupActionsInviteSubtitle =>
      'Ajouter une personne au groupe';

  @override
  String get readingGroupActionsLeave => 'Quitter le groupe';

  @override
  String get readingGroupActionsLeaveSubtitle =>
      'Tu ne verras plus la progression partagée';

  @override
  String get readingGroupActionsDeleteSubtitle =>
      'Supprimer définitivement pour tous les membres';

  @override
  String get readingGroupLeaveConfirmTitle => 'Quitter ce groupe ?';

  @override
  String get readingGroupLeaveConfirm =>
      'Tu n\'auras plus accès à la progression partagée.';

  @override
  String get readingGroupLeaveSuccess => 'Tu as quitté le groupe';

  @override
  String get readingGroupLeaveFailed => 'Impossible de quitter le groupe';

  @override
  String get readingGroupEmptyTitle => 'Aucune lecture à deux';

  @override
  String get readingGroupEmptySubtitle =>
      'Démarre un manga avec un ami et suivez votre progression ensemble.';

  @override
  String get readingGroupEmptyAction => 'Découvrir un manga';

  @override
  String get readingGroupTotalLabel => 'Total';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count ch.';
  }

  @override
  String get readingGroupInviteSoonTitle => 'Bientôt disponible';

  @override
  String get readingGroupInviteSoonMessage =>
      'L\'invitation depuis le groupe arrive très bientôt. Pour l\'instant, recrée un groupe depuis la fiche d\'un manga.';

  @override
  String get libraryToggleListView => 'Vue liste';

  @override
  String get libraryToggleCardView => 'Vue carte';

  @override
  String get libraryShowDownloadedOnly => 'Afficher uniquement les téléchargés';

  @override
  String get libraryShowAllMangas => 'Afficher tous les mangas';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$read sur $total chapitres lus';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
      zero: 'Aucun vote',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => 'Mangas similaires';

  @override
  String get rating => 'Note';
}
