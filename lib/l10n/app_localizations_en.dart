// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MangaTracker';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get invalidCredentials => 'Invalid credentials';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get trending => 'Trending';

  @override
  String get popular => 'Popular';

  @override
  String get newMangas => 'New';

  @override
  String get offlineMode => 'Offline mode';

  @override
  String get offlineModeNoCache => 'Offline mode - No cached data';

  @override
  String get offlineModeActionQueued => 'Offline mode - Action queued';

  @override
  String pendingActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
      zero: 's',
    );
    return '$count pending action$_temp0';
  }

  @override
  String get retry => 'Retry';

  @override
  String get error => 'Error';

  @override
  String get library => 'Library';

  @override
  String get search => 'Search';

  @override
  String get profile => 'My account';

  @override
  String get account => 'Account';

  @override
  String get settings => 'Settings';

  @override
  String get actions => 'Actions';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Change your login password';

  @override
  String get accountInformation => 'Account information';

  @override
  String get email => 'Email';

  @override
  String get notifications => 'Notifications';

  @override
  String get manageNotifications => 'Manage notifications';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutSubtitle => 'Sign out of your account';

  @override
  String get confirmLogout => 'Sign out';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to sign out?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Irreversible action';

  @override
  String get confirmDeleteAccount => 'Delete account';

  @override
  String get confirmDeleteAccountMessage =>
      'This action is irreversible. All your data will be permanently deleted and cannot be recovered.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get passwordChangedSuccess => 'Password changed successfully';

  @override
  String get passwordChangeError => 'Error changing password';

  @override
  String get accountDeletedSuccess => 'Account deleted successfully';

  @override
  String get accountDeleteError => 'Error deleting account';

  @override
  String get userInfoLoadError => 'Unable to load user information';

  @override
  String get user => 'User';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonAvatar => 'Coming soon: avatar change';

  @override
  String get whatsNew => 'What\'s new?';

  @override
  String get version => 'Version';

  @override
  String get newFeaturesAvailable => 'New features available';

  @override
  String get currentVersion => 'Current version';

  @override
  String get great => 'Great!';

  @override
  String get authorizationRequired => 'Authorization required';

  @override
  String get modifyLink => 'Modify link';

  @override
  String get removeLink => 'Remove link';

  @override
  String get chapterSkip => 'Chapter skip';

  @override
  String get validateReading => 'Validate reading';

  @override
  String get addToLibrary => 'Add to library';

  @override
  String get removeFromLibrary => 'Remove from library';

  @override
  String get updateStatus => 'Update status';

  @override
  String get reading => 'Reading';

  @override
  String get completed => 'Completed';

  @override
  String get onHold => 'On hold';

  @override
  String get dropped => 'Dropped';

  @override
  String get planToRead => 'Plan to read';

  @override
  String get reReading => 'Re-reading';

  @override
  String get chapters => 'Chapters';

  @override
  String get readChapters => 'Read chapters';

  @override
  String get totalChapters => 'Total chapters';

  @override
  String get associatedNames => 'Associated Names';

  @override
  String associatedNamesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count names',
      one: '$count name',
      zero: 'No names',
    );
    return '$_temp0';
  }

  @override
  String get saveProgress => 'Save progress';

  @override
  String get description => 'Description';

  @override
  String get authors => 'Authors';

  @override
  String get genres => 'Genres';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get noResults => 'No results';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get home => 'Home';

  @override
  String get myAccount => 'My account';

  @override
  String get offlineModeCached => 'Offline mode - Cached data';

  @override
  String get biometricAuthFailed => 'Biometric authentication failed';

  @override
  String get biometricAuth => 'Biometric login';

  @override
  String get addLink => 'Add link';

  @override
  String get addOrModifyLink => 'Add or modify link';

  @override
  String get linkUrlPlaceholder => 'https://example.com';

  @override
  String get validate => 'Validate';

  @override
  String get invalidLink =>
      'Invalid link. The link must start with http:// or https://';

  @override
  String get linkSaved => 'Link saved!';

  @override
  String get linkRemoved => 'Link removed!';

  @override
  String get readOnline => 'Read online';

  @override
  String get manageLink => 'Manage link';

  @override
  String get recommendedMangas => 'Recommended mangas';

  @override
  String get noRecommendationsAvailable => 'No recommendations available.';

  @override
  String get close => 'Close';

  @override
  String get changeStatus => 'Change status';

  @override
  String get mangaAddedToLibrary => 'Manga added to library';

  @override
  String get mangaMarkedAs => 'Manga marked as';

  @override
  String get readLater => 'Read later';

  @override
  String get upToDate => 'Up to date';

  @override
  String get addToReadLater => 'Add to \"Read later\"';

  @override
  String get mangaRemovedFromLibrary => 'Manga removed from library';

  @override
  String get searchPlaceholder => 'Search Mangas, Manwhas, ...';

  @override
  String get year => 'Year';

  @override
  String get status => 'Status';

  @override
  String get author => 'Author';

  @override
  String get artist => 'Artist';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get seeMore => 'See more';

  @override
  String get seeLess => 'See less';

  @override
  String get all => 'All';

  @override
  String get newReleases => 'New releases';

  @override
  String get chapter => 'Chapter';

  @override
  String chaptersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '$count chapter',
      zero: 'No chapters',
    );
    return '$_temp0';
  }

  @override
  String chapterSaved(String chapter) {
    return 'Chapter $chapter saved';
  }

  @override
  String get chapterRead => 'read';

  @override
  String get chapterUnread => 'unread';

  @override
  String mangaAddedToLibrarySuccess(String title) {
    return '$title has been added to the library!';
  }

  @override
  String get errorAddingToLibrary => 'Error adding to library.';

  @override
  String get errorUpdatingChapter => 'Error updating chapter.';

  @override
  String cannotOpenLink(String url) {
    return 'Cannot open link: $url';
  }

  @override
  String get searchHistoryTitle => 'Search history';

  @override
  String get searchEmptyStateMessage => 'Search for a manga, manhwa or manhua';

  @override
  String get clear => 'Clear';

  @override
  String get biometricAuthTitle => 'Biometric authentication';

  @override
  String get biometricAuthSubtitle =>
      'Use fingerprint or Face ID to sign in quickly';

  @override
  String get enableBiometricAuth => 'Biometric authentication enabled';

  @override
  String get disableBiometricAuth => 'Biometric authentication disabled';

  @override
  String get biometricAuthEnabled => 'Enabled';

  @override
  String get biometricAuthDisabled => 'Disabled';

  @override
  String get biometricAuthFirstTimeTitle => 'Enable biometric authentication?';

  @override
  String get biometricAuthFirstTimeMessage =>
      'Would you like to use your fingerprint or Face ID to sign in quickly in the future?';

  @override
  String get biometricAuthNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get biometricAuthRequiresReconnect =>
      'To enable biometric authentication, please sign in again';

  @override
  String get or => 'Or';

  @override
  String get startTrackingNow => 'Start tracking your reading now';

  @override
  String get username => 'Username';

  @override
  String get confirmPassword => 'Confirm';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get newPassword => 'New password';

  @override
  String get validationEmailRequired => 'Please enter your email address';

  @override
  String get validationEmailInvalid => 'Please enter a valid email address';

  @override
  String get validationPasswordRequired => 'Please enter your password';

  @override
  String get validationPasswordLength =>
      'Your password must be between 8 and 64 characters';

  @override
  String get validationPasswordComplexity =>
      'Your password must contain at least one lowercase letter, one uppercase letter, and one special character';

  @override
  String get validationConfirmPasswordRequired =>
      'Please confirm your password';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';
}
