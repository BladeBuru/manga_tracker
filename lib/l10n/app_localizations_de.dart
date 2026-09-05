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
  String get googleLoginFailed => 'Google-Anmeldung fehlgeschlagen';

  @override
  String get googleLoginConfigError =>
      'Google-Anmeldung nicht verfügbar (App-Konfigurationsfehler)';

  @override
  String get googlePopupBlocked =>
      'Anmeldefenster vom Browser blockiert — erlauben Sie Pop-ups für diese Website und versuchen Sie es erneut';

  @override
  String get loginWithGoogle => 'Mit Google anmelden';

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
  String get searchNoResults => 'Keine Ergebnisse gefunden';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '1 Ergebnis',
    );
    return '$_temp0';
  }

  @override
  String get searchLoadFailed => 'Die Suche ist fehlgeschlagen';

  @override
  String get searchLoadMoreFailed =>
      'Weitere Ergebnisse konnten nicht geladen werden';

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
  String get changePasswordTitle => 'Mein Passwort ändern';

  @override
  String get changePasswordIntro =>
      'Geben Sie Ihr aktuelles Passwort ein und wählen Sie dann ein neues. Ihre anderen Geräte werden abgemeldet.';

  @override
  String get currentPasswordLabel => 'Aktuelles Passwort';

  @override
  String get newPasswordLabel => 'Neues Passwort';

  @override
  String get confirmNewPasswordLabel => 'Neues Passwort bestätigen';

  @override
  String get changePasswordSuccess => 'Passwort geändert';

  @override
  String get changePasswordSuccessHint =>
      'Ihre anderen Geräte wurden abgemeldet. Zurück zum Profil…';

  @override
  String get changePasswordWrongCurrent => 'Das aktuelle Passwort ist falsch';

  @override
  String get changePasswordSocialAccount =>
      'Dieses Konto nutzt die Google-Anmeldung: Es gibt kein Passwort zu ändern';

  @override
  String get accountInformation => 'Kontoinformationen';

  @override
  String get email => 'E-Mail';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get newChapterNotifications => 'Benachrichtigungen für neue Kapitel';

  @override
  String get newChapterNotificationsEnabled => 'Aktiviert';

  @override
  String get newChapterNotificationsDisabled => 'Deaktiviert';

  @override
  String get manageNotifications => 'Benachrichtigungen verwalten';

  @override
  String get notifSectionApp => 'App-Benachrichtigungen';

  @override
  String get notifSectionInfo => 'Informationen';

  @override
  String get notifNewChaptersTitle => 'Neue Kapitel';

  @override
  String get notifNewChaptersSubtitle =>
      'Werden Sie benachrichtigt, wenn Ihre verfolgten Mangas neue Kapitel veröffentlichen';

  @override
  String get notifFriendReqTitle => 'Freundschaftsanfragen';

  @override
  String get notifFriendReqSubtitle =>
      'Jemand möchte Sie als Freund hinzufügen';

  @override
  String get notifSharesTitle => 'Erhaltene Empfehlungen';

  @override
  String get notifSharesSubtitle => 'Ein Freund teilt einen Manga mit Ihnen';

  @override
  String get notifPermissionExplanation =>
      'Benachrichtigungen erscheinen nur, wenn die App die Systemberechtigung hat. Wenn Sie keine erhalten, aktivieren Sie sie in den Telefoneinstellungen.';

  @override
  String get notifOpenSystemSettings => 'Systemeinstellungen öffnen';

  @override
  String get pushNotifFriendRequestTitle => 'Neue Freundschaftsanfrage';

  @override
  String pushNotifFriendRequestBody(String senderUsername) {
    return '$senderUsername möchte Sie als Freund hinzufügen';
  }

  @override
  String get pushNotifShareTitle => 'Neuer Manga geteilt';

  @override
  String pushNotifShareBody(String senderUsername, String mangaTitle) {
    return '$senderUsername empfiehlt Ihnen $mangaTitle';
  }

  @override
  String get theme => 'Design';

  @override
  String get lightMode => 'Helles Design';

  @override
  String get darkMode => 'Dunkles Design';

  @override
  String get systemMode => 'System';

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
  String get chapterNotFound => 'Kapitel nicht gefunden';

  @override
  String get previousChapterTooltip => 'Vorheriges Kapitel';

  @override
  String get nextChapterTooltip => 'Nächstes Kapitel';

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
  String get searchTitle => 'Suchen';

  @override
  String get searchEmptyHistory => 'Keine kürzlichen Suchanfragen';

  @override
  String get searchPopularGenres => 'Beliebte Genres';

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
  String get downloads => 'Downloads';

  @override
  String get manageDownloads => 'Downloads verwalten';

  @override
  String get manageDownloadsSubtitle =>
      'Heruntergeladene Kapitel ansehen und löschen';

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
      'Eigenes Muster für dieses Format hinzufügen';

  @override
  String get customSelectors => 'Benutzerdefinierte Selektoren';

  @override
  String get manageCustomSelectors => 'Selektoren verwalten';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Fügen Sie eigene CSS-Selektoren hinzu, um Werbung zu blockieren oder Inhalte zu erkennen';

  @override
  String get addCustomSelector => 'Selektor hinzufügen';

  @override
  String get selectorDomainLabel => 'Domain (z. B. beispiel.de)';

  @override
  String get selectorCssLabel => 'CSS-Selektor';

  @override
  String get selectorTypeLabel => 'Selektortyp';

  @override
  String get selectorTypeUrlPattern => 'URL-Muster';

  @override
  String get selectorUrlPatternLabel => 'URL-Muster (Regex)';

  @override
  String get selectorUrlPatternHint =>
      'Beispiel: /chapter-(\\d+)/ erkennt /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'Beispiele für URL-Muster:';

  @override
  String get selectorExampleUrlPattern => 'Beispiel: /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'Wenn Ihre Website \"/chapter-22\" in der URL verwendet und das System dies nicht automatisch erkennt:';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Verwenden Sie einen regulären Ausdruck (Regex) mit (\\d+), um die Kapitelnummer zu erfassen.\n\nDieses Muster wird auf ALLE Websites angewendet.\n\nBeispiele für Muster:\n• /chapter-(\\d+)/ → erkennt /chapter-22\n• /chapppter-(\\d+)/ → erkennt /chapppter-22 (mit 3 p)\n• /manga/chapter-(\\d+)/ → erkennt /manga/chapter-22\n• /episode-(\\d+)/ → erkennt /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'Das Muster wird auf ALLE Websites angewendet. Es ist keine Domain erforderlich.';

  @override
  String get selectorTypeAdBlocker => 'Werbeblocker';

  @override
  String get selectorTypeChapterContent => 'Kapitelinhalt';

  @override
  String get selectorDescriptionLabel => 'Beschreibung (optional)';

  @override
  String get selectorDescriptionHint => 'Beschreibung des Selektors';

  @override
  String get selectorRequiredFields => 'Alle Felder sind erforderlich';

  @override
  String get selectorAdded => 'Selektor hinzugefügt';

  @override
  String get deleteSelector => 'Selektor löschen';

  @override
  String get deleteSelectorConfirm =>
      'Möchten Sie diesen Selektor wirklich löschen?';

  @override
  String get selectorDeleted => 'Selektor gelöscht';

  @override
  String get selectorsExported => 'Selektoren in die Zwischenablage exportiert';

  @override
  String get importSelectors => 'Selektoren importieren';

  @override
  String get selectorsJsonLabel => 'JSON der Selektoren';

  @override
  String get import => 'Importieren';

  @override
  String selectorsImported(String count) {
    return '$count Selektor(en) importiert';
  }

  @override
  String get selectorsReadyToShare =>
      'Selektoren bereit zum Teilen! Fügen Sie das JSON in Discord ein.';

  @override
  String get exportSelectors => 'Exportieren';

  @override
  String get shareSelectors => 'Teilen';

  @override
  String get noCustomSelectors => 'Keine benutzerdefinierten Selektoren';

  @override
  String get addFirstSelector =>
      'Fügen Sie Ihren ersten Selektor hinzu, um loszulegen';

  @override
  String get selectorExamples => 'Beispiele';

  @override
  String get selectorExamplesAdBlocker =>
      'Beispiele zum Blockieren von Werbung:';

  @override
  String get selectorExampleAd1 => 'Werbebanner';

  @override
  String get selectorExampleAd2 => 'Werbung nach ID';

  @override
  String get selectorExampleAd3 => 'Werbe-Iframe';

  @override
  String get selectorExampleAd4 => 'Werbeskript';

  @override
  String get selectorExamplesChapter =>
      'Beispiele zum Erkennen des Kapitelinhalts:';

  @override
  String get selectorExampleChapter1 => 'Kapitel-Container';

  @override
  String get selectorExampleChapter2 => 'Manga-Reader';

  @override
  String get selectorExampleChapter3 => 'Kapitelbilder';

  @override
  String get selectorExampleChapter4 => 'Leseinhalt';

  @override
  String get selectorExampleChapter5 => 'Format manga/chapter-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Konkretes Beispiel: Wenn Ihre URL \"meineseite.de/manga/chapter-22\" lautet';

  @override
  String get selectorUrlFormatDetected =>
      'GUTE NACHRICHT: Das Format \"/manga/chapter-22\" in der URL wird vom System bereits automatisch erkannt!\n\nSie müssen KEINEN CSS-Selektor hinzufügen, wenn Ihre Website ausschließlich dieses URL-Format verwendet.';

  @override
  String get selectorWhenNeeded =>
      'Wann sollte ein CSS-Selektor hinzugefügt werden?';

  @override
  String get selectorPracticalExample => 'Praktisches Beispiel:';

  @override
  String get selectorExampleScenario =>
      'Fall: Ihre Website verwendet \"/chapppter-22\" (mit 3 p) statt \"/chapter-22\"';

  @override
  String get selectorStep1 => 'Öffnen Sie die Kapitelseite in Ihrem Browser';

  @override
  String get selectorStep2 =>
      'Drücken Sie F12, um die Entwicklertools zu öffnen';

  @override
  String get selectorStep3 =>
      'Klicken Sie auf das Symbol \"Untersuchen\" (oder Strg+Umschalt+C)';

  @override
  String get selectorStep4 =>
      'Klicken Sie auf den Container, der die Kapitelbilder enthält';

  @override
  String get selectorStep5 =>
      'Suchen Sie im HTML-Code die Klasse oder ID des Containers';

  @override
  String get selectorFillForm => 'Füllen Sie das Formular aus:';

  @override
  String get selectorCssWhenNeededDesc =>
      'NUR wenn Ihre Website einen bestimmten Selektor benötigt, um den HTML-Inhalt der Seite zu erkennen.\n\nWenn das System Ihr Kapitel bereits über die URL korrekt erkennt, müssen Sie KEINEN CSS-Selektor hinzufügen.\n\nFügen Sie einen CSS-Selektor NUR hinzu, wenn:\n• das System den Kapitelinhalt nicht korrekt erkennt\n• Sie Werbung blockieren möchten, die speziell auf dieser Website erscheint\n• die Website besondere Klassen/IDs für den Inhalt verwendet\n\nSo finden Sie den Selektor: Öffnen Sie die Seite (F12 → Untersuchen), suchen Sie den Container mit den Kapitelbildern und verwenden Sie dessen Klasse oder ID (z. B. .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Geben Sie nur den Domainnamen ein (ohne http://, ohne www, ohne den Pfad /manga/chapter-22)';

  @override
  String get selectorOtherExamples => 'Weitere gängige Beispiele:';

  @override
  String get selectorExampleChapter5Desc =>
      'Für Websites, die das Format manga/chapter-22 in ihren URLs verwenden. Beispiel: Wenn Ihre URL \"site.com/manga/chapter-22\" lautet, verwenden Sie diese Selektoren, um den Inhalt zu erkennen.';

  @override
  String get selectorExamplesHint =>
      'Tipp: Verwenden Sie die Entwicklertools Ihres Browsers (F12), um Elemente zu untersuchen und passende CSS-Selektoren zu finden.';

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

  @override
  String get deleteChapterTitle => 'Kapitel löschen';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return 'Möchten Sie Kapitel $chapterNumber wirklich löschen?';
  }

  @override
  String get deleteAllChaptersTitle => 'Alle Kapitel löschen';

  @override
  String get deleteAllChaptersMessage =>
      'Möchten Sie wirklich alle heruntergeladenen Kapitel für diesen Manga löschen?';

  @override
  String get deleteAllDownloadsTitle => 'Alle Downloads löschen';

  @override
  String get deleteAllDownloadsMessage =>
      'Möchten Sie wirklich ALLE Downloads löschen? Diese Aktion ist unwiderruflich.';

  @override
  String get deleteAll => 'Alles löschen';

  @override
  String get chapterDeleted => 'Kapitel gelöscht';

  @override
  String get allChaptersDeleted => 'Alle Kapitel gelöscht';

  @override
  String get allDownloadsDeleted => 'Alle Downloads gelöscht';

  @override
  String get noChaptersDownloaded => 'Keine Kapitel heruntergeladen';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kapitel heruntergeladen',
      one: '1 Kapitel heruntergeladen',
      zero: 'Keine Kapitel heruntergeladen',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => 'Lesen';

  @override
  String get deleteAllChaptersAction => 'Alle Kapitel löschen';

  @override
  String get deleteAllDownloadsTooltip => 'Alle Downloads löschen';

  @override
  String get recommendedForYou => 'Für dich empfohlen';

  @override
  String get recommendedForYouEmpty =>
      'Füge Mangas zu deiner Bibliothek hinzu,\num personalisierte Empfehlungen zu erhalten.';

  @override
  String recommendedForYouCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mangas',
      one: '1 Manga',
    );
    return '$_temp0';
  }

  @override
  String get recommendedForYouCached =>
      'Empfehlungen aus dem Cache (Offline-Modus)';

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String recommendedBecauseOf(String titles) {
    return 'Weil du $titles mochtest';
  }

  @override
  String get yourRating => 'Deine Bewertung';

  @override
  String get myDataTitle => 'Meine Daten';

  @override
  String get myDataSubtitle =>
      'Meine Daten anzeigen, exportieren oder löschen (DSGVO)';

  @override
  String get gdprIntro =>
      'Gemäß DSGVO haben Sie Rechte an Ihren personenbezogenen Daten. Diese Seite ermöglicht Ihnen die einfache Ausübung dieser Rechte.';

  @override
  String get gdprAccessTitle => 'Meine Daten anzeigen';

  @override
  String get gdprAccessSubtitle =>
      'Artikel 15 — Übersicht der gespeicherten Informationen';

  @override
  String get gdprExportTitle => 'Meine Daten exportieren';

  @override
  String get gdprExportSubtitle =>
      'Artikel 20 — vollständiges JSON in Zwischenablage';

  @override
  String get gdprLegalDocs => 'Rechtliche Dokumente';

  @override
  String get gdprDeleteHint =>
      'Um Ihr Konto endgültig zu löschen, gehen Sie zu Profil → Konto löschen. Diese Aktion ist unwiderruflich.';

  @override
  String get privacyPolicyTitle => 'Datenschutzerklärung';

  @override
  String get termsOfServiceTitle => 'Nutzungsbedingungen';

  @override
  String get myDataInfoBanner =>
      'Gemäß DSGVO haben Sie das Recht, auf Ihre Daten zuzugreifen, sie zu exportieren und deren Löschung zu beantragen.';

  @override
  String get myDataSectionPersonalData => 'Personenbezogene Daten';

  @override
  String get myDataSectionMyRights => 'Meine Rechte';

  @override
  String get myDataSectionDeletion => 'Löschung';

  @override
  String get myDataSummaryTitle => 'Übersicht meiner Daten';

  @override
  String get myDataSummarySubtitle =>
      'Übersicht der gespeicherten Daten anzeigen';

  @override
  String get myDataExportSubtitle =>
      'Vollständige JSON-Datei herunterladen (Artikel 20)';

  @override
  String get privacyPolicySubtitle => 'Vollständiges Dokument lesen';

  @override
  String get termsOfServiceSubtitle => 'Nutzungsbedingungen anzeigen';

  @override
  String get myDataDeleteAccountSubtitle => 'Diese Aktion ist unwiderruflich';

  @override
  String get gdprExportSuccessSnack =>
      'Ihre Daten wurden in die Zwischenablage kopiert (JSON).';

  @override
  String get gdprExportFailedSnack => 'Export fehlgeschlagen';

  @override
  String get gdprSummaryLoadFailed => 'Ladefehler';

  @override
  String get myDataBackLabel => 'Profil';

  @override
  String get tosShortVersion =>
      'Manga Tracker wird ohne Gewähr bereitgestellt. Der Herausgeber lehnt jegliche Haftung für nicht konforme Nutzung durch den Benutzer ab (illegale Inhalte, Scraping usw.).\n\nVollständiges Dokument auf der offiziellen Website.';

  @override
  String get privacyShortVersion =>
      'Erfasste Daten: E-Mail, Passwort (gehasht), Manga-Bibliothek, Einstellungen. Keine Daten werden an Dritte verkauft. Sie können Ihre Daten jederzeit exportieren oder löschen.\n\nVollständiges Dokument auf der offiziellen Website.';

  @override
  String get iAcceptTos => 'Ich akzeptiere die Nutzungsbedingungen';

  @override
  String get iAcceptPrivacy => 'Ich akzeptiere die Datenschutzerklärung';

  @override
  String get iAccept => 'Akzeptieren';

  @override
  String get consentRequired =>
      'Sie müssen die Nutzungsbedingungen und die Datenschutzerklärung akzeptieren.';

  @override
  String get consentRefreshTitle => 'Unsere Bedingungen wurden aktualisiert';

  @override
  String get consentRefreshIntro =>
      'Unsere Nutzungsbedingungen und Datenschutzerklärung wurden aktualisiert. Bitte akzeptieren Sie sie, um fortzufahren.';

  @override
  String get refuseAndLogout => 'Ablehnen und abmelden';

  @override
  String get versionLabel => 'Version';

  @override
  String get welcomeTitle => 'Willkommen!';

  @override
  String get loginSubtitle => 'Melde dich in deinem Konto an';

  @override
  String get createAccountTitle => 'Konto erstellen';

  @override
  String get registerSubtitle => 'Beginne, deine Lektüre zu verfolgen';

  @override
  String get orLoginWith => 'oder anmelden mit';

  @override
  String get orSignUpWith => 'oder registrieren mit';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get loadingApp => 'Wird geladen…';

  @override
  String get forgotPasswordTitle => 'Passwort vergessen';

  @override
  String get forgotPasswordIntro =>
      'Gib deine E-Mail ein. Wenn ein Konto existiert, erhältst du einen Link, um ein neues Passwort festzulegen.';

  @override
  String get sendResetLink => 'Link senden';

  @override
  String get resetEmailSentTitle => 'Prüfe dein Postfach';

  @override
  String resetEmailSentMessage(String email) {
    return 'Wenn ein Konto für $email existiert, wurde eine E-Mail mit einem Link zur Passwortänderung gesendet.\n\nDer Link läuft in 30 Minuten ab.';
  }

  @override
  String get resetPasswordTitle => 'Neues Passwort';

  @override
  String get resetPasswordIntro =>
      'Lege ein neues Passwort für dein Konto fest. Nach der Bestätigung wirst du automatisch angemeldet.';

  @override
  String get confirmReset => 'Bestätigen';

  @override
  String get resetTokenExpired =>
      'Ungültiger oder abgelaufener Link. Bitte fordere einen neuen an.';

  @override
  String get resetPasswordSuccess => 'Passwort geändert';

  @override
  String get resetPasswordSuccessHint =>
      'Du bist jetzt angemeldet. Weiterleitung…';

  @override
  String get verifyingEmail => 'Überprüfung läuft…';

  @override
  String get emailVerifiedSuccess => 'E-Mail bestätigt!';

  @override
  String get emailVerifiedHint => 'Anmeldung läuft…';

  @override
  String get emailVerifyFailedTitle => 'Ungültiger oder abgelaufener Link';

  @override
  String get emailVerifyFailedHint =>
      'Der verwendete Link ist nicht mehr gültig. Melde dich an und fordere einen neuen Link aus deinem Profil an.';

  @override
  String get backToLogin => 'Zurück zur Anmeldung';

  @override
  String get verifyEmailBannerMessage =>
      'Bestätige deine E-Mail-Adresse, um alle Funktionen zu aktivieren.';

  @override
  String get emailSentShort => 'Gesendet';

  @override
  String get resendEmailShort => 'Erneut senden';

  @override
  String get recommendedForYouHome => 'Für dich empfohlen';

  @override
  String get seeMoreByGenre => 'Mehr nach Genre anzeigen';

  @override
  String get recommendationsByGenreTitle => 'Empfehlungen nach Genre';

  @override
  String get recommendationsByGenreEmpty =>
      'Noch keine Empfehlungen. Füge Mangas zu deiner Bibliothek hinzu, um persönliche Vorschläge zu erhalten.';

  @override
  String get recommendationsAllTitle => 'Alle Empfehlungen';

  @override
  String get recommendationsAllEmpty => 'Noch keine Empfehlungen für dich.';

  @override
  String get seeAllRecommendations => 'Alle ansehen';

  @override
  String get browseByGenre => 'Nach Genre';

  @override
  String get recommendationsTabAll => 'Alle';

  @override
  String get recommendationsTabByGenre => 'Nach Genre';

  @override
  String get statsTitle => 'Meine Statistiken';

  @override
  String get statsTotalMangas => 'Mangas in deiner Bibliothek';

  @override
  String statsMemberSince(String date) {
    return 'Mitglied seit $date';
  }

  @override
  String get statsTotalChapters => 'Gelesene Kapitel';

  @override
  String get statsReadingTime => 'Geschätzte Lesezeit';

  @override
  String get statsCompletionRate => 'Abschlussquote';

  @override
  String get statsLastRead => 'Zuletzt gelesen';

  @override
  String get statsByStatusTitle => 'Aufteilung nach Status';

  @override
  String get statsByStatusEmpty => 'Noch keine Manga in deiner Bibliothek.';

  @override
  String get statsTopGenresTitle => 'Lieblingsgenres';

  @override
  String get statsTopGenresEmpty =>
      'Füge Mangas hinzu, um deine Lieblingsgenres zu entdecken.';

  @override
  String statsMinutesShort(int count) {
    return '$count Min.';
  }

  @override
  String statsHoursAndMinutesShort(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String statsDaysAndHoursShort(int days, int hours) {
    return '$days T. $hours Std.';
  }

  @override
  String get statusReadLater => 'Zu lesen';

  @override
  String get statusReading => 'Wird gelesen';

  @override
  String get statusCaughtUp => 'Aktuell';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get statsSectionOverview => 'Übersicht';

  @override
  String get statsSectionBreakdown => 'Manga nach Status';

  @override
  String get statsSectionGenres => 'Lieblingsgenres';

  @override
  String get statsLibraryTotal => 'Mangas in deiner Bibliothek';

  @override
  String statsMonthsSinceJoin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mitglied seit $count Monaten',
      one: 'Mitglied seit 1 Monat',
      zero: 'Mitglied seit weniger als einem Monat',
    );
    return '$_temp0';
  }

  @override
  String statsHeroBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mangas',
      one: '1 Manga',
    );
    return '$_temp0';
  }

  @override
  String get profileMyStats => 'Meine Statistiken';

  @override
  String get profileEditTitle => 'Profil bearbeiten';

  @override
  String get profileEditBackLabel => 'Profil';

  @override
  String get profileEditMenuTitle => 'Profil bearbeiten';

  @override
  String get profileEditMenuSubtitle => 'Foto, Anzeigename, Bio, Privatsphäre';

  @override
  String get profileFieldAvatarUrl => 'Avatar-URL';

  @override
  String get profileFieldDisplayName => 'Anzeigename';

  @override
  String get profileFieldBio => 'Bio';

  @override
  String get profileFieldDateOfBirth => 'Geburtsdatum';

  @override
  String get profileFieldGender => 'Geschlecht';

  @override
  String get profileGenderNotSet => 'Nicht angegeben';

  @override
  String get profileGenderMale => 'Männlich';

  @override
  String get profileGenderFemale => 'Weiblich';

  @override
  String get profileGenderNonBinary => 'Nicht-binär';

  @override
  String get profileGenderPreferNotToSay => 'Möchte nicht sagen';

  @override
  String get profileFieldIsPublic => 'Öffentliches Profil';

  @override
  String get profileFieldIsPublicSubtitle => 'Sichtbar für andere Nutzer';

  @override
  String get profileSaved => 'Profil gespeichert';

  @override
  String get profileSaveFailed => 'Speichern fehlgeschlagen';

  @override
  String get friendsTitle => 'Freunde';

  @override
  String get friendsTabAccepted => 'Freunde';

  @override
  String get friendsTabPending => 'Anfragen';

  @override
  String get friendsSearchLabel => 'Freund finden';

  @override
  String get friendsSearchHint => 'Benutzername eingeben (min. 2 Zeichen)';

  @override
  String get friendsAddRequest => 'Anfrage senden';

  @override
  String get friendsAccept => 'Akzeptieren';

  @override
  String get friendsReject => 'Ablehnen';

  @override
  String get friendsRemove => 'Entfernen';

  @override
  String get friendsRequestSent => 'Anfrage gesendet';

  @override
  String get friendsError => 'Fehler';

  @override
  String get friendsEmptyAccepted => 'Noch keine Freunde';

  @override
  String get friendsEmptyAcceptedSubtitle =>
      'Suche oben nach Benutzern, um sie hinzuzufügen.';

  @override
  String get friendsEmptyPending => 'Keine offenen Anfragen';

  @override
  String get friendsEmptyPendingSubtitle =>
      'Eingehende Anfragen erscheinen hier.';

  @override
  String get friendsSectionAccepted => 'Meine Freunde';

  @override
  String get friendsSectionPending => 'Empfangene Anfragen';

  @override
  String get friendsSearchClear => 'Löschen';

  @override
  String get friendsSearchResults => 'Ergebnisse';

  @override
  String get friendsSearchEmpty => 'Kein Benutzer gefunden.';

  @override
  String get profileMyFriends => 'Meine Freunde';

  @override
  String get commentsTitle => 'Kommentare';

  @override
  String get commentsEmpty => 'Noch keine Kommentare. Sei der Erste!';

  @override
  String get commentsSortRecent => 'Neueste';

  @override
  String get commentsSortTop => 'Beliebt';

  @override
  String get commentsInputHint => 'Teile deine Meinung (3-2000 Zeichen)';

  @override
  String get commentsPost => 'Senden';

  @override
  String get commentsDelete => 'Löschen';

  @override
  String get commentsLoadMore => 'Mehr laden';

  @override
  String commentsReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Antworten',
      one: '1 Antwort',
    );
    return '$_temp0';
  }

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String timeMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String timeHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String timeDaysAgo(int count) {
    return 'vor $count T.';
  }

  @override
  String get shareTitle => 'Diesen Manga teilen';

  @override
  String get shareMessageHint => 'Nachricht hinzufügen (optional)';

  @override
  String get shareCancel => 'Abbrechen';

  @override
  String get shareSend => 'Senden';

  @override
  String get shareSuccess => 'Manga geteilt';

  @override
  String get shareFailed => 'Teilen fehlgeschlagen';

  @override
  String get shareLoadError => 'Freunde konnten nicht geladen werden';

  @override
  String get shareNoFriends =>
      'Du hast noch keine Freunde zum Teilen. Füge welche über die Freunde-Seite hinzu.';

  @override
  String get inboxTitle => 'Posteingang';

  @override
  String get inboxEmpty => 'Noch keine Empfehlungen.';

  @override
  String get inboxBadgeNew => 'NEU';

  @override
  String inboxSenderRecommends(String sender) {
    return '$sender empfiehlt';
  }

  @override
  String inboxSharedYouLabel(String sender) {
    return '$sender hat mit dir geteilt';
  }

  @override
  String get inboxFilterAll => 'Alle';

  @override
  String get inboxFilterUnread => 'Ungelesen';

  @override
  String get inboxFilterRead => 'Gelesen';

  @override
  String get inboxGroupToday => 'Heute';

  @override
  String get inboxGroupYesterday => 'Gestern';

  @override
  String get inboxGroupThisWeek => 'Diese Woche';

  @override
  String get inboxGroupOlder => 'Früher';

  @override
  String get inboxEmptyTitle => 'Keine Empfehlungen';

  @override
  String get inboxEmptySubtitle =>
      'Bitte deine Freunde, ihre Lieblingslektüre mit dir zu teilen.';

  @override
  String get inboxEmptyFilteredUnread => 'Keine ungelesenen Empfehlungen.';

  @override
  String get inboxEmptyFilteredRead => 'Keine gelesenen Empfehlungen.';

  @override
  String get profileMyInbox => 'Posteingang';

  @override
  String get readingGroupsTitle => 'Lese-Buddies';

  @override
  String get readingGroupsEmpty =>
      'Noch keine Lesegruppen. Erstelle eine über die Detailseite eines Mangas.';

  @override
  String get readingGroupDetailTitle => 'Lesegruppe';

  @override
  String get readingGroupMembersTitle => 'Mitglieder';

  @override
  String get readingGroupOwnerBadge => 'OWNER';

  @override
  String get readingGroupOpenManga => 'Manga öffnen';

  @override
  String get readingGroupNotStarted => 'Nicht begonnen';

  @override
  String readingGroupChaptersRead(int count) {
    return 'Kap. $count';
  }

  @override
  String get readingGroupChaptersReadLabel => 'gelesen';

  @override
  String readingGroupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get profileMyReadingGroups => 'Lese-Buddies';

  @override
  String get profileSectionPublicInfo => 'Öffentliche Informationen';

  @override
  String get profileSectionAbout => 'Über dich';

  @override
  String get profileSectionPrivacy => 'Privatsphäre';

  @override
  String get profileNotSet => 'Nicht angegeben';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileEditAvatarHeroHint =>
      'Die Vorschau aktualisiert sich, wenn du eine Bild-URL einfügst.';

  @override
  String get profileEditPickPhoto => 'Foto auswählen';

  @override
  String get profileEditClearAvatar => 'Löschen';

  @override
  String get profileEditPhotoPickFailed =>
      'Foto konnte nicht ausgewählt werden';

  @override
  String get profileGenderClear => 'Löschen';

  @override
  String get avatarUrlLabel => 'Avatar-URL';

  @override
  String get avatarUrlInvalid => 'URL muss mit http:// oder https:// beginnen';

  @override
  String get profileSectionAccount => 'Konto';

  @override
  String get profileFieldUsername => 'Benutzername';

  @override
  String get profileFieldEmail => 'E-Mail';

  @override
  String get profileFieldReadOnly => 'Schreibgeschützt';

  @override
  String get profileChangePhoto => 'Foto ändern';

  @override
  String get changelogCardTitle => 'Versionshinweise';

  @override
  String get readingGroupCreateTitle => 'Zusammen lesen';

  @override
  String get readingGroupCreateNameLabel => 'Gruppenname (optional)';

  @override
  String get readingGroupCreateNameHint => 'z.B. Berserk mit Lea';

  @override
  String get readingGroupCreateInviteSection => 'Freunde einladen';

  @override
  String get readingGroupCreateConfirm => 'Gruppe erstellen';

  @override
  String get readingGroupCreateFailed => 'Gruppenerstellung fehlgeschlagen';

  @override
  String get readingGroupCreateInviteRequired =>
      'Wähle mindestens einen Freund aus, um die Gruppe zu erstellen';

  @override
  String get readingGroupDelete => 'Gruppe löschen';

  @override
  String get readingGroupDeleteConfirmTitle => 'Diese Gruppe löschen?';

  @override
  String get readingGroupDeleteConfirm =>
      'Diese Aktion ist unwiderruflich. Alle Mitglieder verlieren den Zugriff auf die Gruppe.';

  @override
  String get readingGroupDeleteSuccess => 'Gruppe gelöscht';

  @override
  String get readingGroupDeleteFailed => 'Gruppenlöschung fehlgeschlagen';

  @override
  String get readingGroupSharedReading => 'Gemeinsames Lesen';

  @override
  String get readingGroupViewGroup => 'Gruppe ansehen';

  @override
  String get readingGroupChapterShort => 'Kap.';

  @override
  String get profileHighlightTitle => 'Neue Funktionen';

  @override
  String get profileNewBadge => 'Neu';

  @override
  String get profileFooterBrand => 'MANGA TRACKER';

  @override
  String get readingGroupListSectionTitle => 'Meine Gruppen';

  @override
  String readingGroupWithLabel(String name) {
    return 'Mit $name';
  }

  @override
  String get readingGroupYouLabel => 'Du';

  @override
  String readingGroupProgressYouVsFriend(
    String you,
    String friend,
    String their,
  ) {
    return 'Du: Kap. $you · $friend: Kap. $their';
  }

  @override
  String get readingGroupChapterDash => '—';

  @override
  String get readingGroupSectionHero => 'Aktuell am Lesen';

  @override
  String get readingGroupSectionProgress => 'Fortschritt';

  @override
  String get readingGroupSectionActions => 'Aktionen';

  @override
  String get readingGroupActionsMarkProgress => 'Fortschritt aktualisieren';

  @override
  String get readingGroupActionsMarkProgressSubtitle =>
      'Manga-Seite zum Weiterlesen öffnen';

  @override
  String get readingGroupActionsInvite => 'Freund einladen';

  @override
  String readingGroupActionsCopyFriendLink(String friend) {
    return '${friend}s Link kopieren';
  }

  @override
  String readingGroupActionsCopyFriendLinkSubtitle(int chapter) {
    return 'Angepasst an Kapitel $chapter';
  }

  @override
  String readingGroupApplyLinkSuccess(int chapter) {
    return 'Link bei Kapitel $chapter gespeichert';
  }

  @override
  String readingGroupCopyLinkSuccess(int chapter) {
    return 'Link kopiert — Kapitel $chapter';
  }

  @override
  String get readingGroupCopyLinkFailed =>
      'Link kann nicht angepasst werden (unbekanntes Format)';

  @override
  String get readingGroupActionsInviteSubtitle =>
      'Eine Person zur Gruppe hinzufügen';

  @override
  String get readingGroupActionsLeave => 'Gruppe verlassen';

  @override
  String get readingGroupActionsLeaveSubtitle =>
      'Du siehst den geteilten Fortschritt nicht mehr';

  @override
  String get readingGroupActionsDeleteSubtitle =>
      'Endgültig für alle Mitglieder löschen';

  @override
  String get readingGroupLeaveConfirmTitle => 'Diese Gruppe verlassen?';

  @override
  String get readingGroupLeaveConfirm =>
      'Du verlierst den Zugriff auf den geteilten Fortschritt.';

  @override
  String get readingGroupLeaveSuccess => 'Du hast die Gruppe verlassen';

  @override
  String get readingGroupLeaveFailed => 'Gruppe konnte nicht verlassen werden';

  @override
  String get readingGroupEmptyTitle => 'Noch keine gemeinsame Lektüre';

  @override
  String get readingGroupEmptySubtitle =>
      'Starte einen Manga mit einem Freund und verfolgt euren Fortschritt zusammen.';

  @override
  String get readingGroupEmptyAction => 'Manga entdecken';

  @override
  String get readingGroupTotalLabel => 'Gesamt';

  @override
  String readingGroupChaptersTotal(int count) {
    return '$count Kap.';
  }

  @override
  String get readingGroupInviteSoonTitle => 'Demnächst verfügbar';

  @override
  String get readingGroupInviteSoonMessage =>
      'Einladungen direkt aus der Gruppe heraus folgen bald. Erstelle bis dahin eine neue Gruppe von der Manga-Seite aus.';

  @override
  String get libraryToggleListView => 'Listenansicht';

  @override
  String get libraryToggleCardView => 'Kartenansicht';

  @override
  String get libraryShowDownloadedOnly => 'Nur heruntergeladene anzeigen';

  @override
  String get libraryShowAllMangas => 'Alle Mangas anzeigen';

  @override
  String libraryProgressLabel(int read, int total) {
    return '$read von $total Kapiteln gelesen';
  }

  @override
  String votesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stimmen',
      one: '1 Stimme',
      zero: 'Keine Stimmen',
    );
    return '$_temp0';
  }

  @override
  String get detailSectionSimilar => 'Ähnliche Mangas';

  @override
  String get rating => 'Bewertung';

  @override
  String get anonymousUser => 'Anonymer Nutzer';

  @override
  String get recommendationsColdStartTitle => 'Entdecke beliebte Manga';

  @override
  String get recommendationsColdStartSubtitle =>
      'Füge deine ersten Lektüren hinzu, um persönliche Empfehlungen zu erhalten';

  @override
  String get friendLibraryError =>
      'Die Bibliothek dieses Freundes konnte nicht geladen werden.';

  @override
  String get friendLibraryEmpty => 'Seine Bibliothek ist noch leer.';

  @override
  String friendLibraryCount(int count) {
    return '$count Manga in seiner Bibliothek';
  }

  @override
  String get statsHistoryTitle => 'Zuletzt gelesen';

  @override
  String get statsActivityTitle => 'Leseaktivität';

  @override
  String get statsBonusTag => 'Extra-Kapitel';

  @override
  String get statsNoHistory =>
      'Noch keine Lektüre aufgezeichnet. Aktualisiere deinen Fortschritt, um deinen Verlauf zu starten.';

  @override
  String get reportMoreChaptersCta => 'Mehr Kapitel melden';

  @override
  String get reportMoreChaptersDialogTitle => 'Mehr Kapitel melden';

  @override
  String get reportMoreChaptersExplainer =>
      'Hast du mehr Kapitel gelesen als die bekannte Gesamtzahl? Gib die neue Gesamtzahl an: Sie zählt für deinen Fortschritt und wird mit den Meldungen anderer Leser abgeglichen.';

  @override
  String get reportMoreChaptersInputLabel => 'Neue Kapitel-Gesamtzahl';

  @override
  String reportMoreChaptersInvalidLow(int total) {
    return 'Die Gesamtzahl muss größer als $total sein.';
  }

  @override
  String reportMoreChaptersInvalidHigh(int max) {
    return 'Die Gesamtzahl darf $max nicht überschreiten.';
  }

  @override
  String get reportMoreChaptersSubmit => 'Melden';

  @override
  String get reportMoreChaptersSuccess =>
      'Danke! Die Kapitelanzahl wurde aktualisiert.';

  @override
  String get reportMoreChaptersError =>
      'Die Meldung kann gerade nicht gesendet werden. Versuche es später erneut.';

  @override
  String get reportMoreChaptersErrorInvalid =>
      'Die bekannte Gesamtzahl hat sich inzwischen geändert. Lade die Seite neu und versuche es erneut.';

  @override
  String get reportMoreChaptersErrorThrottled =>
      'Zu viele Meldungen in kurzer Zeit. Versuche es gleich noch einmal.';

  @override
  String get reportMoreChaptersOffline => 'Offline nicht verfügbar.';

  @override
  String get dismissRecommendationSheetTitle =>
      'Diesen Titel nicht mehr empfehlen';

  @override
  String dismissRecommendationSheetSubtitle(String title) {
    return '„$title“ verschwindet aus deinen Empfehlungen. Du kannst es dir jederzeit anders überlegen.';
  }

  @override
  String get dismissReasonAlreadyRead => 'Bereits gelesen';

  @override
  String get dismissReasonAlreadyReadHint =>
      'Ich habe es gelesen, es gibt nichts mehr zu entdecken';

  @override
  String get dismissReasonNotInterested => 'Kein Interesse';

  @override
  String get dismissReasonNotInterestedHint => 'Nicht mein Genre';

  @override
  String get dismissReasonSeenElsewhere => 'Woanders gesehen';

  @override
  String get dismissReasonSeenElsewhereHint => 'Als Anime, Drama oder Film';

  @override
  String dismissRecommendationSuccess(String title) {
    return '„$title“ erscheint nicht mehr in deinen Empfehlungen';
  }

  @override
  String get dismissRecommendationUndo => 'Rückgängig';

  @override
  String get dismissRecommendationUndone => 'Empfehlung wiederhergestellt';

  @override
  String get dismissRecommendationError =>
      'Der Titel konnte gerade nicht ausgeblendet werden. Bitte versuche es später erneut.';

  @override
  String get dismissRecommendationOffline => 'Offline nicht verfügbar.';

  @override
  String get dismissRecommendationAccessibility =>
      'Lange drücken, um diesen Titel nicht mehr zu empfehlen';

  @override
  String get recommendationsSleepersTitle => '💎 Geheimtipps';

  @override
  String get sessionRejectedBanner =>
      'Sitzung abgelaufen – gespeicherte Daten werden angezeigt';

  @override
  String get sessionRejectedAction => 'Erneut anmelden';

  @override
  String get challengeLoopTitle => 'Überprüfung blockiert';

  @override
  String get challengeLoopMessage =>
      'Die Roboterprüfung dieser Seite wird nicht abgeschlossen – sie lädt immer wieder neu. Öffnen Sie die Seite im Browser, um sie abzuschließen, und kehren Sie dann hierher zurück.';

  @override
  String get challengeLoopOpenBrowser => 'Im Browser öffnen';

  @override
  String get readerRefresh => 'Seite aktualisieren';

  @override
  String get readerMoreActions => 'Weitere Aktionen';

  @override
  String get readerDownloadPage => 'Diese Seite herunterladen';

  @override
  String get adBlockerEnableAction => 'Werbeblocker aktivieren';

  @override
  String get adBlockerDisableAction => 'Werbeblocker deaktivieren';

  @override
  String get adBlockerInteractiveEnable => 'Anzeigenerkennung aktivieren';

  @override
  String get adBlockerInteractiveDisable => 'Anzeigenerkennung deaktivieren';

  @override
  String get adBlockerEnabledNotice =>
      'Werbeblocker auf dieser Seite aktiviert.';

  @override
  String get adBlockerDisabledNotice =>
      'Werbeblocker deaktiviert — Seite neu geladen, um den Inhalt wiederherzustellen.';

  @override
  String get adBlockerInteractiveOnNotice =>
      'Erkennungsmodus an — tippen Sie auf eine Anzeige, um sie zu blockieren.';

  @override
  String get adBlockerInteractiveOffNotice => 'Erkennungsmodus aus.';
}
