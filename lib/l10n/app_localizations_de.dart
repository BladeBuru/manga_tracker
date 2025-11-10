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
}
