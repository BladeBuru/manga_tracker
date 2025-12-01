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
  String get back => 'Back';

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
  String get newChapterNotifications => 'Notifications nouveaux chapitres';

  @override
  String get newChapterNotificationsEnabled => 'Activées';

  @override
  String get newChapterNotificationsDisabled => 'Désactivées';

  @override
  String get manageNotifications => 'Manage notifications';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemMode => 'System';

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

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get emailAlreadyUsed => 'This email address is already registered';

  @override
  String get networkError => 'Please check your internet connection';

  @override
  String get timeoutError =>
      'The server is taking too long to respond. Please try again.';

  @override
  String get passwordStrengthLabel => 'Password strength';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthMedium => 'Medium';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get yesValidate => 'Yes, validate';

  @override
  String chapterSkipMessage(String prev, String next) {
    return 'You are jumping from chapter $prev to $next.\nMark $prev as read?';
  }

  @override
  String validateReadingMessage(String chapter) {
    return 'Have you finished chapter $chapter?';
  }

  @override
  String get validateReadingHint =>
      'Your progress will be saved automatically.';

  @override
  String get adBlockerTitle => 'Ad Blocker';

  @override
  String get adBlockerDescription =>
      'The ad blocker automatically blocks ads on reading sites.\n\nIf you want to add links or suggest improvements for ad blocking, join our Discord server!';

  @override
  String get adBlockerTooltip => 'Ad blocker information';

  @override
  String get joinDiscord => 'Join Discord';

  @override
  String get joinDiscordSubtitle => 'Share your suggestions and report issues';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get manageDownloads => 'Gérer les téléchargements';

  @override
  String get manageDownloadsSubtitle =>
      'Voir et supprimer les chapitres téléchargés';

  @override
  String get discordLinkError => 'Unable to open Discord link';

  @override
  String get urlCopied => 'URL copied to clipboard';

  @override
  String get urlCopyError => 'Error copying URL';

  @override
  String get copyUrl => 'Copy URL';

  @override
  String get progressUpdated => 'Progress updated';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get webModeProgressTracking => 'Web Mode - Progress Tracking';

  @override
  String get webModeProgressDescription =>
      'To track your progress, paste the URL of the chapter you are currently reading.';

  @override
  String get chapterUrlLabel => 'Chapter URL';

  @override
  String get updateProgress => 'Update progress';

  @override
  String get openInNewTab => 'Open in new tab';

  @override
  String get linkUrlLabel => 'Scan site URL';

  @override
  String get linkFormatInfo => 'Chapter format required';

  @override
  String get linkFormatDescription =>
      'Include the chapter number in the URL to enable automatic progress saving.\n\nAccepted formats:\n• /chapter-23/ or /chapitre-23/\n• /c23/ or /ch23/\n• /ep-23/ or /episode-23/\n• ?chapter=23 or ?num=24';

  @override
  String get linkFormatWarning =>
      'No chapter format detected. The link will redirect to the manga page (not a specific chapter).';

  @override
  String get linkFormatDetected =>
      'Chapter format detected! Progress will be saved automatically.';

  @override
  String get linkAddCustomPattern => 'Add a custom pattern for this format';

  @override
  String get customSelectors => 'Custom Selectors';

  @override
  String get manageCustomSelectors => 'Manage Selectors';

  @override
  String get manageCustomSelectorsSubtitle =>
      'Add custom CSS selectors to block ads or identify content';

  @override
  String get addCustomSelector => 'Add Selector';

  @override
  String get selectorDomainLabel => 'Domain (e.g., example.com)';

  @override
  String get selectorCssLabel => 'CSS Selector';

  @override
  String get selectorTypeLabel => 'Selector Type';

  @override
  String get selectorTypeUrlPattern => 'URL Pattern';

  @override
  String get selectorUrlPatternLabel => 'URL Pattern (regex)';

  @override
  String get selectorUrlPatternHint =>
      'Example: /chapter-(\\d+)/ to detect /chapter-22';

  @override
  String get selectorExamplesUrlPattern => 'URL Pattern Examples:';

  @override
  String get selectorExampleUrlPattern => 'Example: /chapter-22';

  @override
  String get selectorExampleUrlPatternExplanation =>
      'If your site uses \"/chapter-22\" in the URL and the system doesn\'t detect it automatically:';

  @override
  String get selectorUrlPatternExampleDesc =>
      'Use a regular expression (regex) with (\\d+) to capture the chapter number.\n\nThis pattern will be applied to ALL sites.\n\nPattern examples:\n• /chapter-(\\d+)/ → detects /chapter-22\n• /chapppter-(\\d+)/ → detects /chapppter-22 (with 3 p\'s)\n• /manga/chapter-(\\d+)/ → detects /manga/chapter-22\n• /episode-(\\d+)/ → detects /episode-22';

  @override
  String get selectorUrlPatternGlobal =>
      'ℹ️ The pattern will be applied to ALL sites. No need to specify a domain.';

  @override
  String get selectorTypeAdBlocker => 'Ad Blocker';

  @override
  String get selectorTypeChapterContent => 'Chapter Content';

  @override
  String get selectorDescriptionLabel => 'Description (optional)';

  @override
  String get selectorDescriptionHint => 'Selector description';

  @override
  String get selectorRequiredFields => 'All fields are required';

  @override
  String get selectorAdded => 'Selector added';

  @override
  String get deleteSelector => 'Delete Selector';

  @override
  String get deleteSelectorConfirm =>
      'Are you sure you want to delete this selector?';

  @override
  String get selectorDeleted => 'Selector deleted';

  @override
  String get selectorsExported => 'Selectors exported to clipboard';

  @override
  String get importSelectors => 'Import Selectors';

  @override
  String get selectorsJsonLabel => 'Selectors JSON';

  @override
  String get import => 'Import';

  @override
  String selectorsImported(String count) {
    return '$count selector(s) imported';
  }

  @override
  String get selectorsReadyToShare =>
      'Selectors ready to share! Paste the JSON in Discord.';

  @override
  String get exportSelectors => 'Export';

  @override
  String get shareSelectors => 'Share';

  @override
  String get noCustomSelectors => 'No custom selectors';

  @override
  String get addFirstSelector => 'Add your first selector to get started';

  @override
  String get selectorExamples => 'Examples';

  @override
  String get selectorExamplesAdBlocker => 'Examples for blocking ads:';

  @override
  String get selectorExampleAd1 => 'Ad Banner';

  @override
  String get selectorExampleAd2 => 'Ad by ID';

  @override
  String get selectorExampleAd3 => 'Ad Iframe';

  @override
  String get selectorExampleAd4 => 'Ad Script';

  @override
  String get selectorExamplesChapter =>
      'Examples for identifying chapter content:';

  @override
  String get selectorExampleChapter1 => 'Chapter Container';

  @override
  String get selectorExampleChapter2 => 'Manga Reader';

  @override
  String get selectorExampleChapter3 => 'Chapter Images';

  @override
  String get selectorExampleChapter4 => 'Reading Content';

  @override
  String get selectorExampleChapter5 => 'Format manga/chapter-22';

  @override
  String get selectorExampleChapter5Explanation =>
      'Concrete example: If your URL is \"mysite.com/manga/chapter-22\"';

  @override
  String get selectorUrlFormatDetected =>
      '✅ GOOD NEWS: The \"/manga/chapter-22\" format in the URL is already automatically detected by the system!\n\nYou do NOT need to add a CSS selector if your site only uses this format in the URL.';

  @override
  String get selectorWhenNeeded => 'When to add a CSS selector?';

  @override
  String get selectorPracticalExample => 'Practical example:';

  @override
  String get selectorExampleScenario =>
      'Case: Your site uses \"/chapppter-22\" (with 3 p\'s) instead of \"/chapter-22\"';

  @override
  String get selectorStep1 => 'Open the chapter page in your browser';

  @override
  String get selectorStep2 => 'Press F12 to open developer tools';

  @override
  String get selectorStep3 => 'Click on the \"Inspect\" icon (or Ctrl+Shift+C)';

  @override
  String get selectorStep4 =>
      'Click on the container that contains the chapter images';

  @override
  String get selectorStep5 =>
      'In the HTML code, find the container\'s class or ID';

  @override
  String get selectorFillForm => 'Fill in the form:';

  @override
  String get selectorCssWhenNeededDesc =>
      '⚠️ ONLY if your site needs a specific selector to identify the HTML content of the page.\n\nIf the system already detects your chapter correctly via the URL, you do NOT need to add a CSS selector.\n\nAdd a CSS selector ONLY if:\n• The system does not correctly detect the chapter content\n• You want to block ads specific to this site\n• The site uses particular classes/IDs for content\n\nTo find the selector: Open the page (F12 → Inspect), find the container of chapter images, and use its class or ID (e.g., .manga-content, #chapter-images)';

  @override
  String get selectorDomainExampleDesc =>
      'Enter only the domain name (without http://, without www, without the path /manga/chapter-22)';

  @override
  String get selectorOtherExamples => 'Other common examples:';

  @override
  String get selectorExampleChapter5Desc =>
      'For sites using the manga/chapter-22 format in their URLs. Example: if your URL is \"site.com/manga/chapter-22\", use these selectors to identify the content.';

  @override
  String get selectorExamplesHint =>
      'Tip: Use your browser\'s developer tools (F12) to inspect elements and find appropriate CSS selectors.';

  @override
  String get captchaDetected =>
      'Captcha detected - Ad blocker has been temporarily disabled';

  @override
  String get captchaResolved =>
      'Captcha resolved - Ad blocker has been re-enabled';

  @override
  String get scrollPositionSaved => 'Scroll position saved';

  @override
  String get chapterProgressSaved => 'Chapter progress saved';

  @override
  String get readingOffline => 'Reading offline';

  @override
  String get chapterDownloaded => 'Chapter downloaded';

  @override
  String get offlineReadingMode => 'Offline reading mode';

  @override
  String get deleteChapterTitle => 'Delete chapter';

  @override
  String deleteChapterMessage(int chapterNumber) {
    return 'Do you really want to delete chapter $chapterNumber?';
  }

  @override
  String get deleteAllChaptersTitle => 'Delete all chapters';

  @override
  String get deleteAllChaptersMessage =>
      'Do you really want to delete all downloaded chapters for this manga?';

  @override
  String get deleteAllDownloadsTitle => 'Delete all downloads';

  @override
  String get deleteAllDownloadsMessage =>
      'Do you really want to delete ALL downloads? This action is irreversible.';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get chapterDeleted => 'Chapter deleted';

  @override
  String get allChaptersDeleted => 'All chapters deleted';

  @override
  String get allDownloadsDeleted => 'All downloads deleted';

  @override
  String get noChaptersDownloaded => 'No chapters downloaded';

  @override
  String chaptersDownloadedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters downloaded',
      one: '1 chapter downloaded',
      zero: 'No chapters downloaded',
    );
    return '$_temp0';
  }

  @override
  String get readChapter => 'Read';

  @override
  String get deleteAllChaptersAction => 'Delete all chapters';

  @override
  String get deleteAllDownloadsTooltip => 'Delete all downloads';
}
