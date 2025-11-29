// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get login => 'Anmelden';

  @override
  String get back => 'Zurück';

  @override
  String get signUp => 'Registrieren';

  @override
  String get invalidCredentials => 'Ungültige Anmeldedaten';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get trending => 'Trending';

  @override
  String get popular => 'Beliebt';

  @override
  String get newMangas => 'Neu';

  @override
  String get offlineMode => 'Offline-Modus';

  @override
  String get offlineModeNoCache => 'Offline-Modus - Keine gecachten Daten';

  @override
  String get offlineModeActionQueued =>
      'Offline-Modus - Aktion in Warteschlange';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en',
      one: '',
      zero: 'en',
    );
    return '$count ausstehende Aktion$_temp0';
  }

  @override
  String get retry => 'Wiederholen';

  @override
  String get error => 'Fehler';

  @override
  String get library => 'Bibliothek';

  @override
  String get search => 'Suche';

  @override
  String get profile => 'Profil';

  @override
  String get account => 'Konto';

  @override
  String get settings => 'Einstellungen';

  @override
  String get actions => 'Aktionen';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordSubtitle => 'Ändern Sie Ihr Anmelde-Passwort';

  @override
  String get accountInformation => 'Kontoinformationen';

  @override
  String get email => 'E-Mail';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get newChapterNotifications => 'Notifications nouveaux chapitres';

  @override
  String get newChapterNotificationsEnabled => 'Activées';

  @override
  String get newChapterNotificationsDisabled => 'Désactivées';

  @override
  String get manageNotifications => 'Benachrichtigungen verwalten';

  @override
  String get theme => 'Design';

  @override
  String get lightMode => 'Helles Design';

  @override
  String get darkMode => 'Dunkles Design';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get french => 'Französisch';

  @override
  String get english => 'Englisch';

  @override
  String get logout => 'Abmelden';

  @override
  String get logoutSubtitle => 'Von Ihrem Konto abmelden';

  @override
  String get confirmLogout => 'Abmelden';

  @override
  String get confirmLogoutMessage => 'Möchten Sie sich wirklich abmelden?';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountSubtitle => 'Unwiderrufliche Aktion';

  @override
  String get confirmDeleteAccount => 'Konto löschen';

  @override
  String get confirmDeleteAccountMessage =>
      'Diese Aktion ist unwiderruflich. Alle Ihre Daten werden dauerhaft gelöscht und können nicht wiederhergestellt werden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get passwordChangedSuccess => 'Passwort erfolgreich geändert';

  @override
  String get passwordChangeError => 'Fehler beim Ändern des Passworts';

  @override
  String get accountDeletedSuccess => 'Konto erfolgreich gelöscht';

  @override
  String get accountDeleteError => 'Fehler beim Löschen des Kontos';

  @override
  String get userInfoLoadError =>
      'Benutzerinformationen konnten nicht geladen werden';

  @override
  String get user => 'Benutzer';

  @override
  String get comingSoon => 'Demnächst verfügbar';

  @override
  String get comingSoonAvatar => 'Demnächst verfügbar: Avatar ändern';

  @override
  String get whatsNew => 'Was ist neu?';

  @override
  String get version => 'Version';

  @override
  String get newFeaturesAvailable => 'Neue Funktionen verfügbar';

  @override
  String get currentVersion => 'Aktuelle Version';

  @override
  String get great => 'Großartig!';

  @override
  String get authorizationRequired => 'Autorisierung erforderlich';

  @override
  String get modifyLink => 'Link ändern';

  @override
  String get removeLink => 'Link entfernen';

  @override
  String get chapterSkip => 'Kapitel überspringen';

  @override
  String get validateReading => 'Lesen validieren';

  @override
  String get addToLibrary => 'Zur Bibliothek hinzufügen';

  @override
  String get removeFromLibrary => 'Aus Bibliothek entfernen';

  @override
  String get updateStatus => 'Status aktualisieren';

  @override
  String get reading => 'Lesen';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get onHold => 'Pausiert';

  @override
  String get dropped => 'Abgebrochen';

  @override
  String get planToRead => 'Geplant';

  @override
  String get reReading => 'Wiederlesen';

  @override
  String get chapters => 'Kapitel';

  @override
  String get readChapters => 'Gelesene Kapitel';

  @override
  String get totalChapters => 'Gesamtkapitel';

  @override
  String get associatedNames => 'Zugehörige Namen';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Namen',
      one: '$count Name',
      zero: 'Keine Namen',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => 'Fortschritt speichern';

  @override
  String get description => 'Beschreibung';

  @override
  String get authors => 'Autoren';

  @override
  String get genres => 'Genres';

  @override
  String get recommendations => 'Empfehlungen';

  @override
  String get loading => 'Laden...';

  @override
  String get noData => 'Keine Daten verfügbar';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get noAccount => 'Haben Sie kein Konto?';

  @override
  String get home => 'Startseite';

  @override
  String get myAccount => 'Mein Konto';

  @override
  String get offlineModeCached => 'Offline-Modus - Gecachte Daten';

  @override
  String get biometricAuthFailed =>
      'Biometrische Authentifizierung fehlgeschlagen';

  @override
  String get biometricAuth => 'Biometrische Anmeldung';

  @override
  String get addLink => 'Link hinzufügen';

  @override
  String get addOrModifyLink => 'Link hinzufügen oder ändern';

  @override
  String get linkUrlPlaceholder => 'https://beispiel.com';

  @override
  String get validate => 'Validieren';

  @override
  String get invalidLink =>
      'Ungültiger Link. Der Link muss mit http:// oder https:// beginnen';

  @override
  String get linkSaved => 'Link gespeichert!';

  @override
  String get linkRemoved => 'Link entfernt!';

  @override
  String get readOnline => 'Online lesen';

  @override
  String get manageLink => 'Link verwalten';

  @override
  String get recommendedMangas => 'Empfohlene Mangas';

  @override
  String get noRecommendationsAvailable => 'Keine Empfehlungen verfügbar.';

  @override
  String get close => 'Schließen';

  @override
  String get changeStatus => 'Status ändern';

  @override
  String get mangaAddedToLibrary => 'Manga zur Bibliothek hinzugefügt';

  @override
  String get mangaMarkedAs => 'Manga markiert als';

  @override
  String get readLater => 'Später lesen';

  @override
  String get upToDate => 'Aktuell';

  @override
  String get addToReadLater => 'Zu \"Später lesen\" hinzufügen';

  @override
  String get mangaRemovedFromLibrary => 'Manga aus Bibliothek entfernt';

  @override
  String get searchPlaceholder => 'Mangas, Manwhas suchen...';

  @override
  String get year => 'Jahr';

  @override
  String get status => 'Status';

  @override
  String get author => 'Autor';

  @override
  String get artist => 'Künstler';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get seeMore => 'Mehr anzeigen';

  @override
  String get seeLess => 'Weniger anzeigen';

  @override
  String get all => 'Alle';

  @override
  String get newReleases => 'Neuerscheinungen';

  @override
  String get chapter => 'Kapitel';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapitel',
      one: '$count Kapitel',
      zero: 'Keine Kapitel',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return 'Kapitel $chapter gespeichert';
  }

  @override
  String get chapterRead => 'gelesen';

  @override
  String get chapterUnread => 'ungelesen';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title wurde zur Bibliothek hinzugefügt!';
  }

  @override
  String get errorAddingToLibrary => 'Fehler beim Hinzufügen zur Bibliothek.';

  @override
  String get errorUpdatingChapter => 'Fehler beim Aktualisieren des Kapitels.';

  @override
  String cannotOpenLink(String url) {
    return 'Link kann nicht geöffnet werden: $url';
  }

  @override
  String get searchHistoryTitle => 'Suchverlauf';

  @override
  String get searchEmptyStateMessage =>
      'Suchen Sie nach einem Manga, Manhwa oder Manhua';

  @override
  String get clear => 'Löschen';

  @override
  String get biometricAuthTitle => 'Biometrische Authentifizierung';

  @override
  String get biometricAuthSubtitle =>
      'Verwenden Sie Fingerabdruck oder Face ID für schnelles Anmelden';

  @override
  String get enableBiometricAuth => 'Biometrische Authentifizierung aktiviert';

  @override
  String get disableBiometricAuth =>
      'Biometrische Authentifizierung deaktiviert';

  @override
  String get biometricAuthEnabled => 'Aktiviert';

  @override
  String get biometricAuthDisabled => 'Deaktiviert';

  @override
  String get biometricAuthFirstTimeTitle =>
      'Biometrische Authentifizierung aktivieren?';

  @override
  String get biometricAuthFirstTimeMessage =>
      'Möchten Sie in Zukunft Ihren Fingerabdruck oder Face ID für schnelles Anmelden verwenden?';

  @override
  String get biometricAuthNotAvailable =>
      'Biometrische Authentifizierung ist auf diesem Gerät nicht verfügbar';

  @override
  String get biometricAuthRequiresReconnect =>
      'Um die biometrische Authentifizierung zu aktivieren, melden Sie sich bitte erneut an';

  @override
  String get or => 'Oder';

  @override
  String get startTrackingNow =>
      'Beginnen Sie jetzt, Ihre Lektüre zu verfolgen';

  @override
  String get username => 'Benutzername';

  @override
  String get confirmPassword => 'Bestätigen';

  @override
  String get alreadyHaveAccount => 'Haben Sie bereits ein Konto?';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get validationEmailRequired =>
      'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get validationEmailInvalid =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get validationPasswordRequired => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String get validationPasswordLength =>
      'Ihr Passwort muss zwischen 8 und 64 Zeichen lang sein';

  @override
  String get validationPasswordComplexity =>
      'Ihr Passwort muss mindestens einen Kleinbuchstaben, einen Großbuchstaben und ein Sonderzeichen enthalten';

  @override
  String get validationConfirmPasswordRequired =>
      'Bitte bestätigen Sie Ihr Passwort';

  @override
  String get validationPasswordsDoNotMatch =>
      'Die Passwörter stimmen nicht überein';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort ausblenden';

  @override
  String get emailAlreadyUsed => 'Diese E-Mail-Adresse ist bereits registriert';

  @override
  String get networkError => 'Bitte überprüfen Sie Ihre Internetverbindung';

  @override
  String get timeoutError =>
      'Der Server benötigt zu lange für die Antwort. Bitte versuchen Sie es erneut.';

  @override
  String get passwordStrengthLabel => 'Passwortstärke';

  @override
  String get passwordStrengthWeak => 'Schwach';

  @override
  String get passwordStrengthMedium => 'Mittel';

  @override
  String get passwordStrengthStrong => 'Stark';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get yesValidate => 'Ja, bestätigen';

  @override
  String chapterSkipMessage(String prev, String next) {
    return 'Sie springen von Kapitel $prev zu $next.\n$prev als gelesen markieren?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return 'Haben Sie Kapitel $chapter beendet?';
  }

  @override
  String get validateReadingHint =>
      'Ihr Fortschritt wird automatisch gespeichert.';

  @override
  String get adBlockerTitle => 'Werbeblocker';

  @override
  String get adBlockerDescription =>
      'Der Werbeblocker blockiert automatisch Werbung auf Leseseiten.\n\nWenn Sie Links hinzufügen oder Verbesserungen für die Werbeblockierung vorschlagen möchten, treten Sie unserem Discord-Server bei!';

  @override
  String get adBlockerTooltip => 'Informationen zum Werbeblocker';

  @override
  String get joinDiscord => 'Discord beitreten';

  @override
  String get joinDiscordSubtitle =>
      'Teilen Sie Ihre Vorschläge und melden Sie Probleme';

  @override
  String get contactUs => 'Kontaktieren Sie uns';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'Discord-Link kann nicht geöffnet werden';

  @override
  String get urlCopied => 'URL in Zwischenablage kopiert';

  @override
  String get urlCopyError => 'Fehler beim Kopieren der URL';

  @override
  String get copyUrl => 'URL kopieren';

  @override
  String get progressUpdated => 'Fortschritt aktualisiert';

  @override
  String get invalidUrl => 'Ungültige URL';

  @override
  String get webModeProgressTracking => 'Web-Modus - Fortschrittsverfolgung';

  @override
  String get webModeProgressDescription =>
      'Um Ihren Fortschritt zu verfolgen, fügen Sie die URL des Kapitels ein, das Sie gerade lesen.';

  @override
  String get chapterUrlLabel => 'Kapitel-URL';

  @override
  String get updateProgress => 'Fortschritt aktualisieren';

  @override
  String get openInNewTab => 'In neuem Tab öffnen';

  @override
  String get linkUrlLabel => 'Scan-Site-URL';

  @override
  String get linkFormatInfo => 'Kapitelformat erforderlich';

  @override
  String get linkFormatDescription =>
      'Fügen Sie die Kapitelnummer in die URL ein, um das automatische Speichern des Fortschritts zu ermöglichen.\n\nAkzeptierte Formate:\n• /kapitel-23/ oder /chapter-23/\n• /c23/ oder /ch23/\n• /ep-23/ oder /episode-23/\n• ?chapter=23 oder ?num=24';

  @override
  String get linkFormatWarning =>
      'Kein Kapitelformat erkannt. Der Link leitet zur Manga-Seite weiter (nicht zu einem bestimmten Kapitel).';

  @override
  String get linkFormatDetected =>
      'Kapitelformat erkannt! Der Fortschritt wird automatisch gespeichert.';

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
      'Captcha erkannt - Werbeblocker wurde vorübergehend deaktiviert';

  @override
  String get captchaResolved =>
      'Captcha gelöst - Werbeblocker wurde wieder aktiviert';

  @override
  String get scrollPositionSaved => 'Scroll-Position gespeichert';

  @override
  String get chapterProgressSaved => 'Kapitelfortschritt gespeichert';

  @override
  String get readingOffline => 'Offline lesen';

  @override
  String get chapterDownloaded => 'Kapitel heruntergeladen';

  @override
  String get offlineReadingMode => 'Offline-Lesemodus';
}
